# shellcheck shell=bash
# shell/index.sh — the one file that decides what a shell loads, and in
# which order. Sourced by both .zshrc and .bashrc.
#
# It exists because those two used to each source their own subset: zsh
# pulled .aliases twice and .functions never, bash pulled all three, and
# GPG_TTY, the asdf shims and the terraform completion were declared in
# both with no one keeping them in step. Add a fragment HERE, once.
#
# Constraint: bash 3.2 and zsh both read this file. No arrays (0-indexed in
# bash, 1-indexed in zsh), no [[ ]], no bashisms, no zshisms.

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"

if [ ! -d "$DOTFILES/shell" ]; then
  echo "dotfiles: $DOTFILES/shell not found — shell configuration not loaded" >&2
  return 0
fi

# Machine role. Same rule as detect_machine_role() in dotfiles-lib.sh, and
# deliberately NOT sourced from it: that file runs tput at load time and
# drops BOLD/GREEN/RESET (a direct collision with shell/bash-prompt.sh)
# plus section/explain/warn/ask into the interactive namespace. The two
# copies must be kept in step — dotfiles-lib.sh carries the matching note.
if [ -z "${MACHINE_ROLE:-}" ]; then
  case "$(hostname | tr '[:upper:]' '[:lower:]')" in
    *mac-mini*|*macmini*|*"mac mini"*) MACHINE_ROLE="server" ;;
    *) MACHINE_ROLE="workstation" ;;
  esac
fi
export MACHINE_ROLE

# Order matters: path first so everything below can find its binaries,
# role last so a machine can override the shared defaults.
for _dotfiles_fragment in path exports aliases functions "role-$MACHINE_ROLE"; do
  if [ -r "$DOTFILES/shell/$_dotfiles_fragment.sh" ]; then
    # shellcheck source=shell/path.sh
    . "$DOTFILES/shell/$_dotfiles_fragment.sh"
  fi
done
unset _dotfiles_fragment

# Machine-local secrets, LAST so they override anything declared above —
# including the role fragment. Moved here from the end of .exports on
# 2026-09-15: left there, the role fragment loaded afterwards and silently
# broke that guarantee.
#
# ~/.env.local is a symlink to .env at the root of this repo, which
# .gitignore keeps out of every commit. configure_dotfiles.sh seeds it from
# .env.example and links it.
if [ -r "$HOME/.env.local" ]; then
  # shellcheck source=/dev/null
  . "$HOME/.env.local"
fi
