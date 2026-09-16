ZSH=$HOME/.oh-my-zsh
ZSH_CUSTOM="${DOTFILES:-$HOME/.dotfiles}/custom"

# You can change the theme with another one:
#   https://github.com/robbyrussell/oh-my-zsh/wiki/themes
ZSH_THEME="baboriginal"

plugins=(gitfast last-working-dir common-aliases sublime zsh-syntax-highlighting history-substring-search elixir aterminal history zsh-autosuggestions)

# oh-my-zsh FIRST, so that everything shell/ declares below wins over the
# plugin defaults rather than the other way round.
source "${ZSH}/oh-my-zsh.sh"

# Everything shared with bash: PATH, exports, aliases, functions, the role
# fragment and ~/.env.local. See shell/index.sh for the order.
. "${DOTFILES:-$HOME/.dotfiles}/shell/index.sh"

# AFTER index.sh: undoes the interactive `rm -i` that oh-my-zsh's
# common-aliases plugin installs. Run any earlier and the plugin would just
# put it back.
unalias rm 2>/dev/null

# zsh equivalents of the bash-only HISTCONTROL/HISTIGNORE set in
# shell/exports.sh, so history behaves the same in both shells.
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# --- Completions (zsh-specific; the bash halves live in .bashrc) ---

if command -v brew >/dev/null 2>&1; then
  fpath=("$(brew --prefix asdf)/share/zsh/site-functions" $fpath)
fi

# Docker Desktop's completions, workstation only — the Mac mini runs colima.
if [ "${MACHINE_ROLE:-}" = "workstation" ] && [ -d "$HOME/.docker/completions" ]; then
  fpath=("$HOME/.docker/completions" $fpath)
fi

autoload -Uz compinit
compinit

# terraform ships a bash-style completion; bashcompinit adapts it.
if command -v terraform >/dev/null 2>&1; then
  autoload -U +X bashcompinit && bashcompinit
  complete -o nospace -C "$(command -v terraform)" terraform
fi

command -v scw >/dev/null 2>&1 && eval "$(scw autocomplete script shell=zsh)"

[ -r "$HOME/.oh-my-zsh/completions/_bun" ] && source "$HOME/.oh-my-zsh/completions/_bun"

# LAST, deliberately: the project-local binstubs go on PATH only once this
# file has finished running. Added here rather than in shell/path.sh on
# 2026-09-15 because path.sh loads first, which meant `brew --prefix`,
# `scw autocomplete` and the asdf/terraform completions above all resolved
# through a repository's ./bin — and two of those are eval'd. Opening a
# terminal inside an untrusted clone was enough to run its code.
path_prepend "./node_modules/.bin"
path_prepend "./bin"
