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
- Refacto et mise en commun entre bash et zsh de .aliasess, .profile, exports, .functions
- Backup existing dotfile first @configure_dotfiles.sh