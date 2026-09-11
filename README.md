# Dot Files

My dot files shared between machines for ZSH, Bash, macOS, Linux, Cygwin and MSYS.

Beyond the usual shell, Git, and editor configuration, this repository carries
two things worth documenting on their own: `credlogin`, which pulls per-service
credentials out of LastPass into a single shell on demand, and the wiring that
lets the same configuration run inside a [SandVault](https://github.com/webcoyote/sandvault)
sandbox user.

## Installation

Run [`script/setup`](script/setup) after checkout. It installs everything in
this directory into the home directory and needs no arguments.

Each top-level file and directory is symlinked to `~/.<name>`, with a trailing
`.sh` stripped: `shrc.sh` becomes `~/.shrc`, `gitconfig` becomes `~/.gitconfig`,
and `git-hooks/` becomes `~/.git-hooks/`. The `bin`,
`bundle`, `claude`, `codex`, `script`, and `tmp` directories, along with `*.md`
and `*.txt`, are skipped by that loop and handled separately:

- `claude/` and `codex/` are linked file by file into `~/.claude/` and `~/.codex/`.
- `AGENTS-GLOBAL.md` is linked to both `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`,
  so Claude Code and Codex read one set of instructions.
- Editor settings land in the VS Code, Cursor, and Zed configuration directories
  for the current platform.
- `rubocop-work.yml` and `rubocop-oss.yml` become `~/Work/.rubocop.yml` and
  `~/OSS/.rubocop.yml`, but only if those directories already exist.
- `~/.dotfiles` and `~/OSS/dotfiles` are pointed at the checkout, which is how
  `shrc.sh` finds `bin/` to add to `PATH`.
- On macOS, `gitconfig.local.macos` is installed as `~/.gitconfig.local`.
- Codespaces keeps its own `ssh/` setup; the loop leaves it alone there.

Setup is idempotent, so rerun it after pulling changes. On Linux it finishes by
exec'ing `script/linux-after-setup`; under CI on macOS, `script/strap-after-setup`.

## Shell startup

Shell configuration is split so Bash and ZSH share as much as possible:

| File | Installed as | Role |
| --- | --- | --- |
| `shprofile.sh` | `~/.shprofile` | login-shell basics: `umask`, history sizes, OS detection (`MACOS`, `LINUX`, `WSL`, `SANDVAULT`), CPU count, Homebrew `shellenv` |
| `shrc.sh` | `~/.shrc` | interactive shell: `PATH` helpers, aliases, per-command setup, editor choice, GitHub token export |
| `zprofile.sh` / `zshrc.sh` | `~/.zprofile` / `~/.zshrc` | ZSH completion, prompt, key bindings; `zshrc.sh` sources `~/.zprofile`, `~/.shrc`, and `~/.credlogin` |
| `bash_profile.sh` / `bashrc.sh` | `~/.bash_profile` / `~/.bashrc` | the Bash equivalents |

Two pieces of state get cached under `~/.cache/shell` and refreshed weekly, so
that a new shell does not pay for a `brew shellenv` and a `gh auth token` every
time: `homebrew-shellenv.sh` and `github-token`. `setup_github_token` reads the
latter and exports `GITHUB_TOKEN`, `GH_TOKEN`, `HOMEBREW_GITHUB_API_TOKEN`, and
`JEKYLL_GITHUB_TOKEN` at every shell start.

`shprofile.sh` sets `SANDVAULT=1` when `$USER` begins with `sandvault`, and sets
`CODING_AGENT_SHELL=1` when the shell was started by Claude Code or Codex. Both
change behavior downstream: the sandbox prompt is yellow instead of green, and
an agent shell skips the "return to last directory" trick that would otherwise
make `cd` state leak between sessions.

## credlogin

`credlogin` ([`credlogin.sh`](credlogin.sh), installed as `~/.credlogin` and
sourced by `zshrc.sh`) pulls per-service credentials out of LastPass into the
current shell on demand. Secrets live in exported environment variables, or in
the ssh-agent, for the lifetime of that shell. Log in to the one service you
need, in the one shell that needs it, and close the shell to revoke it. Only a
value explicitly marked cacheable is also written to disk; see
[Caching](#caching) below.

It is ZSH-only, leaning on associative arrays and ZSH parameter expansion
throughout, and the Bash startup files do not source it.

It requires `lastpass-cli` (in the [`Brewfile`](Brewfile)) and an authenticated
session: `lpass login you@example.com`.

### Verbs

```
credlogin login <service> <instance>   pull credentials into this shell
credlogin logout <service>             undo the active login
credlogin list [service]               list services, or instances of one
credlogin add <service> <instance>     store a new instance in LastPass
credlogin set <service> <instance>     replace an existing instance
credlogin define <service> <entry>...  declare a service
credlogin status                       show what is currently logged in
```

`add` creates a LastPass item and `set` replaces one. They are separate verbs
because `lpass add` always creates: re-adding an existing path leaves two items
with the same name, after which every `lpass show` on it fails as ambiguous.
Both rewrite the whole notes blob, so `set` re-prompts for every field;
answering blank is how you clear one.

### Storage

Entries live in LastPass at `Shell Logins/<service>/<instance>`, with all of a
service's data packed as `KEY=value` lines in the item's notes field. Notes is
the only field every entry has that can hold arbitrary keys: `lastpass-cli`'s
non-interactive `--field=` edits work only against a fixed set of built-in note
types with fixed field names.

A service whose single field is literally named `notes` stores its raw,
unwrapped value there instead. `ssh` is the one that needs this, since a PEM
private key cannot be squeezed onto one line of `KEY=value`.

### Declaring a service

Most services are a list of environment variable settings and nothing more, so
`credlogin define` generates their login and logout functions from that list:

| Entry | Meaning |
| --- | --- |
| `NAME` | required value, read from the `NAME=` line of the notes field |
| `NAME?` | the same, but login still succeeds when it is not stored |
| `A,B,C` | one stored value (under key `A`) exported under all three names |
| `NAME=value` | a fixed value, exported at every login |
| `-NAME` | never exported, only cleared, for a variable that would conflict |
| `+NAME` | a stored value that may also be cached on disk |
| `@name` | labels the variant it appears in, so `login <service> <name>` selects that shape outright |
| `--` | separates alternative shapes of the same service |

An unlabelled login uses the first variant whose required values are all stored.
A variant that requires nothing stored would match every instance, including
mistyped ones, so `define` rejects it unless it carries an `@name` label, after
which it is reachable only by that name. `credlogin` is aliased to `noglob
credlogin` so a `NAME?` entry does not have to be quoted past ZSH globbing.

Login is atomic in the sense that matters: variants resolve in order and nothing
is exported until one comes out whole, so a failed login leaves the environment
untouched. A successful one first clears every variable the spec mentions across
all its variants, so switching instances never leaves a value behind from the
shape that was active before.

### Caching

A value whose entry carries a `+` is also written to
`~/.cache/shell/credlogin/<service>/<instance>` at login, in the same cache as
`homebrew-shellenv.sh` and `github-token` and on the same weekly expiry. A
later login reads it back and never calls LastPass at all, which is what keeps
a fresh shell — or a sandbox account whose LastPass session has lapsed — from
having to `lpass login` again.

Caching is per variable and off by default, because the useful question is per
credential: mark a token that is short-lived and revocable, and leave anything
whose copy on disk would outlive the cache entry unmarked. The file is written
with mode 600 inside the 700 cache directory.

The cache is used only when it can carry a login on its own. A spec that mixes
cached and uncached values still needs LastPass every time, so nothing is
written for it: half a login on disk buys nothing. `add` and `set` delete the
cached copy, since a replaced credential would otherwise keep being answered
from the old one until it expired. `logout` does not: it unsets the variables
this shell exported, and the cache exists precisely to outlive the shell.
Delete `~/.cache/shell/credlogin` to force every service back to LastPass.

### Defined services

- **`github`**: one stored token exported as `GITHUB_TOKEN`, `GH_TOKEN`,
  `HOMEBREW_GITHUB_API_TOKEN`, and `JEKYLL_GITHUB_TOKEN`. That same list appears
  in `shrc.sh`'s `export_github_token`, which the cached `gh`-CLI path uses at
  every shell start; `shrc.sh` is sourced by Bash too, so sharing one list would
  need ZSH-only word splitting there. The token is cached, for the same reason
  the `gh`-CLI one is: it expires and can be revoked, and the alternative is a
  LastPass round trip in every shell.
- **`claude`**: three labelled variants. `@foundry` sets
  `ANTHROPIC_FOUNDRY_API_KEY` and `ANTHROPIC_FOUNDRY_BASE_URL` for an Azure
  Foundry-proxied instance; `@api` sets a plain `ANTHROPIC_API_KEY`;
  `@subscription` stores nothing at all, because Claude Code authenticates
  against the subscription itself. The subscription variant pins
  `CLAUDE_CODE_USE_FOUNDRY=0` rather than leaving it unset, since a value
  inherited from a parent shell would otherwise still point Claude Code at
  the proxy. Both key shapes are cached, so a sandbox account gets by on one
  `lpass login` a week rather than one per agent shell.
- **`codex`** and **`opencode`**: `OPENAI_API_KEY`/`OPENAI_BASE_URL?` and
  `OPENCODE_API_KEY`/`OPENCODE_BASE_URL?`. The variable names are placeholders
  and still need confirming against the two CLIs.
- **`ssh`**: the one service with real logic instead of a spec. Its notes field
  holds a PEM private key, which `login` feeds to `ssh-add` and `logout` removes
  from the agent by the public half derived with `ssh-keygen -y`. A service can
  always be hand-written this way: define `_credlogin_<service>_login` and
  `_credlogin_<service>_logout` plus a `_credlogin_<service>_fields` array of the
  key names it needs. There is no central registry to keep in sync either way.

### Local definitions

[`credlogin.local.sh`](credlogin.local.sh) is installed as `~/.credlogin.local`
and sourced at the end of `credlogin.sh`. It holds definitions tied to one
machine, or named after something not worth publishing.

It is tracked, so it travels to the sandbox guest home with everything else. Put
only `credlogin define` lines in it. A definition names environment variables and
nothing else; every value stays in LastPass, so a credential written here would
be a credential committed.

## Using these dotfiles with a SandVault user

[SandVault](https://github.com/webcoyote/sandvault) runs AI agents as a separate
macOS user account (`sandvault-<user>`) with a restricted sandbox profile, so an
agent cannot reach the real home directory. Install it with `brew install
sandvault`; the [`Brewfile`](Brewfile) already lists it.

The two accounts meet at `/Users/Shared/sv-<user>`, which both can write:

```
/Users/Shared/sv-bridges/
  user/          the sandbox account's home directory
  projects/      repositories cloned in by sv-clone
  assignments/   sandvault's own bookkeeping
  config/        SSH config fragment for the sandbox account
```

### How the dotfiles get in

The sandbox account cannot read the real home directory, so a symlink into it
would be useless there. `script/setup` **copies** a subset of the configuration
into `/Users/Shared/sv-$USER/user` instead, and only when the contents actually
differ. That block runs only if both `brew` and `sv` are on `PATH`.

What gets copied: `shrc`, `shprofile`, `logout`, `credlogin`, `credlogin.local`,
`zprofile`, `zshrc`, `zlogout`, `gitconfig`, `gitignore`, the `bundle/`,
`claude/`, and `codex/` directories, and `AGENTS-GLOBAL.md` as both
`.claude/CLAUDE.md` and `.codex/AGENTS.md`. `codex/hooks.json` is deliberately
skipped. Rerun `script/setup` on the host after changing any of these to push
the new version across; the sandbox home is a copy, not a live link.

`bin/` is not copied. Inside the sandbox, `shrc.sh` adds `~/bin` to the front of
`PATH` when `SANDVAULT` is set, which is where sandvault installs its own tools.

### Launching a session

```sh
sv shell                 # shell in the sandbox home
sv claude [PATH]         # Claude Code in the sandbox
sv codex [PATH]          # Codex in the sandbox
git sv                   # shell in the current repo or worktree (gitconfig alias)
claude-sv [PATH] [-- CLAUDE_ARGS...]
```

[`bin/claude-sv`](bin/claude-sv) is a thin wrapper over `sv claude` that checks
sandvault is installed and prints the install command if it is not, so it can sit
on `PATH` and be used like any other command.

To hand a whole repository over, `sv-clone <URL|PATH>` clones it into
`/Users/Shared/sv-<user>/projects` and opens a session there. Its
`--repo-deploy-key` and `--allow-repo-write` flags create a per-repository GitHub
deploy key so the sandbox gets access to that one repository and nothing else.
Everything after `--` is passed through to `sv`.

### Git and SSH across the boundary

Repositories under the shared workspace are owned by the other account, which
Git would otherwise refuse to touch, so [`gitconfig`](gitconfig) marks them safe:

```
[safe]
	directory = /Users/Shared/sv-bridges/repositories/*
	directory = /Users/Shared/sv-bridges/worktrees/brew/*
	directory = /Users/Shared/sv-bridges/worktrees/platform/*
	directory = /Users/Shared/sv-bridges/projects/*
```

`git sandvault-reset` hard-resets the current branch to `sandvault/<branch>`,
which is how work done in the sandbox comes back to the host checkout.

The sandbox authenticates to GitHub with its own key rather than the host's:
`/Users/Shared/sv-<user>/config` pins `IdentityFile ~/.ssh/id_ed25519_sandvault`
with `IdentitiesOnly yes` for `github.com`. Only the public half is tracked here,
since [`.gitignore`](.gitignore) excludes `ssh/id_*`, and
[`ssh/download-keys.sh`](ssh/download-keys.sh) restores the private halves from
LastPass for every `.pub` file it finds.

### Credentials inside the sandbox

`credlogin` works the same way in the sandbox, with one consequence worth being
deliberate about: the sandbox account has its own LastPass session, so it needs
its own `lpass login` before anything can be fetched. Nothing is inherited from
the host.

That is the point of the arrangement. An agent running in the sandbox holds only
the credentials you logged in to in its shell, for as long as that shell lives,
and a `credlogin login claude subscription` needs no LastPass session at all.

One `lpass login` in the sandbox covers the week for the cached services,
because their cache lives in the sandbox home like everything else it writes.
That is the trade the `+` marker makes: a `github` or `claude` key sits in
`/Users/Shared/sv-<user>/user/.cache/shell/credlogin`, readable by the sandbox
account, rather than being fetched afresh in every agent shell.

## The `bin` directory

`shrc.sh` adds `~/.dotfiles/bin` to the end of `PATH`. Scripts named
`git-<something>` are reachable as `git <something>`.

| Script | Purpose |
| --- | --- |
| `claude-sv` | launch Claude Code inside a SandVault sandbox |
| `git-credential-dotfiles` | pick the right credential helper on Codespaces versus macOS/Linux |
| `git-commit-each` | commit every modified file as its own commit |
| `git-pr-each` | open a pull request per modified file |
| `git-delete-merged-worktrees` | remove clean worktrees whose `HEAD` is merged into the current branch |
| `git-gc-global` | garbage collect every repository beneath the current directory |
| `scm-update` | fetch and rebase every Git and Subversion repository beneath the current directory |
| `github-pr-job-logs` | download the Actions job logs for every check on a pull request |
| `touchid-enable-pam-sudo` | enable TouchID for `sudo` via `/etc/pam.d/sudo_local` |
| `upsy-desky` | raise and lower a standing desk, but only on AC power with the lid up |

## Git configuration

[`gitconfig`](gitconfig) is heavily commented; the parts most worth knowing:

- **Aliases.** Long descriptive names with short forms beside them: `git fs` is
  `fix-up-previous-commit`, `git pr` is `upstream-and-pull-request`, and `git dm`
  diffs against the merge base. A second group audits a codebase: `churn`,
  `bus-factor`, `bug-hotspots`, `commit-velocity`, `firefighting`.
- **Defaults.** Pull rebases, fetch prunes and fetches all remotes, push sets up
  the remote branch automatically, `rerere` records and replays conflict
  resolutions, and the histogram diff algorithm is on.
- **Hooks.** `core.hooksPath` points at `~/.git-hooks`, so
  [`git-hooks/`](git-hooks) applies to every repository.
- **SSH for GitHub.** `url."git@github.com:".insteadOf` rewrites `https://`
  GitHub clones, which matters in networks where HTTPS is awkward.

## Agent configuration

[`AGENTS-GLOBAL.md`](AGENTS-GLOBAL.md) is the shared instruction file for Claude
Code and Codex: shell and commit conventions, and a writing style guide. Setup
links it to both `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`, and copies it
into the sandbox home under both names.

[`claude/settings.json`](claude/settings.json) carries Claude Code's permission
allowlist and denylist, model choice, and theme. [`AGENTS.md`](AGENTS.md) holds
the conventions that apply to this repository in particular.

## Status

I'm using these on all my personal machines and GitHub Codespaces.

## Contact

Originally by [Mike McQuaid](mailto:mike@mikemcquaid.com)

## License

These dot files are licensed under the [GPLv3 License](https://en.wikipedia.org/wiki/GNU_General_Public_License).
The full license text is available in [LICENSE.txt](LICENSE.txt).
