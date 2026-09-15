# The one real bash file. ~/.bash_profile is a stub that sources this, so
# login and non-login interactive shells both end up here.

# Everything shared with zsh: PATH, exports, aliases, functions, the role
# fragment and ~/.env.local. See shell/index.sh for the order.
#
# This sits ABOVE the interactive guard on purpose. .bash_profile is read by
# every login shell, interactive or not, and used to set PATH unconditionally
# — verified 2026-09-15: `HOME=<sandbox> bash -lc` sees the asdf shims today.
# Now that .bash_profile only delegates here, guarding this line would drop
# PATH, exports, aliases and functions for `bash -lc`. The fingerprint harness
# runs -lic and would never catch it.
. "${DOTFILES:-$HOME/.dotfiles}/shell/index.sh"

# Nothing below is useful to a non-interactive shell: a prompt it never
# renders, completions it never offers.
case $- in
  *i*) ;;
  *) return ;;
esac

# PS1. bash-only, so it is not in the shared loader.
. "${DOTFILES:-$HOME/.dotfiles}/shell/bash-prompt.sh"

# --- Completions (bash-specific; the zsh halves live in .zshrc) ---

if command -v brew >/dev/null 2>&1; then
  brew_prefix="$(brew --prefix)"
  [ -r "$brew_prefix/etc/bash_completion" ] && . "$brew_prefix/etc/bash_completion"
  [ -r "$brew_prefix/etc/bash_completion.d/git-completion.bash" ] && \
    . "$brew_prefix/etc/bash_completion.d/git-completion.bash"
  unset brew_prefix
fi

command -v terraform >/dev/null 2>&1 && complete -C "$(command -v terraform)" terraform
command -v asdf >/dev/null 2>&1 && . <(asdf completion bash)
command -v scw >/dev/null 2>&1 && eval "$(scw autocomplete script shell=bash)"
