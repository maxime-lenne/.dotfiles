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
if command -v brew >/dev/null 2>&1; then
  RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@3)"
  export RUBY_CONFIGURE_OPTS
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
