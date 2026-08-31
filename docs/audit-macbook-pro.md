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

## Inventaire système (MacBook Pro, relevé 2026-08-29)

`Mac16,7`, Apple M4 Pro, 48 Go de RAM, macOS 26.7 (25G224), hostname
`MacBook-Pro-de-Maxime`.

Relevé par `.claude/skills/audit-machine/scripts/collect-machine-facts.sh`,
qui agrège `brew list`, `system_profiler SPApplicationsDataType` (le
registre macOS de la provenance de chaque `.app`) et la liste globale de
chaque gestionnaire de paquets. Le script est en lecture seule et
re-jouable : mieux vaut le relancer que faire confiance à ce document
s'il a vieilli.

### Homebrew — formules installées explicitement (48)

`brew list --formula` en totalise 148 ; la centaine restante, ce sont des
dépendances transitives. Le relevé du 2026-08-28 annonçait 48 sur 186 :
`shellcheck` puis `mas` se sont ajoutés, `pyenv` et `openssl@1.1` ont été
retirés le 2026-08-31 (items 18 et 19), et la chute du total vient du
`brew cleanup`/`autoremove` de l'item 8.

**Angle mort de Homebrew à connaître** : les formules issues d'un tap
(`k9s`, `supabase`, `terraform`, `vault`) n'apparaissent **ni** dans
`brew list --installed-on-request`, **ni** dans
`brew info --json=v2 --installed` — alors qu'elles sont installées et sur
le `PATH`. Le relevé précédent signalait déjà le problème pour
`brew leaves` ; il est en fait plus large. Le compte de 48 les réintègre
par différence avec `brew list --formula`, qui, lui, les voit. Tout
inventaire futur doit faire pareil, sinon ces quatre outils passent pour
désinstallés.

