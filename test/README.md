# Regression tests

```sh
test/run                 # everything
test/run credlogin shrc  # only the files whose names match an argument
test/run -v              # name every assertion, not only the failures
```

The suite exercises the shell configuration itself: what a login shell works
out about the machine, what ends up on `PATH`, which aliases and editor a
shell settles on, how `credlogin` resolves a service, and where `script/setup`
puts each file. It needs nothing installed that the `Brewfile` does not
already bring, and it reaches no network and no LastPass account.

## Layout

| File | Covers |
| --- | --- |
| `harness.sh` | assertions and fixtures, sourced by every test file |
| `run` | discovery and reporting |
| `shprofile_test.sh` | OS detection, CPU count, the shell cache, the Homebrew shellenv cache |
| `shrc_test.sh` | the `PATH` helpers, the tool-dependent aliases, the editor ladder |
| `bash_startup_test.sh` | `bashrc.sh` and `bash_profile.sh`, and what Bash deliberately does not load |
| `zprofile_test.zsh` | the prompt, `git_branch`, completion and globbing options |
| `zshrc_test.zsh` | the whole ZSH startup chain on a machine with none of the optional tools |
| `credlogin_test.zsh` | the spec grammar, variant resolution, the credential cache, login and logout |
| `setup_test.sh` | where `script/setup` puts each file, and what it skips |
| `syntax_test.sh` | every file parses under the shell that reads it |

## Writing a test

A test file is an ordinary script named `*_test.sh` for Bash or `*_test.zsh`
for ZSH. It sources `harness.sh`, calls assertions top to bottom, and ends
with `finish`. Each file runs in its own process, so one file's aliases,
functions, and `PATH` cannot reach the next. Nothing aborts on a failed
assertion: one broken function should not hide the state of everything after
it.

```sh
source "$(dirname "$0")/harness.sh"   # ZSH: "${0:a:h}/harness.sh"

sandbox_home
assert_equal "a sandvault account sets SANDVAULT" "1" "${SANDVAULT}"

finish
```

The assertions are `assert_equal`, `assert_unequal`, `assert_empty`,
`assert_set`, `assert_match` (a shell glob), `assert_contains`,
`assert_excludes`, `assert_ok` and `assert_fails` (which take a command),
and `assert_file_mode`. Each takes the description first. `skip` records a
check that could not run here and why; `fail` reports one outright.

The fixtures are:

- `sandbox_home` — a throwaway home directory laid out the way `script/setup`
  lays out the real one, exported as `HOME`. It is removed when the file
  exits.
- `fake_bin name...` — a directory of stub commands, printed on stdout. What
  the configuration does about a tool has to be testable on a machine that
  happens not to have it, and on one that happens to.
- `BARE_PATH` — a `PATH` with nothing on it but the system utilities, so a
  test decides for itself which optional tools a shell finds.
- `BASH_BIN` and `ZSH_BIN` — absolute, so a test that strips `PATH` down to
  its stubs can still start a shell.

Two things are worth knowing before adding to this:

- `assert_ok` and `assert_fails` run their command in a command substitution.
  A test of something that exports a variable has to run it in the test shell
  and check `$?` afterwards.
- ZSH scopes a trap set inside a function to that function, which is why the
  cleanup trap is registered at the top of `harness.sh` rather than inside
  `sandbox_home`.

## What is not covered

`script/setup` is run only on macOS: on Linux it ends by `exec`ing
`script/linux-after-setup`, which logs in to GitHub and changes the login
shell. CI runs `script/setup` for real on all three platforms.

Nothing here talks to LastPass. The `credlogin` tests pin `PATH` to one with
no `lpass` on it and assert as much before anything else, so a test that
quietly started reaching the real account would fail rather than pass.

`shellcheck` is asserted at error severity only. The warnings that remain are
deliberate or cosmetic, and the `bash-language-server` the editors drive
surfaces those while writing.
