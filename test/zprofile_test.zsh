#!/bin/zsh
# zprofile.sh: the prompt, and the ZSH options a login shell is set up with.

source "${0:a:h}/harness.sh"

sandbox_home

# Source ~/.zprofile in a fresh ZSH and print what it made of the machine.
# HOMEBREW_PREFIX is pinned so setup_homebrew returns before running brew:
# what it does with a real one is shprofile.sh's business, tested there.
zprofile() {
  local snippet="$1"
  shift
  env -u SANDVAULT -u SSH_CONNECTION -u PROMPT -u RPROMPT \
    HOME="${HOME}" PATH="${PATH}" HOMEBREW_PREFIX="${TEST_HOME}/brew" \
    USER="${USER:-tester}" "$@" \
    "${ZSH_BIN}" -c "source ~/.zprofile >/dev/null 2>&1; ${snippet}"
}

# --- the prompt tells you which account you are in ---------------------

assert_contains "an ordinary shell is green" \
  "green" "$(zprofile 'echo "${PROMPT}"' USER=bridges)"
assert_contains "the sandbox is yellow" \
  "yellow" "$(zprofile 'echo "${PROMPT}"' USER=bridges SANDVAULT=1)"
assert_contains "an SSH session is cyan" \
  "cyan" "$(zprofile 'echo "${PROMPT}"' USER=bridges SSH_CONNECTION="1 2 3 4")"
assert_contains "root is magenta" \
  "magenta" "$(zprofile 'echo "${PROMPT}"' USER=root)"
assert_contains "root wins over the sandbox" \
  "magenta" "$(zprofile 'echo "${PROMPT}"' USER=root SANDVAULT=1)"
assert_contains "the sandbox wins over SSH" \
  "yellow" "$(zprofile 'echo "${PROMPT}"' USER=bridges SANDVAULT=1 SSH_CONNECTION="1 2 3 4")"
assert_contains "the prompt shows the host" \
  '%m' "$(zprofile 'echo "${PROMPT}"' USER=bridges)"

assert_contains "the right prompt shows the branch" \
  'git_branch' "$(zprofile 'echo "${RPROMPT}"')"
assert_contains "and the working directory" \
  '%~' "$(zprofile 'echo "${RPROMPT}"')"
assert_ok "prompt_subst is on, so the branch is re-read each time" \
  test -n "$(zprofile '[[ -o prompt_subst ]] && echo yes')"

# --- git_branch --------------------------------------------------------

REPO="${TEST_HOME}/repo"
mkdir -p "${REPO}"
git -C "${REPO}" init -q -b trunk
git -C "${REPO}" -c user.email=t@example.com -c user.name=T \
  commit -q --allow-empty -m first

git_branch_in() {
  zprofile "cd '$1' && git_branch"
}

assert_equal "a repository reports its branch" \
  "(trunk) " "$(git_branch_in "${REPO}")"
git -C "${REPO}" checkout -q -b feature/x
assert_equal "including one with a slash in the name" \
  "(feature/x) " "$(git_branch_in "${REPO}")"
git -C "${REPO}" checkout -q --detach
assert_empty "a detached HEAD reports nothing" "$(git_branch_in "${REPO}")"
assert_empty "and neither does a directory outside a repository" \
  "$(git_branch_in "${TEST_HOME}")"

# --- completion and globbing -------------------------------------------

assert_equal "completion is initialised" \
  "yes" "$(zprofile '(( ${+functions[compdef]} )) && echo yes')"
assert_equal "zmv is available" \
  "yes" "$(zprofile '(( ${+functions[zmv]} )) && echo yes')"
assert_equal "globbing ignores case" \
  "yes" "$(zprofile '[[ -o no_case_glob ]] && echo yes')"
assert_equal "completion matches case-insensitively" \
  "m:{a-zA-Z}={A-Za-z}" \
  "$(zprofile 'zstyle -a ":completion:*" matcher-list m && echo "${m[1]}"')"
assert_contains "Homebrew completions are on FPATH" \
  "${TEST_HOME}/brew/share/zsh/site-functions" "$(zprofile 'echo "${FPATH}"')"

assert_empty "WORDCHARS is cleared, for macOS-like word jumps" \
  "$(zprofile 'echo "${WORDCHARS}"')"

# --- what it pulls in for itself ---------------------------------------

assert_equal "zprofile loads shprofile when nothing else has" \
  "1" "$(zprofile 'echo "${SHPROFILE_LOADED}"')"
assert_equal "and leaves it alone when something already did" \
  "already" "$(zprofile 'echo "${SHPROFILE_LOADED}"' SHPROFILE_LOADED=already)"

finish
