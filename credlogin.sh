# credlogin — pull per-service credentials out of LastPass into the current
# shell, on demand. Secrets live in exported env vars (or the ssh-agent) for
# the lifetime of the shell; the one exception is a value whose spec entry is
# marked "+", which is also written to the shell cache under ~/.cache/shell so
# that a later shell can log its service in without a LastPass session.
#
# Usage:
#   credlogin login <service> <instance>
#   credlogin logout <service>
#   credlogin list [service]
#   credlogin add <service> <instance>
#   credlogin set <service> <instance>
#   credlogin define <service> <entry>...
#   credlogin status
#
# Entries live in LastPass at "Shell Logins/<service>/<instance>", with all
# of a service's data packed as "KEY=value" lines in the item's notes field.
# lastpass-cli's non-interactive custom --field= edits only work on a fixed
# set of built-in note types (server, ssh-key, ...) with fixed field names —
# there's no "Generic" type with arbitrary field names — so notes is the one
# field every entry has that can hold whatever a service needs. A service
# with exactly one field named "notes" instead stores its raw, unwrapped
# value there (used by ssh, whose PEM key can't be squeezed onto one line).
#
# Most services are declared with `credlogin define`, which takes a list of
# environment variable settings and generates the functions below from it; see
# __credlogin_define for the entry grammar. A service that needs real logic
# instead (ssh) is still just a pair of functions named
# _credlogin_<service>_login/_logout plus a _credlogin_<service>_fields array
# of the KEY names it needs — there's no central registry to keep in sync
# either way.

typeset -gA CREDLOGIN_ACTIVE
typeset -gA CREDLOGIN_SSH_PUBKEY
typeset -gA CREDLOGIN_SPEC

# zsh expands aliases while parsing, so the alias defined below turns this
# function's name into `noglob credlogin` on a re-source of an already-loaded
# shell. Drop it first; the alias is redefined a few lines down either way.
unalias credlogin 2>/dev/null

credlogin() {
  local verb="$1" service="$2" instance="$3"
  case "${verb}" in
    login) __credlogin_login "${service}" "${instance}" ;;
    logout) __credlogin_logout "${service}" ;;
    list|ls) __credlogin_list "${service}" ;;
    add) __credlogin_store add "${service}" "${instance}" ;;
    set) __credlogin_store set "${service}" "${instance}" ;;
    define) __credlogin_define "${service}" "${@:3}" ;;
    status) __credlogin_status ;;
    *) __credlogin_usage ;;
  esac
}

# so a `NAME?` entry doesn't have to be quoted past zsh's globbing
alias credlogin='noglob credlogin'

__credlogin_usage() {
  cat >&2 <<'EOF'
usage: credlogin <verb> <service> [instance]
  login <service> <instance>   pull credentials from LastPass into this shell
  logout <service>             undo the active login for that service
  list [service]                list services, or instances of one service
  add <service> <instance>     store a new instance's credentials in LastPass
  set <service> <instance>     replace an existing instance's credentials
  define <service> <entry>...  declare a service as a list of env var settings
  status                        show what's currently logged in

define entries, each naming one or more variables:
  NAME          required value, read from the NAME= line of the notes field
  NAME?         same, but login still succeeds when it isn't stored
  A,B,C         one stored value (under key A) exported as all three names
  NAME=value    a fixed value, exported every login
  NAME=$(cmd)   a value produced by running cmd, not stored in LastPass at all
  -NAME         never exported, only cleared — for a conflicting variable
  +NAME         a fetched value that may also live in the shell cache, so a
                later login needs no LastPass session until the cache expires
  @name         labels the variant it appears in, so `login <service> <name>`
                uses that shape outright; a variant that requires nothing
                stored has to be labelled, and is reachable only by its name
  --            separates alternative shapes of the same service; an unlabelled
                login uses the first whose required values are all stored
EOF
}

