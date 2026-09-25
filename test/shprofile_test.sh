#!/bin/bash
# shprofile.sh: what a login shell works out about the machine it is on, and
# the cache that keeps it from working it out again next time.

source "$(dirname "$0")/harness.sh"

sandbox_home

# Source shprofile.sh in a fresh Bash with the machine facts it reads set to
# whatever this test wants them to be, then print what it made of them. The
# variables it exports are unset first, so nothing leaks in from the shell
# running the suite.
shprofile() {
  local snippet="$1"
  shift
  env -u MACOS -u LINUX -u UNIX -u WINDOWS -u WSL -u SANDVAULT -u CPUCOUNT \
    -u MAKEFLAGS -u BUNDLE_JOBS -u TERMINALAPP -u TERM_PROGRAM \
    -u CODING_AGENT_SHELL -u CLAUDECODE -u CLAUDE_CODE_ENTRYPOINT \
    -u CLAUDE_CODE_SESSION_ID -u CODEX_CI -u CODEX_THREAD_ID \
    -u CODEX_TUI_SESSION_LOG_PATH -u HOMEBREW_PREFIX \
    HOME="${HOME}" PATH="${PATH}" USER="${USER:-tester}" \
    "$@" bash -c 'source "$0" >/dev/null; '"${snippet}" "${DOTFILES}/shprofile.sh"
}

# --- OS detection ------------------------------------------------------

assert_equal "Darwin sets MACOS" \
  "1" "$(shprofile 'echo "${MACOS}"' UNAME_S=Darwin)"
assert_equal "Darwin sets UNIX" \
  "1" "$(shprofile 'echo "${UNIX}"' UNAME_S=Darwin)"
assert_empty "Darwin does not set LINUX" \
  "$(shprofile 'echo "${LINUX}"' UNAME_S=Darwin)"

assert_equal "Linux sets LINUX" \
  "1" "$(shprofile 'echo "${LINUX}"' UNAME_S=Linux)"
assert_equal "Linux sets UNIX" \
  "1" "$(shprofile 'echo "${UNIX}"' UNAME_S=Linux)"
assert_empty "Linux does not set MACOS" \
  "$(shprofile 'echo "${MACOS}"' UNAME_S=Linux)"

assert_equal "MSYS sets WINDOWS" \
  "1" "$(shprofile 'echo "${WINDOWS}"' UNAME_S=MINGW64_NT-10.0)"
assert_equal "Cygwin sets WINDOWS" \
  "1" "$(shprofile 'echo "${WINDOWS}"' UNAME_S=CYGWIN_NT-10.0)"
assert_empty "Windows is not UNIX" \
  "$(shprofile 'echo "${UNIX}"' UNAME_S=MINGW64_NT-10.0)"

assert_empty "an unrecognised uname sets no OS variable" \
  "$(shprofile 'echo "${MACOS}${LINUX}${WINDOWS}${UNIX}"' UNAME_S=Plan9)"

# WSL is read out of /proc/version, so it can only be checked where there is
# one; on Linux without the marker it must stay unset either way.
if [ -r /proc/version ]; then
  if grep -qEi "(Microsoft|WSL)" /proc/version; then
    assert_equal "WSL is detected under WSL" \
      "1" "$(shprofile 'echo "${WSL}"' UNAME_S=Linux)"
  else
    assert_empty "plain Linux does not set WSL" \
      "$(shprofile 'echo "${WSL}"' UNAME_S=Linux)"
  fi
else
  assert_empty "WSL stays unset without /proc/version" \
    "$(shprofile 'echo "${WSL}"' UNAME_S=Linux)"
fi

# --- USER and the sandbox marker ---------------------------------------

assert_equal "a sandvault account sets SANDVAULT" \
  "1" "$(shprofile 'echo "${SANDVAULT}"' USER=sandvault-bridges)"
assert_empty "an ordinary account does not" \
  "$(shprofile 'echo "${SANDVAULT}"' USER=bridges)"
assert_empty "a name that merely contains sandvault does not" \
  "$(shprofile 'echo "${SANDVAULT}"' USER=not-sandvault)"
assert_equal "an empty USER falls back to LOGNAME" \
  "fallback" "$(shprofile 'echo "${USER}"' USER= LOGNAME=fallback)"

# --- CPU count ---------------------------------------------------------

assert_match "CPUCOUNT is a positive number" \
  '[1-9]*' "$(shprofile 'echo "${CPUCOUNT}"')"
assert_equal "CPUCOUNT falls back to 1 on an unknown OS" \
  "1" "$(shprofile 'echo "${CPUCOUNT}"' UNAME_S=Plan9)"
assert_empty "one CPU sets no MAKEFLAGS" \
  "$(shprofile 'echo "${MAKEFLAGS}"' UNAME_S=Plan9)"
assert_equal "MAKEFLAGS follows CPUCOUNT" \
  "-j$(shprofile 'echo "${CPUCOUNT}"')" "$(shprofile 'echo "${MAKEFLAGS}"')"
assert_equal "BUNDLE_JOBS follows CPUCOUNT" \
  "$(shprofile 'echo "${CPUCOUNT}"')" "$(shprofile 'echo "${BUNDLE_JOBS}"')"

# --- history and umask -------------------------------------------------

assert_equal "HISTSIZE is raised" "100000" "$(shprofile 'echo "${HISTSIZE}"')"
assert_equal "SAVEHIST is raised" "100000" "$(shprofile 'echo "${SAVEHIST}"')"
assert_equal "umask is 022" "0022" "$(shprofile 'umask')"

