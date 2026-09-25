# Assertions and fixtures for the dotfiles regression tests.
#
# Sourced by every test file. The shell configuration is split between Bash
# and ZSH, so the tests are too, and this file has to run under both: no
# associative arrays, no `local -n`, nothing newer than Bash 3.2.
#
# A test file is an ordinary script. It sources this file, calls assertions
# top to bottom, and ends with `finish`, which prints the tally and sets the
# exit status. Nothing aborts on a failed assertion: one broken function
# should not hide the state of everything after it.

DOTFILES="${DOTFILES:-$(cd -- "$(dirname -- "$0")/.." && pwd -P)}"

TESTS_RUN=0
TESTS_FAILED=0
TESTS_SKIPPED=0
TEST_HOME=""

# Registered here, at the top of a sourced file, rather than inside
# sandbox_home: ZSH scopes a trap set inside a function to that function, and
# would throw the sandbox away the moment it was made.
clean_up() {
  case "${TEST_HOME}" in
    */dotfiles-test.*) rm -rf "${TEST_HOME}" ;;
  esac
}
trap clean_up EXIT

pass() {
  TESTS_RUN=$((TESTS_RUN + 1))
  [ -n "${DOTFILES_TEST_VERBOSE}" ] && printf '  ok   %s\n' "$1"
  return 0
}

fail() {
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_FAILED=$((TESTS_FAILED + 1))
  printf '  FAIL %s\n' "$1"
  shift
  for detail; do
    printf '       %s\n' "${detail}"
  done
}

skip() {
  TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
  printf '  skip %s (%s)\n' "$1" "$2"
}

assert_equal() {
  if [ "$2" = "$3" ]; then
    pass "$1"
  else
    fail "$1" "expected: [$2]" "actual:   [$3]"
  fi
}

assert_unequal() {
  if [ "$2" != "$3" ]; then
    pass "$1"
  else
    fail "$1" "expected anything but: [$2]"
  fi
}

assert_empty() {
  if [ -z "$2" ]; then
    pass "$1"
  else
    fail "$1" "expected empty, got: [$2]"
  fi
}

assert_set() {
  if [ -n "$2" ]; then
    pass "$1"
  else
    fail "$1" "expected a value, got nothing"
  fi
}

# $2 is a shell glob, matched against the whole of $3
assert_match() {
  case "$3" in
    $2) pass "$1" ;;
    *) fail "$1" "pattern: [$2]" "actual:  [$3]" ;;
  esac
}

assert_contains() {
  case "$3" in
    *"$2"*) pass "$1" ;;
    *) fail "$1" "expected to contain: [$2]" "actual:              [$3]" ;;
  esac
}

assert_excludes() {
  case "$3" in
    *"$2"*) fail "$1" "expected not to contain: [$2]" "actual:                  [$3]" ;;
    *) pass "$1" ;;
  esac
}

# Run a command, discarding its output, and check how it exited.
assert_ok() {
  local desc="$1" out exit_status
  shift
  out="$("$@" 2>&1)"
  exit_status=$?
  if [ "${exit_status}" -eq 0 ]; then
    pass "${desc}"
  else
    fail "${desc}" "exited ${exit_status}" "output: ${out}"
  fi
}

assert_fails() {
  local desc="$1" out exit_status
  shift
  out="$("$@" 2>&1)"
  exit_status=$?
  if [ "${exit_status}" -ne 0 ]; then
    pass "${desc}"
  else
    fail "${desc}" "expected a non-zero exit, got 0" "output: ${out}"
  fi
}

assert_file_mode() {
  local mode
  if [ "$(uname -s)" = "Darwin" ]; then
    mode="$(stat -f %Lp "$3" 2>/dev/null)"
  else
    mode="$(stat -c %a "$3" 2>/dev/null)"
  fi
  assert_equal "$1" "$2" "${mode}"
}

# A throwaway home directory laid out the way script/setup lays out the real
# one: every `*.sh` linked to `~/.<name>`, plus the `~/.dotfiles` link that
# shrc.sh finds `bin` through. Tests source `~/.zshrc` and friends out of
# this, so the startup chain under test is the installed one rather than a
# rearrangement of it.
sandbox_home() {
  local file name
  TEST_HOME="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-test.XXXXXX")"

  for file in "${DOTFILES}"/*.sh; do
    name="${file##*/}"
    ln -s "${file}" "${TEST_HOME}/.${name%.sh}"
  done
  ln -s "${DOTFILES}" "${TEST_HOME}/.dotfiles"

  export HOME="${TEST_HOME}"
}

# A directory of stub commands, for the `quiet_which` branches: what the
# configuration does about a tool has to be testable on a machine that
# happens not to have it, and on one that happens to.
fake_bin() {
  local dir name
  dir="$(mktemp -d "${TEST_HOME}/fake-bin.XXXXXX")"
  # `which` is a system utility rather than one of the optional tools, and
  # shrc.sh shells out to it, so every stub directory gets a working one.
  printf '#!/bin/sh\ncommand -v "$1"\n' >"${dir}/which"
  chmod +x "${dir}/which"
  for name; do
    printf '#!/bin/sh\nexit 0\n' >"${dir}/${name}"
    chmod +x "${dir}/${name}"
  done
  printf '%s' "${dir}"
}

# A PATH with nothing on it but the system utilities, so a test decides for
# itself which optional tools the shell finds.
BARE_PATH="/usr/bin:/bin:/usr/sbin:/sbin"

# Absolute, because a test that strips PATH down to its stubs still has to be
# able to start a shell. Not named BASH, which Bash sets to its own path.
BASH_BIN="$(command -v bash)"
ZSH_BIN="$(command -v zsh)"

finish() {
  if [ "${TESTS_SKIPPED}" -gt 0 ]; then
    printf '  %d passed, %d skipped' "$((TESTS_RUN - TESTS_FAILED))" "${TESTS_SKIPPED}"
  else
    printf '  %d passed' "$((TESTS_RUN - TESTS_FAILED))"
  fi
  if [ "${TESTS_FAILED}" -gt 0 ]; then
    printf ', %d FAILED\n' "${TESTS_FAILED}"
    exit 1
  fi
  printf '\n'
  exit 0
}
