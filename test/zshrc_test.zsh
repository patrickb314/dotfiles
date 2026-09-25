#!/bin/zsh
# zshrc.sh: the whole ZSH startup chain, on a machine with none of the
# optional tools it reaches for.

source "${0:a:h}/harness.sh"

sandbox_home

# Start a ZSH that reads the installed ~/.zshrc, seeing only the system
# utilities. Neither gh nor lpass is on that PATH, which is the case worth
# protecting: a shell has to come up clean on a machine where the credential
# tooling is missing or logged out.
zshrc() {
  env -i HOME="${HOME}" PATH="${BARE_PATH}" TERM=dumb USER="${USER:-tester}" \
    "${ZSH_BIN}" -c "source ~/.zshrc; $1"
}

assert_ok "a login shell comes up without error" \
  env -i HOME="${HOME}" PATH="${BARE_PATH}" TERM=dumb USER="${USER:-tester}" \
  "${ZSH_BIN}" -c "source ~/.zshrc"
assert_empty "and says nothing on the way" "$(zshrc true 2>&1)"

# --- what the chain pulls in -------------------------------------------

assert_equal "zshrc loads shprofile" "1" "$(zshrc 'echo "${SHPROFILE_LOADED}"')"
assert_contains "zshrc loads zprofile" "%m" "$(zshrc 'echo "${PROMPT}"')"
assert_equal "zshrc loads shrc" \
  "yes" "$(zshrc '(( ${+functions[add_to_path_start]} )) && echo yes')"
assert_equal "zshrc loads credlogin" \
  "yes" "$(zshrc '(( ${+functions[credlogin]} )) && echo yes')"
assert_equal "and the local service definitions with it" \
  "yes" "$(zshrc '(( ${+functions[__credlogin_define]} )) && echo yes')"

# The gh login at the top of zshrc.sh is the only credential a shell fetches
# for itself, and it has to stay quiet and non-fatal when it cannot.
assert_empty "the github login is silent when gh is missing" \
  "$(zshrc 'true' 2>&1)"
assert_empty "and exports no token" "$(zshrc 'echo "${GITHUB_TOKEN}"')"
assert_equal "leaving nothing logged in" \
  "credlogin: no active logins" "$(zshrc 'credlogin status')"

# --- history and options ------------------------------------------------

assert_equal "history goes to the ZSH history file" \
  "${HOME}/.zsh_history" "$(zshrc 'echo "${HISTFILE}"')"
assert_equal "history is shared between shells" \
  "yes" "$(zshrc '[[ -o share_history ]] && echo yes')"
assert_equal "duplicate history entries are skipped when searching" \
  "yes" "$(zshrc '[[ -o hist_find_no_dups ]] && echo yes')"
assert_equal "history entries lose their extra blanks" \
  "yes" "$(zshrc '[[ -o hist_reduce_blanks ]] && echo yes')"
assert_equal "background jobs survive logout" \
  "yes" "$(zshrc '[[ -o no_hup ]] && echo yes')"
assert_equal "command spelling is corrected" \
  "yes" "$(zshrc '[[ -o correct ]] && echo yes')"

# --- ZSH-only aliases ---------------------------------------------------

assert_contains "zmv does not glob its arguments" \
  "noglob zmv" "$(zshrc 'alias zmv')"
assert_contains "neither does rake" "noglob rake" "$(zshrc 'alias rake')"
assert_contains "nor bundle exec" "noglob bundle exec" "$(zshrc 'alias be')"
assert_contains "nor credlogin, so a NAME? entry needs no quoting" \
  "noglob credlogin" "$(zshrc 'alias credlogin')"

# --- key bindings --------------------------------------------------------

assert_equal "emacs bindings are used whatever EDITOR is" \
  "yes" "$(zshrc 'bindkey | grep -q "\"\^A\" beginning-of-line" && echo yes')"
assert_contains "Ctrl-U searches back through history" \
  "history-beginning-search-backward" "$(zshrc 'bindkey "^u"')"
assert_contains "Ctrl-V searches forward" \
  "history-beginning-search-forward" "$(zshrc 'bindkey "^v"')"

# --- the optional sourced files -----------------------------------------

# Both are sourced only when the Homebrew prefix really holds them, so a
# machine without them must not break, and one with them must pick them up.
mkdir -p "${TEST_HOME}/brew/share/zsh-autosuggestions" "${TEST_HOME}/brew/etc"
echo 'AUTOSUGGESTIONS_LOADED=1' \
  >"${TEST_HOME}/brew/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
echo 'GRC_LOADED=1' >"${TEST_HOME}/brew/etc/grc.zsh"

with_brew() {
  env -i HOME="${HOME}" PATH="${BARE_PATH}" TERM=dumb USER="${USER:-tester}" \
    HOMEBREW_PREFIX="${TEST_HOME}/brew" \
    "${ZSH_BIN}" -c "source ~/.zshrc; $1"
}

assert_equal "autosuggestions are sourced from the Homebrew prefix" \
  "1" "$(with_brew 'echo "${AUTOSUGGESTIONS_LOADED}"')"
assert_equal "so is grc" "1" "$(with_brew 'echo "${GRC_LOADED}"')"
assert_empty "and neither is missed when the prefix has no copy" \
  "$(zshrc 'echo "${AUTOSUGGESTIONS_LOADED}${GRC_LOADED}"')"

finish
