# Mac mini system audit

Point-in-time inventory and cleanup audit of the Mac mini
(local/remote server — see
[Machines & environments](../README.md#machines--environments)),
moved out of the main README to keep that file focused on how to use
the dotfiles rather than a snapshot of one machine's state. Re-generate
rather than trust this if it's been a while.

## System inventory (Mac mini, snapshot 2026-08-28)

Full inventory of what's installed on this machine and how, gathered
from `brew list`, `system_profiler SPApplicationsDataType` (macOS's
own record of where each `.app` came from), and each language package
manager's global-install list.

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
- **Kept for compatibility**: libiconv, libksba, libxslt, openssl@1.1 (deprecated upstream, still needed by ruby-build — see [Package managers](../README.md#package-managers)), zlib

`openai-whisper` was removed on 2026-08-28 — it was the only thing
pulling in `pytorch`, `numpy`, `openblas`, `gcc`, `llvm@20` and 8 more
transitive-only formulae, so `brew autoremove` cascaded and freed
~2.5 GB. `goplaces` used to also show up here as a stray formula
install (`0.2.1`) left behind after the tap switched to shipping it as
a cask (`0.4.4`, still installed — see casks below); the formula copy
is now gone.

### Homebrew — casks (37)

- **AI tools**: chatgpt, claude-code, codex, codexbar, lm-studio, ollama-app
- **Dev tools/IDE**: jetbrains-toolbox, sublime-text, ghostty, postman, github, zed
- **Browsers**: arc, google-chrome
- **Communication**: discord, microsoft-teams, slack, telegram, zoom
- **Productivity/notes**: miro, notion, notion-calendar, timing, typora
- **Design**: figma
- **Utilities**: gcloud-cli, gpg-suite, goplaces, ngrok, raycast, superwhisper, font-hack-nerd-font, raspberry-pi-imager
- **Media**: vlc
- **Containers**: docker, docker-desktop

`hyper`, `notion-mail`, `airtable` and `evernote` (the last one was
already commented out in `install-deps.sh`, but the app itself was
still installed from an older run) were uninstalled on 2026-08-28,
along with their leftover `~/Library/Application Support`/Caches/
Preferences data. `install-deps.sh`'s Hyper/VS Code/Cursor/Airtable/
Notion-mail install steps and the tracked `.hyper.js` config (Hyper's
config file, symlinked by `configure_dotfiles.sh`) are gone too.

`zed`, `vlc` and `raspberry-pi-imager` were adopted into Homebrew on
2026-08-28 (see item 8 below) — previously installed manually, now
listed here instead of under "Installed manually".

### Mac App Store (18 apps)

`install-deps.sh` gained an `mas` CLI + App Store apps step on
2026-08-28 (see item 9 below), but it hasn't been run on this machine
yet — `mas` itself still isn't installed here. Until then these can't
be listed/updated from the terminal: Airmail, Copilot, Developer,
Enchanted, ExcalidrawZ, Keynote, Messenger, Microsoft Excel, Microsoft
PowerPoint, MindNode 2, MindNode Classic, Numbers, OneDrive, Pages,
Speedtest, TestFlight, TypingLand, WhatsApp.

### Installed manually (not Homebrew, not the App Store)

Each of these was downloaded/installed outside any package manager,
so Homebrew/`clean-mac.sh` doesn't know about it and can't auto-update
or track it:

- **Claude.app** (desktop) — direct download, no official Homebrew cask for it (only `claude-code`, the CLI).
- **JetBrains IDEs** (WebStorm, PyCharm, RubyMine, DataGrip) — managed by JetBrains Toolbox, itself a Homebrew cask.
- **Google Drive**, plus its Chrome-generated PWA shortcuts (Google Docs/Sheets/Slides) — Google's own installer.
- **Stats**, **AlexSideBar** — menu bar utilities, no cask used even though one exists for Stats.
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
   [Machines & environments](../README.md#machines--environments)): Docker
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
8. ~~Casks exist but weren't used~~ **Done.** Zed, VLC, and Raspberry
   Pi Imager were installed manually. Adopted into Homebrew on
   2026-08-28 via `brew install --cask --force <name>` (replaces the
   `/Applications` app bundle in place — no user data lost, since that
   lives outside the bundle) and added to `install-deps.sh` so
   `brew upgrade`/`clean-mac.sh` cover them like everything else
   instead of them silently going stale.
9. **No `mas` CLI** — the 18 Mac App Store apps are invisible to
   Homebrew tooling. **Partially done**: `brew install mas` plus the
   App Store app list were added to `install-deps.sh` on 2026-08-28,
   but that step hasn't been run on this machine yet, so `mas` itself
   still isn't installed and `mas outdated` doesn't work until it is.
10. **`python@3.13`** is installed on request but, now that
    `openai-whisper`/`pytorch`/`numpy` are gone (see below), `brew
    uses --installed python@3.13` returns nothing — it's fully
    orphaned and safe to `brew uninstall python@3.13`. `python@3.14`
    stays: `ansible` and `gcloud-cli` both depend on it. Re-checked on
    2026-08-28 — still orphaned, still installed, still pending.
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
