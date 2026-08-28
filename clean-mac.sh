#!/bin/bash

# clean-mac.sh - Libere de l'espace disque en nettoyant les caches
# et fichiers temporaires des outils de dev installes via ce projet
# (Homebrew, Docker Desktop, JetBrains, Ollama, uv, bun), et propose
# la suppression complete des gestionnaires de version legacy
# (pyenv, nvm, rvm) remplaces par asdf/uv/bun.
#
# macOS uniquement (Homebrew, Library/, Docker Desktop, JetBrains,
# Xcode...). Pour les serveurs Linux (Raspberry Pi, Scaleway,
# conteneurs), voir la section dediee dans le README : ce script ne
# s'y applique pas.
#
# Le script detecte s'il tourne sur le Mac mini (role "server", plus
# un poste de dev mais un serveur local/distant headless) ou sur le
# MacBook Pro (role "workstation") via le hostname, et adapte le ton
# des recommandations sur les outils legacy et GUI en consequence.
#
# Chaque section explique ce qui va etre supprime avant de demander
# une confirmation. Rien n'est supprime sans validation explicite.
#
# Options:
#   -y, --yes         repond "oui" a toutes les questions automatiquement
#       --dry-run     affiche ce qui serait fait sans rien supprimer
#       --server      force le role "serveur" (recommandations Mac mini)
#       --workstation force le role "poste de dev" (recommandations MacBook Pro)
#   -h, --help        affiche cette aide

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/dotfiles-lib.sh"

AUTO_YES=false
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    -y|--yes) AUTO_YES=true ;;
    --dry-run) DRY_RUN=true ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
  esac
done

# Detecte le role de la machine (--server/--workstation, MACHINE_ROLE,
# ou hostname) : le Mac mini de ce setup sert de serveur local/distant
# (plus un poste de dev pur), le MacBook Pro reste le poste de dev.
detect_machine_role "$@"

TOTAL_FREED_KB=0

ask_to_clean() {
  local description=$1
  if ask "Nettoyer $description ?"; then
    return 0
  fi
  skipped "$description"
  return 1
}

run() {
  if $DRY_RUN; then
    echo "${DIM}  [dry-run] $*${RESET}"
  else
    "$@"
  fi
}

dir_size_kb() {
  du -sk "$1" 2>/dev/null | awk '{s+=$1} END {print s+0}'
}

kb_to_human() {
  awk -v kb="$1" 'BEGIN {
    if (kb >= 1048576) printf "%.2f Go", kb/1048576;
    else if (kb >= 1024) printf "%.2f Mo", kb/1024;
    else printf "%d Ko", kb;
  }'
}

report_freed() {
  local label=$1 before_kb=$2 path=$3
  local after_kb
  after_kb=$(dir_size_kb "$path")
  local freed=$((before_kb - after_kb))
  [ "$freed" -lt 0 ] && freed=0
  TOTAL_FREED_KB=$((TOTAL_FREED_KB + freed))
  echo "${GREEN}✔${RESET} $label : $(kb_to_human "$freed") libérés"
}

echo "${BOLD}Nettoyage de l'espace disque - Mac dev setup${RESET}"
$DRY_RUN && echo "${YELLOW}Mode dry-run : rien ne sera réellement supprimé.${RESET}"
echo "Chaque section explique ce qui va être nettoyé et demande confirmation avant d'agir."
if [ "$MACHINE_ROLE" = "server" ]; then
  explain "Rôle détecté : ${BOLD}serveur${RESET}${CYAN} (Mac mini) — ce Mac n'est plus un poste de dev pur mais un serveur local/distant headless. Les recommandations sur les outils legacy et GUI sont plus tranchées.${RESET}"
else
  explain "Rôle détecté : ${BOLD}poste de dev${RESET}${CYAN} (MacBook Pro) — nettoyage plus prudent, les IDE et outils GUI restent utiles au quotidien.${RESET}"
fi
explain "Force le rôle avec --server / --workstation si la détection par hostname se trompe."

DISK_FREE_BEFORE=$(df -h / | awk 'NR==2 {print $4}')

