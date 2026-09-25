#!/bin/bash
# shrc.sh: the PATH helpers every other file builds on, and the choices made
# from what happens to be installed.

source "$(dirname "$0")/harness.sh"

sandbox_home

# --- PATH helpers ------------------------------------------------------

# Sourcing shrc.sh rewrites PATH, so the helpers are tested against a PATH
# this test owns rather than the one they were defined with.
MACOS=1 source "${DOTFILES}/shrc.sh" >/dev/null

mkdir -p "${TEST_HOME}/a" "${TEST_HOME}/ab" "${TEST_HOME}/b" "${TEST_HOME}/c"
A="${TEST_HOME}/a"
AB="${TEST_HOME}/ab"
B="${TEST_HOME}/b"
C="${TEST_HOME}/c"
MISSING="${TEST_HOME}/nowhere"
REAL_PATH="${PATH}"

PATH="${A}:${B}:${C}"
remove_from_path "${B}"
assert_equal "a directory is removed from the middle" "${A}:${C}" "${PATH}"

PATH="${A}:${B}:${C}"
remove_from_path "${A}"
assert_equal "and from the front" "${B}:${C}" "${PATH}"

PATH="${A}:${B}:${C}"
remove_from_path "${C}"
assert_equal "and from the end" "${A}:${B}" "${PATH}"

# The removal works on ":${PATH}:" for exactly this reason: a plain
# substitution would eat the prefix of a longer sibling entry.
PATH="${AB}:${B}"
remove_from_path "${A}"
assert_equal "a directory is not confused with a longer one beside it" \
  "${AB}:${B}" "${PATH}"

PATH="${A}:${B}"
remove_from_path "${MISSING}"
assert_equal "removing a directory that does not exist is a no-op" \
  "${A}:${B}" "${PATH}"

PATH="${A}:${B}"
add_to_path_start "${C}"
assert_equal "add_to_path_start prepends" "${C}:${A}:${B}" "${PATH}"

PATH="${A}:${B}"
add_to_path_start "${B}"
assert_equal "adding an entry already present moves it rather than duplicating it" \
  "${B}:${A}" "${PATH}"

PATH="${A}:${B}"
add_to_path_start "${MISSING}"
assert_equal "a directory that does not exist is not added" "${A}:${B}" "${PATH}"

PATH="${A}:${B}"
add_to_path_end "${C}"
assert_equal "add_to_path_end appends" "${A}:${B}:${C}" "${PATH}"

PATH="${A}:${B}"
add_to_path_end "${A}"
assert_equal "appending an entry already present moves it to the end" \
  "${B}:${A}" "${PATH}"

PATH="${A}:${B}"
add_to_path_end "${MISSING}"
assert_equal "add_to_path_end also skips a missing directory" \
  "${A}:${B}" "${PATH}"

PATH="${A}:${B}"
force_add_to_path_start "${MISSING}"
assert_equal "force_add_to_path_start adds one anyway" \
  "${MISSING}:${A}:${B}" "${PATH}"

PATH="${REAL_PATH}"
assert_ok "quiet_which finds a command that exists" quiet_which sh
assert_fails "quiet_which rejects one that does not" \
  quiet_which definitely-not-a-command
assert_equal "quiet_which prints nothing" "" "$(quiet_which sh)"

# --- what a login shell puts on PATH -----------------------------------

# Run shrc.sh against a PATH holding only the system directories, so what it
# adds is the whole of what is there afterwards.
shrc_path() {
  env HOME="${HOME}" PATH="${BARE_PATH}" "$@" \
    bash -c "source ${DOTFILES}/shrc.sh >/dev/null; echo \"\${PATH}\""
}

assert_contains "the dotfiles bin directory is on PATH" \
  "${HOME}/.dotfiles/bin" "$(shrc_path MACOS=1)"
assert_contains "so is the uv tool directory" \
  "${HOME}/.local/bin" "$(mkdir -p "${HOME}/.local/bin"; shrc_path MACOS=1)"
assert_contains "and the Go bin directory" \
  "${HOME}/.gopath/bin" "$(mkdir -p "${HOME}/.gopath/bin"; shrc_path MACOS=1)"
assert_equal "GOPATH is set" \
  "${HOME}/.gopath" "$(env HOME="${HOME}" PATH="${BARE_PATH}" MACOS=1 \
    bash -c "source ${DOTFILES}/shrc.sh >/dev/null; echo \"\${GOPATH}\"")"

# In the sandbox the account's own ~/bin holds the tools sandvault installs,
# and it has to win over everything else.
mkdir -p "${HOME}/bin"
assert_match "a sandbox shell puts its own bin first" \
  "${HOME}/bin:*" "$(shrc_path MACOS=1 SANDVAULT=1)"
assert_excludes "an ordinary shell does not" \
  "${HOME}/bin:" "$(shrc_path MACOS=1)"

# --- aliases and variables that depend on what is installed ------------

