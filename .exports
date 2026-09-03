# Make nano the default editor
export EDITOR="vim"

# Don’t clear the screen after quitting a manual page
export MANPAGER="less -X"

# Larger history. 50000 since 2026-09-04: .exports is now sourced by zsh too
# (see .zshrc), and oh-my-zsh already sets HISTSIZE=50000 — aligning bash on
# that value keeps a single history size across both shells instead of having
# zsh silently overridden down to the old 32768.
# HISTFILESIZE, HISTCONTROL and HISTIGNORE below are bash-only knobs; zsh
# ignores them, which is harmless.
export HISTSIZE=50000
export HISTFILESIZE=$HISTSIZE
export HISTCONTROL=ignoredups

# timestamps for bash history. www.debian-administration.org/users/rossen/weblog/1
# saved for later analysis
HISTTIMEFORMAT='%F %T '
export HISTTIMEFORMAT

# Make some commands not show up in history
export HISTIGNORE="ls:ls *:cd:cd -:pwd;exit:date:* --help"

# Configure the bundle open editor to atom
export BUNDLER_EDITOR="atom"

# ---------------------------------------------------------------------------
# Application environment
# ---------------------------------------------------------------------------
# Non-sensitive variables the local tooling expects. Secrets never belong
# here — this file is versioned. They go to ~/.env.local, loaded below.

# Airmail MCP server: fixed port, and no auto-launch (the server is started
# on demand, not by the client). The matching token is a secret and lives in
# ~/.env.local — see .env.example.
export AIRMAIL_MCP_PORT=9876
export AIRMAIL_MCP_AUTO_LAUNCH=0

# ---------------------------------------------------------------------------
# Machine-local secrets
# ---------------------------------------------------------------------------
# Kept LAST so ~/.env.local can override anything declared above.
# ~/.env.local is a symlink to .env at the root of the dotfiles repo, which
# .gitignore keeps out of every commit — same layout as the other dotfiles,
# but that one file is never versioned. configure_dotfiles.sh seeds it from
# .env.example and links it.
[ -r "$HOME/.env.local" ] && . "$HOME/.env.local"
