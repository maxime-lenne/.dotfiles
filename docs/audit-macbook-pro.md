# MacBook Pro system audit

Point-in-time inventory and cleanup audit of the MacBook Pro
(dev workstation — see
[Machines & environments](../README.md#machines--environments)),
kept out of the main README for the same reason as its
[Mac mini counterpart](audit-mac-mini.md): it's a snapshot of one
machine's state, not usage documentation. Re-generate rather than
trust this if it's been a while.

**Read this differently from the Mac mini audit.** There, the goal was
to shrink a machine back down to a server footprint. Here a large
footprint is the *expected* state — this is the daily driver, it's
supposed to carry IDEs, Docker, design and communication apps. So the
findings below are about **drift and hygiene** (things installed
outside any package manager, tools installed twice, declared stack vs.
actual stack, disk pressure), not about minimalism.

## System inventory (MacBook Pro, snapshot 2026-08-28)

`Mac16,7`, macOS 26.7 (25G224), hostname `MacBook-Pro-de-Maxime`.
Gathered from `brew leaves` / `brew list --installed-on-request`,
`system_profiler SPApplicationsDataType` (macOS's own record of where
each `.app` came from), and each language package manager's
global-install list.

### Homebrew — formulae installed on request (48)

`brew list --formula` totals 186; the other ~138 are transitive
dependencies (image/codec libs pulled in by ffmpeg/imagemagick, crypto
and Python libs, etc.) — see `brew leaves` for the live list.

- **Version/package managers**: asdf, uv, pyenv
- **Databases**: postgresql@14, postgresql@18, supabase (`supabase/tap`)
- **DevOps/cloud/infra**: ansible, azure-cli, cloudflared, helm, kubernetes-cli (kubectl), k9s (`derailed/k9s`), terraform + vault (`hashicorp/tap`), scw (Scaleway CLI)
- **Git/dev tooling**: git, gh, hub, bash-completion, coreutils, automake, pkgconf
- **AI/LLM CLI**: aider, opencode (`anomalyco/tap`), llmfit
- **Media/image processing**: ffmpeg, ghostscript, gifsicle, imagemagick, jhead, jpeg, jpegoptim, optipng, pngcrush, pngquant, poppler, portaudio
- **iOS/mobile**: ideviceinstaller, libimobiledevice
- **Misc CLI**: asciinema
- **Kept for compatibility**: libiconv, libksba, libxml2, libxslt, libyaml, openssl@1.1 (deprecated upstream, still needed by ruby-build), openssl@3, zlib

Note the tap formulae (k9s, terraform, vault, supabase, opencode) don't
show up in a plain `brew leaves` listing even though
`brew info` confirms `installed_on_request: true` for each — use
`brew list --installed-on-request` alongside it, or they look like
orphans when they aren't. `brew autoremove --dry-run` currently returns
nothing, so there's no dependency-only cruft to reclaim.

### Homebrew — casks (42)

- **AI tools**: chatgpt*, claude, codex, codexbar, copilot-cli, cursor, lm-studio, ollama-app, superwhisper
- **Dev tools/IDE**: ghostty, wezterm, hyper, sublime-text, visual-studio-code, jetbrains-toolbox, postman, dbeaver-community*, github* (GitHub Desktop), mqttx, ngrok, gcloud-cli, gpg-suite, fuse-t, docker-desktop
- **Browsers**: arc, firefox, google-chrome
- **Communication**: discord, microsoft-teams, slack, telegram, zoom
- **Productivity/notes**: airtable*, evernote*, miro, notion, notion-calendar, notion-mail*, typora, raycast
- **Design**: figma
- **Fonts**: font-hack-nerd-font

`*` = **orphaned registration**: Homebrew still records the cask as
installed, but the `.app` it points to is gone from `/Applications`
(deleted by hand rather than with `brew uninstall`). Six of them:
`airtable`, `chatgpt`, `dbeaver-community`, `evernote`, `github`,
`notion-mail` — see item 4 below.

### Mac App Store (17 apps)

`mas` is **not installed on this machine** either (the `mas` step added
to `install-deps.sh` on 2026-08-28 hasn't been run here), so these
can't be listed or updated from the terminal: Airmail, Copilot,
Developer, ExcalidrawZ, Keynote, Microsoft Excel, Microsoft OneNote,
Microsoft Outlook, Microsoft PowerPoint, Microsoft Word, MindNode Next,
Numbers, OneDrive, Pages, TestFlight, WhatsApp, Xcode.

### Installed manually (not Homebrew, not the App Store)

Downloaded/installed outside any package manager, so Homebrew and
`clean-mac.sh` can't see, update or track them:

- **Antigravity** (Google's agentic IDE) — also appended a `PATH` line to `.zshrc`. A cask exists.
- **Zed**, **Stats**, **Timing** — casks exist for all three (Zed was adopted into Homebrew on the Mac mini on 2026-08-28; that was never done here).
- **Microsoft Edge**, **Google Drive** (+ its Chrome-generated PWA shortcuts: Google Docs/Sheets/Slides) — vendor installers, casks exist. Both ship their own auto-updater LaunchAgents (`com.microsoft.EdgeUpdater.wake`, `com.google.keystone.agent`, `com.google.GoogleUpdater.wake`).
- **Cloudflare WARP** — cask exists.
- **ChatGPT Classic.app** — an older/renamed ChatGPT build; the `chatgpt` cask's target (`/Applications/ChatGPT.app`) no longer exists, so these two are almost certainly the same install gone out of sync.
- **Claude Code CLI** — installed by its own installer under `~/Library/Application Support/Claude/claude-code/2.1.237`, plus the auto-generated **Claude Code URL Handler.app**. A `claude-code` cask exists and is what the Mac mini uses.
- **GitHub Copilot.app**, **Fireflies**, **Paper**, **Pencil** — direct downloads.
- **JetBrains IDEs** (WebStorm, PyCharm, RubyMine, DataGrip, in `~/Applications`) — managed by JetBrains Toolbox, itself a Homebrew cask.
- **Hardware-vendor utilities**: DDPM (Dell Display and Peripheral Manager — drives the U4025QW, including its KVM), Logi Options+ / LogiPluginService, Nanoleaf Desktop, Reachy Mini Control. Casks exist for `logi-options+` and `nanoleaf`.
- **Not installs**: `N8Ninja.app` (×4) and `MuJoCo_(mjpython).app` only exist as Xcode DerivedData build products and inside a Python venv respectively — they're build output, not something to uninstall.

### Language-level global installs

Updated 2026-08-28 after the item-6 migration below.

- **asdf** 0.18.0 — plugins `nodejs` (24.20.0 home default, 22.11.0 also installed) and `ruby` (3.3.5 home default), pinned in `~/.tool-versions`. `node`, `npm`, `ruby` and `gem` all resolve through `~/.asdf/shims`.
- **uv** 0.11.23 — owns Python: managed interpreters 3.13.15 and 3.14.0, plus the Homebrew `python@3.14` that `ansible`/`gcloud-cli` pull in as the bare `python3`.
- **uv tool**: `aider-chat`, `mistral-vibe` (+ `vibe-acp`), `specify-cli`
- **bun** 1.3.9 — installed (`~/.bun`), no global packages
- **npm -g**: nothing. `@openai/codex` and `corepack` went with nvm; codex stays available through its Homebrew cask, which resolves audit item 7's duplicate.
- **pnpm / cargo / go install / pipx**: nothing (`~/.cargo` and `~/go/bin` don't exist)
- **nvm / pyenv / rvm**: **all removed.** `~/.nvm`, `~/.pyenv` and `~/.rvm` no longer exist, and nothing in the shell config ever initialised them.
- **gem**: `~/.gem` (66 MB, cache-only, orphaned under the macOS system Ruby 2.6.10) is the last leftover — see item 6.

### Background services (`brew services list`)

`cloudflared`, `postgresql@14`, `postgresql@18` and `unbound` are
installed; **none is running**.

### Disk usage

**Snapshot 2026-08-28, after the first cleanup pass: 339 GB used of
460 GB — 101 GB free (77% full)**, up from 37 GB free. The gain came
from Ollama (41 GB of models removed) and caches (30 GB → 17 GB).
Docker was *not* reclaimed. Largest remaining contributors:

| Item | Size | Status |
|---|---|---|
| `~/Library/Containers/com.docker.docker` (`Docker.raw`) | **67 GB** | **untouched** — still 128 GB apparent / 67 GB actual |
| `~/Library/Caches` | 17 GB | was 30 GB |
| JetBrains: 4 IDE bundles (11.8 GB) + `~/Library/Application Support/JetBrains` (8.7 GB) | 20.5 GB | untouched |
| Xcode.app (4.0 GB) + `~/Library/Developer` (5.7 GB) | 9.7 GB | untouched |
| `/opt/homebrew` (Cellar 4.5 GB, Caskroom 787 MB) | 6.3 GB | untouched |
| `~/.cache` (uv 3.0 GB, chrome-devtools-mcp 295 MB) | 3.3 GB | untouched |
| `~/.ollama` | 16 KB | was 41 GB — all 5 models removed |
| Version managers: `.bun` 1.7 GB, `.asdf` ~600 MB | ~2.3 GB | `.pyenv`/`.nvm`/`.rvm` (1.4 GB) removed |

## Audit & recommendations

Findings from the inventory above, roughly ordered by impact. Nothing
here has been actioned yet.

1. ~~Disk is at 92% (37 GB free).~~ **Largely done — 101 GB free
   (77%) as of 2026-08-28.** The ~64 GB recovered came from items 3 and
   4; item 2 (Docker, 67 GB) is still outstanding and is now by a wide
   margin the largest single thing on this disk.
2. **Docker.raw is still 67 GB — NOT done.** Docker has been started
   since (the file was written 2026-08-28 23:17) but the size hasn't
   moved: 128 GB apparent, 67 GB actual. Pruning containers/images is
   not enough on its own — Docker Desktop never shrinks the disk image
   by itself. Run `docker system df` to see what's in there, then
   `docker system prune -a --volumes` (destructive: removes unused
   images *and* volumes — check volumes first), and then use Docker
   Desktop's *Settings → Resources → Disk image size* or
   *Troubleshoot → Clean / Purge data* to hand the space back to the
   filesystem. Expect 30–50 GB.
3. ~~Ollama holds 41 GB in 5 models.~~ **Done — all five removed**
   (`glm-4.7-flash` 19 GB, `mistral-small3.2` 15 GB, `deepseek-r1:8b`
   5.2 GB, `mistral` 4.4 GB, `mxbai-embed-large` 669 MB). `~/.ollama` is
   down to 16 KB. Note the app itself is still installed and running, so
   any model needed later is one `ollama pull` away.
4. ~~30 GB of `~/Library/Caches`.~~ **Partially done — down to
   17 GB.** Worth a second pass on the two the standard cleanup
   doesn't reach: Playwright's downloaded browsers
   (`npx playwright uninstall --all`) and pip's cache
   (`pip cache purge`).
5. ~~Six casks registered but their app is gone.~~ **Five of six
   done.** `airtable`, `chatgpt`, `dbeaver-community`, `evernote` and
   `notion-mail` are deregistered. **`github` (GitHub Desktop) is still
   registered at 3.5.4 with no app in `/Applications`** — finish it with
   `brew uninstall --cask --force github`. Original finding:
   They pollute `brew outdated`, and any `brew upgrade` will happily
   *reinstall* apps that were deliberately deleted. Clear them with
   `brew uninstall --cask --force <token>` (add `--zap` only if the
   leftover `~/Library` data should go too). Note `airtable`, `evernote`
   and `notion-mail` were already removed from `install-deps.sh` and
   uninstalled on the Mac mini on 2026-08-28 — this machine just never
   caught up. Check what `ChatGPT Classic.app` actually is before
   zapping `chatgpt`.
6. ~~The declared package-manager stack isn't the one running here.~~
   **Done on 2026-08-28 — migrated to the declared stack.** The state
   found was worse than "drift": the cleanup pass had already removed
   `~/.nvm`, `~/.pyenv` and `~/.rvm`, while asdf still had **zero
   plugins**, so the machine had **no Node.js at all** (`node: not
   found` in a login shell) and `ruby` still resolved to the macOS
   system 2.6.10. Worth noting the shell config was never the problem —
   `.zshrc` has only ever set up asdf's shims and never initialised
   nvm/pyenv/rvm; those tools had been leaking onto `PATH` by other
   means. What was done:

   - `asdf plugin add nodejs ruby`.
   - **Node**: 24.20.0 installed and set as the home default, plus
     22.11.0 for the one project that pins it. Verified: `node -v`
     resolves through `~/.asdf/shims`.
   - **Ruby**: 3.3.5 built and set as the home default — the version
     `maxime-lenne.github.io/.tool-versions` asks for, which was
     unsatisfiable until now. Built against **openssl@3**, not the
     openssl@1.1 the old `RUBY_CONFIGURE_OPTS` pointed at; verified with
     `OpenSSL::OPENSSL_VERSION` → 3.6.3. `.zshrc` updated accordingly,
     and `brew uses --installed openssl@1.1` now returns nothing, so
     that EOL formula can be dropped (it's still in `install-deps.sh`'s
     "basic libraries").
   - **Python**: uv already owned it, nothing to migrate. Added the
     3.13 interpreter so the project pinning `.python-version` 3.13
     resolves locally; uv reads the same file pyenv did, which is why
     no Python project broke when pyenv disappeared.
   - **Per-project pins verified end to end**: in the Jekyll repo,
     `ruby -v` → 3.3.5 and `node -v` → v22.11.0 from its
     `.tool-versions`; in the Python project, `uv python find` → the
     uv-managed 3.13.
   - **`install-deps.sh`**: the `nvm`, `pyenv` and `rvm` install
     branches are gone, so a rebuild can't recreate the drift. `pnpm`/
     `yarn` stay as an explicit opt-in for lockfile compatibility. The
     `--server`/`--workstation` split no longer differs on package
     managers, only on GUI/App Store apps — the header comment says so.
   - **README**: the "Package managers" section now records the legacy
     three as removed rather than "being phased out".

   One leftover: **`~/.gem` (66 MB) still needs deleting** — it holds
   only 111 cached `.gem` files and the rubygems index under Ruby 2.6.0,
   no installed gems and no binaries, and asdf's Ruby doesn't use it.
   `rm -rf ~/.gem` (the same thing that was done on the Mac mini).
7. **`aider` is still installed twice** — Homebrew formula
   (`/opt/homebrew/bin/aider`) *and* `uv tool aider-chat`
   (`~/.local/bin/aider`, v0.86.2). `~/.local/bin` comes first on
   `PATH`, so the uv copy wins and the Homebrew one just goes stale
   invisibly. Keep the `uv tool` install (it's the one aider upstream
   recommends) and run `brew uninstall aider`. **The `codex` duplicate
   resolved itself**: the npm global went with nvm, leaving only the
   Homebrew cask at `/opt/homebrew/bin/codex`.
8. ~~111 outdated formulae and 20 outdated casks.~~ **Done.**
   `brew outdated` now returns zero of each. The thing that made this
   necessary hasn't changed though — give `brew upgrade` a recurring
   slot, or the same backlog rebuilds silently.
9. **Editor and terminal sprawl.** Nine editors/IDEs (Cursor, VS Code,
   Zed, Sublime Text, Antigravity + WebStorm/PyCharm/RubyMine/DataGrip)
   and three terminals (Ghostty, WezTerm, Hyper). On a workstation this
   is defensible — but **Hyper was explicitly retired** (its cask,
   install step and tracked `.hyper.js` were removed from this repo on
   2026-08-28) and is still installed here, and the `wezterm` cask
   install is commented out in `install-deps.sh` while WezTerm remains
   installed. Those two are drift, not choice. The four JetBrains IDEs
   are 20.5 GB with Toolbox caches — Toolbox can also be told to keep
   fewer old versions.
10. **AI-tool overlap is even wider here than on the Mac mini**: Claude,
    Claude Code, ChatGPT (×2 states), Codex (×2 installs), CodexBar,
    Copilot (App Store) + GitHub Copilot.app + `copilot-cli`, Cursor,
    Antigravity, LM Studio, Ollama, Fireflies, superwhisper, aider,
    opencode, mistral-vibe, llmfit. Worth one deliberate pass deciding
    which are actually in the daily loop; the ones that aren't are still
    running updaters and filling caches (copilot 616 MB, codexbar
    343 MB).
11. **Ten apps installed by hand where a Homebrew cask exists**:
    Antigravity, Zed, Stats, Timing, Cloudflare WARP, Microsoft Edge,
    Google Drive, Nanoleaf Desktop, Logi Options+, Claude Code CLI.
    Same fix that was applied on the Mac mini:
    `brew install --cask --force <token>` adopts the existing bundle in
    place (no user data lost — that lives outside the app bundle), then
    add them to `install-deps.sh` so `brew upgrade` and `clean-mac.sh`
    cover them. Bonus: it retires the per-vendor auto-updater
    LaunchAgents from Google and Microsoft.
12. **No `mas`** — the 17 App Store apps are invisible to Homebrew
    tooling, exactly as on the Mac mini. The `install-deps.sh` step
    exists; it just needs running here. Its hardcoded list is also
    already stale relative to this machine (it installs Enchanted,
    Messenger, MindNode 2/Classic, Speedtest, TypingLand — none of which
    are installed here — and misses OneNote, Outlook, Word, MindNode
    Next, ExcalidrawZ, Xcode, which are).
13. ~~`install-deps.sh` has real bugs.~~ **Done on 2026-08-28.** Every
    package name below was checked against `brew info` before being
    changed; the script passes `bash -n`, and the rewritten helper was
    unit-tested against a stubbed `brew`.

    *Would have failed outright:* `ask_to-install "mqttx"` (hyphen for
    underscore — a command-not-found), `install_or_upgrade "--cask"" mqttx"`
    (the two strings concatenated into the single argument
    `--cask mqttx`), a bare `ngrok` call outside any guard, and
    `apm install file-icons` — Atom's package manager, sunset in 2022.

    *Installed the wrong thing, silently:* `install_or_upgrade "cursor"`
    without `--cask` (looked for a nonexistent formula); the `java` cask,
    which Homebrew removed — now `temurin`; the `ollama` cask alias
    instead of the `ollama-app` that's actually installed; the `docker`
    cask, confusable with the `docker` CLI formula the colima step
    installs — now `docker-desktop`; `postgresql`, an alias whose target
    major changes over time — now `postgresql@18`; and
    `mongodb-community@5.0`, EOL since October 2024.

    *Ran unconditionally or twice:* a stray `brew install --cask
    gcloud-cli` outside every guard, plus a second "GCP CLI" prompt
    installing `google-cloud-sdk` — which `brew info` confirms is just
    an alias for `gcloud-cli`. Both removed.

    *The helper itself:* `install_or_upgrade` decided "already
    installed?" with `brew list | grep $package`, an unanchored
    substring match — `jpeg` matched the installed `jpeg-turbo`, so it
    ran `brew upgrade jpeg` on a package that was never installed. It
    now matches exactly (`grep -qxF`), compares tap-qualified names like
    `derailed/k9s/k9s` on their last component the way brew lists them,
    accepts several packages per call (the image-tools line passed all
    nine as one space-joined string), and reports a failing brew command
    instead of swallowing it — which is what makes the two
    tap-dependent steps below degrade gracefully.

    *Ordering:* `gem install colorls` ran in the fonts section, long
    before any Ruby manager existed, so it hit the macOS system Ruby.
    Moved into the Ruby section. `hub` was dropped from
    `gem install bundler pry hub` — it's the Homebrew formula the Git
    section already installs, not a gem.

    *Left as-is, flagged:* `goplaces` (cask) and `mqttx-cli` (formula)
    are in neither homebrew/core nor any tap set up on this machine,
    though both are installed on the Mac mini. Their upstream taps
    couldn't be identified from here, so the steps carry a comment and
    now fail loudly instead of aborting the run.

    **Follow-up, done 2026-08-29: `shellcheck` is now wired in as a
    pre-commit hook** (`hooks/pre-commit`, enabled via
    `core.hooksPath`, which `configure_dotfiles.sh` sets on a fresh
    clone). It lints the staged content rather than the working tree,
    defaults to `-S info` so it catches the unquoted-expansion class,
    and degrades to a notice when shellcheck isn't installed. The four
    existing scripts were brought to a clean baseline first — a hook
    that fails on day one gets bypassed forever: a missing shebang in
    `configure_dotfiles.sh` (a blank first line meant it was never a
    shebang at all, so the script ran under whatever shell invoked it),
    `read` without `-r` in `dotfiles-lib.sh`, and three unquoted
    expansions in `install-deps.sh` including both `sudo chown -R`
    calls.
14. ~~Uncommitted drift in the working tree.~~ **Done — committed on
    2026-08-28**, together with the item-6 migration. What went in:
    `EDITOR=atom` → `vim`, the Antigravity `PATH` line its installer
    appended, and a commented-out `wezterm` cask line in
    `install-deps.sh` kept as a reminder next to the `ghostty` install.
    Still open, and unrelated to any working-tree state:
    `.zshrc` exports `BUNDLER_EDITOR="atom"` — Atom was discontinued in
    2022, and now that `EDITOR` is `vim` this line is the last thing
    still pointing at it.
15. **Two PostgreSQL majors installed (14 and 18), neither running**,
    plus `unbound` and `cloudflared` idle. If 14 is only kept for an old
    project, dump what's needed and drop it; two majors also means two
    data directories.
16. **The iOS/mobile toolchain is ~10 GB** (Xcode 4.0 GB, CoreSimulator
    3.5 GB, DerivedData 2.1 GB, plus `ideviceinstaller`/
    `libimobiledevice`). The N8Ninja DerivedData builds show it's
    genuinely used — but DerivedData and unused simulator runtimes are
    pure cache: `xcrun simctl delete unavailable` and clearing
    DerivedData reclaim most of it without touching the toolchain.
17. **Minor fix for the sibling doc**: [audit-mac-mini.md](audit-mac-mini.md)
    labels DDPM as "BenQ/Qisda monitor control". It's Dell's *Display
    and Peripheral Manager* — the utility for the U4025QW, including its
    KVM. Worth correcting there.
