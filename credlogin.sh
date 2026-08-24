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
# A service is any pair of functions named _credlogin_<service>_login/_logout
# plus a _credlogin_<service>_fields array of the KEY names it needs — no
# central registry to keep in sync.

typeset -gA CREDLOGIN_ACTIVE
typeset -gA CREDLOGIN_SSH_PUBKEY

credlogin() {
  local verb="$1" service="$2" instance="$3"
  case "${verb}" in
    login) __credlogin_login "${service}" "${instance}" ;;
    logout) __credlogin_logout "${service}" ;;
    list|ls) __credlogin_list "${service}" ;;
    add) __credlogin_store add "${service}" "${instance}" ;;
    set) __credlogin_store set "${service}" "${instance}" ;;
    status) __credlogin_status ;;
    *) __credlogin_usage ;;
  esac
}

__credlogin_usage() {
  cat >&2 <<'EOF'
usage: credlogin <verb> <service> [instance]
  login <service> <instance>   pull credentials from LastPass into this shell
  logout <service>             undo the active login for that service
  list [service]                list services, or instances of one service
  add <service> <instance>     store a new instance's credentials in LastPass
  set <service> <instance>     replace an existing instance's credentials
  status                        show what's currently logged in
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

__credlogin_login() {
  local service="$1" instance="$2"
  if [[ -z "${service}" || -z "${instance}" ]]; then
    echo "usage: credlogin login <service> <instance>" >&2
    return 1
  fi

  local login_fn="_credlogin_${service}_login"
  (( ${+functions[${login_fn}]} )) || {
    echo "credlogin: unknown service '${service}' (see \`credlogin list\`)" >&2
    return 1
  }

  __credlogin_ready || return 1
  "${login_fn}" "${instance}" || return 1
  CREDLOGIN_ACTIVE[${service}]="${instance}"
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

# github — reuses the export_github_token helper already defined in shrc.sh
# so there's one definition of "what env vars mean GitHub auth."
typeset -ga _credlogin_github_fields
_credlogin_github_fields=("GITHUB_TOKEN")

_credlogin_github_login() {
  local instance="$1" notes token
  notes="$(__credlogin_notes github "${instance}")"
  token="$(__credlogin_kv "${notes}" GITHUB_TOKEN)"
  [[ -n "${token}" ]] || {
    echo "credlogin: no 'GITHUB_TOKEN' field for github/${instance}" >&2
    return 1
  }
  export_github_token "${token}"
}

_credlogin_github_logout() {
  unset GITHUB_TOKEN GH_TOKEN HOMEBREW_GITHUB_API_TOKEN JEKYLL_GITHUB_TOKEN
}

# claude — replaces the hardcoded key block that used to live in shrc.sh.
# Fill in ANTHROPIC_FOUNDRY_API_KEY/_BASE_URL for an Azure Foundry-proxied
# instance, or just ANTHROPIC_API_KEY for a plain direct-API instance.
typeset -ga _credlogin_claude_fields
_credlogin_claude_fields=("ANTHROPIC_API_KEY" "ANTHROPIC_FOUNDRY_API_KEY" "ANTHROPIC_FOUNDRY_BASE_URL")

_credlogin_claude_login() {
  local instance="$1" notes api_key foundry_key foundry_url
  notes="$(__credlogin_notes claude "${instance}")"
  foundry_key="$(__credlogin_kv "${notes}" ANTHROPIC_FOUNDRY_API_KEY)"
  foundry_url="$(__credlogin_kv "${notes}" ANTHROPIC_FOUNDRY_BASE_URL)"
  if [[ -n "${foundry_key}" && -n "${foundry_url}" ]]; then
    export ANTHROPIC_FOUNDRY_API_KEY="${foundry_key}"
    export ANTHROPIC_FOUNDRY_BASE_URL="${foundry_url}"
    export CLAUDE_CODE_USE_FOUNDRY=1
    export CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1
    return
  fi

  api_key="$(__credlogin_kv "${notes}" ANTHROPIC_API_KEY)"
  [[ -n "${api_key}" ]] || {
    echo "credlogin: no usable fields for claude/${instance}" >&2
    return 1
  }
  export ANTHROPIC_API_KEY="${api_key}"
}

_credlogin_claude_logout() {
  unset ANTHROPIC_API_KEY ANTHROPIC_FOUNDRY_API_KEY ANTHROPIC_FOUNDRY_BASE_URL \
    CLAUDE_CODE_USE_FOUNDRY CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS
}

# codex — same shape as claude. TODO: confirm the exact env vars the Codex
# CLI you use expects; OPENAI_API_KEY/OPENAI_BASE_URL are placeholders.
typeset -ga _credlogin_codex_fields
_credlogin_codex_fields=("OPENAI_API_KEY" "OPENAI_BASE_URL")

_credlogin_codex_login() {
  local instance="$1" notes api_key base_url
  notes="$(__credlogin_notes codex "${instance}")"
  api_key="$(__credlogin_kv "${notes}" OPENAI_API_KEY)"
  [[ -n "${api_key}" ]] || {
    echo "credlogin: no 'OPENAI_API_KEY' field for codex/${instance}" >&2
    return 1
  }
  base_url="$(__credlogin_kv "${notes}" OPENAI_BASE_URL)"

  export OPENAI_API_KEY="${api_key}"
  [[ -n "${base_url}" ]] && export OPENAI_BASE_URL="${base_url}"
}

_credlogin_codex_logout() {
  unset OPENAI_API_KEY OPENAI_BASE_URL
}

# opencode — same shape again. TODO: confirm the exact env vars opencode
# expects; OPENCODE_API_KEY/OPENCODE_BASE_URL are placeholders.
typeset -ga _credlogin_opencode_fields
_credlogin_opencode_fields=("OPENCODE_API_KEY" "OPENCODE_BASE_URL")

_credlogin_opencode_login() {
  local instance="$1" notes api_key base_url
  notes="$(__credlogin_notes opencode "${instance}")"
  api_key="$(__credlogin_kv "${notes}" OPENCODE_API_KEY)"
  [[ -n "${api_key}" ]] || {
    echo "credlogin: no 'OPENCODE_API_KEY' field for opencode/${instance}" >&2
    return 1
  }
  base_url="$(__credlogin_kv "${notes}" OPENCODE_BASE_URL)"

  export OPENCODE_API_KEY="${api_key}"
  [[ -n "${base_url}" ]] && export OPENCODE_BASE_URL="${base_url}"
}

_credlogin_opencode_logout() {
  unset OPENCODE_API_KEY OPENCODE_BASE_URL
}

# to avoid non-zero exit code
true
