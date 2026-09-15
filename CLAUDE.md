# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal macOS dotfiles: shell configuration symlinked into `$HOME`, plus
two provisioning/maintenance scripts (`install-deps.sh`, `clean-mac.sh`).
There is no build, no test suite and no CI — the code *is* the deliverable,
and it runs against the user's live machine. That makes two things unusual:

- **Changes are destructive by default.** `install-deps.sh` installs
  software and `chown`s system directories; `clean-mac.sh` deletes caches
  and whole tool installs; `configure_dotfiles.sh` moves the user's real
  dotfiles aside and symlinks over them. Never run any of them to "check
  that it works" — see Verification below.
- **The repo serves two machines with different roles** (see
  `README.md` → Machines & environments). Most non-trivial edits have to
  answer "workstation, server, or both?".

## Verification (there are no tests)

```bash
shellcheck -x -S info <file>        # the actual gate; -S info catches SC2086
./clean-mac.sh --dry-run            # exercises clean-mac.sh, deletes nothing
bash -n install-deps.sh             # syntax-only check; there is no dry-run here
```

`-x` is not optional: `shell/index.sh` and several fragments `source` other
tracked files, and without `-x` shellcheck refuses to follow those (SC1091,
error tier) instead of checking them in context — plain `shellcheck -S info`
exits 1 on files that are otherwise clean.

`hooks/pre-commit` runs `shellcheck -x -S info` over the **staged** content
of every `*.sh` and every extensionless file with a shell shebang. The
tracked scripts are at a green baseline at that severity — keep them there
rather than adding `# shellcheck disable` lines.

The hook only fires after `./configure_dotfiles.sh` (or
`git config core.hooksPath hooks`) has run once in the clone, since
`core.hooksPath` lives in the unversioned `.git/config`.

`install-deps.sh` has no dry-run mode. Reason about it statically, or test
a single extracted section by hand — do not run the script.

## Hard constraints

- **bash 3.2.** The scripts run under macOS's `/bin/bash`. No associative
  arrays, no `${var^^}`/`${var,,}`, no `mapfile`/`readarray`, no `**`
  globbing. `hooks/pre-commit` is written to the same constraint even
  though git could invoke a newer bash.
- **asdf shims must stay first on `PATH`** among *absolute* directories
  (`shell/path.sh` guarantees it). The one deliberate exception is
  `./bin:./node_modules/.bin`, which sit ahead of them so a bare `rails`
  finds the project's binstub — that binstub delegates to bundler and so to
  the asdf Ruby, so the constraint's intent holds. Don't "fix" it. Those two
  entries are added at the very end of `.zshrc` and `.bashrc` (not in
  `shell/path.sh`, which loads first and, until 2026-09-15, put them ahead
  of `brew --prefix`, `scw` and the asdf/terraform completions those rc
  files run — two of which are `eval`'d, so opening a terminal in an
  untrusted clone could execute its code). Keep them last, after every
  completion block.
- **asdf / uv / bun are the only version managers.** nvm, pyenv and rvm
  were removed from both machines on 2026-08-28 and neither role installs
  them. Don't reintroduce them; `clean-mac.sh` keeps a section that
  detects and removes leftovers, which is deliberate — don't delete it.
- **`RUBY_CONFIGURE_OPTS` in `shell/exports.sh` is coupled to
  `install-deps.sh`.** Both pin `openssl@3`; changing the OpenSSL formula
  means changing both.

## Architecture

**Machine roles.** `dotfiles-lib.sh` is sourced (never executed) by both
`clean-mac.sh` and `install-deps.sh`. It provides `detect_machine_role`
— resolving `--server`/`--workstation`, then `$MACHINE_ROLE`, then the
hostname (`*mac-mini*` → server, everything else → workstation) — plus the
color variables and the `section`/`explain`/`warn`/`skipped`/`ask` output
helpers. `ask` honours `AUTO_YES=true`, which is how `-y` works.

