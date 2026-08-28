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

Legacy tools that predate this setup and are being phased out because
they're now redundant:

- **pyenv** → replaced by `uv` (`uv python install`, `uv venv`).
- **nvm** → replaced by `asdf` (nodejs plugin) or `bun` directly.
- **rvm** → replaced by `asdf` (ruby plugin).
- **npm** / **yarn** → kept only for compatibility with projects that
  require them; `bun` is the default otherwise.

`clean-mac.sh` has a dedicated section that detects leftover
`~/.pyenv`, `~/.nvm`, `~/.rvm` installs and offers to remove them
completely (not just their cache) — see below.

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

## System inventory (Mac mini, snapshot 2026-08-28)

Full inventory of what's installed on this machine and how, gathered
from `brew list`, `system_profiler SPApplicationsDataType` (macOS's
own record of where each `.app` came from), and each language package
manager's global-install list. Useful as a baseline for future audits
— re-generate rather than trust this if it's been a while.

This Mac is shared with another local account (`raphael`) — a few
apps below belong to that account, not this dev/server setup.

### Homebrew — formulae installed on request (61)

The rest of `brew list --formula` (~155 total) is transitive
dependencies (image/codec libs pulled in by ffmpeg/imagemagick,
Python/crypto libs, etc.) — not listed individually, see `brew leaves`
for the live list.

