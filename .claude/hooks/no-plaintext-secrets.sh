#!/bin/bash
#
# Claude Code PreToolUse hook: refuse to write a literal secret into one
# of the shell config files this repo tracks.
#
# These files are symlinked into $HOME *and* committed to a public
# GitHub repository. A token pasted into .exports is published the next
# time anything is pushed, and rewriting history afterwards does not
# un-leak it — the only real fix is rotating the credential. So this
# blocks before the write rather than warning after it.
#
# What it allows, deliberately: a reference. `export API_KEY="$MY_KEY"`,
# `$(...)`, or an empty default are how a secret is *supposed* to reach
# the shell — the value lives in a machine-local file that is never
# committed, which is exactly the pattern tasks.md is heading toward.
#
# Reads the hook payload on stdin, writes a deny verdict on stdout.
#
# Written for bash 3.2, the version macOS still ships at /bin/bash.

set -uo pipefail

input=$(cat)

command -v jq > /dev/null 2>&1 || exit 0

file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
[ -n "$file" ] || exit 0

# Only the tracked shell config. Anything else in the repo — scripts,
# docs, skills — is out of scope: this guards the files that get both
# published and sourced at login.
case "$(basename "$file")" in
  .exports|.aliases|.functions|.zshrc|.bashrc|.bash_profile|.bash_prompt|.gitconfig) ;;
  *) exit 0 ;;
esac

# Write carries the whole file in `content`; Edit carries only the
# replacement in `new_string`. Checking the incoming text rather than
# the file on disk is what makes this a *pre*-write guard.
payload=$(printf '%s' "$input" | jq -r '.tool_input.content // .tool_input.new_string // empty')
[ -n "$payload" ] || exit 0

# An assignment whose *name* looks like a credential and whose value is
# a literal. Anchoring on the assignment keeps prose and comments out of
# it: a line mentioning "password" is not a leak.
hits=$(printf '%s\n' "$payload" \
  | grep -inE '^[[:space:]]*(export[[:space:]]+)?[A-Za-z_][A-Za-z0-9_]*(TOKEN|SECRET|PASSWORD|PASSWD|API_?KEY|ACCESS_?KEY|PRIVATE_?KEY|CREDENTIALS?)[A-Za-z0-9_]*=' \
  | grep -vE '=[[:space:]]*("?\$|`|"")' \
  || true)

[ -n "$hits" ] || exit 0

jq -n --arg file "$file" --arg hits "$hits" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: ("Refus d écriture : ce qui ressemble à un secret en clair irait dans " + $file + ". Les fichiers de config shell de ce dépôt sont publiés sur GitHub, et ~/ n en contient que des liens symboliques — écrire par l un ou l autre chemin revient au même. Une fois poussé, réécrire l historique ne dé-fuite rien : il faut faire tourner la clé.\n\nLignes en cause :\n" + $hits + "\nÉcris plutôt une référence : export MA_CLE=\"$MA_CLE\", la valeur restant dans un fichier local non versionné (~/.extra, chargé par .bash_profile). Si c est un faux positif, dis-le et l utilisateur pourra écrire la ligne lui-même.")
  }
}'
