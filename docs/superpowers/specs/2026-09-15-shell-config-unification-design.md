# Unifying the bash and zsh shell configuration

**Date:** 2026-09-15
**Status:** approved, not yet implemented
**Tracked as:** "Refacto et mise en commun entre bash et zsh de .aliases,
.profile, exports, .functions" in [docs/TASKs.md](../../TASKs.md)

## Problem

The repo has two shell entry points that were meant to load the same
configuration and no longer do. `README.md` and `CLAUDE.md` both call this
the repo's main known wart. Concretely, as of 2026-09-15:

| | `.zshrc` | `.bash_profile` / `.bashrc` |
|---|---|---|
| `.aliases` | sourced **twice** (l. 17 and l. 44) | sourced |
| `.exports` | sourced (since 2026-09-04) | sourced |
| `.functions` | **never** | sourced |
| `GPG_TTY` | l. 36 | `.bash_profile` l. 24 |
| asdf shims | `.zshrc` l. 28 | `.bashrc` l. 6 (duplicated) |
| terraform completion | l. 65 | `.bash_profile` l. 30 |
| `LANG` / `LC_ALL` / `LC_CTYPE` | l. 47-49 | absent |
| `HOMEBREW_NO_ANALYTICS` | l. 13 | absent |

Three further defects were measured rather than assumed:

1. **`PATH` is not idempotent.** A nested shell re-prepends what its parent
   already exported: 12 entries are duplicated in a plain login zsh today.
2. **`alias find=gfind` makes `find` unusable** — `gfind` is not installed
   and `install-deps.sh` never installs `findutils`.
3. **`.bashrc` sources `.bash_profile`**, the inverse of the convention.
   That inversion is why the asdf shims had to be re-declared in `.bashrc`:
   they must land *after* the `.bash_profile` body.

## Goals

- One place that decides what loads, in what order, for both shells.
- Both shells first-class: bash is used interactively (SSH to the Mac mini,
  rescue sessions), not just as a script interpreter.
- Per-role divergence, reusing the existing rule (`$MACHINE_ROLE`, else
  hostname `*mac-mini*` → server).
- Dead and broken entries removed, with the reason recorded in a comment.
- No behaviour change that is not listed in "Content audit" below.

## Non-goals

- A `conf.d` glob-loaded fragment scheme. Considered and rejected: ~300
  lines of config across two machines does not need an extension point.
- Touching `custom/plugins/` (vendored oh-my-zsh code).
- Making GUI apps see these variables. They are shell exports; an app
  launched from the Dock inherits `launchd`. Unchanged and out of scope.

## Architecture

### Repository layout

```
shell/
  index.sh             the single loader, sourced by both shells
  path.sh              all PATH construction + path_prepend/path_append
  exports.sh           was .exports
  aliases.sh           was .aliases
  functions.sh         was .functions
  role-workstation.sh  GUI aliases, Docker Desktop, Antigravity, k8s
  role-server.sh       headless-only
  bash-prompt.sh       was .bash_prompt (PS1; bash only)
.zshrc                 zsh-specific only
.bashrc                bash-specific only
.bash_profile          2-line stub
```

`$HOME` goes from nine shell dotfiles to three.

### Why `.bash_profile` still exists

zsh reads `.zshrc` for interactive login shells; bash does **not** read
`.bashrc` for login shells. Verified on this machine:

```
bash -li  → .bash_profile only
bash -i   → .bashrc only
zsh  -li  → .zshrc
```

Terminal.app and SSH both start a login shell, so a bash config living only
in `.bashrc` would never load. `.bash_profile` is therefore reduced to
`[ -r ~/.bashrc ] && . ~/.bashrc` and nothing else, which gives the intended
"one real file per shell" while staying correct. This also reverses the
current inversion and removes the duplicated asdf block.

### Load order (`shell/index.sh`)

```
1. path.sh          asdf shims guaranteed first (hard constraint)
2. exports.sh
3. aliases.sh
4. functions.sh
5. role-$MACHINE_ROLE.sh
6. ~/.env.local     moved here from the end of .exports
```

Two ordering constraints the loader does not own, one per shell:

- **zsh**: oh-my-zsh must load *before* `index.sh`, so `aliases.sh` wins over
  the plugin defaults, and `.zshrc`'s `unalias rm` must come *after*
  `index.sh` — it exists to undo the interactive `rm -i` that the
  `common-aliases` plugin installs, and would otherwise run too early.
