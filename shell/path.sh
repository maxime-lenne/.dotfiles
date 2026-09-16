# shellcheck shell=bash
# shell/path.sh — the single place where PATH is built.
#
# Sourced by shell/index.sh under both bash 3.2 and zsh, so: no arrays
# (0-indexed in bash, 1-indexed in zsh), no [[ ]], no bashisms.

# Add a directory to PATH unless it is already there.
#
# Without the guard, every nested shell re-prepends what its parent
# exported. Measured 2026-09-15 on a plain login zsh: 12 duplicated
# entries, including ./bin and the asdf shims.
path_prepend() {
  case ":${PATH}:" in
    *":$1:"*) ;;
    *) PATH="$1${PATH:+:$PATH}" ;;
  esac
}

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
