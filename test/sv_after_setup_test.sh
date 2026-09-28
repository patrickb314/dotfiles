#!/bin/bash
# script/sv-after-setup: where each account finds the Zotero library the two
# of them share.

source "$(dirname "$0")/harness.sh"

sandbox_home
SHARED="${TEST_HOME}/shared"
mkdir -p "${SHARED}/Zotero" "${TEST_HOME}/.local/bin"
touch "${SHARED}/Zotero/zotero.sqlite"

# Stubs for everything that installs or registers a server, and the real jq,
# which the script uses to write the config it is tested on. `claude` reports
# the LSP plugin as installed, which leaves that block out of it.
BIN="$(fake_bin uv)"
printf '#!/bin/sh\necho lsp@dotfiles\n' >"${BIN}/claude"
chmod +x "${BIN}/claude"
ln -s "$(command -v jq)" "${BIN}/jq"
cp "${BIN}/uv" "${TEST_HOME}/.local/bin/zotero-mcp"

sv_after_setup() {
  env -i HOME="${TEST_HOME}" PATH="${BIN}:${BARE_PATH}" USER="${USER:-tester}" \
    SANDVAULT=1 SHARED_WORKSPACE="${SHARED}" \
    "${BASH_BIN}" "${DOTFILES}/script/sv-after-setup"
}

assert_ok "the sandbox account runs it clean" sv_after_setup
assert_ok "and links the shared library into its own home" \
  test "${TEST_HOME}/Zotero" -ef "${SHARED}/Zotero"
assert_equal "which zotero-mcp opens by path" "${SHARED}/Zotero/zotero.sqlite" \
  "$(jq -r .zotero_db_path "${TEST_HOME}/.config/zotero-mcp/config.json")"
assert_ok "and runs clean again with the link in place" sv_after_setup

finish