- **bash**: `.bashrc` sources `bash-prompt.sh` itself. It sets `PS1` and is
  bash-only, so it never belongs in the shared loader.

`~/.env.local` moves to the loader so that "a secret overrides anything
declared above it" stays true by construction. Left at the end of
`exports.sh`, the role fragment would load after it and silently break the
invariant. `README.md` and a comment in `configure_dotfiles.sh` state the
old position and must be updated.

### `$DOTFILES` resolution

`DOTFILES="${DOTFILES:-$HOME/.dotfiles}"`, with a one-line warning if the
directory is missing. The alternative — each rc file resolving its own
symlink — needs `${BASH_SOURCE[0]}` in one shell and `${(%):-%N}` in the
other, reintroducing exactly the divergence this work removes. The repo is
at `~/.dotfiles` on both machines.

### Role detection

Reimplemented in ~5 lines inside `index.sh`, using the same rule as
`detect_machine_role`. `dotfiles-lib.sh` is deliberately **not** sourced: it
runs `tput` at load time, and exports `BOLD`/`GREEN`/`RESET` (a direct
collision with `bash-prompt.sh`) plus `section`/`explain`/`warn`/`ask` into
the interactive namespace. The duplication is intentional and gets a comment
on both sides naming the other.

### Portability constraint

`index.sh` and every shared fragment are sourced by bash 3.2 **and** zsh.
No bashisms, no zshisms, and **no arrays at all** — they are 0-indexed in
bash and 1-indexed in zsh. Each fragment carries `# shellcheck shell=bash`
so `hooks/pre-commit` lints it in the right dialect. This is a net gain: the
shell configuration becomes lintable, which it is not today
(`.claude/hooks/shellcheck-on-write.sh` explicitly skips the shebang-less rc
files because shellcheck reads zsh as sh and floods).

## Content audit

Verified against the actual machine on 2026-09-15, not assumed.

### Removed — dead or broken

| Entry | Finding |
|---|---|
| `alias find=gfind` | `gfind` absent → `find` currently unusable |
| `sniff`, `httpdump` | `ngrep` absent, and they target `en1`, which has no IP (`en0` is the live interface) |
| `ftp_server_start` / `_stop` | `/System/Library/LaunchDaemons/ftp.plist` no longer ships with macOS |
| `postgresql_server_*`, `redis_*` | No such plist present; `brew services` is the current way |
| `undopush` | `git push -f origin HEAD^:master` — force-push, `master` hardcoded |
| Heroku Toolbelt `PATH` entry | `/usr/local/heroku/bin` does not exist; the current formula installs into `/opt/homebrew/bin`, already on `PATH` |
| `# FIX: type -t md5sum...` | Dead comment |
| libxml2 / libxslt / libiconv `bin` on `PATH` | They shadow the system `xmllint` and `iconv`. Compiling against these libs needs `LDFLAGS`/`CPPFLAGS`, not `PATH` |

### Fixed

| Entry | Change |
|---|---|
| `alias stt="sublime"` | → `subl` (the binary exists; only the name was wrong) |
| `alias localip` | `en1` → `en0` |
| `export BUNDLER_EDITOR="atom"` | → `"$EDITOR"`; Atom was discontinued in 2022 and is absent |
| `server()` | `SimpleHTTPServer` is Python 2 and `python` is absent → `python3 -m http.server` |
| `flush` | `dscacheutil -flushcache` alone is insufficient on current macOS → add `sudo killall -HUP mDNSResponder` |
| `gifify` | `convert` is deprecated in ImageMagick 7 → `magick` |
| `cp_p`, `extract`, `gifify` | Unquoted `$1`/`$2` throughout (SC2086) → quoted; this is the repo's lint gate |
| Hardcoded `/Users/maxime-lenne/...` paths | Seven of them across `.zshrc` and `.bash_profile` (Docker, bun completions, `.local/bin`, Antigravity, `$HOME/bin`) → `$HOME`, so the repo stops assuming a username |
| `PATH` duplication | `path_prepend` / `path_append` drop an entry that is already present, so a nested shell or a `reload` stops stacking. 12 entries are duplicated today |
| `./bin:./node_modules/.bin` | Kept — it is a deliberate Rails/node convenience — but moved to the **tail** of `PATH`. Relative directories at the head mean `cd` into a cloned repo runs its `bin/`. Comment records the trade-off |
| `HISTCONTROL`, `HISTIGNORE`, `HISTFILESIZE` | Stay in `exports.sh` (harmless under zsh); zsh gains the equivalent `setopt HIST_IGNORE_DUPS` / `HIST_IGNORE_SPACE` |

