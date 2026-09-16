- Dans le dossier .claude que puis je mettre en commun entre plusieurs mac ?

Excellente question pour synchroniser tes configs entre Macs ! Voici ce que tu peux/dois partager :
✅ À synchroniser (via iCloud/Dropbox/Git)
.claude.json - Configuration MCPs
json{
"mcpServers": {
"filesystem": { "command": "npx", ... },
"n8n-mcp": { ... }
}
}
⚠️ Attention : Utilise des variables d'environnement pour les chemins/secrets spécifiques à chaque machine
styles/ - Tes styles d'écriture personnalisés

Partageable sans problème
Identiques sur tous tes Macs

prompts/ - Prompts custom (si tu en crées)

Parfaitement portables

❌ À NE PAS synchroniser
logs/ - Logs spécifiques à chaque machine

Contenu différent par machine
Peut causer des conflits

Données de cache/session (si présentes)

Spécifiques à l'instance locale

🎯 Stratégie recommandée pour toi
Option 1 : Git (ma préférence)
bashcd ~/.claude
git init
echo "logs/" >> .gitignore
git add .
git commit -m "Initial config"
git remote add origin <ton-repo-privé>
Option 2 : Symlink vers iCloud
bash# Sur chaque Mac
mv ~/.claude ~/Library/Mobile\ Documents/com~apple~CloudDocs/.claude
ln -s ~/Library/Mobile\ Documents/com~apple~CloudDocs/.claude ~/.claude
Option 3 : Variables d'environnement pour les différences
json// .claude.json identique partout
{
"mcpServers": {
"n8n-mcp": {
"env": {
"N8N_API_URL": "${N8N_URL}",  // Défini dans ~/.zshrc sur chaque Mac
"N8N_API_KEY": "${N8N_KEY}"
}
}
}
}
Vu que tu as un Mac mini M4 Pro et probablement un MacBook, je te conseille Git + variables d'env pour garder la flexibilité tout en versionnant ta config.
Tu veux que je t'aide à mettre ça en place ?

- [x] Ajout de l'export des variables d'env nécessaire au programe — fait le
  2026-09-04. Config non sensible dans `.exports` (section « Application
  environment »), secrets dans `.env` à la racine du dépôt — gitignoré, seul
  dotfile jamais versionné — symlinké en `~/.env.local` par
  `configure_dotfiles.sh` et chargé en dernier par `.exports`.
  `.env.example` versionné documente les clés.
  `.zshrc` source désormais `.exports` (fin de la dérive EDITOR /
  BUNDLER_EDITOR). `~/.extra`, cité partout mais sourcé nulle part, est
  remplacé par `~/.env.local`. Voir README « Environment variables &
  secrets ». Limite connue : portée shell uniquement — une app GUI lancée
  depuis le Dock hérite de launchd, pas de `.zshrc`.
- [x] Refacto et mise en commun entre bash et zsh de .aliasess, .profile,
  exports, .functions — fait le 2026-09-15. `.aliases`, `.exports`,
  `.functions` et `.bash_prompt` ont quitté `$HOME` pour `shell/`, chargés
  dans un ordre unique par `shell/index.sh` (lui-même sourcé par `.zshrc`
  et `.bashrc`) : `path` → `exports` → `aliases` → `functions` →
  `role-$MACHINE_ROLE` → `~/.env.local`. zsh ne saute plus `.functions`, ni
  ne charge `.aliases` deux fois ; `EDITOR`/`BUNDLER_EDITOR`/`GPG_TTY`
  n'existent plus qu'à un seul endroit. Voir la spec
  `docs/superpowers/specs/2026-09-15-shell-config-unification-design.md`
  et le plan `docs/superpowers/plans/2026-09-15-shell-config-unification.md`.
- [x] Backup existing dotfile first @configure_dotfiles.sh — fait le
  2026-09-15 (même plan que ci-dessus, tâche 10) : le `mv` inconditionnel
  est remplacé par un backup horodaté uniquement quand la cible existe
  réellement, et un lien déjà correct ne déclenche plus de backup — le
  script est désormais idempotent.
- Dérive Ruby : `install-deps.sh` installe `bundler`, `rails`, `jekyll` et
  `colorls`, mais seuls `bundler` et `jekyll` sont présents dans le Ruby
  3.3.5 d'asdf (constaté le 2026-09-15). Conséquence visible : `rails` hors
  d'un projet tombe sur `/usr/bin/rails`, le stub Apple en `#!/usr/bin/ruby`,
  et l'alias `lc` reste inactif. Relancer la section Ruby d'`install-deps.sh`
  puis `asdf reshim ruby`.

