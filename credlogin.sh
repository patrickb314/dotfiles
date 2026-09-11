# credlogin — pull per-service credentials out of LastPass into the current
# shell, on demand. Nothing touches disk; secrets live only in exported env
# vars (or the ssh-agent) for the lifetime of the shell.
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
  -NAME         never exported, only cleared — for a conflicting variable
  --            separates alternative shapes of the same service; login uses
                the first whose required values are all stored
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
# needs neither an instance nor a LastPass session
__credlogin_needs_lastpass() {
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

  if __credlogin_needs_lastpass "${service}"; then
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
  local entry="$1"
  case "${entry}" in
    --) print -r -- "--" ;;
    -?*) print -r -- "clear ${entry#-} " ;;
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

  local entry line kind names name prev="" spec=""
  local -a fields
  for entry in "$@"; do
    line="$(__credlogin_spec_line "${entry}")"
    if [[ "${line}" == "--" ]]; then
      [[ -n "${prev}" && "${prev}" != "--" ]] || {
        echo "credlogin: empty variant in ${service} spec" >&2
        return 1
      }
    else
      kind="${line%% *}"
      names="${line#* }"
      names="${names%% *}"
      [[ -n "${names}" ]] || {
        echo "credlogin: '${entry}' names no variable" >&2
        return 1
      }
      for name in ${(s:,:)names}; do
        [[ "${name}" =~ '^[A-Za-z_][A-Za-z0-9_]*$' ]] || {
          echo "credlogin: invalid variable name '${name}' in '${entry}'" >&2
          return 1
        }
      done
      # the first of an alias list is the key the value is stored under, so
      # that's the one add/set prompts for
      [[ "${kind}" == secret || "${kind}" == optional ]] &&
        fields+=("${names%%,*}")
    fi
    spec+="${line}"$'\n'
    prev="${line}"
  done
  [[ "${prev}" != "--" ]] || {
    echo "credlogin: empty variant in ${service} spec" >&2
    return 1
  }

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
    [[ "${line}" == "--" ]] && continue
    names="${line#* }"
    print -rl -- ${(s:,:)${names%% *}}
  done <<<"${CREDLOGIN_SPEC[$1]}"
}

__credlogin_spec_logout() {
  local name
  for name in $(__credlogin_spec_vars "$1"); do
    unset "${name}"
  done
}

__credlogin_spec_login() {
  local service="$1" instance="$2" notes line kind names name value ok=1
  local -a pending

  __credlogin_needs_lastpass "${service}" &&
    notes="$(__credlogin_notes "${service}" "${instance}")"

  # resolve variants in order and keep the first that comes out whole; nothing
  # touches the environment until one does, so a failed login is a no-op
  while IFS= read -r line; do
    if [[ "${line}" == "--" ]]; then
      (( ok )) && break
      ok=1
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
      secret|optional)
        value="$(__credlogin_kv "${notes}" "${names%%,*}")"
        if [[ -z "${value}" ]]; then
          [[ "${kind}" == optional ]] || ok=0
          continue
        fi
        for name in ${(s:,:)names}; do
          pending+=("${name} ${value}")
        done
        ;;
    esac
  done <<<"${CREDLOGIN_SPEC[${service}]}"

  local fields_var="_credlogin_${service}_fields"
  (( ok )) || {
    echo "credlogin: no usable fields for ${service}/${instance} (looked for: ${(@P)fields_var})" >&2
    return 1
  }

  __credlogin_spec_logout "${service}"
  local item
  for item in "${pending[@]}"; do
    export "${item%% *}=${item#* }"
  done
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

# github — one stored token under every name that means "GitHub auth". That
# list is spelled out again in shrc.sh's export_github_token, which the gh-CLI
# path uses at every shell start; shrc.sh is sourced by bash too, so sharing
# one list would need zsh-only word splitting there.
credlogin define github GITHUB_TOKEN,GH_TOKEN,HOMEBREW_GITHUB_API_TOKEN,JEKYLL_GITHUB_TOKEN

# claude — replaces the hardcoded key block that used to live in shrc.sh.
# Fill in ANTHROPIC_FOUNDRY_API_KEY/_BASE_URL for an Azure Foundry-proxied
# instance, or just ANTHROPIC_API_KEY for a plain direct-API instance.
credlogin define claude \
  ANTHROPIC_FOUNDRY_API_KEY ANTHROPIC_FOUNDRY_BASE_URL \
  CLAUDE_CODE_USE_FOUNDRY=1 CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1 \
  -- \
  ANTHROPIC_API_KEY

# codex/opencode — TODO: confirm the exact env vars the Codex CLI and opencode
# expect; these names are placeholders.
credlogin define codex OPENAI_API_KEY OPENAI_BASE_URL?
credlogin define opencode OPENCODE_API_KEY OPENCODE_BASE_URL?

# machine-specific or private service definitions, kept out of the repo
[[ -r ~/.credlogin.local ]] && source ~/.credlogin.local

# to avoid non-zero exit code
true
