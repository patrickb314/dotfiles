#!/bin/bash
# Every shell file parses under the shell that reads it, and every executable
# script is readable by the interpreter its shebang names.

source "$(dirname "$0")/harness.sh"

cd "${DOTFILES}" || exit 1

# shprofile.sh and shrc.sh are sourced by both halves of the startup chain, so
# a ZSH-ism in either is a broken Bash shell and vice versa.
for file in shprofile.sh shrc.sh logout.sh; do
  assert_ok "${file} parses under Bash" bash -n "${file}"
  assert_ok "${file} parses under ZSH" zsh -n "${file}"
done

for file in bashrc.sh bash_profile.sh bash_logout.sh; do
  assert_ok "${file} parses under Bash" bash -n "${file}"
done

# credlogin.sh leans on ZSH associative arrays and parameter expansion
# throughout, which is why the Bash files do not source it.
for file in zshrc.sh zprofile.sh zlogout.sh credlogin.sh credlogin.local.sh; do
  assert_ok "${file} parses under ZSH" zsh -n "${file}"
done

assert_equal "every shell file in the root is accounted for above" \
  "bash_logout.sh bash_profile.sh bashrc.sh credlogin.local.sh credlogin.sh logout.sh shprofile.sh shrc.sh zlogout.sh zprofile.sh zshrc.sh" \
  "$(ls ./*.sh | sed 's#^\./##' | sort | tr '\n' ' ' | sed 's/ $//')"

# --- the scripts --------------------------------------------------------

for script in bin/* script/* git-hooks/*; do
  [ -f "${script}" ] || continue
  shebang="$(head -1 "${script}")"
  case "${shebang}" in
    *ruby) assert_ok "${script} parses as Ruby" ruby -c "${script}" ;;
    *bash) assert_ok "${script} parses under Bash" bash -n "${script}" ;;
    *sh) assert_ok "${script} parses under sh" sh -n "${script}" ;;
    *) fail "${script} has a shebang this test does not know" "${shebang}" ;;
  esac
  assert_ok "${script} is executable" test -x "${script}"
done

# --- shellcheck ---------------------------------------------------------

# Only errors. The warnings that remain are deliberate or cosmetic, and the
# bash-language-server the editors drive surfaces those while writing; a test
# that failed on them would be red from the day it was written.
if command -v shellcheck >/dev/null; then
  for file in shprofile.sh shrc.sh bashrc.sh bash_profile.sh; do
    assert_ok "shellcheck finds no error in ${file}" \
      shellcheck -S error -s bash "${file}"
  done
  for script in bin/* script/*; do
    case "$(head -1 "${script}")" in
      *bash) assert_ok "shellcheck finds no error in ${script}" \
        shellcheck -S error -s bash "${script}" ;;
      *sh) assert_ok "shellcheck finds no error in ${script}" \
        shellcheck -S error -s sh "${script}" ;;
    esac
  done
else
  skip "shellcheck finds no errors" "shellcheck is not installed"
fi

# --- the tests themselves -----------------------------------------------

for file in test/run test/harness.sh test/*_test.sh; do
  assert_ok "${file} parses under Bash" bash -n "${file}"
done
for file in test/*_test.zsh; do
  assert_ok "${file} parses under ZSH" zsh -n "${file}"
done
assert_ok "harness.sh parses under ZSH too" zsh -n test/harness.sh

finish
