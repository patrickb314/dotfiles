# Superset and friends
tap "anomalyco/tap"
# Basic compilation tools
brew "cmake"
# And its documentation
brew "cmake-docs"
# CMake language server, which the Zed `neocmake` extension finds on `PATH`
brew "neocmakelsp"
# C source formatting
brew "clang-format"
# `clangd`, the C/C++ language server Zed drives
brew "llvm"
# Non-make build system for cmake/etc.
brew "ninja"
# Collection of portable C++ source libraries
brew "boost"
# Google Testing and Mocking Framework
brew "googletest"
# Ghostscript for PDF generation
brew "ghostscript"
# Search tool like grep, but optimized for programmers
brew "ack"
# Faster search tool in the same vein as ack
brew "ripgrep"
# Static analysis and lint tool, for (ba)sh scripts
brew "shellcheck"
# Shell script language server, which leans on `shellcheck` for diagnostics
brew "bash-language-server"
# Static checker for GitHub Actions workflow files
brew "actionlint"
# Clone of cat(1) with syntax highlighting and Git integration
brew "bat"
# General-purpose data compression with high compression ratio
brew "xz"
# GNU versions of the BSD file, shell, and text utilities
brew "coreutils"
# Disk Usage/Free Utility - a better 'df' alternative
brew "duf"
# More intuitive version of du in rust
brew "dust"
# Modern, maintained replacement for ls
brew "eza"
# Simple, fast and user-friendly alternative to find
brew "fd"
# Ruby scripting
brew "ruby"
# Ruby language server and linter, both of which Zed drives as language servers
brew "ruby-lsp"
brew "rubocop"
# JavaScript runtime, needed by the npm packages below
brew "node"
# Additional python poackage installation
brew "uv"
# Python language server
brew "python-lsp-server"
# GitHub command-line tool
brew "gh"
# Distributed revision control system
brew "git"
# Syntax-highlighting pager for git and diff output
brew "git-delta"
# Large files in git
brew "git-lfs"
# Colorize logfiles and command output
brew "grc"
# Improved top (interactive process viewer)
brew "htop"
# Command-line benchmarking tool
brew "hyperfine"
# Basic spelling tools
brew "ispell"
# Markdown language server geared to wiki-style linked note vaults
brew "markdown-oxide"
# Markdown language server Claude Code drives for ordinary documents
brew "marksman"
# LaTeX language server; the TeX distribution itself is the `mactex-no-gui` cask
brew "texlab"
# XML security library
brew "libxmlsec1"
# Mac App Store command-line interface
brew "mas"
# Open LLM model executor
brew "ollama"
# Route Claude Code requests to other models
brew "claude-code-router"
# Modern implementation of SSH
brew "openssh"
# Framework for layout and rendering of i18n text
brew "pango"
# Package compiler and linker metadata toolkit
brew "pkgconf"
# Wrapper to colorize and simplify ping's output
brew "prettyping"
# Run AI agents isolated in a sandboxed macOS user account
brew "sandvault"
# Autoformat shell script source code
brew "shfmt"
# Test runner for command-line programs
brew "shelltestrunner"
# Human-friendly alternative to netstat for socket and port monitoring
brew "somo"
# Internet file retriever
brew "wget"
# Linter for YAML files
brew "yamllint"
# YAML language server
brew "yaml-language-server"
# JSON language server, along with its CSS, HTML, and ESLint siblings
brew "vscode-langservers-extracted"
# Find security issues in GitHub Actions setups
brew "zizmor"
# Password manager that keeps all passwords secure behind one password
brew "lastpass-cli"
# Terminal-based AI coding assistant
cask "claude-code"
# OpenAI's coding agent that runs in your terminal
cask "codex"
# Terminal for orchestrating agents
cask "superset"
# App to build and share containerised applications and microservices
# cask "docker-desktop"
# TeX for papers and talks, without the GUI front ends
cask "mactex-no-gui"
# Reference library, and the local API `zotero-mcp` reads and writes
cask "zotero"
# Open-source code editor
cask "zed"
# Microsoft code editor
cask "visual-studio-code"
# Video communication and virtual meeting platform
cask "zoom"
# Brainstorming tool
cask "obsidian"
# Additional lastpass setups
gem "lastpass-ssh"
# Oft-used Mac apps
mas "AdBlock", id: 1402042596
mas "Kindle", id: 302584613
mas "LastPass for Safari", id: 6504626762
mas "Slack", id: 803453959
mas "Toggl Track", id: 1291898086
mas "Xcode", id: 497799835
# Sandboxing and web-scraping helpers that only ship via npm
npm "@anthropic-ai/sandbox-runtime"
npm "firecrawl-cli"
npm "firecrawl-mcp"
# PDF reading for agents, reached through the `pdfvision` skill rather than MCP
npm "pdfvision"

# Sandboxing and MCP helpers that ship via uv. script/sv-after-setup installs
# these too, for the sandbox account; they are listed here so that a
# `brew bundle cleanup` does not then take them away again.
uv "arxiv-mcp-server"
uv "zotero-mcp-server[all]"

# The list below is what Visual Studio Code has installed; `brew bundle`
# drives a single editor at a time and defaults to `code`.
vscode "anthropic.claude-code"
vscode "github.codespaces"
vscode "github.vscode-github-actions"
vscode "github.vscode-pull-request-github"
vscode "james-yu.latex-workshop"
vscode "ms-python.debugpy"
vscode "ms-python.python"
vscode "ms-python.vscode-pylance"
vscode "ms-python.vscode-python-envs"
vscode "ms-vscode.cmake-tools"
vscode "ms-vscode.cpp-devtools"
vscode "ms-vscode.cpptools"
vscode "ms-vscode.cpptools-extension-pack"
vscode "ms-vscode.cpptools-themes"
vscode "shd101wyy.markdown-preview-enhanced"
vscode "twxs.cmake"
