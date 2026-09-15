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

# The ONE deliberate exception to "shims first", and the reason it is not
# a violation: inside a Rails or node project a bare `rails` must resolve
# to the project's ./bin/rails binstub, which re-execs through bundler and
# therefore through the asdf Ruby. The constraint exists so that no *tool*
# path shadows an asdf version; a project-local binstub does not.
#
# Accepted trade-off (2026-09-15): `cd` into an untrusted clone and a bare
# command may run that repository's bin/. Do not "fix" this by moving the
# two entries down — it is a decision, not an oversight.
path_prepend "./node_modules/.bin"
path_prepend "./bin"

# Removed 2026-09-15:
#   - /opt/homebrew/opt/{libxml2,libxslt,libiconv}/bin — these shadowed the
#     system xmllint and iconv. Compiling against those libs needs
#     LDFLAGS/CPPFLAGS, not PATH.
#   - /usr/local/heroku/bin — the old .pkg installer's path, long gone.
#     The current formula installs into /opt/homebrew/bin.
#   - a bare "/usr/local" (not /usr/local/bin) inherited from .bash_profile.

export PATH
