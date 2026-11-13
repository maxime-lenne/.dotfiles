# Mac mini system audit

Point-in-time inventory and cleanup audit of the Mac mini
(local/remote server — see
[Machines & environments](../README.md#machines--environments)),
moved out of the main README to keep that file focused on how to use
the dotfiles rather than a snapshot of one machine's state. Re-generate
rather than trust this if it's been a while.

## Inventaire système (Mac mini, relevé 2026-11-09)

Mac16,11 (Apple M4 Pro, 24 Go), macOS 27.2 (26B123), hostname
`mac-mini` — renommé le 2026-11-07 depuis `mac.home`, qui faisait
détecter la machine comme **workstation** par `detect_machine_role`.

Chiffres tirés de `brew list --installed-on-request`, `brew list --cask`,
`mas list`, `system_profiler SPApplicationsDataType` (provenance de
chaque `.app`) et de la liste globale de chaque gestionnaire de paquets,
via `.claude/skills/audit-machine/scripts/collect-machine-facts.sh`.

Le Mac est partagé avec un second compte local, `raphael-oliveira`
(l'ancien compte `raphael` n'existe plus). Les apps de l'ancien compte
relevées au 2026-08-28 (LibreOffice, Steam) ne sont plus dans
`/Applications`.

### Homebrew — formules installées explicitement (64)

Sur 185 formules au total, les 121 autres sont des dépendances
transitives. À noter parmi elles : `summarize` tire à lui seul `node`,
`deno`, `yt-dlp` et `tesseract` ; `aider` tire `python@3.12`.

- **Runtimes** : asdf, uv, go
- **DevOps/cloud/infra** : docker, colima, ansible, kubernetes-cli, helm, k9s, kind, kubeseal, terraform, terraformer, vault, cloudflared, scw, supabase, macmon
- **Services** : nginx, dnsmasq, postgresql@18
- **Git/outillage** : git, git-lfs, git-filter-repo, gh, hub, shellcheck, bash-completion, coreutils, automake, pkgconf, mas
- **IA en terminal** : aider, opencode, llmfit, summarize, portaudio
- **Image/média** : ffmpeg, imagemagick, ghostscript, poppler, gifsicle, jhead, jpeg, jpegoptim, optipng, pngcrush, pngquant, advancecomp, agg, asciinema, pandoc
- **Apple/iOS** : swiftformat, swiftlint, xcodegen, ideviceinstaller, libimobiledevice
- **Bibliothèques de compilation** : openssl@3, libxml2, libxslt, libiconv, libksba, libyaml, zlib

Depuis le relevé précédent : `elixir` (et `erlang`, `wxwidgets@3.2`,
`unixodbc` par cascade, 276 Mo pour ces trois-là) désinstallé le 2026-11-07 ; `yarn`,
`pnpm`, `sentry-wizard`, `mqttx-cli`, `python@3.14` explicite et
`openssl@1.1` ne sont plus là. Arrivés : `ffmpeg`, `mas`, `shellcheck`,
`supabase`, `postgresql@18`, `opencode`, `llmfit`, `aider`,
`libimobiledevice`, `ideviceinstaller`, `libxml2`, `libyaml`, `openssl@3`.

88 formules et 18 casks sont en retard d'une version (`brew outdated`).

### Homebrew — casks (31)

- **IA** : chatgpt, claude, claude-code, codex, codexbar, copilot-cli
- **Navigateurs** : brave-browser, google-chrome
- **Dev/éditeurs** : docker-desktop, ghostty, sublime-text, jetbrains-toolbox (aucun IDE installé à travers lui), fuse-t, temurin, gcloud-cli
- **Communication** : slack, discord, telegram
- **Productivité/notes** : notion, notion-calendar, typora, timing, raycast, superwhisper, google-drive
- **Design/média** : figma, vlc
- **Utilitaires** : gpg-suite, stats, font-hack-nerd-font, raspberry-pi-imager

Désinstallés le 2026-11-07 (décision rôle serveur) : arc, firefox,
microsoft-edge, zoom, microsoft-teams, miro, cursor, antigravity,
lm-studio, nanoleaf, logi-options+, ollama-app. Absents depuis le relevé
précédent sans trace de date : postman, github, zed, goplaces, ngrok.
Aucun cask fantôme (cask enregistré, app absente du disque).

### Mac App Store (13 apps)

`mas` est désormais installé. Airmail, Copilot, Developer, ExcalidrawZ,
Microsoft Excel, OneNote, Outlook, PowerPoint, Word, MindNode, OneDrive,
WhatsApp, Xcode (3,9 Go). TestFlight (10 Mo) est aussi présent mais
n'apparaît pas dans `mas list`.

### Installé manuellement (ni Homebrew, ni App Store)

- **Nod** (0.5.0) — aucun cask (`brew search --cask nod` ne renvoie rien d'approchant).
- **Google Docs / Sheets / Slides** — raccourcis PWA générés par Chrome ; pas des installs à part entière.
- **GPG Keychain** — posé par le `.pkg` du cask `gpg-suite`, que `system_profiler` ne rattache pas au cask.
- **LogiPluginService** (`/Applications/Utilities`) — reliquat de `logi-options+`, voir item 7.
- **Claude Code URL Handler** (`~/Applications`) — généré par le CLI Claude Code, pas une install.

### Installs globaux par langage

- **asdf** : `nodejs` 26.10.0 et `ruby` 4.0.7 (fixés dans `~/.tool-versions`)
- **uv tool** : `vllm` 0.11.0 (avec `vllm-metal`, installé le 2026-11-07) — `aider-chat`, `openhands`, `openhands-acp` et `specify-cli` ne sont plus là (aider passe désormais par Homebrew)
- **uv python** : 3.13.15 géré par uv ; 3.14.7 et 3.12.14 viennent de Homebrew
- **npm -g** (Node asdf) : `gitmoji-cli` 9.7.0
- **bun** 1.4.2 : aucun paquet global
- **pnpm / yarn** : non installés
- **gem** (Ruby asdf 4.0.7) : 176 gems, dont `rails` 8.1.4 et `colorls`
- **go** : présent ; **cargo / pipx / composer** : non installés
- **Gestionnaires legacy** : `~/.nvm`, `~/.pyenv`, `~/.rvm` absents

### Services en arrière-plan (`brew services list`)

`cloudflared` tourne en démon système (`com.cloudflare.cloudflared`,
hors `brew services`) depuis la correction de l'item 13 ; la copie
Homebrew, qui faisait doublon, est arrêtée. `colima`, `dnsmasq`,
`nginx`, `postgresql@18` et `vault` sont installés mais arrêtés ;
`dnsmasq` ne tourne pas non plus en démon root (aucun processus, aucun
`/Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist` — voir item 5).

## Audit & recommandations

Findings from the inventory above, roughly ordered by impact. Items
marked **Done** were actioned on 2026-08-28; items marked **Fait**
later, at the date given.

Avancement au 2026-11-10 — traités : 1, 4, 6, 8, 9, 10, 12, 13, 15
(conservé) ; en attente d'une commande `sudo` : 2, 7, 14 ; partiels :
3, 11 ; régressé : 5 ; ouvert : 16.

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
   **Partiel au 2026-11-09.** Partis : Arc, Zoom, Teams, Miro, Cursor,
   Postman, Airtable, Notion Mail, les quatre IDE JetBrains (Toolbox
   n'en gère plus aucun). Restent : Docker Desktop (2,2 Go, voir item
   14), JetBrains Toolbox (vide), Sublime Text, Figma, Slack, Discord,
   Telegram, Notion + Notion Calendar, Typora, Timing, Raycast,
   superwhisper, Ghostty, Stats. ~~Reste-à-faire, une fois tranché ce qui
   sert encore en session écran partagé :
   `brew uninstall --cask jetbrains-toolbox sublime-text figma discord typora timing superwhisper`.~~
   **Tranché le 2026-11-10 : seul Docker Desktop part** (voir item 14),
   le reste est conservé volontairement. Item clos dès que
   l'item 14 l'est.
3. **AI-tool sprawl**: ChatGPT, Claude, Claude Code, Codex, CodexBar,
   LM Studio, Ollama, Aider, OpenHands, Enchanted (an Ollama GUI) and
   Zed still overlap in purpose (Cursor is gone — see below). Worth
   deciding on a core set (e.g. Claude Code + Ollama CLI for a server)
   and dropping the rest here rather than keeping every one installed
   on every machine.
   **Partiel au 2026-11-07.** Le runtime de modèles locaux est tranché :
   vLLM (`uv tool`, backend Metal) remplace Ollama.app et LM Studio,
   tous deux désinstallés ; Enchanted, Zed, Antigravity et OpenHands
   sont partis. Restent en recouvrement : ChatGPT, Claude (desktop),
   CodexBar en GUI ; Claude Code, Codex, Copilot CLI, aider, opencode
   en CLI. Reste-à-faire : garder les CLI réellement utilisés en ssh et
   retirer les GUI, p. ex. `brew uninstall --cask chatgpt claude codexbar`.
4. ~~**Xcode-beta.app (3.6 GB)**~~ **Fait — absente au 2026-11-09.**
   Mais Xcode stable (App Store, 3,9 Go) l'a remplacée ; elle ne se
   justifie que si le serveur compile du Swift/iOS. Sinon, la retirer
   avec `swiftformat`, `swiftlint`, `xcodegen` : voir item 15.
5. ~~`dnsmasq` service in error state.~~ **Done.** It was loaded as a
   *user* LaunchAgent (`~/Library/LaunchAgents/homebrew.mxcl.dnsmasq.plist`),
   but its config binds port 53 (`port=53`, serving `*.white-wood.local`
   → `192.168.1.71` for the LAN), which only root can do — hence the
   permission-denied failure. Fixed on 2026-08-28 by stopping the
   user-level service and starting it as a root system daemon instead
   (`brew services stop dnsmasq` then `sudo brew services start dnsmasq`
   — the matching `/Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist`
   was already present, just not the one loaded). Verified with
   `dig @192.168.1.71 test.white-wood.local` resolving correctly.
   Running it as root took `root:admin` ownership of some Cellar paths
   (`/opt/homebrew/Cellar/dnsmasq/...`, `/opt/homebrew/opt/dnsmasq`,
   `/opt/homebrew/var/homebrew/linked/dnsmasq`) — a future
   `brew upgrade`/`reinstall`/`uninstall dnsmasq` run as a normal user
   will need `sudo rm` on those paths first, per Homebrew's own
   warning.
   **Régressé au 2026-11-09 — la configuration n'existe plus.** Aucun
   processus `dnsmasq`, plus de `/Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist`,
   et `/opt/homebrew/etc/dnsmasq.conf` est le fichier d'origine
   entièrement commenté (ni `port=53`, ni `white-wood.local`). La
   machine a aussi changé d'IP : `192.168.1.23`, plus `.71`, donc
   `dig @192.168.1.71 test.white-wood.local` ne répond plus. À
   trancher : si le DNS local sert encore, recréer la règle
   `address=/white-wood.local/192.168.1.23` puis
   `sudo brew services start dnsmasq` ; sinon `brew uninstall dnsmasq`.
6. ~~Stale system-Ruby gems.~~ **Done.** `~/.gem` (91 MB, under the old
   system Ruby, orphaned since asdf owns `ruby` 3.3.5) removed.
7. **Hardware-vendor apps installed unconditionally** (DDPM, Nanoleaf
   Desktop, Reachy Mini Control, Logi Tune, EPSON Manuals) — these are
   typically only needed while actively configuring that piece of
   hardware. On a server especially, consider removing them and
   reinstalling only when you actually need to change a device's
   settings.
   **Presque fait au 2026-11-09.** DDPM, Reachy Mini Control, Logi
   Tune et EPSON Manuals sont absents ; Nanoleaf et Logi Options+
   désinstallés le 2026-11-07, et `install-deps.sh` ne les propose plus
   au rôle serveur. Reste un reliquat de l'installeur Logitech :
   `/Applications/Utilities/LogiPluginService.app` et deux reçus pkg
   (`com.logi.installer.pluginservice.*`). Pour finir :
   `sudo rm -rf /Applications/Utilities/LogiPluginService.app && sudo pkgutil --forget com.logi.installer.pluginservice.package && sudo pkgutil --forget com.logi.installer.pluginservice.media.package`.
8. ~~Casks exist but weren't used~~ **Done.** Zed, VLC, and Raspberry
   Pi Imager were installed manually. Adopted into Homebrew on
   2026-08-28 via `brew install --cask --force <name>` (replaces the
   `/Applications` app bundle in place — no user data lost, since that
   lives outside the bundle) and added to `install-deps.sh` so
   `brew upgrade`/`clean-mac.sh` cover them like everything else
   instead of them silently going stale.
9. ~~**No `mas` CLI**~~ **Fait — `mas` installé au 2026-11-09**,
   `mas list` voit les 13 apps. Mais la section App Store
   d'`install-deps.sh` est réservée au rôle workstation : sur un
   serveur, ces 13 apps sont désormais hors déclaration, voir item 16.
10. ~~`python@3.13` orphaned.~~ **Done.** Now that
    `openai-whisper`/`pytorch`/`numpy` were gone (see item 12), `brew
    uses --installed python@3.13` returned nothing — fully orphaned.
    Uninstalled on 2026-08-28 (`brew uninstall python@3.13`).
    `python@3.14` stays: `ansible` and `gcloud-cli` both depend on it.
11. **`macmon`, `summarize`, `mqttx-cli`** and a few other niche
    formulae are worth a quick "do I still use this" pass next time
    `clean-mac.sh` runs `brew autoremove` — small individually, but
    they're exactly the kind of thing that silently accumulates.
    **Partiel au 2026-11-09.** `mqttx-cli` est parti. `macmon` reste
    utile en headless. `summarize` est le vrai poids : c'est la seule
    formule qui tire `node`, `deno`, `yt-dlp` et (avec ghostscript)
    `tesseract`. Si elle ne sert pas : `brew uninstall summarize && brew autoremove`.
12. ~~`openai-whisper`, `Cursor`, `VS Code`.~~ **Done.**
    `brew uninstall openai-whisper` cascaded via `brew autoremove`
    into 13 dependency-only formulae — `llvm@20` (1.5 GB), `pytorch`
    (341 MB), `gcc` (497 MB), `numpy`, `openblas`, `protobuf`,
    `pybind11`, `abseil`, `eigen`, `isl`, `libmpc`, `mpfr`, `sleef` —
    roughly **2.5 GB** freed. Cursor (~180 MB of leftover app data)
    and VS Code (~200 KB) were uninstalled via
    `brew uninstall --cask`, including their orphaned
    `~/Library/Application Support`/`~/.cursor`/`~/.vscode` data.
13. ~~`cloudflared` est lancé deux fois, et les deux copies échouent en
    boucle.~~ **Fait le 2026-11-09 — tunnel rétabli.** Le service
    Homebrew est arrêté (`brew services list` : `none`, LaunchAgent
    retiré). Le démon système a été réinstallé avec le jeton
    (`/Library/Application Support/com.cloudflare.cloudflared/token`,
    248 octets, `root` en 600) ; il tourne depuis 17:54 sans une seule
    relance (`runs = 1`), et `curl http://127.0.0.1:20241/ready` répond
    `readyConnections: 4`. Les deux logs ont été vidés. Constat
    d'origine, relevé le 2026-11-09 :
    - **Le service Homebrew** (`~/Library/LaunchAgents/sh.brew.cloudflared.plist`,
      posé le 2026-11-06 à 17:05 par `brew services start cloudflared`)
      lance le binaire **sans aucun argument** : il ne correspond à
      aucun tunnel et fait doublon avec le démon officiel. launchd l'a
      relancé 25 387 fois (code de sortie 1) ;
      `/opt/homebrew/var/log/cloudflared.log` est fait de 25 575 lignes
      `permission denied` (460 Ko).
    - **Le démon officiel** (`/Library/LaunchDaemons/com.cloudflare.cloudflared.plist`,
      posé à 17:08 par `sudo cloudflared service install`, comme le
      demande Cloudflare) est le bon : il exécute
      `cloudflared tunnel run --token-file "/Library/Application Support/com.cloudflare.cloudflared/token"`
      pour le tunnel géré à distance `1fcd20dd-590f-4519-8ca9-0a6497f6e19f`.
      Ce tunnel a fonctionné : quatre connexions enregistrées le
      2026-11-06 à 16:08 UTC (lhr13, cdg14), puis arrêt propre sur
      SIGTERM à 16:42:56 UTC. Depuis, **le fichier de jeton manque**
      (le dossier est vide), et chaque relance échoue sur
      `Failed to read token file` : 50 275 échecs (code 255), et
      `/Library/Logs/com.cloudflare.cloudflared.err.log` atteint 7,9 Mo.
      **Le tunnel est donc coupé depuis le 2026-11-06.**

    Pour régler, dans l'ordre :
    1. Retirer le doublon Homebrew (aucune perte, il ne servait aucun
       tunnel) : `brew services stop cloudflared`.
    2. Remettre le jeton du tunnel, à recopier depuis le dashboard
       Zero Trust (Networks → Tunnels → le tunnel `1fcd20dd…` → *Install
       connector*). Le plus simple est de réinstaller le démon, qui
       réécrit le fichier de jeton :
       `sudo cloudflared service uninstall && sudo cloudflared service install <token>`.
       Vérifier ensuite qu'il reste en vie :
       `sudo launchctl print system/com.cloudflare.cloudflared | grep -E 'state|runs'`.
    3. Vider les deux logs gonflés par les boucles :
       `: > /opt/homebrew/var/log/cloudflared.log && sudo sh -c ': > /Library/Logs/com.cloudflare.cloudflared.err.log'`.
14. ~~Docker Desktop est toujours le moteur actif, colima ne tourne
    pas.~~ **Presque fait le 2026-11-10.** Docker Desktop a été vérifié
    vide (`docker ps -a`, `docker volume ls`, `docker images` : rien),
    puis remplacé : colima tourne (`--vm-type vz --vz-rosetta`, 4 CPU,
    8 Go, 60 Go de disque), démarre à l'ouverture de session
    (`brew services start colima`), et le contexte actif est `colima`
    (`docker run hello-world` OK). Ce que Desktop fournissait d'autre a
    été remplacé par des formules : `docker-compose`, `docker-buildx`,
    `docker-credential-helper`. Dans `~/.docker/config.json`,
    `credsStore` est passé de `desktop` à `osxkeychain`,
    `cliPluginsExtraDirs` a été ajouté et les hooks des plugins de
    Desktop retirés. `install-deps.sh` ne propose plus Docker Desktop
    au rôle serveur. Reste-à-faire, qui exige `sudo` (le cask retire des
    liens dans `/usr/local` et le helper `com.docker.vmnetd`) :
    `brew uninstall --cask docker-desktop`. Attention : colima est un
    LaunchAgent, il ne démarre qu'à l'ouverture de **ta** session. Après
    un redémarrage sans ouverture de session automatique, aucun
    conteneur ne tourne. Constat d'origine : `docker context show` renvoie `desktop-linux` ; le README
    prescrit colima + CLI `docker` sur ce serveur. `Docker.raw` ne pèse
    que 13 Mo réels, donc rien à migrer de lourd — mais vérifier quand
    même avant de désinstaller (`docker ps -a`, `docker volume ls`),
    car **désinstaller Docker Desktop supprime ses volumes**. Puis :
    `colima start && docker context use colima && brew uninstall --cask docker-desktop`.
15. ~~Outillage Apple/iOS sans usage serveur évident : Xcode (3,9 Go,
    App Store), `swiftformat`, `swiftlint`, `xcodegen`,
    `ideviceinstaller`, `libimobiledevice`, TestFlight. Ils vont
    ensemble : un serveur qui ne compile pas d'app iOS n'en a besoin
    d'aucun.~~ **Conservé volontairement (décision du 2026-11-10)** :
    le Mac mini sert à l'automatisation des builds Apple/iOS, qui a
    besoin de toute la chaîne. Rien à faire. À ne pas re-signaler dans
    un prochain audit tant que ce rôle tient.
16. **13 apps App Store hors déclaration pour le rôle serveur.** Depuis
    la correction du hostname (2026-11-07), `install-deps.sh` saute la
    section App Store sur cette machine : Airmail, Copilot, Developer,
    ExcalidrawZ, Excel, OneNote, Outlook, PowerPoint, Word, MindNode,
    OneDrive, WhatsApp et Xcode ne seraient pas réinstallés par une
    reconstruction — ce qui est voulu pour un serveur, à condition de
    les retirer. `mas uninstall` exige `sudo` :
    `sudo mas uninstall 918858936 6738511300 640199958 6636493997 462058435 784801555 985367838 462062816 462054704 6446116532 823766827 310633997`.
    Puis `brew uninstall mas` s'il ne sert plus. Petit reliquat associé :
    `~/.ollama` (24 Ko, logs écrits le 2026-11-07 juste avant la
    désinstallation d'Ollama.app) — `rm -rf ~/.ollama`.