# ------------------------------------------------------------------
# Homebrew
# ------------------------------------------------------------------
section "Homebrew"
if have_cmd brew; then
  CACHE_DIR=$(brew --cache 2>/dev/null)
  explain "Homebrew garde en cache les anciennes versions de formules/casks et leurs archives de téléchargement dans $CACHE_DIR."
  explain "Ces fichiers ne servent qu'à réinstaller une ancienne version ou éviter un re-téléchargement ; les supprimer n'affecte pas les logiciels installés."
  echo "Taille actuelle du cache : $(kb_to_human "$(dir_size_kb "$CACHE_DIR")")"
  if ask_to_clean "les anciennes versions et le cache de téléchargement Homebrew (brew cleanup)"; then
    before=$(dir_size_kb "$CACHE_DIR")
    run brew cleanup -s --prune=all
    report_freed "Homebrew cleanup" "$before" "$CACHE_DIR"
  fi

  explain "brew autoremove supprime les dépendances qui ne sont plus utilisées par aucun package installé."
  if ask_to_clean "les dépendances Homebrew orphelines (brew autoremove)"; then
    run brew autoremove
  fi
else
  skipped "Homebrew n'est pas installé"
fi

# ------------------------------------------------------------------
# Docker Desktop
# ------------------------------------------------------------------
section "Docker Desktop"
if have_cmd docker; then
  if docker info >/dev/null 2>&1; then
    echo "Espace utilisé par Docker actuellement :"
    docker system df

    explain "docker system prune supprime les conteneurs arrêtés, les réseaux inutilisés et les images 'dangling' (sans tag, non utilisées). C'est sans risque : rien de ce qui tourne actuellement n'est touché."
    if ask_to_clean "les conteneurs arrêtés, réseaux et images inutilisées (docker system prune)"; then
      run docker system prune -f
    fi

    explain "Option plus agressive : supprime en plus TOUTES les images non utilisées par un conteneur actif et TOUS les volumes non attachés. Cela peut supprimer des données stockées dans des volumes non montés (bases de données arrêtées, etc.)."
    if ask_to_clean "TOUTES les images et volumes Docker inutilisés (docker system prune -a --volumes) — plus risqué"; then
      run docker system prune -af --volumes
    fi

    explain "Le cache de build Docker (BuildKit) accumule des couches intermédiaires de vos builds. Le vider n'affecte pas les images déjà construites, seulement la vitesse des prochains builds."
    if ask_to_clean "le cache de build Docker (docker builder prune)"; then
      run docker builder prune -af
    fi
  else
    warn "Docker Desktop n'est pas démarré. Lance l'application puis relance ce script pour nettoyer son cache."
  fi
else
  skipped "Docker n'est pas installé"
fi

# ------------------------------------------------------------------
# JetBrains (WebStorm, PyCharm, DataGrip, RubyMine, Toolbox...)
# ------------------------------------------------------------------
section "JetBrains (IDEs + Toolbox)"
JB_CACHES="$HOME/Library/Caches/JetBrains"
JB_LOGS="$HOME/Library/Logs/JetBrains"