# Source shrc.sh on a PATH holding nothing but the stub commands a test asks
# for, so what the shell believes is installed is exactly what the test says.
# The OS variables come first and the tools after a `--`; shrc.sh itself adds
# /usr/local/bin and the directories under HOME, none of which hold any of
# the tools below.
shell_with() {
  local snippet="$1" flags=()
  shift
  while [ $# -gt 0 ] && [ "$1" != "--" ]; do
    flags+=("$1")
    shift
  done
  [ "${1-}" = "--" ] && shift
  env -i HOME="${HOME}" PATH="$(fake_bin "$@")" "${flags[@]}" \
    "${BASH_BIN}" -c "source ${DOTFILES}/shrc.sh >/dev/null; ${snippet}"
}

# Homebrew's own bin directory goes on PATH before any of this runs, so on a
# machine that really has one of these tools the branch for not having it
# cannot be reached at all. Say so rather than asserting something weaker.
unless_installed() {
  [ -n "$(shell_with 'quiet_which '"$1"' && echo yes' MACOS=1)" ]
}

assert_contains "eza takes over ls when it is installed" \
  "eza --classify --group --git" "$(shell_with 'alias ls' MACOS=1 -- eza)"
if unless_installed eza; then
  skip "otherwise macOS gets plain ls" "eza is installed on this machine"
  skip "and its colour scheme" "eza is installed on this machine"
else
  assert_contains "otherwise macOS gets plain ls" \
    "ls -F" "$(shell_with 'alias ls' MACOS=1)"
  assert_equal "and its colour scheme" \
    "GxFxCxDxBxegedabagaced" "$(shell_with 'echo "${LSCOLORS}"' MACOS=1)"
fi
assert_contains "Linux gets a colourised ls instead" \
  "color=auto" "$(shell_with 'alias ls' LINUX=1)"

assert_contains "bat takes over cat when it is installed" \
  "bat" "$(shell_with 'alias cat' MACOS=1 -- bat)"
assert_equal "and tells Homebrew to use it" \
  "1" "$(shell_with 'echo "${HOMEBREW_BAT}"' MACOS=1 -- bat)"
assert_equal "and pins its theme" \
  "ansi" "$(shell_with 'echo "${BAT_THEME}"' MACOS=1 -- bat)"
assert_empty "without bat, cat is left alone" \
  "$(shell_with 'alias cat 2>/dev/null')"

assert_equal "delta becomes the Git pager" \
  "delta" "$(shell_with 'echo "${GIT_PAGER}"' -- delta)"
assert_contains "but not inside Superset, which pages for itself" \
  "less" "$(shell_with 'echo "${GIT_PAGER}"' SUPERSET_HOME_DIR=/somewhere -- delta)"
assert_contains "and less is the fallback without delta" \
  "less" "$(shell_with 'echo "${GIT_PAGER}"')"

assert_contains "dust replaces du" "dust" "$(shell_with 'alias du' -- dust)"
assert_contains "duf replaces df" "duf" "$(shell_with 'alias df' -- duf)"
assert_contains "prettyping replaces ping" \
  "prettyping" "$(shell_with 'alias ping' -- prettyping)"
assert_contains "htop replaces top" "htop" "$(shell_with 'alias top' -- htop)"

# --- the editor ladder -------------------------------------------------

assert_equal "zed wins when it is installed" \
  "zed" "$(shell_with 'echo "${EDITOR}"' -- zed vim cursor code)"
assert_equal "vim is next" \
  "vim" "$(shell_with 'echo "${EDITOR}"' -- vim cursor code)"
assert_equal "then cursor" \
  "cursor" "$(shell_with 'echo "${EDITOR}"' -- cursor code)"
assert_equal "then code" \
  "code" "$(shell_with 'echo "${EDITOR}"' -- code)"
assert_empty "and nothing at all when none are installed" \
  "$(shell_with 'echo "${EDITOR}"')"
assert_contains "zed redirects the code alias at itself" \
  "you like zed now" "$(shell_with 'alias code' -- zed code)"
assert_contains "code gets a vscode alias pointing at the binary" \
  "/code'" "$(shell_with 'alias vscode' -- code)"

# --- small helper functions --------------------------------------------

assert_fails "json with no argument does nothing" \
  env HOME="${HOME}" PATH="${BARE_PATH}" MACOS=1 \
  bash -c "source ${DOTFILES}/shrc.sh >/dev/null; json"
assert_fails "receipt with no argument does nothing" \
  env HOME="${HOME}" PATH="${BARE_PATH}" MACOS=1 \
  bash -c "source ${DOTFILES}/shrc.sh >/dev/null; receipt"

mkdir -p "${HOME}/.Trash"
: >"${HOME}/rubbish"
trash "${HOME}/rubbish"
assert_ok "trash moves a file to the Trash" test -f "${HOME}/.Trash/rubbish"
assert_fails "and takes it out of where it was" test -e "${HOME}/rubbish"

# --- the aliases that do not depend on anything ------------------------

assert_contains "mkdir makes parents and says so" \
  "mkdir -vp" "$(shell_with 'alias mkdir')"
assert_contains "df is human-readable" "df -H" "$(shell_with 'alias df')"
assert_contains "du is human-readable" "du -sh" "$(shell_with 'alias du')"
assert_contains "less ignores case" "ignore-case" "$(shell_with 'alias less')"
assert_contains "rsync resumes and reports" "--partial" "$(shell_with 'alias rsync')"
assert_equal "CLICOLOR is on" "1" "$(shell_with 'echo "${CLICOLOR}"')"
assert_contains "macOS locates with Spotlight" \
  "mdfind" "$(shell_with 'alias locate' MACOS=1)"
assert_contains "Linux opens with xdg-open" \
  "xdg-open" "$(shell_with 'alias open' LINUX=1)"

finish