**`install-deps.sh`** is a flat sequence of
`if ask_to_install "<label>"; then … fi` blocks, some wrapped in an
`if [ "$MACHINE_ROLE" = … ]` guard. Add packages via `install_or_upgrade`
(`--cask` as the first argument for casks) rather than calling `brew`
directly: it matches `brew list` **exactly** — a previous grep-based
version matched `jpeg` against the installed `jpeg-turbo` — and reports
rather than swallows a failing brew command. Server role skips GUI apps
and installs the package-manager stack without prompting.

**`clean-mac.sh`** is one `section` per tool. Every deletion goes through
`run` (a no-op under `--dry-run`) and is gated by `ask_to_clean`, with the
size reported before the prompt and accumulated into `TOTAL_FREED_KB`.
Preserve that shape: size → explain → ask → `run`. It is macOS-only by
design; Linux servers are explicitly out of scope.

**Shell config loads through one file.** `shell/index.sh` is sourced by
both `.zshrc` and `.bashrc` and is the only place that decides load order:
`path` → `exports` → `aliases` → `functions` → `role-$MACHINE_ROLE` →
`~/.env.local` (last, so a secret overrides everything above it). Add a
fragment there, once — not in an rc file.

`$HOME` holds three shell files: `.zshrc`, `.bashrc`, and a `.bash_profile`
that does nothing but source `.bashrc` (bash does not read `.bashrc` in a
login shell, and Terminal.app and ssh both start one). Anything genuinely
shell-specific — oh-my-zsh, `compinit`, `PS1`, completions — stays in its
rc file; everything else belongs under `shell/`.

`shell/index.sh` and every shared fragment are read by bash 3.2 **and**
zsh: no arrays at all (0-indexed in bash, 1-indexed in zsh), no bashisms,
no zshisms. Each carries `# shellcheck shell=bash` and is covered by the
pre-commit hook.

Role detection is duplicated from `detect_machine_role` in
`dotfiles-lib.sh` on purpose — that file runs `tput` at load time and
exports `BOLD`/`GREEN`/`RESET` plus `section`/`ask`/… into the interactive
namespace. Keep the two rules in step.

**`custom/plugins/`** is vendored third-party oh-my-zsh code
(zsh-autosuggestions, zsh-syntax-highlighting, aterminal, elixir). Don't
edit or lint-fix it; if a commit touches one of its `*.sh` files the
pre-commit hook will flag upstream's style — `git commit --no-verify` is
the right answer there, not patching vendored code.

**`configure_dotfiles.sh`** symlinks a hardcoded list of dotfiles into
`$HOME` and is idempotent since 2026-09-15: it backs up a real file once,
skips a re-run whose link already points at the repo, and removes its own
stale symlinks for the four files that moved into `shell/`. Adding a new
dotfile to the repo means adding its name to the relevant `for name in …`
loop.

## Conventions

- **Commits use gitmoji**: an emoji, then a lowercase imperative summary
  (`👷 add shellcheck pre-commit hook`, `♻️ retire nvm/pyenv/rvm`,
  `🔥 uninstall unused apps`). Single `master` branch, no PR flow.
- **Output language differs per script**: `clean-mac.sh` speaks French to
  the user, `install-deps.sh` speaks English. Match the file you're in.
- **Comments explain the *why*, especially dated decisions.** The existing
  ones record what a change replaced and when (the openssl@3 switch, the
  exact-match fix in `install_or_upgrade`, why `colima` over Docker
  Desktop on the server). Keep that register when adding code.
- `clean-mac.sh` runs under `set -uo pipefail`; `install-deps.sh`
  deliberately does not, since it continues past failing brew steps.

## docs/

`docs/audit-mac-mini.md` and `docs/audit-macbook-pro.md` are point-in-time
inventories of each machine, not documentation of this repo. Regenerate
them (`brew leaves`, `system_profiler SPApplicationsDataType`, each
language manager's global list) rather than trusting a stale one, and note
the snapshot date when you do.