- `~/.zprofile` n'est pas géré par ce dépôt et modifie quand même le `PATH` :
  il ajoute `~/.docker/bin` (Docker Desktop) et, ligne 9, un second
  `/usr/local/bin` que `path_helper` avait déjà mis — seul doublon de `PATH`
  qui subsiste après le refacto du 2026-09-15 (il y en avait 12 avant).
  Comme zsh lit `.zprofile` avant `.zshrc`, `shell/path.sh` ne peut pas
  l'empêcher. Décider : soit l'absorber dans le dépôt et le symlinker comme
  les autres, soit le vider puisque `shell/role-workstation.sh` gère déjà
  `~/.docker/bin`. Constaté le 2026-09-16.

- Config MCP à versionner et à partager entre le MacBook et le Mac mini.
  État relevé le 2026-09-16, décision reportée. Ce qui est vérifié :
  - Le scope *user* vit dans `~/.claude.json` — 161 Ko d'état de session
    (`projects`, caches, onboarding) avec une clé `mcpServers` dedans.
    Donc pas symlinkable comme les autres dotfiles : on ne peut versionner
    que les serveurs, pas le fichier.
  - Un `.mcp.json` à la racine d'un dépôt est *project-scoped* : il ne
    vaudrait que quand on travaille dans ce dépôt-là, pas partout. Ce
    n'est pas la cible pour une config commune aux deux machines.
  - Trois serveurs déclarés : `github` (HTTP, PAT dans un header
    `Authorization` → le seul cas « secret » ; sorti en
    `${GITHUB_MCP_TOKEN}` dans `.env` le 2026-09-16), `pencil` (binaire sous
    `/Applications/Pencil.app` → workstation uniquement, le rôle server
    saute les GUI) et `MCP_DOCKER` (`docker mcp gateway run`, en échec
    `CONNECTION_CLOSED` ce jour-là).
  - L'expansion de `${VAR}` marche aussi en scope user, pas seulement
    dans les `.mcp.json` : `~/.claude.json` stocke la chaîne telle quelle
    (`claude mcp add-json` n'expanse rien à l'écriture) et Claude Code la
    résout à la connexion, depuis l'environnement du processus qui le
    lance. Vérifié le 2026-09-16 sur le header du serveur `github` : une
    valeur bidon récolte un 401, la bonne connecte. Donc pas besoin
    d'`envsubst` au provisioning — mais même réserve launchd que pour
    Airmail : un `claude` lancé depuis une app GUI n'hérite pas du shell
    et ne verra pas la variable.
  - `claude` 2.1.273 expose `--mcp-config <fichiers>` et
    `--strict-mcp-config`.
  Décider entre trois mécanismes :
  1. Sync au provisioning : le dépôt porte `mcp/servers.json` avec les
     `${VAR}`, un script idempotent appelé par `configure_dotfiles.sh`
     l'expanse et le pousse via `claude mcp add-json -s user`, en sautant
     `pencil` sur le serveur. Couvre tous les points d'entrée (CLI,
     extension IDE, app desktop), aucun alias. Push unidirectionnel : un
     `claude mcp add` fait à la main dérive jusqu'au prochain run.
  2. `--mcp-config` + fonction shell autour de `claude` : le fichier du
     dépôt est la config, rotation de token sans re-run. Mais ne couvre
     que les shells qui chargent nos alias, et fusionne avec les serveurs
     user déjà en place (doublons à nettoyer d'abord).
  3. Versionner `mcp/servers.json` en simple référence + une commande
     dans le README, synchro manuelle.
  Dans tous les cas : `.ai/mcp/mcp.json` (vide, non suivi, créé le
  2026-09-02, lu par rien) est un vestige à supprimer ou à remplacer.
  Fait à part le 2026-09-16, sans attendre la décision ci-dessus : le PAT
  github est passé de `~/.claude.json` (en clair) à `.env`, et
  `.env.example` documente la clé.

- Le point faible qui reste n'est pas une fuite, c'est l'absence de garde-fou. .env vit à la racine d'un dépôt git publié, et .gitignore:17 est la seule chose qui l'en empêche — c'est écrit noir sur blanc dans tes propres commentaires. Or :

  - hooks/pre-commit ne fait que du shellcheck, aucun scan de secret : un git add -f .env, ou un token collé à la main dans shell/exports.sh, passerait sans broncher ;
  - .claude/hooks/no-plaintext-secrets.sh couvre bien ce cas, mais seulement quand c'est moi qui écris — pas tes éditions manuelles, pas git.

  Tu as déjà la regex écrite dans le hook Claude ; l'étendre au contenu stagé dans hooks/pre-commit fermerait les deux trous d'un coup. Je peux le faire si tu veux.