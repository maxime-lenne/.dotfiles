#!/bin/bash
#
# Claude Code PostToolUse hook: lint a shell script the moment it is
# written, instead of waiting for the pre-commit hook to catch it.
#
# The repo keeps a green `shellcheck -S info` baseline, and the whole
# point of that baseline is that it never accumulates debt. Catching a
# finding at write time means it gets fixed in the same breath as the
# edit, while the reasoning is still loaded; catching it at commit time
# means stopping a finished train of thought to go back.
#
# Reads the hook payload on stdin, writes a `decision: block` verdict on
# stdout when shellcheck complains — on PostToolUse that feeds the
# reason back to Claude and lets the turn continue, which is what makes
# it a correction loop rather than a wall.
#
# Written for bash 3.2, the version macOS still ships at /bin/bash.

set -uo pipefail

input=$(cat)

# jq is /usr/bin/jq on macOS — shipped with the OS, so no dependency to
# declare. Falling back to silence rather than erroring: a hook that
# breaks the session is worse than a hook that misses a lint.
command -v jq > /dev/null 2>&1 || exit 0

file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_response.filePath // empty')
[ -n "$file" ] || exit 0
[ -f "$file" ] || exit 0

# Vendored oh-my-zsh plugins are upstream's code. Linting them reports
# style we have no business "fixing" — see CLAUDE.md.
case "$file" in
  */custom/plugins/*) exit 0 ;;
esac

# Shell file? Either a .sh, or extensionless with a shell shebang. The
# rc files (.zshrc, .bashrc...) have no shebang and are deliberately
# out of scope: shellcheck reads them as sh and floods on zsh syntax.
case "$file" in
  *.sh) ;;
  *)
    head -n 1 "$file" | grep -qE '^#!.*/(env +)?(ba|k|z)?sh\b' || exit 0
    ;;
esac

command -v shellcheck > /dev/null 2>&1 || exit 0

if out=$(shellcheck -S info -- "$file" 2>&1); then
  exit 0
fi

jq -n --arg out "$out" '{
  decision: "block",
  reason: ("shellcheck -S info flags the file just written. This repo keeps a green baseline at that severity — fix the finding rather than adding a `# shellcheck disable`, and remember the scripts target bash 3.2.\n\n" + $out)
}'
