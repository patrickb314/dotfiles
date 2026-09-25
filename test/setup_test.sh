#!/bin/bash
# script/setup: where each file in this directory ends up in the home
# directory, and what it deliberately leaves alone.

source "$(dirname "$0")/harness.sh"

# Linux ends script/setup with `exec script/linux-after-setup`, which logs in
# to GitHub and changes the login shell, so the run below stops at the border.
# CI runs script/setup for real on all three platforms.
if [ "$(uname -s)" != "Darwin" ]; then
  skip "script/setup installs the dotfiles" "it execs linux-after-setup here"
  finish
fi

# A home directory with nothing in it, rather than the sandbox the other
# tests use: what setup creates is the whole of what should be there.
TEST_HOME="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-test.XXXXXX")"

# No brew, sv, uv, claude, or ollama on this PATH, so the blocks that sync
# into the sandbox account and install MCP servers stay out of it.
setup() {
  env -i HOME="${TEST_HOME}" PATH="${BARE_PATH}" USER="${USER:-tester}" \
    "${BASH_BIN}" "${DOTFILES}/script/setup"
}

assert_ok "setup runs clean on an empty home directory" setup

links_to() {
  [ "$1" -ef "$2" ]
}

# --- the plain files ----------------------------------------------------

assert_ok "a .sh file loses its extension" \
  links_to "${TEST_HOME}/.shrc" "${DOTFILES}/shrc.sh"
assert_ok "and so does every other one" \
  links_to "${TEST_HOME}/.zshrc" "${DOTFILES}/zshrc.sh"
assert_ok "credlogin.local keeps the rest of its name" \
  links_to "${TEST_HOME}/.credlogin.local" "${DOTFILES}/credlogin.local.sh"
assert_ok "a file without one is linked as it is" \
  links_to "${TEST_HOME}/.gitconfig" "${DOTFILES}/gitconfig"
assert_ok "a directory is linked whole" \
  links_to "${TEST_HOME}/.git-hooks" "${DOTFILES}/git-hooks"

# --- what is skipped ----------------------------------------------------

for skipped in bin bundle script test tmp; do
  assert_fails "${skipped} is not linked into the home directory" \
    test -e "${TEST_HOME}/.${skipped}"
done
# claude/ and codex/ do reach the home directory, but as real directories
# holding a link per file, so each account's own state can live beside them.
assert_fails "claude/ is not linked whole" \
  links_to "${TEST_HOME}/.claude" "${DOTFILES}/claude"
assert_ok "it is a directory of its own" test -d "${TEST_HOME}/.claude"
assert_fails "and neither is codex/" \
  links_to "${TEST_HOME}/.codex" "${DOTFILES}/codex"
assert_fails "nor is the README" test -e "${TEST_HOME}/.README.md"
assert_fails "nor the licence" test -e "${TEST_HOME}/.LICENSE.txt"
assert_fails "nor the Ollama model list" test -e "${TEST_HOME}/.ollama-models.txt"

# --- the paths the shell configuration relies on ------------------------

assert_ok "the checkout is reachable as ~/.dotfiles" \
  links_to "${TEST_HOME}/.dotfiles" "${DOTFILES}"
assert_ok "and as ~/OSS/dotfiles" \
  links_to "${TEST_HOME}/OSS/dotfiles" "${DOTFILES}"
assert_ok "so shrc.sh finds bin through it" \
  test -x "${TEST_HOME}/.dotfiles/bin/claude-sv"

# --- macOS-only placements ----------------------------------------------

assert_ok "gitconfig.local.macos is installed under its plain name" \
  links_to "${TEST_HOME}/.gitconfig.local" "${DOTFILES}/gitconfig.local.macos"
assert_fails "and not under its own" test -e "${TEST_HOME}/.gitconfig.local.macos"
assert_ok "VS Code settings land in its support directory" \
  links_to "${TEST_HOME}/Library/Application Support/Code/User/settings.json" \
  "${DOTFILES}/vscode-settings.json"
assert_ok "Cursor settings in its own" \
  links_to "${TEST_HOME}/Library/Application Support/Cursor/User/settings.json" \
  "${DOTFILES}/cursor-settings.json"
assert_ok "and Zed settings under .config" \
  links_to "${TEST_HOME}/.config/zed/settings.json" "${DOTFILES}/zed-settings.json"

# --- the agent configuration --------------------------------------------

assert_ok "one instruction file serves Claude Code" \
  links_to "${TEST_HOME}/.claude/CLAUDE.md" "${DOTFILES}/AGENTS-GLOBAL.md"
assert_ok "and Codex" \
  links_to "${TEST_HOME}/.codex/AGENTS.md" "${DOTFILES}/AGENTS-GLOBAL.md"
assert_ok "claude/ is linked file by file rather than whole" \
  links_to "${TEST_HOME}/.claude/settings.json" "${DOTFILES}/claude/settings.json"
assert_ok "down to the files inside a skill" \
  links_to "${TEST_HOME}/.claude/skills/write-like-bridges/SKILL.md" \
  "${DOTFILES}/claude/skills/write-like-bridges/SKILL.md"
assert_ok "and codex/ the same way" \
  links_to "${TEST_HOME}/.codex/hooks.json" "${DOTFILES}/codex/hooks.json"

# --- rerunning ----------------------------------------------------------

# The rubocop files are installed only into directories that already exist,
# and setup makes ~/OSS itself after that loop has run, so the second run is
# the one that places it. Setup is meant to be rerun after every pull.
assert_fails "the OSS rubocop config waits for the directory to exist" \
  test -e "${TEST_HOME}/OSS/.rubocop.yml"
assert_ok "setup runs clean a second time" setup
assert_ok "and places it then" \
  links_to "${TEST_HOME}/OSS/.rubocop.yml" "${DOTFILES}/rubocop-oss.yml"
assert_ok "leaving the rest where it was" \
  links_to "${TEST_HOME}/.shrc" "${DOTFILES}/shrc.sh"
assert_fails "the Work config stays away without a Work directory" \
  test -e "${TEST_HOME}/Work/.rubocop.yml"

# --- the shell it installs actually starts ------------------------------

assert_ok "a ZSH shell starts from what was installed" \
  env -i HOME="${TEST_HOME}" PATH="${BARE_PATH}" TERM=dumb \
  USER="${USER:-tester}" "${ZSH_BIN}" -c "source ~/.zshrc"
assert_ok "and a Bash one does too" \
  env -i HOME="${TEST_HOME}" PATH="${BARE_PATH}" TERM=dumb HOSTNAME=testhost \
  "${BASH_BIN}" -c "source ~/.bashrc"

finish
