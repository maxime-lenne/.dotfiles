source ~/.bash_profile

# asdf shims first: it's the single version manager for Ruby, Node...
# (replaces rbenv/nvm/rvm, all removed). Must come before any other
# tool-specific PATH entry so asdf-managed versions take priority.
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

# asdf 0.16+ is a single Go binary: no more asdf.sh/asdf.bash to source,
# shims in PATH above is enough. Only completions need loading.
command -v asdf >/dev/null 2>&1 && . <(asdf completion bash)
