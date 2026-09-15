# bash does not read ~/.bashrc in a login shell, and Terminal.app and ssh
# both start one — verified 2026-09-15:
#   bash -li -> .bash_profile only
#   bash -i  -> .bashrc only
#   zsh  -li -> .zshrc
# zsh has no such split, which is why it gets a single .zshrc. So bash gets
# one real file too, .bashrc, and this exists only to reach it.
#
# This also reverses the previous arrangement, where .bashrc sourced
# .bash_profile — the inverse of the convention, and the reason the asdf
# shims had to be re-declared in .bashrc to land after it.
[ -r "$HOME/.bashrc" ] && . "$HOME/.bashrc"