### Kept behind a `command -v` guard, and added to `install-deps.sh`

`lc` / `colorls`, and `heroku`. Both are wanted but absent; the guard means
nothing breaks before they are installed and the alias reappears by itself
afterwards. Workstation role only.

### Promoted to the shared core

Today zsh-only, so bash has never had them: `HOMEBREW_NO_ANALYTICS`,
`LANG` / `LC_ALL` / `LC_CTYPE`, `RUBY_CONFIGURE_OPTS`. `GPG_TTY` is declared
twice today and will be declared once.

`RUBY_CONFIGURE_OPTS` keeps its `$(brew --prefix openssl@3)` call: measured
at 19 ms, not worth freezing, and it stays coupled to `install-deps.sh` as
`CLAUDE.md` requires.

### Role split

- **workstation**: `subl`/`stt`, `showdesktop` / `hidedesktop` /
  `showFiles` / `hideFiles`, Docker Desktop completions, Antigravity
  `PATH`, `k8s-scaleway` / `k8s-staging`, `lc`.
- **common**: everything else. `scw` and `terraform` completions guarded by
  `command -v`, since neither is guaranteed on the server.

### Unchanged

Navigation (`..` through `.....`, `~`, `-`), `ls`, `tree`, `ip`, `ips`,
`whois`, `trimcopy`, `cleanup`, `fs`, `emptytrash`, `reload`, `extract`,
`cp_p`, `EDITOR`, `MANPAGER`, `HISTSIZE`, `AIRMAIL_MCP_*`.

`sail` is kept untouched although `php` and `composer` are absent: it resolves
`vendor/bin/sail` inside a project, so it costs nothing and works the day a
Laravel checkout is on the machine.

## Migration

`~/.aliases`, `~/.exports`, `~/.functions` and `~/.bash_prompt` are symlinks
to files that this change deletes. Left alone, both machines end up with
four broken symlinks. `configure_dotfiles.sh` therefore:

1. Shortens its symlink list to `.bashrc`, `.bash_profile`, `.zshrc`,
   `.gitconfig`, `.gitignore_global`.
2. Removes each of the four obsolete links **only** when it is a symlink
   pointing into this repo. A real file (a machine never configured here)
   is left untouched.
3. Gets the fix its header `TODO` has been asking for, since this change
   forces a re-run on two machines: no `mv` when the target is already the
   intended symlink, no error when the target does not exist, and a
   timestamped backup instead of clobbering the previous one.

`install-deps.sh` gains `colorls` and `heroku` under the workstation role.

## Verification

There is no test suite and none of these scripts may be run to "see if it
works". The safety net is a before/after fingerprint:

1. **Baseline captured before any edit** (done, 2026-09-15): for both zsh
   and bash, the sorted list of aliases, of function names, of exported
   variables, and the `PATH`.
2. After the refactor, the same capture runs against a sandbox `$HOME`
   pointing at the repo, and is diffed against the baseline. **Every
   difference must appear in the Content audit above**; anything else is a
   regression.
3. **`PATH` idempotence**: sourcing `index.sh` twice leaves `PATH` byte-for-
   byte identical.
4. **asdf shims first**: explicit assertion on `PATH` after a full load, in
   both shells.
5. `shellcheck -S info shell/*.sh` — the repo's gate.
6. The server role is exercised with `MACHINE_ROLE=server`; the Mac mini is
   not needed.

## Rollback

One commit on `master`. `git revert` plus a re-run of
`configure_dotfiles.sh` restores the previous state; the timestamped
`.backup` files are the second line of defence.

## Documentation to update

- `README.md`: the shell configuration section, and the `~/.env.local`
  paragraph (it now names `index.sh`, not `.exports`).
- `CLAUDE.md`: the "Shell config has two divergent entry points" section
  becomes false and is rewritten to describe the loader.
- `docs/TASKs.md`: mark the task done, dated 2026-09-15.