__credlogin_ready() {
  quiet_which lpass || {
    echo "credlogin: lpass CLI not found (brew install lastpass-cli)" >&2
    return 1
  }
  lpass status -q &>/dev/null && return 0
  echo "credlogin: not logged in to LastPass — run \`lpass login you@example.com\` first" >&2
  return 1
}

# named item_path, not path: zsh ties the lowercase "path" array to $PATH,
# and shadowing it with a local scalar breaks command lookup in this scope
__credlogin_item_path() {
  echo "Shell Logins/${1}/${2}"
}

__credlogin_notes() {
  local service="$1" instance="$2"
  lpass show --sync=auto --notes "$(__credlogin_item_path "${service}" "${instance}")" 2>/dev/null
}

# extract the value of a "KEY=value" line from a notes blob
__credlogin_kv() {
  local notes="$1" key="$2" line
  while IFS= read -r line; do
    [[ "${line}" == "${key}"=* ]] && { echo "${line#"${key}"=}"; return 0; }
  done <<<"${notes}"
  return 1
}

# a service whose variables all have fixed values has nothing to fetch, so it
# needs neither an instance nor a LastPass session — and neither does a
# labelled variant of one that stores nothing, like claude's subscription
# shape or github's gh-CLI shape, nor a login the shell cache can still
# satisfy on its own
__credlogin_needs_lastpass() {
  local spec="${CREDLOGIN_SPEC[$1]}"
  if [[ -n "${spec}" ]]; then
    spec="$(__credlogin_spec_for "$1" "$2")"
    __credlogin_spec_reads_notes "${spec}" || return 1
    ! __credlogin_cached_notes "$1" "$2" "${spec}" &>/dev/null
    return
  fi

  local fields_var="_credlogin_${1}_fields"
  (( ${+parameters[${fields_var}]} )) || return 0

  local -a fields
  fields=("${(@P)fields_var}")
  (( ${#fields} ))
}

__credlogin_login() {
  local service="$1" instance="$2"
  if [[ -z "${service}" ]]; then
    echo "usage: credlogin login <service> <instance>" >&2
    return 1
  fi

  local login_fn="_credlogin_${service}_login"
  (( ${+functions[${login_fn}]} )) || {
    echo "credlogin: unknown service '${service}' (see \`credlogin list\`)" >&2
    return 1
  }

  if __credlogin_needs_lastpass "${service}" "${instance}"; then
    if [[ -z "${instance}" ]]; then
      echo "usage: credlogin login <service> <instance>" >&2
      return 1
    fi
    __credlogin_ready || return 1
  fi

  "${login_fn}" "${instance}" || return 1
  CREDLOGIN_ACTIVE[${service}]="${instance:-on}"
}

__credlogin_logout() {
  local service="$1"
  if [[ -z "${service}" ]]; then
    echo "usage: credlogin logout <service>" >&2
    return 1
  fi

  local instance="${CREDLOGIN_ACTIVE[${service}]}"
  if [[ -z "${instance}" ]]; then
    echo "credlogin: ${service} is not logged in" >&2
    return 1
  fi

  "_credlogin_${service}_logout" "${instance}"
  unset "CREDLOGIN_ACTIVE[${service}]"
}

__credlogin_list() {
  local service="$1"

  if [[ -z "${service}" ]]; then
    local fn
    for fn in ${(ko)functions}; do
      [[ "${fn}" == _credlogin_*_login ]] || continue
      fn="${fn#_credlogin_}"
      echo "${fn%_login}"
    done
    return
  fi

  __credlogin_ready || return 1
  lpass ls "Shell Logins/${service}" 2>/dev/null | sed -E "s#^Shell Logins/${service}/##"
}

__credlogin_store() {
  local verb="$1" service="$2" instance="$3"
  if [[ -z "${service}" || -z "${instance}" ]]; then
    echo "usage: credlogin ${verb} <service> <instance>" >&2
    return 1
  fi

  local fields_var="_credlogin_${service}_fields"
  (( ${+parameters[${fields_var}]} )) || {
    echo "credlogin: unknown service '${service}' (see \`credlogin list\`)" >&2
    return 1
  }
  __credlogin_ready || return 1

  local -a fields
  fields=("${(@P)fields_var}")
  (( ${#fields} )) || {
    echo "credlogin: ${service} stores nothing in LastPass" >&2
    return 1
  }

  local item_path
  item_path="$(__credlogin_item_path "${service}" "${instance}")"

  local value
  if [[ "${#fields[@]}" -eq 1 && "${fields[1]}" == "notes" ]]; then
    echo "credlogin: paste ${item_path} contents, then Ctrl-D on its own line:" >&2
    value="$(cat)"
  else
    local field blob=""
    for field in "${fields[@]}"; do
      print -n "credlogin: ${field} for ${item_path}: "
      read -rs value
      print
      blob+="${field}=${value}"$'\n'
    done
    value="${blob}"
  fi

  # `lpass add` always creates, so re-adding a path that already exists leaves
  # two items with the same name and every later `lpass show` on it dies as
  # ambiguous; `lpass edit` is the one that replaces an entry in place. Either
  # way --notes rewrites the whole blob, so `set` re-prompts for every field:
  # answering blank is how you clear one (login skips empty values).
  local lpass_verb="add" past_tense="added"
  if [[ "${verb}" == "set" ]]; then
    lpass_verb="edit"
    past_tense="updated"
  fi

  lpass "${lpass_verb}" --non-interactive --sync=now --notes "${item_path}" \
    <<<"${value}" || return 1

  # a cached copy of what was just replaced would otherwise go on answering
  # logins with the old value until it expired
  local cache_file
  cache_file="$(__credlogin_cache_path "${service}" "${instance}")" &&
    rm -f "${cache_file}"

  echo "credlogin: ${past_tense} ${item_path}"
}

__credlogin_status() {
  if (( ${#CREDLOGIN_ACTIVE} == 0 )); then
    echo "credlogin: no active logins"
    return
  fi

  local service
  for service in ${(ko)CREDLOGIN_ACTIVE}; do
    echo "${service} -> ${CREDLOGIN_ACTIVE[${service}]}"
  done
}

# Specs are stored one entry per line as "<kind> <names> <value>", with the
# value running to the end of the line and "--" alone on a line between
# variants. Translating at define time means the grammar is parsed in exactly
# one place, and the fixed two-word prefix lets login split each line back
# apart without caring what the value contains.
__credlogin_spec_line() {
  local entry="$1" inner
  case "${entry}" in
    --) print -r -- "--" ;;
    @?*) print -r -- "variant ${entry#@} " ;;
    -?*) print -r -- "clear ${entry#-} " ;;
    # only a fetched value can be cached: a literal is already in the spec, and
    # the rest name no value at all
    +?*)
      inner="$(__credlogin_spec_line "${entry#+}")"
      case "${inner%% *}" in
        secret|optional|command) print -r -- "cached_${inner}" ;;
        *) return 1 ;;
      esac
      ;;
    # a value written as a command substitution is produced by running that
    # command at login rather than read from the notes field; every other
    # entry with an "=" in it is a fixed value
    *=\$\(*\)) print -r -- "command ${entry%%=*} ${${entry#*=\$\(}%\)}" ;;
    *=*) print -r -- "literal ${entry%%=*} ${entry#*=}" ;;
    *\?) print -r -- "optional ${entry%\?} " ;;
    *) print -r -- "secret ${entry} " ;;
  esac
}