if [ -d "$JB_CACHES" ] || [ -d "$JB_LOGS" ]; then
  explain "Chaque IDE JetBrains (WebStorm, PyCharm, DataGrip, RubyMine...) garde un cache d'indexation dans ~/Library/Caches/JetBrains. Il est régénéré automatiquement à la réouverture du projet (réindexation, un peu plus lent au premier lancement)."
  if [ -d "$JB_CACHES" ]; then
    echo "Taille actuelle : $(kb_to_human "$(dir_size_kb "$JB_CACHES")")"
    if ask_to_clean "le cache d'indexation des IDEs JetBrains (~/Library/Caches/JetBrains)"; then
      before=$(dir_size_kb "$JB_CACHES")
      run rm -rf "${JB_CACHES:?}"/*
      report_freed "Cache JetBrains" "$before" "$JB_CACHES"
    fi
  fi

  explain "Les logs des IDEs (~/Library/Logs/JetBrains) ne sont utiles qu'en cas de bug report, sans impact sur le fonctionnement."
  if [ -d "$JB_LOGS" ]; then
    echo "Taille actuelle : $(kb_to_human "$(dir_size_kb "$JB_LOGS")")"
    if ask_to_clean "les logs des IDEs JetBrains (~/Library/Logs/JetBrains)"; then
      before=$(dir_size_kb "$JB_LOGS")
      run rm -rf "${JB_LOGS:?}"/*
      report_freed "Logs JetBrains" "$before" "$JB_LOGS"
    fi
  fi

  TOOLBOX_APPS="$HOME/Library/Application Support/JetBrains/Toolbox/apps"
  if [ -d "$TOOLBOX_APPS" ]; then
    explain "JetBrains Toolbox conserve parfois plusieurs versions installées de chaque IDE (rollback). Dossier : $TOOLBOX_APPS ($(kb_to_human "$(dir_size_kb "$TOOLBOX_APPS")"))."
    explain "Ce script ne supprime pas ces versions automatiquement (risque de casser l'IDE actif). Ouvre JetBrains Toolbox > Settings > 'Shelf life of unused instances' pour limiter le nombre de versions gardées, ou désinstalle manuellement les anciennes versions IDE par IDE."
  fi
else
  skipped "aucune installation JetBrains détectée"
fi

# ------------------------------------------------------------------
# Ollama
# ------------------------------------------------------------------
section "Ollama"
if have_cmd ollama; then
  explain "Les modèles Ollama téléchargés (souvent plusieurs Go chacun) sont stockés dans ~/.ollama/models. Un modèle supprimé devra être re-téléchargé pour être réutilisé (ollama pull)."
  MODEL_LIST=$(ollama list 2>/dev/null | tail -n +2)
  if [ -z "$MODEL_LIST" ]; then
    skipped "aucun modèle Ollama installé"
  else
    echo "Modèles installés :"
    echo "$MODEL_LIST"
    echo ""
    echo "$MODEL_LIST" | while IFS= read -r line; do
      name=$(echo "$line" | awk '{print $1}')
      size=$(echo "$line" | awk '{print $3, $4}')
      [ -z "$name" ] && continue
      if ask_to_clean "le modèle Ollama '$name' ($size)"; then
        run ollama rm "$name"
      fi
    done
  fi

  explain "Les logs Ollama (~/.ollama/logs) ne sont utiles qu'en cas de débogage."
  OLLAMA_LOGS="$HOME/.ollama/logs"
  if [ -d "$OLLAMA_LOGS" ]; then
    echo "Taille actuelle : $(kb_to_human "$(dir_size_kb "$OLLAMA_LOGS")")"
    if ask_to_clean "les logs Ollama (~/.ollama/logs)"; then
      before=$(dir_size_kb "$OLLAMA_LOGS")
      run rm -rf "${OLLAMA_LOGS:?}"/*
      report_freed "Logs Ollama" "$before" "$OLLAMA_LOGS"
    fi
  fi
else
  skipped "Ollama n'est pas installé"
fi

# ------------------------------------------------------------------
# uv
# ------------------------------------------------------------------
section "uv (package manager Python)"
if have_cmd uv; then
  UV_CACHE_DIR=$(uv cache dir 2>/dev/null)
  explain "uv garde en cache les wheels/sdists Python téléchargés dans $UV_CACHE_DIR pour accélérer les futures installations. Les supprimer n'affecte aucun environnement déjà créé, juste la vitesse des prochains 'uv sync/install' (re-téléchargement)."
  echo "Taille actuelle : $(kb_to_human "$(dir_size_kb "$UV_CACHE_DIR")")"
  if ask_to_clean "le cache uv (uv cache clean)"; then
    before=$(dir_size_kb "$UV_CACHE_DIR")
    run uv cache clean
    report_freed "Cache uv" "$before" "$UV_CACHE_DIR"
  fi
else
  skipped "uv n'est pas installé"
fi

# ------------------------------------------------------------------
# bun
# ------------------------------------------------------------------
section "bun"
if have_cmd bun; then
  BUN_CACHE_DIR="$HOME/.bun/install/cache"
  explain "bun garde en cache les packages npm téléchargés dans $BUN_CACHE_DIR pour accélérer les futurs 'bun install'. Les supprimer n'affecte aucun projet déjà installé, juste la vitesse de la prochaine installation."
  echo "Taille actuelle : $(kb_to_human "$(dir_size_kb "$BUN_CACHE_DIR")")"
  if ask_to_clean "le cache bun ($BUN_CACHE_DIR)"; then
    before=$(dir_size_kb "$BUN_CACHE_DIR")
    # 'bun pm cache rm' exige un package.json dans le dossier courant,
    # on supprime donc directement le contenu du dossier de cache.
    run rm -rf "${BUN_CACHE_DIR:?}"/*
    report_freed "Cache bun" "$before" "$BUN_CACHE_DIR"
  fi
else
  skipped "bun n'est pas installé"
fi

# ------------------------------------------------------------------
# Gestionnaires de version legacy (pyenv, nvm, rvm)
# ------------------------------------------------------------------
section "Gestionnaires de version legacy (pyenv, nvm, rvm)"
explain "Ce setup utilise asdf (Ruby, Node...), uv (Python) et bun (JS/TS) comme gestionnaires de version/paquets principaux. pyenv, nvm et rvm faisaient le même travail avant et ne devraient plus être installés en double."
if [ "$MACHINE_ROLE" = "server" ]; then
  explain "Rôle serveur : ces outils historiques n'ont plus de raison d'être sur cette machine, suppression complète recommandée (pas juste le cache)."
else
  explain "Rôle poste de dev : vérifie d'abord qu'aucun vieux projet/rc file ne les référence encore avant de les supprimer complètement."
fi

for entry in "pyenv|$HOME/.pyenv|remplacé par uv (uv python install / uv venv)" \
             "nvm|$HOME/.nvm|remplacé par asdf (plugin nodejs) ou bun" \
             "rvm|$HOME/.rvm|remplacé par asdf (plugin ruby)"; do
  IFS="|" read -r name dir reason <<< "$entry"
  if [ -d "$dir" ]; then
    size=$(kb_to_human "$(dir_size_kb "$dir")")
    warn "$name détecté ($dir, $size) — $reason"
    if have_cmd "$name"; then
      warn "$name est encore actif dans ce shell (trouvé dans le PATH) — vérifie tes fichiers .zshrc/.bash_profile avant de supprimer."
    fi
    if ask_to_clean "la suppression complète de $name ($dir, $size) — désinstallation, pas juste le cache"; then
      before=$(dir_size_kb "$dir")
      run rm -rf "${dir:?}"
      report_freed "$name (suppression complète)" "$before" "$dir"
      warn "Pense à retirer les lignes d'initialisation de $name de tes fichiers shell (.zshrc/.bash_profile) si elles y sont encore."
    fi
  else
    skipped "$name n'est pas installé ($dir introuvable)"
  fi
done

# ------------------------------------------------------------------
# Bonus : autres caches de dev courants sur ce setup
# ------------------------------------------------------------------
section "Bonus : autres caches de dev (npm, pnpm, pip, Xcode)"

if have_cmd npm; then
  explain "npm garde un cache de packages téléchargés (~/.npm). Sans risque : sera reconstitué au besoin."
  NPM_CACHE_DIR="$HOME/.npm"
  if [ -d "$NPM_CACHE_DIR" ]; then
    echo "Taille actuelle : $(kb_to_human "$(dir_size_kb "$NPM_CACHE_DIR")")"
    if ask_to_clean "le cache npm (npm cache clean --force)"; then
      before=$(dir_size_kb "$NPM_CACHE_DIR")
      run npm cache clean --force
      report_freed "Cache npm" "$before" "$NPM_CACHE_DIR"
    fi
  fi
fi

if have_cmd pnpm; then
  explain "pnpm garde un store global de packages partagés entre projets. 'pnpm store prune' ne supprime que les paquets qui ne sont référencés par aucun projet existant sur la machine."
  if ask_to_clean "le store pnpm inutilisé (pnpm store prune)"; then
    run pnpm store prune
  fi
fi

if have_cmd pip || have_cmd pip3; then
  PIP_CACHE_DIR="$HOME/Library/Caches/pip"
  if [ -d "$PIP_CACHE_DIR" ]; then
    explain "pip garde en cache les wheels téléchargés (~/Library/Caches/pip). Sans risque : sera reconstitué au besoin."
    echo "Taille actuelle : $(kb_to_human "$(dir_size_kb "$PIP_CACHE_DIR")")"
    if ask_to_clean "le cache pip (pip cache purge)"; then
      before=$(dir_size_kb "$PIP_CACHE_DIR")
      run pip cache purge
      report_freed "Cache pip" "$before" "$PIP_CACHE_DIR"
    fi
  fi
fi

XCODE_DD="$HOME/Library/Developer/Xcode/DerivedData"
if [ -d "$XCODE_DD" ]; then
  explain "Xcode DerivedData contient les artefacts de build (~/Library/Developer/Xcode/DerivedData). Se régénère automatiquement au prochain build, sans perte."
  echo "Taille actuelle : $(kb_to_human "$(dir_size_kb "$XCODE_DD")")"
  if ask_to_clean "Xcode DerivedData"; then
    before=$(dir_size_kb "$XCODE_DD")
    run rm -rf "${XCODE_DD:?}"/*
    report_freed "Xcode DerivedData" "$before" "$XCODE_DD"
  fi
fi

# ------------------------------------------------------------------
# Résumé
# ------------------------------------------------------------------
section "Résumé"
DISK_FREE_AFTER=$(df -h / | awk 'NR==2 {print $4}')
echo "Espace libre estimé libéré (basé sur les tailles avant/après) : ${GREEN}$(kb_to_human "$TOTAL_FREED_KB")${RESET}"
echo "Espace disque libre sur / avant : $DISK_FREE_BEFORE"
echo "Espace disque libre sur / après : $DISK_FREE_AFTER"
$DRY_RUN && echo "${YELLOW}Rappel : mode dry-run, aucune suppression n'a été effectuée.${RESET}"
echo "${BOLD}Nettoyage terminé.${RESET}"
