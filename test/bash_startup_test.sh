#!/bin/bash
# bashrc.sh and bash_profile.sh: the Bash half of the startup chain, which
# shares shprofile.sh and shrc.sh with ZSH and deliberately stops there.

source "$(dirname "$0")/harness.sh"

sandbox_home

bashrc() {
  local snippet="$1"
  shift
  env -i HOME="${HOME}" PATH="${BARE_PATH}" TERM=dumb USER="${USER:-tester}" \
    HOSTNAME="testhost" "$@" \
    "${BASH_BIN}" -c "source ~/.bashrc; ${snippet}"
}

assert_ok "a Bash shell comes up without error" \
  env -i HOME="${HOME}" PATH="${BARE_PATH}" TERM=dumb HOSTNAME=testhost \
  "${BASH_BIN}" -c "source ~/.bashrc"
assert_empty "and says nothing on the way" "$(bashrc true 2>&1)"

# --- what the chain pulls in -------------------------------------------

assert_equal "bashrc reaches bash_profile, and so shprofile" \
  "1" "$(bashrc 'echo "${SHPROFILE_LOADED}"')"
assert_equal "bashrc loads shrc" \
  "yes" "$(bashrc 'declare -f add_to_path_start >/dev/null && echo yes')"

# credlogin leans on ZSH associative arrays and parameter expansion
# throughout, so Bash does not source it — and therefore a Bash shell holds
# no GitHub token at all. Both halves of that are worth pinning down.
assert_empty "Bash does not load credlogin" \
  "$(bashrc 'declare -f credlogin >/dev/null && echo yes')"
assert_empty "and so exports no GitHub token" \
  "$(bashrc 'echo "${GITHUB_TOKEN}${GH_TOKEN}"')"

# --- login and interactive detection ------------------------------------

assert_equal "an interactive shell says so" \
  "1" "$(env -i HOME="${HOME}" PATH="${BARE_PATH}" TERM=dumb HOSTNAME=testhost \
    "${BASH_BIN}" -ic 'echo "${INTERACTIVE_BASH}"' 2>/dev/null)"
assert_empty "a script does not" "$(bashrc 'echo "${INTERACTIVE_BASH}"')"
assert_equal "HOST is set for the sake of the shared configuration" \
  "testhost" "$(bashrc 'echo "${HOST}"')"

# --- history ------------------------------------------------------------

assert_equal "history goes to the Bash history file" \
  "${HOME}/.bash_history" "$(bashrc 'echo "${HISTFILE}"')"
assert_equal "duplicates are dropped" "ignoredups" "$(bashrc 'echo "${HISTCONTROL}"')"
assert_equal "each command is written out as it is run" \
  "history -a" "$(bashrc 'echo "${PROMPT_COMMAND}"')"
assert_contains "noise is kept out of the history" \
  "ls" "$(bashrc 'echo "${HISTIGNORE}"')"

# --- shell options ------------------------------------------------------

shopt_set() {
  env -i HOME="${HOME}" PATH="${BARE_PATH}" HOSTNAME=testhost \
    "${BASH_BIN}" -c "source ~/.bash_profile; shopt -q $1 && echo on"
}

assert_equal "history is appended rather than overwritten" \
  "on" "$(shopt_set histappend)"
assert_equal "multi-line commands are saved whole" "on" "$(shopt_set cmdhist)"
assert_equal "cd spelling is corrected" "on" "$(shopt_set cdspell)"
assert_equal "the window size is rechecked after each command" \
  "on" "$(shopt_set checkwinsize)"

# --- the prompt tells you which account you are in ----------------------

prompt_for() {
  env -i HOME="${HOME}" PATH="${BARE_PATH}" TERM=dumb HOSTNAME=testhost "$@" \
    "${BASH_BIN}" -c 'source ~/.bash_profile; echo "${PS1}"'
}

assert_contains "an ordinary shell is green" "01;32" "$(prompt_for USER=bridges)"
assert_contains "the sandbox is yellow" "01;33" "$(prompt_for USER=bridges SANDVAULT=1)"
assert_contains "an SSH session is cyan" \
  "01;36" "$(prompt_for USER=bridges SSH_CONNECTION="1 2 3 4")"
assert_contains "root is magenta" "01;35" "$(prompt_for USER=root)"
assert_contains "root wins over the sandbox" \
  "01;35" "$(prompt_for USER=root SANDVAULT=1)"

# --- logout -------------------------------------------------------------

assert_ok "both shells' logout files reach the shared one" \
  test -L "${HOME}/.bash_logout" -a -L "${HOME}/.zlogout" -a -L "${HOME}/.logout"
assert_ok "and sourcing it is harmless" \
  env -i HOME="${HOME}" PATH="${BARE_PATH}" "${BASH_BIN}" -c "source ~/.bash_logout"

finish