__credlogin_define() {
  local service="$1"
  shift
  if [[ -z "${service}" || $# -eq 0 ]]; then
    echo "usage: credlogin define <service> <entry>..." >&2
    return 1
  fi
  [[ "${service}" =~ '^[A-Za-z_][A-Za-z0-9_]*$' ]] || {
    echo "credlogin: invalid service name '${service}'" >&2
    return 1
  }

  # a variant requiring nothing stored resolves against any instance at all, so
  # letting login fall through to one would turn every mistyped instance into a
  # silent success; such a variant must be labelled and is then reachable only
  # by its name
  local entry line kind names name prev="" spec="" required=0 labelled=0 multi=0
  local -a fields
  __credlogin_reachable() {
    (( required || labelled )) && return 0
    echo "credlogin: a variant of ${service} requires nothing stored, so it would match every instance — label it with @name" >&2
    return 1
  }
  for entry in "$@"; do
    line="$(__credlogin_spec_line "${entry}")" || {
      echo "credlogin: '${entry}' names no stored value, so it cannot be cached" >&2
      return 1
    }
    if [[ "${line}" == "--" ]]; then
      [[ -n "${prev}" && "${prev}" != "--" ]] || {
        echo "credlogin: empty variant in ${service} spec" >&2
        return 1
      }
      __credlogin_reachable || return 1
      required=0
      labelled=0
      multi=1
    else
      kind="${line%% *}"
      names="${line#* }"
      names="${names%% *}"
      [[ -n "${names}" ]] || {
        echo "credlogin: '${entry}' names no variable" >&2
        return 1
      }
      if [[ "${kind}" == variant ]]; then
        # a variant label is matched against the instance argument, so it
        # follows LastPass item naming rather than the C identifier rule.
        # Checked against the rest of the line, not just its first word, so a
        # label with a space in it fails instead of being quietly truncated.
        [[ "${${line#* }% }" =~ '^[A-Za-z0-9][A-Za-z0-9._-]*$' ]] || {
          echo "credlogin: invalid variant name '${entry#@}'" >&2
          return 1
        }
        labelled=1
      fi
      [[ "${kind}" == *secret ]] && required=1
      [[ "${kind}" == variant ]] || for name in ${(s:,:)names}; do
        [[ "${name}" =~ '^[A-Za-z_][A-Za-z0-9_]*$' ]] || {
          echo "credlogin: invalid variable name '${name}' in '${entry}'" >&2
          return 1
        }
      done
      # the first of an alias list is the key the value is stored under, so
      # that's the one add/set prompts for
      [[ "${kind}" == *secret || "${kind}" == *optional ]] &&
        fields+=("${names%%,*}")
    fi
    spec+="${line}"$'\n'
    prev="${line}"
  done
  [[ "${prev}" != "--" ]] || {
    echo "credlogin: empty variant in ${service} spec" >&2
    return 1
  }
  if (( multi )); then
    __credlogin_reachable || return 1
  fi
  unfunction __credlogin_reachable

  CREDLOGIN_SPEC[${service}]="${spec%$'\n'}"
  typeset -ga "_credlogin_${service}_fields"
  set -A "_credlogin_${service}_fields" "${(@u)fields}"
  functions[_credlogin_${service}_login]='__credlogin_spec_login '"${service}"' "$1"'
  functions[_credlogin_${service}_logout]='__credlogin_spec_logout '"${service}"
}

# every variable a spec mentions, across all of its variants and whatever kind
# of entry named it: login clears this whole set before exporting anything, so
# re-logging in or switching instances never leaves a variable behind from the
# shape that was active before
__credlogin_spec_vars() {
  local line names
  while IFS= read -r line; do
    [[ "${line}" == "--" || "${line}" == variant\ * ]] && continue
    names="${line#* }"
    print -rl -- ${(s:,:)${names%% *}}
  done <<<"${CREDLOGIN_SPEC[$1]}"
}

# the lines of the variant an instance labels with an `@name` entry, if any.
# Naming a shape outright keeps a mistyped instance an error instead of a
# quiet slide into whichever later variant happens to need nothing stored.
__credlogin_spec_variant() {
  local service="$1" instance="$2" line found=0 variant=""
  [[ -n "${instance}" ]] || return 1

  while IFS= read -r line; do
    if [[ "${line}" == "--" ]]; then
      (( found )) && break
      variant=""
    elif [[ "${line}" == "variant ${instance} " ]]; then
      found=1
    else
      variant+="${line}"$'\n'
    fi
  done <<<"${CREDLOGIN_SPEC[${service}]}"

  (( found )) || return 1
  print -rn -- "${variant}"
}

# the spec a login resolves against: the variant the instance names, or every
# shape but the command-sourced ones. A command hands out the same value for
# any instance, so its variant is reachable only by its label, exactly like
# any other variant that needs nothing stored.
__credlogin_spec_for() {
  local spec line
  spec="$(__credlogin_spec_variant "$1" "$2")" && { print -rn -- "${spec}"; return }

  while IFS= read -r line; do
    [[ "${line%% *}" == *command ]] && continue
    print -r -- "${line}"
  done <<<"${CREDLOGIN_SPEC[$1]}"
}

__credlogin_spec_reads_notes() {
  local line
  while IFS= read -r line; do
    case "${line%% *}" in *secret|*optional) return 0 ;; esac
  done <<<"$1"
  return 1
}

# Cacheable values — the ones whose entry carried a "+" — are copied into the
# shell cache at login and read back from there until it expires, so a later
# shell, or a sandbox account whose LastPass session is gone, can log the
# service in without one. Caching is per variable and off by default: a value
# that outlives its cache entry is a value left on disk for no gain.
__credlogin_cache_path() {
  [[ "$2" =~ '^[A-Za-z0-9][A-Za-z0-9._-]*$' ]] || return 1
  echo "${SHELL_CACHE_DIR}/credlogin/${1}/${2}"
}

# the cached notes for a login, when they are fresh and complete enough to
# resolve the spec alone; a partial cache is no use, since resolving it still
# ends in the LastPass fetch it was meant to save
__credlogin_cached_notes() {
  local service="$1" instance="$2" spec="$3" file notes
  file="$(__credlogin_cache_path "${service}" "${instance}")" || return 1
  notes="$(shell_cache_read "${file}")" || return 1
  __credlogin_spec_resolve "${spec}" "${notes}" &>/dev/null || return 1
  print -r -- "${notes}"
}

__credlogin_cache_write() {
  local service="$1" instance="$2" spec="$3" notes="$4"
  local file line key value blob=""
  file="$(__credlogin_cache_path "${service}" "${instance}")" || return

  while IFS= read -r line; do
    [[ "${line%% *}" == cached_* ]] || continue
    key="${${${line#* }%% *}%%,*}"
    value="$(__credlogin_kv "${notes}" "${key}")" || continue
    blob+="${key}=${value}"$'\n'
  done <<<"${spec}"

  # a blob the next login would have to go back to LastPass for anyway is one
  # more copy of a secret on disk buying nothing, and a spec with nothing
  # cacheable in it has no business leaving a file behind at all
  [[ -n "${blob}" ]] || return
  __credlogin_spec_resolve "${spec}" "${blob}" &>/dev/null || return

  print -rn -- "${blob}" | shell_cache_write "${file}"
}

# run the commands a spec sources values from and append what they print to
# the notes, under the key the entry names. Everything downstream then sees
# one shape whatever a value came from, so a command-sourced value resolves
# and caches like a stored one.
__credlogin_spec_run() {
  local spec="$1" notes="$2" line key value
  while IFS= read -r line; do
    [[ "${line%% *}" == *command ]] || continue
    key="${${${line#* }%% *}%%,*}"
    __credlogin_kv "${notes}" "${key}" &>/dev/null && continue
    value="$(eval "${${line#* }#* }" 2>/dev/null)" || continue
    [[ -n "${value}" ]] || continue
    [[ -n "${notes}" ]] && notes+=$'\n'
    notes+="${key}=${value}"
  done <<<"${spec}"
  print -r -- "${notes}"
}

# the notes to resolve a login against: the cache when it can carry the login
# on its own, otherwise LastPass and the spec's own commands, whose cacheable
# values are written back for the shells that come after
__credlogin_notes_for() {
  local service="$1" instance="$2" spec="$3" notes
  if ! notes="$(__credlogin_cached_notes "${service}" "${instance}" "${spec}")"; then
    __credlogin_spec_reads_notes "${spec}" &&
      notes="$(__credlogin_notes "${service}" "${instance}")"
    notes="$(__credlogin_spec_run "${spec}" "${notes}")"
    __credlogin_cache_write "${service}" "${instance}" "${spec}" "${notes}"
  fi
  print -r -- "${notes}"
}

__credlogin_spec_logout() {
  local name
  for name in $(__credlogin_spec_vars "$1"); do
    unset "${name}"
  done
}

# resolve variants in order and report the first that comes out whole as
# "NAME value" lines. Nothing here touches the environment, so a failed login
# is a no-op and a spec can be tried against the cache and the answer thrown
# away when it comes up short.
__credlogin_spec_resolve() {
  local spec="$1" notes="$2" line kind names name value
  local ok=1 required=0 multi=0
  local -a pending

  [[ $'\n'"${spec}"$'\n' == *$'\n--\n'* ]] && multi=1

  while IFS= read -r line; do
    if [[ "${line}" == "--" ]]; then
      (( ok && (required || ! multi) )) && break
      ok=1
      required=0
      pending=()
      continue
    fi
    (( ok )) || continue

    kind="${line%% *}"
    value="${line#* }"
    names="${value%% *}"
    value="${value#* }"

    case "${kind}" in
      literal) pending+=("${names} ${value}") ;;
      # a command's value reached the notes the same way a stored one did, so
      # only its kind tells them apart, and only for deciding whether this
      # shape is one an unlabelled login may fall through to
      *secret|*optional|*command)
        [[ "${kind}" == *secret ]] && required=1
        value="$(__credlogin_kv "${notes}" "${names%%,*}")"
        if [[ -z "${value}" ]]; then
          [[ "${kind}" == *optional ]] || ok=0
          continue
        fi
        for name in ${(s:,:)names}; do
          pending+=("${name} ${value}")
        done
        ;;
    esac
  done <<<"${spec}"

  (( ok && (required || ! multi) )) || return 1
  (( ${#pending} )) && print -rl -- "${pending[@]}"
  return 0
}

__credlogin_spec_login() {
  local service="$1" instance="$2" spec notes resolved line names item
  local -a wanted

  spec="$(__credlogin_spec_for "${service}" "${instance}")"
  notes="$(__credlogin_notes_for "${service}" "${instance}" "${spec}")"

  resolved="$(__credlogin_spec_resolve "${spec}" "${notes}")" || {
    while IFS= read -r line; do
      [[ "${line%% *}" == *secret || "${line%% *}" == *command ]] || continue
      names="${line#* }"
      wanted+=("${${names%% *}%%,*}")
    done <<<"${spec}"
    echo "credlogin: no usable fields for ${service}/${instance} (looked for: ${wanted})" >&2
    return 1
  }

  __credlogin_spec_logout "${service}"
  while IFS= read -r item; do
    [[ -n "${item}" ]] || continue
    export "${item%% *}=${item#* }"
  done <<<"${resolved}"
}

# ssh — the notes field holds the raw PEM private key directly (its one
# field is literally named "notes", not packed as a KEY=value line), since
# a private key is multi-line and can't sit on one line of that format.
# Passphrase-protected keys aren't specifically handled: ssh-add will fall
# back to its normal askpass prompt if the key needs one.
typeset -ga _credlogin_ssh_fields
_credlogin_ssh_fields=("notes")

_credlogin_ssh_login() {
  local instance="$1" key pubkey
  key="$(__credlogin_notes ssh "${instance}")"
  [[ -n "${key}" ]] || {
    echo "credlogin: no key stored for ssh/${instance}" >&2
    return 1
  }

  pubkey="$(ssh-keygen -y -f /dev/stdin <<<"${key}" 2>/dev/null)"
  [[ -n "${pubkey}" ]] || {
    echo "credlogin: could not parse key for ssh/${instance}" >&2
    return 1
  }

  ssh-add - <<<"${key}" &>/dev/null || {
    echo "credlogin: ssh-add failed for ssh/${instance}" >&2
    return 1
  }
  CREDLOGIN_SSH_PUBKEY[${instance}]="${pubkey}"
}

_credlogin_ssh_logout() {
  local instance="$1"
  local pubkey="${CREDLOGIN_SSH_PUBKEY[${instance}]}"
  [[ -n "${pubkey}" ]] || {
    echo "credlogin: no recorded key for ssh/${instance}" >&2
    return 1
  }
  ssh-add -d /dev/stdin <<<"${pubkey}" &>/dev/null
  unset "CREDLOGIN_SSH_PUBKEY[${instance}]"
}

# github — one token under both names that mean "GitHub auth", from either of
# the two places one lives. `login github gh` takes the gh CLI's own token,
# which is what a host shell wants and what zshrc.sh logs in at every start;
# any other instance takes a token stored in LastPass, which is what the
# sandbox wants, since the gh CLI's configuration never crosses into it. Both
# are cached: they are revocable, expiring tokens, and the alternative is a
# `gh` call, or an `lpass login`, in every shell.
credlogin define github \
  @gh '+GITHUB_TOKEN,GH_TOKEN=$(gh auth token)' \
  -- \
  +GITHUB_TOKEN,GH_TOKEN

# claude — replaces the hardcoded key block that used to live in shrc.sh.
# Fill in ANTHROPIC_FOUNDRY_API_KEY/_BASE_URL for an Azure Foundry-proxied
# instance, or just ANTHROPIC_API_KEY for a plain direct-API instance.
# `credlogin login claude subscription` needs no stored credentials at all:
# Claude Code authenticates against the subscription itself, so the flags are
# pinned off rather than left unset, since an inherited CLAUDE_CODE_USE_FOUNDRY
# from a parent shell would otherwise still point it at the proxy. Both key
# shapes are cached, so a sandbox account gets by on one `lpass login` rather
# than one per agent shell.
credlogin define claude \
  @foundry \
  +ANTHROPIC_FOUNDRY_API_KEY +ANTHROPIC_FOUNDRY_BASE_URL \
  CLAUDE_CODE_USE_FOUNDRY=1 CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1 \
  -- \
  @api \
  +ANTHROPIC_API_KEY \
  -- \
  @subscription \
  CLAUDE_CODE_USE_FOUNDRY=0 CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=0

# codex/opencode — TODO: confirm the exact env vars the Codex CLI and opencode
# expect; these names are placeholders.
credlogin define codex OPENAI_API_KEY OPENAI_BASE_URL?
credlogin define opencode OPENCODE_API_KEY OPENCODE_BASE_URL?

# firecrawl/zotero — the credentials the MCP servers in script/sv-after-setup
# read out of the environment, plus the firecrawl and zotero CLIs, which read
# the same keys. Claude Code runs an MCP server as a child process, so each one
# inherits these from the shell that started Claude Code and the MCP
# configuration itself holds no secrets. zotero-mcp is set up against the local
# Zotero API, so it only wants these when pointed at the web API instead.
# Cached for the reason the claude keys are: otherwise every agent shell in the
# sandbox would need its own lpass login. ZOTERO_LIBRARY_TYPE is optional
# because the server assumes a personal library when it is unset; a group
# library is the case that has to say so.
credlogin define firecrawl +FIRECRAWL_API_KEY
credlogin define zotero +ZOTERO_API_KEY +ZOTERO_LIBRARY_ID +ZOTERO_LIBRARY_TYPE?

# per-machine or otherwise unshared service definitions
[[ -r ~/.credlogin.local ]] && source ~/.credlogin.local

# to avoid non-zero exit code
true
