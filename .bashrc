source ~/.bash_profile

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

. <(asdf completion bash)
. "$HOME/.asdf/asdf.sh"
. "$HOME/.asdf/completions/asdf.bash"
