ZSH=$HOME/.oh-my-zsh

# You can change the theme with another one:
#   https://github.com/robbyrussell/oh-my-zsh/wiki/themes
ZSH_THEME="baboriginal"

ZSH_CUSTOM=$HOME/.dotfiles/custom

# Useful plugins for Rails development with Sublime Text
plugins=(gitfast last-working-dir common-aliases sublime zsh-syntax-highlighting history-substring-search elixir aterminal history zsh-autosuggestions)

# Prevent Homebrew from reporting - https://github.com/Homebrew/brew/blob/master/share/doc/homebrew/Analytics.md
export HOMEBREW_NO_ANALYTICS=1

# Actually load Oh-My-Zsh
source "${ZSH}/oh-my-zsh.sh"
source ~/.aliases
unalias rm # No interactive rm by default (brought by plugins/common-aliases)


export PATH="/opt/homebrew/opt/libxml2/bin:$PATH"
export PATH="/opt/homebrew/opt/libxslt/bin:$PATH"
export PATH="/opt/homebrew/opt/libiconv/bin:$PATH"

# asdf shims first: it's the single version manager for Ruby, Node...
# (replaces rbenv/nvm/rvm, all removed). Must come before any other
# tool-specific PATH entry so asdf-managed versions take priority.
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:${PATH}"

# ruby-build (which asdf's ruby plugin relies on) compiles Ruby against
# this OpenSSL. openssl@3 since 2026-08-28: Ruby 3.3.5 builds and links
# against it fine (verified: OpenSSL::OPENSSL_VERSION reports 3.6.3),
# and openssl@1.1 is EOL upstream with nothing left depending on it.
export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@3)"

export GPG_TTY=$(tty)

# Rails and Ruby uses the local `bin` folder to store binstubs.
# So instead of running `bin/rails` like the doc says, just run `rails`
# Same for `./node_modules/.bin` and nodejs
export PATH="./bin:./node_modules/.bin:${PATH}:/usr/local/sbin"

export ANDROID_HOME="/Users/$USER/Library/Android/sdk"
export PATH="${PATH}:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools"

# Store your own aliases in the ~/.aliases file and load the here.
[[ -f "$HOME/.aliases" ]] && source "$HOME/.aliases"

# Encoding stuff for the terminal
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"

export EDITOR="vim"
export BUNDLER_EDITOR="atom"


export PATH="/Users/maxime-lenne/.local/bin:$PATH"

# Scaleway CLI autocomplete initialization.
eval "$(scw autocomplete script shell=zsh)"

autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /opt/homebrew/bin/terraform terraform

alias k8s-scaleway="export KUBECONFIG=~/.kube/config_scaleway"
alias k8s-staging="export KUBECONFIG=~/Documents_non_icloud/workspace_devops/k8s-productivity/environments/staging/kubeconfig-k8s-productivity.yaml"

fpath=($(brew --prefix asdf)/share/zsh/site-functions $fpath)
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/maxime-lenne/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions

export PATH="$HOME/bin:$PATH"

# bun completions
[ -s "/Users/maxime-lenne/.oh-my-zsh/completions/_bun" ] && source "/Users/maxime-lenne/.oh-my-zsh/completions/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Added by Antigravity
export PATH="/Users/maxime-lenne/.antigravity/antigravity/bin:$PATH"
