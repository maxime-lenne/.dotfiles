# shellcheck shell=bash
# shell/role-workstation.sh — loaded by shell/index.sh when MACHINE_ROLE is
# "workstation" (the MacBook Pro). Everything here is GUI-bound or
# machine-specific and has no business on the headless Mac mini.
#
# PATH additions MUST use path_append: shell/path.sh owns the head of PATH,
# including the asdf-shims-first guarantee. Prepending here would break it.

# Sublime Text. The alias said "sublime" until 2026-09-15; the binary
# Homebrew actually installs is `subl`.
command -v subl >/dev/null 2>&1 && alias stt="subl"

# colorls is declared by install-deps.sh's Ruby section but was missing from
# the asdf Ruby 3.3.5 on 2026-09-15. Guarded so the alias simply does not
# exist rather than failing when called, and reappears once the gem is back.
command -v colorls >/dev/null 2>&1 && alias lc='colorls -lA --sd'

# Hide/show all desktop icons (useful when presenting)
alias hidedesktop="defaults write com.apple.finder CreateDesktop -bool false && killall Finder"
alias showdesktop="defaults write com.apple.finder CreateDesktop -bool true && killall Finder"

# Hide/show hidden files. The trailing
# "/System/Library/CoreServices/Finder.app" the old aliases passed to
# killall was read as a second process *name*, never matched anything, and
# only made killall exit non-zero — dropped 2026-09-15.
alias showFiles='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder'
alias hideFiles='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder'

# Kubernetes contexts (were inline in .zshrc, so bash never had them)
alias k8s-scaleway="export KUBECONFIG=\$HOME/.kube/config_scaleway"
alias k8s-staging="export KUBECONFIG=\$HOME/Documents_non_icloud/workspace_devops/k8s-productivity/environments/staging/kubeconfig-k8s-productivity.yaml"

# Docker Desktop and Antigravity ship CLIs outside Homebrew. Both were
# hardcoded as /Users/maxime-lenne/... until 2026-09-15.
[ -d "$HOME/.docker/bin" ] && path_append "$HOME/.docker/bin"
[ -d "$HOME/.antigravity/antigravity/bin" ] && path_append "$HOME/.antigravity/antigravity/bin"
export PATH