- **Gestionnaires de versions/paquets** : asdf, uv, mas *(App Store — ajouté le 2026-09-01, item 12 ; `pyenv` retiré le 2026-08-31, item 18)*
- **Bases de données** : postgresql@14, postgresql@18, supabase *(tap)*
- **DevOps/cloud/infra** : ansible, azure-cli, cloudflared, helm, kubernetes-cli (kubectl), k9s *(tap)*, terraform + vault *(tap)*, scw (CLI Scaleway)
- **Git/outillage dev** : git, gh, hub, bash-completion, coreutils, automake, pkgconf, shellcheck *(nouveau — c'est le linter du hook de pré-commit)*
- **CLI IA/LLM** : aider, opencode *(tap)*, llmfit
- **Média/image** : ffmpeg, ghostscript, gifsicle, imagemagick, jhead, jpeg, jpegoptim, optipng, pngcrush, pngquant, poppler, portaudio
- **iOS/mobile** : ideviceinstaller, libimobiledevice
- **Divers CLI** : asciinema
- **Gardées pour compatibilité** : libiconv, libksba, libxml2, libxslt, libyaml, openssl@3, zlib *(`openssl@1.1` retiré le 2026-08-31 — item 19)*

`brew autoremove --dry-run` ne renvoie rien : aucune dépendance orpheline
à récupérer.

### Homebrew — casks (42)

36 au relevé du 2026-08-29, 42 au 2026-08-28 : les six sortis étaient
cinq enregistrements fantômes désinscrits (`airtable`, `chatgpt`,
`dbeaver-community`, `evernote`, `notion-mail` — item 5) et `hyper`,
effectivement retiré (item 9). Les six revenus sont d'une tout autre
nature : ce sont les apps **adoptées** le 2026-09-01 au titre de
l'item 11 — elles étaient déjà sur la machine, Homebrew les voit
désormais.

- **IA** : claude, codex, codexbar, copilot-cli, cursor, lm-studio, ollama-app, superwhisper, antigravity†
- **Dev/IDE** : ghostty, wezterm, sublime-text, visual-studio-code, zed†, jetbrains-toolbox, postman, github\*, mqttx, ngrok, gcloud-cli, gpg-suite, fuse-t, docker-desktop
- **Navigateurs** : arc, firefox, google-chrome, microsoft-edge†
- **Communication** : discord, microsoft-teams, slack, telegram, zoom
- **Productivité/notes** : miro, notion, notion-calendar, typora, raycast
- **Design** : figma
- **Matériel / système** : nanoleaf†, stats†, timing†
- **Polices** : font-hack-nerd-font

`*` = **enregistrement fantôme** : Homebrew tient le cask pour installé
alors que le `.app` a disparu de `/Applications`. Il n'en reste qu'un,
`github` (GitHub Desktop) — item 5.

`†` = **adopté le 2026-09-01** : l'app était installée à la main, le cask
a repris le bundle en place (item 11).

En retard : `codex`, `cursor`, `lm-studio`.

Taps configurés : `anomalyco/tap`, `derailed/k9s`, `hashicorp/tap`,
`macos-fuse-t/cask`, `steipete/tap`, `supabase/tap`.

### Mac App Store (17 apps)

`mas` 7.0.0 est installé depuis le 2026-09-01 : ces apps sont enfin
listables et actualisables depuis le terminal, et `install-deps.sh`
déclare exactement les 17 installées, ni plus ni moins (item 12).

Airmail, Copilot, Developer, ExcalidrawZ, Keynote, Excel, OneNote,
Outlook, PowerPoint, Word, MindNode Next, Numbers, OneDrive, Pages,
TestFlight, WhatsApp, Xcode.

### Installé manuellement (ni Homebrew, ni App Store) — 20

Installés hors de tout gestionnaire de paquets : ni Homebrew ni
`clean-mac.sh` ne peuvent les voir, les mettre à jour ou les suivre.

- **Un cask existe, adoption en attente** (item 11) : **Cloudflare WARP**, **Google Drive**, **Logi Options+** — leurs casks réclament un mot de passe administrateur, à lancer à la main. Six autres (Antigravity, Zed, Stats, Timing, Microsoft Edge, Nanoleaf) ont été adoptées le 2026-09-01 et ont quitté cette liste.
- **Claude Code CLI** (+ son **Claude Code URL Handler.app** auto-généré) — reste hors Homebrew **délibérément** : le cask poserait un second binaire, plus ancien, à un autre chemin. Voir item 11.
- **IDE JetBrains** (WebStorm, PyCharm, RubyMine, DataGrip, dans `~/Applications`) — gérés par JetBrains Toolbox, lui-même un cask.
- **Téléchargements directs** : GitHub Copilot.app, Fireflies, Paper, Pencil, ChatGPT Classic.app.
- **Utilitaires constructeur** : DDPM (Dell Display and Peripheral Manager — pilote le U4025QW, KVM compris), Logi Options+ / LogiPluginService, Nanoleaf Desktop, Reachy Mini Control.
- **Ne sont pas des installs** : Google Docs/Sheets/Slides sont des raccourcis PWA générés par Chrome. GPG Keychain.app est un composant du cask `gpg-suite`, posé par son `.pkg` — il ressort ici parce qu'un cask `.pkg` ne déclare aucun artefact `app:`.

Note de méthode : zoom, Microsoft Teams et fuse-t figuraient dans cette
liste avant correction du collecteur. Ce sont des casks à base de `.pkg`,
qui ne déclarent pas d'artefact `app:` ; ils sont bien gérés par Homebrew
et **ne constituent pas des doublons**. Le collecteur les rattache
désormais via les chemins nommés dans leurs strophes `uninstall`/`zap`.

### Installs globaux par langage

- **asdf** 0.20.0 (0.18.0 au relevé précédent) — plugins `nodejs` (24.20.0 par défaut, 22.11.0 également installé) et `ruby` (3.3.5 par défaut), épinglés dans `~/.tool-versions`.
- **uv** 0.12.7 — interpréteurs gérés 3.13.15 et 3.14.0, plus les `python@3.12`/`python@3.14` de Homebrew que tirent ansible et gcloud-cli.
- **uv tool** : `aider-chat` 0.86.2, `mistral-vibe` 2.17.1 (+ `vibe-acp`). `specify-cli` a disparu depuis le relevé précédent.
- **bun** 1.3.9 — aucun paquet global.
- **npm -g** : `corepack` 0.35.0 et `npm` 11.19.0, sous le Node 24.20.0 d'asdf. Ce sont les deux paquets livrés avec Node, pas des installs délibérées.
- **pnpm / yarn / cargo / go / pipx / composer** : aucun.
- **Ruby** : 3.3.5 via les shims asdf, uniquement les gems par défaut. `~/.gem` **a été supprimé** : le reliquat de l'item 6 est soldé.
- **nvm / pyenv / rvm** : entièrement absents depuis le 2026-08-31 — répertoires *et* formules Homebrew. La formule `pyenv` 2.8.4 qui survivait à la suppression de `~/.pyenv` a été retirée (item 18).
- **Java** : aucun JDK, et c'est désormais un choix assumé — la config morte qui en supposait un a été retirée le 2026-08-31 (item 20). `install-deps.sh` garde sa section « Java (Temurin JDK) » derrière son prompt, donc un besoin futur est à un `./install-deps.sh` de distance.

### Services en arrière-plan (`brew services list`)

`cloudflared`, `postgresql@14` et `postgresql@18` sont installés ;
**aucun ne tourne**. `unbound` a disparu depuis le relevé précédent.

### Occupation disque

**Relevé 2026-08-29 : 317 Gio utilisés sur 460 — 123 Gio libres (73 %)**,
contre 339 Go utilisés et 101 Go libres le 2026-08-28.

Piège de mesure : sous APFS, `df -h /` porte sur le volume système scellé
et affiche ~12 Gio quel que soit le remplissage réel. Le chiffre qui
compte est celui de `/System/Volumes/Data`.

| Poste | Taille | Évolution |
|---|---|---|
| `~/Library/Containers/com.docker.docker` (`Docker.raw`) | **67 Go** | **inchangé** — 128 Go apparent / 67 Go réel |
| `~/Library/Caches` | 17 Go | inchangé |
| JetBrains (`~/Library/Application Support/JetBrains`) | 8,7 Go | inchangé |
| `/opt/homebrew` | 6,2 Go | 6,3 Go |
| `/Applications/Xcode.app` | 4,0 Go | inchangé |
| `~/Library/Developer` | 3,7 Go | 5,7 Go (−2,0 Go) |
| `~/.asdf` | 507 Mo | ~600 Mo |
| `~/.cache` | 300 Mo | 3,3 Go (−3,0 Go) |
| `~/.bun` | 58 Mo | 1,7 Go (−1,6 Go) |
| `~/.ollama` | 32 Ko | 16 Ko |

### Dérive vis-à-vis de `install-deps.sh`

Comparaison dans les deux sens entre ce que porte la machine et ce que le
script déclare. Ni Homebrew ni `clean-mac.sh` ne savent le faire, et
c'est pourtant ce qui décide si une reconstruction reproduirait l'état
actuel.

**Installé mais non déclaré** — une reconstruction les perdrait :
`azure-cli`, `supabase`, `ideviceinstaller`, `libimobiledevice`,
`libyaml`, `llmfit`, `opencode`, `poppler`, `postgresql@14`, plus les
casks `copilot-cli` et `fuse-t`.

**Déclaré mais absent** — le script promet ce qui n'est pas là :
`temurin` (Java), `mas`, `colima` et le CLI `docker`, `kind`, `kubeseal`.
Côté casks, `claude-code`, `stats`, `timing`, `zed` et `google-drive` ne
sont pas un manque mais l'autre face de l'item 11 : l'app est installée à
la main, donc Homebrew ne la voit pas. Le reste (`alfred`, `gitter`,
`goplaces`, `medis`, `raspberry-pi-imager`, `spotify`, `vlc`, et les
bases mysql/redis/mongodb/elasticsearch) est derrière des prompts
optionnels ou propre au Mac mini : absence normale.

## Audit & recommandations

Constats tirés de l'inventaire ci-dessus, classés par impact décroissant
à leur création. La numérotation est stable : elle est citée dans les
messages de commit, donc un item traité reste à sa place et un nouveau
constat s'ajoute à la fin.

### Où en est l'audit — mis à jour le 2026-09-01

**Soldés** : 3, 6, **12**, 13, **18**, **19**, **20**, **21** (à
`postgresql@14` près, renvoyé à l'item 15), **23**.
**Partiels, qui ont bougé** : 1, 9, **11** (six apps adoptées sur dix),
14, 15, 16.
**Toujours ouverts** : **2** (Docker, 67 Go — de loin le premier poste
du disque, intact depuis quatre relevés), **5** (cask fantôme `github`),
**7** (aider en double), 4, 10, 17, 22.
**Rouvert** : 8 (`brew outdated` était retombé à zéro, il remonte à 3).

Le relevé du 2026-08-29 n'avait rien exécuté de correctif — l'audit
constate, `clean-mac.sh` et `install-deps.sh` agissent. Les sessions
suivantes ont traité, sur demande explicite, les items 18 à 20 le
2026-08-31 (plus l'item 23 découvert au passage), puis 11, 12 et 21 le
2026-09-01.

**Ce qui attend une main humaine**, faute de mot de passe administrateur
dans une session non interactive :

```
brew install --cask --force cloudflare-warp google-drive logi-options+
```

1. ~~Disk is at 92% (37 GB free).~~ **Largement traité — 123 Gio libres
   (73 %) au 2026-08-29**, contre 101 Go (77 %) la veille et 37 Go à
   l'origine. Les ~22 Go regagnés depuis viennent de `~/.cache`
   (−3,0 Go), `~/.bun` (−1,6 Go) et `~/Library/Developer` (−2,0 Go), le
   reste étant du `brew cleanup` (−37 formules transitives). L'item 2
   (Docker, 67 Go) reste ouvert et pèse maintenant **plus de la moitié
   de l'espace encore récupérable**.
2. **Docker.raw fait toujours 67 Go — TOUJOURS PAS TRAITÉ.**
   Re-mesuré le 2026-08-29 : 128 Go apparent, 67 Go réel, strictement
   identique aux deux relevés précédents. Pruning containers/images is
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
4. ~~30 GB of `~/Library/Caches`.~~ **Partiel — descendu à 17 Go, et
   toujours 17 Go au 2026-08-29 : la seconde passe n'a pas eu lieu.**
   Elle porte sur les deux caches que le nettoyage standard n'atteint
   pas : les navigateurs téléchargés par Playwright
   (`npx playwright uninstall --all`) et le cache pip
   (`pip cache purge`).
5. ~~Six casks registered but their app is gone.~~ **Cinq sur six
   traités ; le sixième résiste.** `airtable`, `chatgpt`,
   `dbeaver-community`, `evernote` et `notion-mail` sont désinscrits —
   confirmé par la chute de 42 à 36 casks. **`github` (GitHub Desktop)
   est toujours enregistré sans app dans `/Applications`**, re-détecté
   automatiquement au relevé du 2026-08-29 ; à solder avec
   `brew uninstall --cask --force github`. Constat d'origine :
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

   ~~One leftover: **`~/.gem` (66 MB) still needs deleting**~~ —
   **fait : `~/.gem` n'existe plus au 2026-08-29.** L'item 6 est
   entièrement soldé.
7. **`aider` est toujours installé deux fois** — re-vérifié le
   2026-08-29 : la formule Homebrew `aider` *et* `uv tool aider-chat`
   v0.86.2 sont toutes deux présentes, inchangé. Détail d'origine :
   Homebrew formula
   (`/opt/homebrew/bin/aider`) *and* `uv tool aider-chat`
   (`~/.local/bin/aider`, v0.86.2). `~/.local/bin` comes first on
   `PATH`, so the uv copy wins and the Homebrew one just goes stale
   invisibly. Keep the `uv tool` install (it's the one aider upstream
   recommends) and run `brew uninstall aider`. **The `codex` duplicate
   resolved itself**: the npm global went with nvm, leaving only the
   Homebrew cask at `/opt/homebrew/bin/codex`.
8. ~~111 outdated formulae and 20 outdated casks.~~ **Traité le
   2026-08-28, et déjà en train de se reconstituer** : `brew outdated`
   affiche 3 casks en retard au 2026-08-29 (`codex`, `cursor`,
   `lm-studio`). C'est exactement ce que l'item annonçait — la cause
   n'ayant pas changé, le backlog remonte. Trois en un jour reste
   trivial à traiter (`brew upgrade`), mais confirme qu'il faut lui
   donner un créneau récurrent plutôt qu'une passe manuelle.
9. **Editor and terminal sprawl.** ~~Trois terminaux (Ghostty, WezTerm,
   Hyper)~~ — **Hyper a bien été désinstallé** (vérifié le 2026-08-29 :
   plus de `Hyper.app`, plus de cask), ce qui solde la moitié de l'item.
   **Reste la dérive `wezterm`** : le cask est installé alors que sa
   ligne d'install est commentée dans `install-deps.sh` — soit on
   décommente, soit on désinstalle, mais l'état actuel n'est reproductible
   par personne. Le reste du constat tient : neuf éditeurs/IDE (Cursor,
   VS Code, Zed, Sublime Text, Antigravity +
   WebStorm/PyCharm/RubyMine/DataGrip), ce qui est défendable sur un
   poste de travail. Les quatre IDE JetBrains pèsent 8,7 Go de caches
   Toolbox — Toolbox sait aussi conserver moins d'anciennes versions.
10. **AI-tool overlap is even wider here than on the Mac mini**: Claude,
    Claude Code, ChatGPT (×2 states), Codex (×2 installs), CodexBar,
    Copilot (App Store) + GitHub Copilot.app + `copilot-cli`, Cursor,
    Antigravity, LM Studio, Ollama, Fireflies, superwhisper, aider,
    opencode, mistral-vibe, llmfit. Worth one deliberate pass deciding
    which are actually in the daily loop; the ones that aren't are still
    running updaters and filling caches (copilot 616 MB, codexbar
    343 MB).

    *Re-vérifié le 2026-08-29 : inchangé, à un retrait près —
    `specify-cli` a disparu des `uv tool`. Tout le reste est toujours
    là, y compris `ChatGPT Classic.app` à côté du cask `chatgpt`
    désinscrit. Deux des trois casks en retard (`codex`, `lm-studio`)
    appartiennent à cette famille : ce sont des outils qu'on ne lance
    plus assez pour les tenir à jour, mais assez installés pour qu'ils
    se mettent à jour tout seuls.*
11. **Dix apps installées à la main alors qu'un cask existe** —
    **six adoptées le 2026-09-01, trois en attente, une abandonnée.**

    *Adoptées* (`brew install --cask --force`, bundle repris en place) :
    Stats, Timing, Microsoft Edge — versions strictement identiques,
    aucun changement fonctionnel — plus Antigravity (2.0.6 → 2.11.0),
    Zed (1.7.2 → 1.17.2) et Nanoleaf (2.3.5 → 2.5.0), que l'adoption
    met à jour au passage. Vérifié après coup : les six sont
    enregistrées dans `brew list --cask` et les apps sont en place aux
    versions attendues. Les casks passent de 36 à 42.

    *En attente* : Cloudflare WARP, Google Drive et Logi Options+.
    Leurs casks passent par un `.pkg` ou un installeur, donc réclament
    un mot de passe administrateur qu'une session non interactive ne
    peut pas fournir. À lancer à la main :
    `brew install --cask --force cloudflare-warp google-drive logi-options+`
    — prévoir une reconnexion au VPN et, pour Google Drive, un
    possible re-login avec ré-autorisation de l'accès disque complet.

    *Abandonnée — **Claude Code CLI doit sortir de cette liste***. Le
    cask `claude-code` ne pose pas une app mais un binaire `claude`
    dans `/opt/homebrew/bin`, en version 2.1.236, alors que le CLI
    installé vit dans `~/.local/bin/claude` en 2.1.252 — et
    `~/.local/bin` passe avant dans le `PATH`. L'adopter n'adopterait
    donc rien : ça ajouterait une seconde copie, plus ancienne, que
    rien n'appellerait et qui périmerait sans qu'on la voie. C'est
    exactement le défaut décrit à l'item 7 pour `aider`. Le constat
    d'origine se trompait en la rangeant avec les neuf autres.

    Les dix sont en revanche **déclarées dans `install-deps.sh`** :
    Antigravity, Microsoft Edge, Nanoleaf, Logi Options+ et Cloudflare
    WARP y ont été ajoutés (les cinq autres y étaient déjà), avec pour
    les deux derniers une note sur le mot de passe administrateur.

    Constat d'origine : La comparaison avec `install-deps.sh`
    le montre par l'autre bout : `stats`, `timing`, `zed`,
    `google-drive` et `claude-code` sont **déclarés dans le script et
    absents de Homebrew** — le script promet une install que la machine
    a déjà, mais par un autre chemin. Constat d'origine :
    **Ten apps installed by hand where a Homebrew cask exists**:
    Antigravity, Zed, Stats, Timing, Cloudflare WARP, Microsoft Edge,
    Google Drive, Nanoleaf Desktop, Logi Options+, Claude Code CLI.
    Same fix that was applied on the Mac mini:
    `brew install --cask --force <token>` adopts the existing bundle in
    place (no user data lost — that lives outside the app bundle), then
    add them to `install-deps.sh` so `brew upgrade` and `clean-mac.sh`
    cover them. Bonus: it retires the per-vendor auto-updater
    LaunchAgents from Google and Microsoft.
12. ~~**Toujours pas de `mas`.**~~ **Fait le 2026-09-01.** `mas` 7.0.0
    installé, et la liste codée en dur de `install-deps.sh` resynchronisée
    sur `mas list` : **17 déclarées, 17 installées, zéro écart dans les
    deux sens** (vérifié par comparaison des identifiants).

    Six entrées retirées, dont les apps ne sont plus installées :
    Enchanted, Messenger, MindNode 2, MindNode Classic, Speedtest,
    TypingLand. Les re-déclarer signifiait qu'une reconstruction
    réinstallerait en silence des apps délibérément supprimées — le
    piège même que l'item 5 décrit pour les casks fantômes. Cinq
    ajoutées : OneNote, Outlook, Word, MindNode Next (qui remplace les
    deux MindNode) et Xcode, ce dernier placé en fin de section parce
    qu'il pèse ~10 Go. Le bloc porte désormais la commande qui le
    régénère, pour que la prochaine resynchronisation ne se fasse pas à
    la main.

    *Correction au constat d'origine* : il rangeait ExcalidrawZ parmi
    les manquantes, alors qu'elle était déjà déclarée. Constat
    d'origine, pour le reste exact :
    the 17 App Store apps are invisible to Homebrew
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
    **Toujours ouvert, et pire que décrit** : `BUNDLER_EDITOR="atom"`
    est présent **dans deux fichiers**, `.zshrc:55` *et* `.exports:21`.
    Atom est arrêté depuis 2022, et maintenant qu'`EDITOR` vaut `vim`,
    ces deux lignes sont les dernières à le désigner encore. Le doublon
    illustre au passage la divergence bash/zsh que `tasks.md` veut
    résorber : la même variable, définie deux fois, dans deux chaînes de
    chargement différentes.
15. ~~**Deux majeures PostgreSQL installées (14 et 18), aucune ne
    tourne**, plus `unbound` et `cloudflared` au repos.~~ **Partiel :
    `unbound` a été désinstallé** (vérifié le 2026-08-29). Restent les
    deux PostgreSQL, toujours arrêtées, et `cloudflared`. Si la 14 n'est
    gardée que pour un vieux projet, dumper ce qu'il faut et la retirer :
    deux majeures, ce sont aussi deux répertoires de données. À noter,
    `postgresql@14` fait partie des paquets **installés sans être
    déclarés** dans `install-deps.sh`, qui ne connaît que la 18.
16. ~~**La chaîne iOS/mobile pèse ~10 Go.**~~ **Partiel — descendue à
    ~7,7 Go** (Xcode 4,0 Go inchangé, `~/Library/Developer` 3,7 Go
    contre 5,7 Go). Les 2,0 Go regagnés viennent de DerivedData et des
    runtimes de simulateur, c'est-à-dire du cache pur, exactement là où
    l'item disait d'aller chercher. Le reste de la méthode tient pour
    une seconde passe : `xcrun simctl delete unavailable` et vidage de
    DerivedData récupèrent l'essentiel sans toucher à la toolchain, qui
    est réellement utilisée (`ideviceinstaller`/`libimobiledevice` sont
    installés, et les builds N8Ninja le confirment).
17. **Correction à porter dans le document jumeau** — toujours à faire
    au 2026-08-29 : [audit-mac-mini.md](audit-mac-mini.md) ligne 88
    qualifie DDPM de « BenQ/Qisda monitor control ». C'est le *Dell
    Display and Peripheral Manager*, l'utilitaire du U4025QW, KVM
    compris.
18. ~~**La formule Homebrew `pyenv` 2.8.4 est toujours installée.**~~
    **Fait le 2026-08-31.** `brew uninstall pyenv` (7,6 Mo ; zéro
    dépendant, `~/.pyenv` déjà absent, aucune référence dans la config
    shell — les trois vérifiés avant la suppression). La faille de
    détection est bouchée dans la foulée : la section « legacy » de
    `clean-mac.sh` teste maintenant **la formule Homebrew en plus du
    répertoire**, pour les trois gestionnaires, et signale les
    dépendants au lieu de proposer une désinstallation à l'aveugle.
    Constat d'origine — alors que l'item 6 a retiré pyenv de la stack, que `~/.pyenv` n'existe
    plus, que `install-deps.sh` ne l'installe plus et que le README le
    déclare remplacé par `uv`. Le répertoire de données a été supprimé,
    le paquet non — c'est le cas de figure exact que la section « legacy »
    de `clean-mac.sh` est censée rattraper, sauf qu'elle teste
    l'existence de `~/.pyenv` et pas celle de la formule. Deux
    conséquences : `brew upgrade` continue de le maintenir, et il
    réapparaîtra dans tout inventaire comme un gestionnaire de versions
    concurrent d'asdf/uv. `brew uninstall pyenv` (rien n'en dépend), et
    tant qu'à faire, faire tester la formule à `clean-mac.sh` et pas
    seulement le répertoire.
19. ~~**`openssl@1.1` est toujours installé alors qu'il est EOL et que
    plus rien n'en dépend.**~~ **Fait le 2026-08-31.** À noter pour la
    postérité : la formule a été **désactivée dans homebrew-core le
    2024-11-11**, donc ce retrait est sans retour par `brew` — d'où les
    vérifications préalables, toutes négatives : zéro dépendant, et
    aucun binaire des Ruby d'asdf ni des Python d'uv ne liait
    `libssl.1.1` (`otool -L`). Après coup, Ruby 3.3.5 rapporte toujours
    OpenSSL 3.6.3 et le shell de login démarre proprement. Constat
    d'origine : `brew uses --installed openssl@1.1` ne
    renvoie rien, et l'item 6 avait explicitement conclu qu'il pouvait
    être retiré une fois Ruby rebâti contre `openssl@3` — ce qui a été
    fait le 2026-08-28, `.zshrc` et `install-deps.sh` pointant tous deux
    sur `openssl@3` depuis. Le retrait, lui, n'a jamais eu lieu.
    `brew uninstall openssl@1.1`. Garder une bibliothèque crypto EOL
    installée n'est pas neutre : elle reste sur le disque, elle se
    proposera comme cible de link à toute compilation future, et elle
    brouille la lecture de l'inventaire.
20. ~~**Aucun JDK n'est installé, et la config shell pointe sur un JDK
    fantôme.**~~ **Tranché et fait le 2026-08-31 : config morte
    supprimée, pas de JDK installé.** Les trois lignes de
    `.bash_profile` (`#JDK1.7` et son `JAVA_HOME` vers un
    `jdk-10.0.1` inexistant, plus l'ajout au `PATH`) sont retirées.
    Rien sur cette machine ne réclamait de JDK : aucune formule
    installée n'en dépend, et les IDE JetBrains embarquent leur propre
    runtime (JBR). `install-deps.sh` conserve sa section « Java
    (Temurin JDK) » derrière son prompt, donc un besoin futur reste à
    un `./install-deps.sh` de distance — et le jour venu, `JAVA_HOME`
    devra valoir `$(/usr/libexec/java_home)` plutôt qu'un chemin figé.
    Les lignes n'ont **pas** été laissées en commentaire, l'item 9
    montrant assez ce que devient une ligne commentée « pour plus
    tard ». Constat d'origine : `java` est le stub macOS, qui répond « Unable to locate a
    Java Runtime » ; `/Library/Java/JavaVirtualMachines/` est vide. Or
    `install-deps.sh` déclare `temurin` (section « Java (Temurin JDK) »),
    et surtout `.bash_profile:21` exporte
    `JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-10.0.1.jdk/Contents/Home/`
    — un chemin qui n'existe pas — puis l'ajoute au `PATH` à la ligne
    suivante. Java 10 est hors support depuis 2018. Deux issues, à
    trancher plutôt qu'à laisser en l'état : soit Java sert encore et il
    faut installer `temurin` puis pointer `JAVA_HOME` sur
    `$(/usr/libexec/java_home)`, soit il ne sert plus et ces deux lignes
    doivent disparaître de `.bash_profile`. À noter que ce `JAVA_HOME`
    n'existe que côté bash : c'est un exemple de plus de la divergence
    bash/zsh.
21. ~~**Onze paquets sont installés sans être déclarés dans
    `install-deps.sh`.**~~ **Dix déclarés le 2026-09-01 ; il en reste
    un, volontairement.** `libyaml` (bibliothèque de base), `poppler`
    (outils PDF), `azure-cli` et `supabase` (nouveaux prompts cloud),
    `libimobiledevice` + `ideviceinstaller` (nouveau prompt outillage
    iOS), `llmfit`, `opencode` et le cask `copilot-cli` (section IA),
    et le cask `fuse-t` (nouveau prompt, avec son tap). Les trois
    formules de tap sont déclarées en nom qualifié avec leur
    `brew tap`, et commentées pour rappeler qu'elles échappent aux
    inventaires agrégés (item 22).

    **`postgresql@14` est laissé de côté sciemment** : le déclarer
    contredirait l'item 15, qui recommande de s'en débarrasser. Sa
    résolution appartient à cet item-là, pas à celui-ci ; c'est
    désormais le seul écart de déclaration de la machine.

    Constat d'origine : : `azure-cli`, `supabase`, `ideviceinstaller`,
    `libimobiledevice`, `libyaml`, `llmfit`, `opencode`, `poppler`,
    `postgresql@14`, plus les casks `copilot-cli` et `fuse-t`. Une
    reconstruction de la machine à partir du dépôt ne les remettrait
    pas. C'est la dérive la moins visible de toutes — rien ne casse, rien
    ne prévient, et on ne s'en aperçoit que le jour où on repart d'un
    disque vide. Décider pour chacun : soit il compte, et il rejoint le
    script dans la bonne section (et derrière le bon rôle
    `--server`/`--workstation`), soit il ne compte pas, et il se
    désinstalle.
22. **Angle mort méthodologique : les formules de tap échappent aux
    inventaires de Homebrew.** `k9s`, `supabase`, `terraform` et `vault`
    sont installées et sur le `PATH`, mais n'apparaissent **ni** dans
    `brew list --installed-on-request`, **ni** dans
    `brew info --json=v2 --installed`. Le relevé du 2026-08-28 le
    signalait pour `brew leaves` en croyant `brew info` fiable ; il ne
    l'est pas. Conséquence directe : le premier relevé automatisé les a
    comptées comme désinstallées, et la comparaison avec
    `install-deps.sh` les aurait déclarées « déclarées mais absentes »
    alors qu'elles sont là. Le collecteur les récupère désormais par
    différence avec `brew list --formula`, seul inventaire qui les voie.
    À garder en tête pour toute vérification manuelle : `brew list
    --versions <formule>` dit la vérité, les inventaires agrégés non.
23. ~~**`ANDROID_HOME` pointe vers un SDK qui n'existe pas.**~~
    **Trouvé et corrigé le 2026-08-31**, en traitant l'item 20 : même
    classe de défaut, découvert en cherchant si Java servait encore.
    `.zshrc` exportait `ANDROID_HOME=~/Library/Android/sdk` — répertoire
    absent — puis ajoutait ses `tools` et `platform-tools` au `PATH`,
    soit deux entrées fantômes à chaque shell. Les deux lignes sont
    retirées. Vérifié dans un environnement vierge (`env -i`) : plus
    aucun chemin Android ni Java dans le `PATH` d'un shell de login,
    zsh comme bash. À noter pour les prochains audits : un `PATH`
    hérité ment sur ce point — la session en cours garde les anciennes
    entrées, seul un shell neuf dit la vérité.
