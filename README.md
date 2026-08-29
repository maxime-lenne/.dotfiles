# .dotfiles

## Requirements

### Git and GitHub SSH Setup

Before using these dotfiles project, make sure you have:

1. **Git installed** (without Homebrew):
   ```bash
   # Download the latest Git for macOS installer
   curl -O https://sourceforge.net/projects/git-osx-installer/files/git-2.33.0-intel-universal-mavericks.dmg

   # Mount the disk image
   hdiutil attach git-2.33.0-intel-universal-mavericks.dmg

   # Install the package
   sudo installer -pkg /Volumes/Git\ 2.33.0\ Mavericks\ Intel\ Universal/git-2.33.0-intel-universal-mavericks.pkg -target /

   # Unmount the disk image
   hdiutil detach /Volumes/Git\ 2.33.0\ Mavericks\ Intel\ Universal/
   ```

2. **GitHub SSH connection configured**:
   ```bash
   # Generate SSH key
   ssh-keygen -f ~/.ssh/github -t ed25519 -C "your_email@example.com"

   # Start the ssh-agent in the background
   eval "$(ssh-agent -s)"

   # Add your SSH key to the ssh-agent
   ssh-add ~/.ssh/github

   # Copy the SSH key to your clipboard
   pbcopy < ~/.ssh/github.pub
   ```

   Then add the SSH key to your GitHub account:
   1. Go to GitHub → Settings → SSH and GPG keys
   2. Click "New SSH key"
   3. Paste your key and save

   Test your connection:
   ```bash
   ssh -T git@github.com
   ```

## Installation

To install dotfiles:

```bash
git clone git@github.com:maxime-lenne/.dotfiles.git
cd .dotfiles
chmod 755 install-deps.sh
chmod 755 configure_dotfiles.sh
./install-deps.sh
./configure_dotfiles.sh
```

`configure_dotfiles.sh` also points git at this repo's own hooks — see
below.

## Git hooks (`hooks/`)