- **Languages/runtimes**: asdf, go, python@3.13, elixir, yarn
- **DevOps/cloud/infra**: docker, colima, ansible, kubernetes-cli (kubectl), helm, kind, kubeseal, k9s, terraform, vault, cloudflared, scw (Scaleway CLI), macmon
- **Git/dev tooling**: git, git-lfs, git-filter-repo, gh, hub, bash-completion, pnpm, coreutils, automake, pkgconf
- **Media/image processing**: imagemagick, ghostscript, gifsicle, jhead, jpeg, jpegoptim, optipng, pngcrush, pngquant, advancecomp, agg, portaudio
- **Misc CLI**: asciinema, summarize, swiftformat, swiftlint, xcodegen, sentry-wizard, pandoc, dnsmasq, nginx, mqttx-cli, terraformer
- **Kept for compatibility**: libiconv, libksba, libxslt, openssl@1.1 (deprecated upstream, still needed by ruby-build — see [Package managers](#package-managers)), zlib

`openai-whisper` was removed on 2026-08-28 — it was the only thing
pulling in `pytorch`, `numpy`, `openblas`, `gcc`, `llvm@20` and 8 more
transitive-only formulae, so `brew autoremove` cascaded and freed
~2.5 GB. `goplaces` used to also show up here as a stray formula
install (`0.2.1`) left behind after the tap switched to shipping it as
a cask (`0.4.4`, still installed — see casks below); the formula copy
is now gone.

### Homebrew — casks (34)

- **AI tools**: chatgpt, claude-code, codex, codexbar, lm-studio, ollama-app
- **Dev tools/IDE**: jetbrains-toolbox, sublime-text, ghostty, postman, github
- **Browsers**: arc, google-chrome
- **Communication**: discord, microsoft-teams, slack, telegram, zoom
- **Productivity/notes**: miro, notion, notion-calendar, timing, typora
- **Design**: figma
- **Utilities**: gcloud-cli, gpg-suite, goplaces, ngrok, raycast, superwhisper, font-hack-nerd-font
- **Containers**: docker, docker-desktop

`hyper`, `notion-mail`, `airtable` and `evernote` (the last one was
already commented out in `install-deps.sh`, but the app itself was
still installed from an older run) were uninstalled on 2026-08-28,
along with their leftover `~/Library/Application Support`/Caches/
Preferences data. `install-deps.sh`'s Hyper/VS Code/Cursor/Airtable/
Notion-mail install steps and the tracked `.hyper.js` config (Hyper's
config file, symlinked by `configure_dotfiles.sh`) are gone too.

### Mac App Store (18 apps)

No `mas` CLI installed, so these can't be listed/updated from the
terminal today (`brew install mas` would fix that): Airmail, Copilot,
Developer, Enchanted, ExcalidrawZ, Keynote, Messenger, Microsoft
Excel, Microsoft PowerPoint, MindNode 2, MindNode Classic, Numbers,
OneDrive, Pages, Speedtest, TestFlight, TypingLand, WhatsApp.

### Installed manually (not Homebrew, not the App Store)

Each of these was downloaded/installed outside any package manager,
so Homebrew/`clean-mac.sh` doesn't know about it and can't auto-update
or track it:

- **Claude.app** (desktop) — direct download, no official Homebrew cask for it (only `claude-code`, the CLI).
- **JetBrains IDEs** (WebStorm, PyCharm, RubyMine, DataGrip) — managed by JetBrains Toolbox, itself a Homebrew cask.
- **Google Drive**, plus its Chrome-generated PWA shortcuts (Google Docs/Sheets/Slides) — Google's own installer.
- **Stats**, **AlexSideBar** — menu bar utilities, no cask used even though one exists for Stats.
- **Zed**, **VLC**, **Raspberry Pi Imager** — a Homebrew cask exists for each but wasn't used.
- **Xcode-beta.app** (3.6 GB) — Apple Developer site, not the App Store.
- **N8Ninja** — TestFlight beta build (n8n desktop client).
- **Hardware-vendor utilities**: DDPM (BenQ/Qisda monitor control), Nanoleaf Desktop (347 MB), Reachy Mini Control, Logi Tune, EPSON Manuals.
- **Claude Code URL Handler** — auto-generated helper app, not a separate install (comes with the Claude Code CLI).
- **LibreOffice**, **Steam** — belong to the `raphael` account, not this setup.

### Language-level global installs

- **uv tool**: `aider-chat`, `openhands` (+ `openhands-acp`), `specify-cli`
- **npm -g**: nothing besides npm itself
- **bun / pnpm global**: nothing
- **gem**: nothing — `~/.gem` (91 MB of gems installed under the old system Ruby 2.6.10, orphaned since asdf owns `ruby`) was removed on 2026-08-28
- **asdf plugins**: only `ruby` (3.3.5) — no `nodejs` plugin yet
- **cargo / go install**: nothing (`~/.cargo` doesn't exist, `~/go/bin` is empty)
- **pipx**: not installed

### Background services (`brew services list`)

`cloudflared`, `colima`, `nginx`, `unbound`, `vault` are installed but
not currently running. `dnsmasq` is loaded but in **error** state
(last run failed) — worth checking if it's actually needed.

## Audit & recommendations

Findings from the inventory above, roughly ordered by impact. Items
marked **Done** were actioned on 2026-08-28.

1. ~~Duplicate/overlapping casks.~~ **Done — partially a non-issue.**
   `brew info` showed `docker`/`docker-desktop` and `ollama`/`ollama-app`
   are the *same* cask under two names (one Caskroom install each,
   just an old-name alias) — nothing to remove there, removing "the
   duplicate" would have uninstalled the real thing. `goplaces` was a
   genuine duplicate: a stray formula install (`0.2.1`) left over
   after the tap switched to shipping it as a cask (`0.4.4`, still
   installed). The formula copy is gone.
2. **This Mac mini still carries a full dev-workstation footprint**,
   which contradicts its stated role (see
   [Machines & environments](#machines--environments)): Docker
   Desktop, 4 JetBrains IDEs (WebStorm/PyCharm/RubyMine/DataGrip) via
   Toolbox, Sublime Text, Postman, Figma, Slack, Arc, Discord,
   Telegram, Zoom, Teams, Notion (+Mail +Calendar), Miro, Airtable,
   Typora — none of that belongs on a headless server. Cursor and VS
   Code are gone (see below); the rest is still there. Once the
   MacBook Pro is confirmed as the daily driver, prune this list here.
3. **AI-tool sprawl**: ChatGPT, Claude, Claude Code, Codex, CodexBar,
   LM Studio, Ollama, Aider, OpenHands, Enchanted (an Ollama GUI) and
   Zed still overlap in purpose (Cursor is gone — see below). Worth
   deciding on a core set (e.g. Claude Code + Ollama CLI for a server)
   and dropping the rest here rather than keeping every one installed
   on every machine.
4. **Xcode-beta.app (3.6 GB)** — a beta of Apple's IDE on a machine
   that's meant to run headless. Remove unless actively used for
   iOS/macOS beta testing.
5. **`dnsmasq` service in error state.** Either fix it (`brew services
   restart dnsmasq` and check logs) or remove it if it's not actually
   used — a broken DNS resolver service sitting on a server is worth
   resolving one way or the other, not leaving silently broken.
6. ~~Stale system-Ruby gems.~~ **Done.** `~/.gem` (91 MB, under the old
   system Ruby, orphaned since asdf owns `ruby` 3.3.5) removed.
7. **Hardware-vendor apps installed unconditionally** (DDPM, Nanoleaf
   Desktop, Reachy Mini Control, Logi Tune, EPSON Manuals) — these are
   typically only needed while actively configuring that piece of
   hardware. On a server especially, consider removing them and
   reinstalling only when you actually need to change a device's
   settings.
8. **Casks exist but weren't used** for Zed, VLC, and Raspberry Pi
   Imager (installed manually instead) — no functional problem, but
   switching them to Homebrew would make `brew upgrade`/`clean-mac.sh`
   cover them like everything else instead of them silently going
   stale.
9. **No `mas` CLI** — the 18 Mac App Store apps are invisible to
   Homebrew tooling. `brew install mas` would let `mas outdated` catch
   updates for Keynote/Numbers/Pages/TestFlight/etc. instead of
   relying on the App Store app to notice.
10. **`python@3.13`** is installed on request but, now that
    `openai-whisper`/`pytorch`/`numpy` are gone (see below), `brew
    uses --installed python@3.13` returns nothing — it's fully
    orphaned and safe to `brew uninstall python@3.13`. `python@3.14`
    stays: `ansible` and `gcloud-cli` both depend on it.
11. **`macmon`, `summarize`, `mqttx-cli`** and a few other niche
    formulae are worth a quick "do I still use this" pass next time
    `clean-mac.sh` runs `brew autoremove` — small individually, but
    they're exactly the kind of thing that silently accumulates.
12. ~~`openai-whisper`, `Cursor`, `VS Code`.~~ **Done.**
    `brew uninstall openai-whisper` cascaded via `brew autoremove`
    into 13 dependency-only formulae — `llvm@20` (1.5 GB), `pytorch`
    (341 MB), `gcc` (497 MB), `numpy`, `openblas`, `protobuf`,
    `pybind11`, `abseil`, `eigen`, `isl`, `libmpc`, `mpfr`, `sleef` —
    roughly **2.5 GB** freed. Cursor (~180 MB of leftover app data)
    and VS Code (~200 KB) were uninstalled via
    `brew uninstall --cask`, including their orphaned
    `~/Library/Application Support`/`~/.cursor`/`~/.vscode` data.
