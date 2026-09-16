# shellcheck shell=bash
# shell/exports.sh — environment shared by bash and zsh.
# Was ~/.exports, bash-only until 2026-09-04 and moved here 2026-09-15.
#
# Secrets do NOT belong here: this file is versioned and pushed publicly.
# They live in ~/.env.local, which shell/index.sh sources last.

export EDITOR="vim"

# "$EDITOR" since 2026-09-15: this said "atom", discontinued in 2022 and
# absent from both machines, so `bundle open` silently did nothing.
export BUNDLER_EDITOR="$EDITOR"

# Don't clear the screen after quitting a manual page
export MANPAGER="less -X"

# bun's install root. Declared in .zshrc only until 2026-09-15 (zsh-only,
# same drift as the encoding exports below), and dropped outright when
# .zshrc was cut down to the shell-specific bits — bun still resolves via
# the $HOME/.bun/bin entry shell/path.sh adds, but `bun upgrade` and global
# installs use this variable to find their install root.
export BUN_INSTALL="$HOME/.bun"

# Encoding. Declared in .zshrc only until 2026-09-15, so bash had none.
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"

# https://github.com/Homebrew/brew/blob/master/docs/Analytics.md
# Also zsh-only until 2026-09-15.
export HOMEBREW_NO_ANALYTICS=1

# Declared twice until 2026-09-15 (.zshrc and .bash_profile). Split across
# two statements because shellcheck SC2155 (warning tier, which the repo's
# -S info gate includes) rejects export-and-assign with a command substitution.
GPG_TTY=$(tty)
export GPG_TTY

# ruby-build (which asdf's ruby plugin relies on) compiles Ruby against
# this OpenSSL. openssl@3 since 2026-08-28: Ruby 3.3.5 builds and links
# against it fine, and openssl@1.1 is EOL upstream. Kept coupled to
# install-deps.sh, which pins the same formula — change both or neither.
# The brew call costs 19 ms (measured 2026-09-15), not worth freezing.
#
# Guarded on the output, not just on `brew` existing (2026-09-15): a
# freshly-provisioned Mac mini can have brew installed before the
# openssl@3 formula is, and `brew --prefix openssl@3` fails on a formula
# it doesn't know about. Without this, that failure was silent — an
# exported RUBY_CONFIGURE_OPTS="--with-openssl-dir=" that later made
# `asdf install ruby` build against nothing.
if command -v brew >/dev/null 2>&1; then
  _openssl3_prefix="$(brew --prefix openssl@3 2>/dev/null)"
  if [ -n "$_openssl3_prefix" ]; then
    RUBY_CONFIGURE_OPTS="--with-openssl-dir=$_openssl3_prefix"
    export RUBY_CONFIGURE_OPTS
  fi
  unset _openssl3_prefix
fi

# Larger history. 50000 since 2026-09-04, matching oh-my-zsh's own HISTSIZE
# so the two shells agree instead of zsh being silently capped.
# HISTFILESIZE, HISTCONTROL, HISTTIMEFORMAT and HISTIGNORE are bash-only
# knobs; zsh ignores them harmlessly and gets the equivalent setopt calls
# in .zshrc instead.
export HISTSIZE=50000
export HISTFILESIZE=$HISTSIZE
export HISTCONTROL=ignoredups
HISTTIMEFORMAT='%F %T '
export HISTTIMEFORMAT
export HISTIGNORE="ls:ls *:cd:cd -:pwd;exit:date:* --help"

# ---------------------------------------------------------------------------
# Application environment
# ---------------------------------------------------------------------------
# Airmail MCP server: fixed port, no auto-launch (started on demand, not by
# the client). The matching token is a secret and lives in ~/.env.local —
# see .env.example.
export AIRMAIL_MCP_PORT=9876
export AIRMAIL_MCP_AUTO_LAUNCH=0

# ~/.env.local is NOT sourced here any more (moved to shell/index.sh on
# 2026-09-15). It has to load after every fragment, including the role one,
# for "a secret overrides anything above it" to stay true.