`hooks/pre-commit` runs `shellcheck` over the shell scripts in a commit
before it lands. The scripts here are the only thing standing between a
machine rebuild and the drift documented in the
[audits](#system-inventories--audits), and every defect found in
`install-deps.sh` on 2026-08-28 — unquoted expansions, a typo'd
function name, a package name Homebrew had removed — is the kind
shellcheck catches for free.

How it behaves:

- It lints the **staged** content, not the working tree, so a
  partially-staged file is judged on what actually goes into the commit.
- It picks up `*.sh` plus any extensionless file whose staged content
  starts with a shell shebang.
- Severity is `info` by default — that tier includes SC2086
  (unquoted expansion), the class of bug that was actually present.
  Override per commit with `SHELLCHECK_SEVERITY=warning git commit`.
- No shellcheck installed? It says so and lets the commit through
  rather than blocking work on a machine that hasn't been set up.
- Bypass a single commit with `git commit --no-verify`.

`core.hooksPath` lives in `.git/config`, which isn't versioned, so a
fresh clone needs `./configure_dotfiles.sh` (or
`git config core.hooksPath hooks`) once before the hook does anything.

## Claude Code hooks (`.claude/hooks/`)

Not to be confused with `hooks/` above: that one holds the **git** hook
(`core.hooksPath`), this one holds hooks that run inside a Claude Code
session, wired in `.claude/settings.json`. Two of them:

- **`shellcheck-on-write.sh`** (PostToolUse) lints a shell file the
  moment it's written, instead of waiting for the commit. Same
  `-S info` severity as the git hook, so the two agree; skips
  `custom/plugins/` (vendored) and the rc files (no shebang, and
  shellcheck reads zsh as sh and floods).
- **`no-plaintext-secrets.sh`** (PreToolUse) refuses a write that would
  put a literal credential into one of the tracked shell config files.
  These are published to a public repo *and* symlinked into `$HOME`, so
  a token pasted into `.exports` leaks on the next push and rewriting
  history doesn't un-leak it. A reference (`"$MY_KEY"`, `$(...)`) is
  allowed — that's the pattern to use, with the value in an
  unversioned `~/.extra`.

Both read the hook payload on stdin, need `jq` (macOS ships it at
`/usr/bin/jq`), and fail open: if a dependency is missing they exit
quietly rather than breaking the session.

## Shared script helpers (`dotfiles-lib.sh`)

`clean-mac.sh` and `install-deps.sh` both need to know the machine's
role (`--server` / `--workstation`, see below) and both use the same
colored-output / yes-no-prompt pattern. That overlap lives in
`dotfiles-lib.sh`, sourced by both scripts — not meant to be run on
its own. It provides `detect_machine_role`, the color variables, and
the output/prompt helpers (`section`, `explain`, `warn`, `skipped`,
`ask`).

## Machines & environments

These dotfiles run on machines that don't all play the same role, so the
right amount of tooling isn't the same everywhere:

- **MacBook Pro — dev workstation.** Full dev environment: IDEs
  (JetBrains, Cursor...), Docker Desktop, design/communication apps,
  every language toolchain. Disk usage is expected to be higher here;
  `clean-mac.sh` stays conservative (caches only, no forced removal).
- **Mac mini — local/remote server.** No longer a dev box: it runs
  services headless (local and remotely accessible), not IDEs. It
  should carry the minimum footprint needed to run things: no GUI
  apps, no Docker Desktop (prefer `colima` + the `docker` CLI — same
  daemon, no GUI overhead), no IDEs, no legacy version managers left
  over from when it was still a dev machine. `clean-mac.sh` detects
  this machine (by hostname) and switches to more assertive
  recommendations — see below.
- **Linux servers (Raspberry Pi, Scaleway VPS, Docker containers).**
  Out of scope for `clean-mac.sh` (macOS-only: Homebrew, `~/Library`,
  Docker Desktop, JetBrains, Xcode). These environments should stay
  minimal by construction rather than be cleaned up after the fact:
  install only the runtime actually needed (e.g. `uv` or a plain
  Python/Node binary), skip version managers entirely when the
  environment only ever runs one version, and prefer slim/distroless
  base images for containers so there's no accumulated cache to clean
  in the first place.

## Package managers

Primary, used everywhere: **asdf** (Ruby and other language versions),
**uv** (Python — versions, venvs, packages), **bun** (JS/TS runtime and
package manager). This combo is intentional: fast, low overhead, and
each one replaces a whole category of older tools instead of stacking
on top of them.

Legacy tools that predated this setup — **all removed on 2026-08-28**,
from the MacBook Pro and the Mac mini alike, and no longer installed by
`install-deps.sh` on either role:

- **pyenv** → replaced by `uv` (`uv python install`, `uv venv`). uv
  reads the same `.python-version` files pyenv did, so per-project pins
  kept working as-is.
- **nvm** → replaced by `asdf` (nodejs plugin). Node lives in
  `~/.asdf`, resolved through the shims on `PATH`; `.nvmrc` files need
  converting to `.tool-versions`.
- **rvm** → replaced by `asdf` (ruby plugin). `ruby` no longer resolves
  to the macOS system 2.6.10.
- **npm** / **pnpm** / **yarn** → kept only for projects whose lockfile
  requires them; `bun` is the default otherwise.

`clean-mac.sh` still has the section that detects leftover `~/.pyenv`,
`~/.nvm`, `~/.rvm` installs and offers to remove them completely (not
just their cache) — keep it for machines that haven't been through this
yet, and as a guard against an installer silently putting one back.

## Disk cleanup (`clean-mac.sh`)

`clean-mac.sh` frees up disk space taken by caches, logs and temporary
files from the dev tools installed via `install-deps.sh`. It goes
section by section, explains what it's about to remove and why it's
safe, shows the current size, and asks for confirmation before doing
anything. Nothing is deleted without an explicit yes. macOS only — see
[Machines & environments](#machines--environments) for Linux servers.

It detects which machine it's running on (by hostname — `mac-mini`
matches the **server** role, anything else is treated as
**workstation**) and adapts its tone accordingly: on the Mac mini it
pushes harder for full removal of legacy tools since nothing there
should still depend on them; on the MacBook Pro it stays more
cautious since it's still an active dev environment. Override the
detection with `--server` / `--workstation` (or the `MACHINE_ROLE`
env var) if it gets it wrong.

What it can clean, section by section:

- **Homebrew**: old formula/cask versions and download cache (`brew cleanup`), orphaned dependencies (`brew autoremove`).
- **Docker Desktop**: stopped containers, unused networks and dangling images (`docker system prune`), optionally *all* unused images and volumes (more aggressive, can delete data from unmounted volumes), and the build cache (`docker builder prune`).
- **JetBrains** (WebStorm, PyCharm, DataGrip, RubyMine, Toolbox...): the IDEs' indexing cache (`~/Library/Caches/JetBrains`, rebuilt automatically on next open) and logs (`~/Library/Logs/JetBrains`). Toolbox's old IDE version archives are only reported (size + where to configure retention), never deleted automatically.
- **Ollama**: downloaded models, asked one by one by name and size (deleting one means re-pulling it later), plus its logs.
- **uv**: the Python package cache (`uv cache clean`).
- **bun**: the package cache (`~/.bun/install/cache`).
- **Legacy version managers** (`pyenv`, `nvm`, `rvm`): detects leftover installs and offers to remove each one *completely* (not just its cache), since they're superseded by asdf/uv/bun — see [Package managers](#package-managers).
- **Bonus**: npm cache, pnpm store (`pnpm store prune`), pip cache, and Xcode DerivedData.

At the end it prints a summary of the estimated space freed and the
free disk space before/after.

Usage:

```bash
./clean-mac.sh                # interactive, asks before each cleanup
./clean-mac.sh --dry-run      # shows what would be done, deletes nothing
./clean-mac.sh -y             # auto-confirms every prompt
./clean-mac.sh --server       # force the Mac mini / server recommendations
./clean-mac.sh --workstation  # force the MacBook Pro / dev recommendations
```

## System inventories & audits

Point-in-time inventories of everything installed on each machine,
plus a cleanup audit with findings and recommendations, live in
`docs/` rather than here — they're snapshots of one machine's state,
not usage documentation for this repo:

- [`docs/audit-mac-mini.md`](docs/audit-mac-mini.md) — the server:
  what to strip back to a headless footprint.
- [`docs/audit-macbook-pro.md`](docs/audit-macbook-pro.md) — the
  workstation: a large footprint is expected, so the findings are
  about drift and hygiene (manual installs, tools installed twice,
  declared stack vs. actual stack, disk pressure).
