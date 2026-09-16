# shellcheck shell=bash
# shell/path.sh — the single place where PATH is built.
#
# Sourced by shell/index.sh under both bash 3.2 and zsh, so: no arrays
# (0-indexed in bash, 1-indexed in zsh), no [[ ]], no bashisms.

# Strip every occurrence of a directory from PATH.
#
# Written without `IFS=: ; for dir in $PATH` on purpose: unquoted expansion
# word-splits in bash but NOT in zsh, where SH_WORD_SPLIT is off by default.
# The ${x%%:*} / ${x#*:} walk below behaves identically in both.
path_remove() {
  local rest="$PATH" out="" dir
  while [ -n "$rest" ]; do
    dir="${rest%%:*}"
    if [ "$rest" = "$dir" ]; then rest=""; else rest="${rest#*:}"; fi
    [ "$dir" = "$1" ] && continue
    out="${out:+$out:}$dir"
  done
  PATH="$out"
}

# Move a directory to the front of PATH, removing any earlier occurrence.
#
# It *moves* rather than skipping-if-present, and that distinction is the
# whole point. A skip-if-present version shipped on 2026-09-15 and was
# wrong: macOS runs path_helper from /etc/profile, which rebuilds PATH with
# /etc/paths (/usr/bin, /bin...) at the FRONT, keeping the inherited entries
# after them. So in any login shell started from an already-configured one —
# `bash -lc`, tmux, and above all the `reload` alias, which is `exec $SHELL
# -l` — the shims were already "in PATH", the prepend skipped, and /usr/bin
# stayed ahead of them. `ruby` silently became /usr/bin/ruby, Apple's 2.6,
# instead of the asdf version. That breaks this repo's hard constraint the
# moment you reload your shell after editing it.
#
# Removing first also collapses the duplicates the pre-2026-09-15 config
# accumulated — 12 of them in a plain login zsh — so this keeps the
# deduplication that skip-if-present was introduced for, without trading
# away the ordering guarantee.
path_prepend() {
  path_remove "$1"
  PATH="$1${PATH:+:$PATH}"
}

# Appending is about availability, not priority, so an entry already present
# is left exactly where it is.
path_append() {
  case ":${PATH}:" in
    *":$1:"*) ;;
    *) PATH="${PATH:+$PATH:}$1" ;;
  esac
}

# Prepended in reverse order of priority: the last call ends up first.

path_append "/usr/local/sbin"

[ -d "$HOME/bin" ] && path_prepend "$HOME/bin"
[ -d "$HOME/.bun/bin" ] && path_prepend "$HOME/.bun/bin"
[ -d "$HOME/.local/bin" ] && path_prepend "$HOME/.local/bin"

# asdf shims: the single version manager for Ruby and Node since the
# 2026-08-28 removal of nvm/pyenv/rvm. They must precede every absolute
# tool path so asdf-managed versions win. Before this file existed they
# sat at position 7 of PATH, behind four absolute directories, which made
# CLAUDE.md's "shims first" hard constraint false in practice.
path_prepend "${ASDF_DATA_DIR:-$HOME/.asdf}/shims"

# The project-local binstubs (./bin, ./node_modules/.bin) are NOT added
# here. They are the one deliberate exception to "shims first" — inside a
# Rails or node project a bare `rails` must resolve to the project's
# ./bin/rails binstub, which re-execs through bundler and therefore
# through the asdf Ruby — but this file loads FIRST in shell/index.sh, so
# adding them here put them ahead of everything index.sh sources
# afterwards: `brew --prefix` in shell/exports.sh, and the terraform/asdf/
# scw completions in .zshrc and .bashrc, two of which are `eval`'d. A repo
# with an executable ./bin/brew or ./bin/scw got to run its own code at
# shell startup just from having its cwd open in a new terminal. Moved
# 2026-09-15 to the very end of .zshrc and .bashrc instead, after every
# completion block, so they land on PATH only once the rest of startup
# has already resolved its tools. See those files for the accepted
# trade-off note: a bare command typed at the prompt can still hit a
# repository's bin/, which is the residual, intended risk.

# Removed 2026-09-15:
#   - /opt/homebrew/opt/{libxml2,libxslt,libiconv}/bin — these shadowed the
#     system xmllint and iconv. Compiling against those libs needs
#     LDFLAGS/CPPFLAGS, not PATH.
#   - /usr/local/heroku/bin — the old .pkg installer's path, long gone.
#     The current formula installs into /opt/homebrew/bin.
#   - a bare "/usr/local" (not /usr/local/bin) inherited from .bash_profile.

export PATH
