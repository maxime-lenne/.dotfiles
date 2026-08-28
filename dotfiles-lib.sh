#!/bin/bash

# dotfiles-lib.sh - Helpers shared between clean-mac.sh and
# install-deps.sh: machine role detection (--server/--workstation),
# colored output helpers, and the yes/no prompt pattern.
#
# Meant to be sourced, not executed directly:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "$SCRIPT_DIR/dotfiles-lib.sh"

# --- Colors (disabled when stdout isn't a terminal) ---
if [ -t 1 ]; then
  BOLD=$(tput bold); DIM=$(tput dim); RESET=$(tput sgr0)
  GREEN=$(tput setaf 2); YELLOW=$(tput setaf 3); CYAN=$(tput setaf 6)
else
  BOLD=""; DIM=""; RESET=""; GREEN=""; YELLOW=""; CYAN=""
fi

have_cmd() { command -v "$1" >/dev/null 2>&1; }

section() {
  echo ""
  echo "${BOLD}------------------------------${RESET}"
  echo "${BOLD}$1${RESET}"
  echo "${BOLD}------------------------------${RESET}"
}

explain() {
  echo "${CYAN}ℹ${RESET}  $1"
}

warn() {
  echo "${YELLOW}⚠${RESET}  $1"
}

skipped() {
  echo "${DIM}-  ignoré : $1${RESET}"
}

# Ask a yes/no question, auto-answering "yes" if AUTO_YES=true.
# Usage: ask "Nettoyer X ?" && do_the_thing
ask() {
  local prompt=$1
  if [ "${AUTO_YES:-false}" = true ]; then
    echo "${GREEN}→ (auto) $prompt${RESET}"
    return 0
  fi
  local choice
  read -r -p "${BOLD}$prompt (y/n): ${RESET}" choice
  case "$choice" in
    y|Y) return 0 ;;
    *) return 1 ;;
  esac
}

# Detects the machine role (server = Mac mini / headless server,
# workstation = MacBook Pro / dev machine) from --server/--workstation
# flags, the MACHINE_ROLE env var, or the hostname as a last resort.
# Sets the global MACHINE_ROLE variable. Does not consume "$@": callers
# still parse their own remaining flags separately.
detect_machine_role() {
  MACHINE_ROLE="${MACHINE_ROLE:-}"
  local arg
  for arg in "$@"; do
    case "$arg" in
      --server) MACHINE_ROLE="server" ;;
      --workstation) MACHINE_ROLE="workstation" ;;
    esac
  done
  if [ -z "$MACHINE_ROLE" ]; then
    case "$(hostname | tr '[:upper:]' '[:lower:]')" in
      *mac-mini*|*macmini*|*"mac mini"*) MACHINE_ROLE="server" ;;
      *) MACHINE_ROLE="workstation" ;;
    esac
  fi
}