# --- agent and terminal markers ----------------------------------------

assert_equal "Claude Code sets CODING_AGENT_SHELL" \
  "1" "$(shprofile 'echo "${CODING_AGENT_SHELL}"' CLAUDECODE=1)"
assert_equal "a Claude Code session id sets it too" \
  "1" "$(shprofile 'echo "${CODING_AGENT_SHELL}"' CLAUDE_CODE_SESSION_ID=abc)"
assert_equal "Codex sets CODING_AGENT_SHELL" \
  "1" "$(shprofile 'echo "${CODING_AGENT_SHELL}"' CODEX_THREAD_ID=abc)"
assert_empty "a human shell does not" \
  "$(shprofile 'echo "${CODING_AGENT_SHELL}"')"

assert_equal "Terminal.app sets TERMINALAPP" \
  "1" "$(shprofile 'echo "${TERMINALAPP}"' TERM_PROGRAM=Apple_Terminal)"
assert_empty "another terminal does not" \
  "$(shprofile 'echo "${TERMINALAPP}"' TERM_PROGRAM=iTerm.app)"
assert_ok "Terminal.app defines set_terminal_app_pwd" \
  env TERM_PROGRAM=Apple_Terminal bash -c \
  "source ${DOTFILES}/shprofile.sh >/dev/null; declare -f set_terminal_app_pwd >/dev/null"

assert_equal "sourcing marks itself loaded" \
  "1" "$(shprofile 'echo "${SHPROFILE_LOADED}"')"

# --- the shell cache ---------------------------------------------------

source "${DOTFILES}/shprofile.sh" >/dev/null
CACHE="${SHELL_CACHE_DIR}/test-entry"

assert_fails "a read of a missing entry is a miss" shell_cache_read "${CACHE}"

printf 'hello\n' | shell_cache_write "${CACHE}"
assert_equal "a write then a read round-trips" \
  "hello" "$(shell_cache_read "${CACHE}")"
assert_file_mode "a cache entry is owner-readable only" 600 "${CACHE}"
assert_file_mode "the cache directory is owner-only" 700 "${SHELL_CACHE_DIR}"

: >"${CACHE}"
assert_fails "an empty entry is a miss" shell_cache_read "${CACHE}"

printf 'hello\n' | shell_cache_write "${CACHE}"
NOW_EPOCH=$(($(date +%s) + 604799))
assert_ok "an entry a second short of a week is still fresh" \
  shell_cache_read "${CACHE}"
NOW_EPOCH=$(($(date +%s) + 604800))
assert_fails "an entry a week old has expired" shell_cache_read "${CACHE}"
NOW_EPOCH="$(date +%s)"

NESTED="${SHELL_CACHE_DIR}/credlogin/service/instance"
printf 'nested\n' | shell_cache_write "${NESTED}"
assert_equal "a write creates the directories above it" \
  "nested" "$(shell_cache_read "${NESTED}")"
assert_file_mode "and leaves the one holding the entry owner-only" \
  700 "${SHELL_CACHE_DIR}/credlogin/service"
assert_file_mode "the nested entry is owner-readable only" 600 "${NESTED}"

# --- the Homebrew shellenv cache ---------------------------------------

# A brew that records every time it is run, so a test can tell a cache hit
# from a cache miss by whether the real command was needed.
FAKE_PREFIX="${TEST_HOME}/fake-brew"
mkdir -p "${FAKE_PREFIX}/bin"
cat >"${FAKE_PREFIX}/bin/brew" <<FAKE
#!/bin/sh
echo ran >>"${TEST_HOME}/brew-runs"
echo 'export HOMEBREW_PREFIX="${FAKE_PREFIX}"'
FAKE
chmod +x "${FAKE_PREFIX}/bin/brew"

setup_homebrew_run() {
  rm -f "${TEST_HOME}/brew-runs"
  env -u HOMEBREW_PREFIX HOME="${HOME}" PATH="${BARE_PATH}" \
    NOW_EPOCH="$1" bash -c "source ${DOTFILES}/shprofile.sh >/dev/null
      setup_homebrew
      echo \"\${HOMEBREW_PREFIX}\""
}

printf 'export HOMEBREW_PREFIX="%s"\n' "${FAKE_PREFIX}" >"${HOMEBREW_SHELLENV_CACHE}"
assert_equal "a fresh cache supplies HOMEBREW_PREFIX" \
  "${FAKE_PREFIX}" "$(setup_homebrew_run "$(date +%s)")"
assert_equal "and does not shell out to brew" \
  "" "$(cat "${TEST_HOME}/brew-runs" 2>/dev/null)"

assert_equal "an expired cache still supplies a prefix" \
  "${FAKE_PREFIX}" "$(setup_homebrew_run "$(($(date +%s) + 604800))")"
assert_equal "but is refreshed from brew" \
  "ran" "$(cat "${TEST_HOME}/brew-runs" 2>/dev/null)"

assert_equal "an already-set prefix short-circuits the whole thing" \
  "/preset" "$(env HOMEBREW_PREFIX=/preset HOME="${HOME}" PATH="${BARE_PATH}" \
    bash -c "source ${DOTFILES}/shprofile.sh >/dev/null
      setup_homebrew
      echo \"\${HOMEBREW_PREFIX}\"")"

finish
