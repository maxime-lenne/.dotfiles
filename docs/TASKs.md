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
- Trou dans la regex de `.claude/hooks/no-plaintext-secrets.sh` (constaté
  le 2026-09-15, en vérifiant le correctif du chemin `shell/*.sh`) : le nom
  de variable doit avoir au moins un caractère avant le mot-clé — `export
  API_KEY="..."` ou `export TOKEN="..."` seuls ne matchent pas
  `[A-Za-z_][A-Za-z0-9_]*(TOKEN|...|API_?KEY|...)`, faute de caractère
  disponible pour le groupe précédent, alors que `MY_API_KEY` ou `GH_TOKEN`
  sont bien détectés. Pas corrigé dans ce lot (hors du périmètre demandé) ;
  un correctif possible est de rendre le préfixe optionnel
  (`[A-Za-z0-9_]*` au lieu de `[A-Za-z_][A-Za-z0-9_]*`).