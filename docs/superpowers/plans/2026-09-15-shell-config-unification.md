# Shell configuration unification — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the two divergent shell entry points with a single `shell/` loader sourced by both bash and zsh, and apply the content audit recorded in the spec.

**Architecture:** A `shell/` directory in the repo holds every fragment plus `index.sh`, the one file that decides load order. `$HOME` keeps only `.zshrc`, `.bashrc` and a two-line `.bash_profile`, each reduced to what is genuinely shell-specific. Role divergence (workstation / server) is a fragment chosen by name.

**Tech Stack:** POSIX shell constrained to bash 3.2 **and** zsh, shellcheck `-S info`, oh-my-zsh, asdf.

**Spec:** `docs/superpowers/specs/2026-09-15-shell-config-unification-design.md`

## Global Constraints

- **bash 3.2.** No associative arrays, no `${var^^}`/`${var,,}`, no `mapfile`, no `**`.
- **No arrays at all** in `shell/index.sh` and every shared fragment: they are 0-indexed in bash and 1-indexed in zsh.
- **asdf shims first among absolute directories.** `./bin` and `./node_modules/.bin` are the single documented exception and stay ahead of them.
- Every file under `shell/` starts with `# shellcheck shell=bash` and must pass `shellcheck -S info`.
- **Never run** `install-deps.sh`, `clean-mac.sh` or `configure_dotfiles.sh` against the real `$HOME` to "check that it works". Task 10 is the only one that touches `$HOME`, and only after Task 9's diff is clean.
- Comments explain the **why** and carry a date, matching the existing register.
- Commits use gitmoji: an emoji, then a lowercase imperative summary.
- `install-deps.sh` is **out of scope** and must not be modified.

---

## File Structure

| File | Responsibility |
|---|---|
| `shell/index.sh` | Resolve `$DOTFILES`, detect the role, source fragments in order, load `~/.env.local` last |
| `shell/path.sh` | `path_prepend` / `path_append`, and the whole head of `PATH` |
| `shell/exports.sh` | Environment variables shared by both shells |
| `shell/aliases.sh` | Role-independent aliases |
| `shell/functions.sh` | Role-independent functions |
| `shell/role-workstation.sh` | GUI aliases, Docker Desktop / Antigravity `PATH`, kubeconfig |
| `shell/role-server.sh` | Headless placeholder |
| `shell/bash-prompt.sh` | `PS1` (bash only, sourced by `.bashrc`, never by the loader) |
| `.zshrc` | oh-my-zsh, `unalias rm`, `setopt`, zsh completions |
| `.bashrc` | The real bash file: loader, prompt, bash completions |
| `.bash_profile` | Two-line stub reaching `.bashrc` |
| `configure_dotfiles.sh` | Shorter symlink list, stale-link cleanup, idempotent backups |

---

### Task 1: Fingerprint harness and a reproducible "before"

The repo has no test suite, so this task builds the only thing that can
tell a refactor from a regression. It produces no repo change.

**Files:**
- Create: `$SCRATCH/fingerprint.sh` (throwaway, outside the repo)

`$SCRATCH` is the session scratchpad directory.

- [ ] **Step 1: Write the harness**

```bash
cat > "$SCRATCH/fingerprint.sh" <<'EOF'
#!/bin/bash
# fingerprint.sh <zsh|bash> <dotfiles-checkout> — throwaway verification tool.
# Builds a sandbox $HOME symlinking whichever rc files the given checkout
# has, starts a login+interactive shell in it, and prints a normalised
# inventory. Never touches the real $HOME.
set -u
shell_name=$1
checkout=$2
sandbox=$(mktemp -d)

for name in .zshrc .bashrc .bash_profile .aliases .exports .functions .bash_prompt; do
  [ -e "$checkout/$name" ] && ln -s "$checkout/$name" "$sandbox/$name"
done
# oh-my-zsh lives in the real $HOME and is not part of this repo; link it in
# so the plugin interaction (notably `unalias rm`) is actually exercised.
[ -d "$HOME/.oh-my-zsh" ] && ln -s "$HOME/.oh-my-zsh" "$sandbox/.oh-my-zsh"
# ~/.dotfiles must resolve inside the sandbox too: the pre-refactor .zshrc
# hardcodes ZSH_CUSTOM=$HOME/.dotfiles/custom, and the post-refactor rc
# files fall back to $HOME/.dotfiles when DOTFILES is unset. Without this
# the custom plugins silently fail to load on both sides of the diff.
ln -s "$checkout" "$sandbox/.dotfiles"

DOTFILES="$checkout" HOME="$sandbox" "/bin/$shell_name" -lic '
  echo "### ALIASES"
  alias | sed "s/^alias //" | LC_ALL=C sort
  echo "### FUNCTIONS"
  { typeset +f 2>/dev/null || declare -F | sed "s/^declare -f //"; } | LC_ALL=C sort
  echo "### PATH"
  echo "$PATH" | tr ":" "\n"
  echo "### EXPORTS"
  env | grep -vE "^(HOME|PWD|OLDPWD|SHLVL|_|TMPDIR|DOTFILES)=" | LC_ALL=C sort
' 2>/dev/null | sed "s|$sandbox|\$HOME|g; s|$checkout|\$DOTFILES|g"

rm -rf "$sandbox"
EOF
chmod +x "$SCRATCH/fingerprint.sh"
```

- [ ] **Step 2: Capture the "before" from a pristine checkout**

A git worktree pins the pre-refactor state, so "before" stays reproducible
however far the working tree drifts.

Run:
```bash
git worktree add --detach "$SCRATCH/before" HEAD
for s in zsh bash; do
  "$SCRATCH/fingerprint.sh" "$s" "$SCRATCH/before" > "$SCRATCH/before-$s.txt"
done
wc -l "$SCRATCH"/before-*.txt
```
Expected: both files non-empty; `before-zsh.txt` contains `### ALIASES`,
`### FUNCTIONS`, `### PATH`, `### EXPORTS`.

- [ ] **Step 3: Verify the harness discriminates**

A harness that reports "no change" no matter what is worthless. Prove it
reacts:

Run:
```bash
echo 'alias __canary__="true"' >> "$SCRATCH/before/.aliases"
"$SCRATCH/fingerprint.sh" zsh "$SCRATCH/before" | grep -c __canary__
git -C "$SCRATCH/before" checkout .aliases
```
Expected: `1`. If it prints `0`, the harness is not loading `.aliases` —
stop and fix it before writing any refactor.

- [ ] **Step 4: Record the known-dead entries**

Run:
```bash
grep -E "^(find|lc|sniff|httpdump|undopush|ftp_server_|postgresql_server_|redis_)" "$SCRATCH/before-zsh.txt"
```
Expected: the entries the spec removes are present. This is the list the
final diff must show disappearing, and nothing else.

No commit — this task creates nothing inside the repo.

---

### Task 2: `shell/path.sh`

**Files:**
- Create: `shell/path.sh`

**Interfaces:**
- Produces: `path_prepend <dir>` and `path_append <dir>`, both no-ops when
  `<dir>` is already in `PATH`. Every later fragment uses these and never
  assigns `PATH` directly. Role fragments use **`path_append` only** —
  `path.sh` owns the head of `PATH`.

- [ ] **Step 1: Write the file**

```sh
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
```

- [ ] **Step 2: Lint**

Run: `shellcheck -S info shell/path.sh`
Expected: no output.

- [ ] **Step 3: Test idempotence and order**

```bash
env -i HOME="$HOME" PATH=/usr/bin:/bin /bin/bash -c '
  . shell/path.sh; first="$PATH"
  . shell/path.sh; second="$PATH"
  [ "$first" = "$second" ] || { echo "FAIL: PATH not idempotent"; exit 1; }
  case "$PATH" in ./bin:./node_modules/.bin:*) ;; *) echo "FAIL: binstubs not first"; exit 1;; esac
  shims="${ASDF_DATA_DIR:-$HOME/.asdf}/shims"
  rest="${PATH#./bin:./node_modules/.bin:}"
  case "$rest" in "$shims":*) ;; *) echo "FAIL: shims not first absolute entry: $rest"; exit 1;; esac
  echo PASS
'
```
Expected: `PASS`.

- [ ] **Step 4: Commit**

```bash
git add shell/path.sh
git commit -m "🏗️ build PATH in one place, with deduplication"
```

---

### Task 3: `shell/exports.sh`

**Files:**
- Create: `shell/exports.sh` (via `git mv .exports shell/exports.sh`, then edit)
- Delete: `.exports`

**Interfaces:**
- Consumes: nothing.
- Produces: `EDITOR`, `BUNDLER_EDITOR`, `MANPAGER`, `LANG`/`LC_ALL`/`LC_CTYPE`, `HOMEBREW_NO_ANALYTICS`, `GPG_TTY`, `RUBY_CONFIGURE_OPTS`, the `HIST*` family, `AIRMAIL_MCP_*`. It must **not** source `~/.env.local` any more — Task 7 does that.

- [ ] **Step 1: Move the file so history follows**

```bash
mkdir -p shell && git mv .exports shell/exports.sh
```

- [ ] **Step 2: Replace its contents**

```sh
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
```

- [ ] **Step 3: Lint and check nothing sources .env.local twice**

Run:
```bash
shellcheck -S info shell/exports.sh && ! grep -q "env.local" shell/exports.sh && echo PASS
```
Expected: `PASS` (the only `env.local` mention left is in a comment — if
the grep fails on the comment, narrow it to `grep -q '^\[ -r .*env.local'`).

- [ ] **Step 4: Commit**

```bash
git add -A shell/exports.sh .exports
git commit -m "♻️ move .exports into shell/, drop the atom editor"
```

---

### Task 4: `shell/aliases.sh`

**Files:**
- Create: `shell/aliases.sh` (via `git mv .aliases shell/aliases.sh`, then edit)
- Delete: `.aliases`

**Interfaces:**
- Consumes: nothing. Role-specific aliases go to Task 6, not here.

- [ ] **Step 1: Move and rewrite**

```bash
git mv .aliases shell/aliases.sh
```

```sh
# shellcheck shell=bash
# shell/aliases.sh — was ~/.aliases until 2026-09-15.
# Role-independent only; GUI and kubeconfig aliases are in
# shell/role-workstation.sh.

# Easier navigation: .., ..., ~ and -
alias ..="cd .."
alias cd..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ~="cd ~"
alias -- -="cd -"

alias ls='ls -AGl'
alias tree='tree -CA'

# IP addresses. en0 since 2026-09-15: these targeted en1, which has had no
# address on either machine — en0 is the live interface.
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias localip="ipconfig getifaddr en0"
alias ips="ifconfig -a | perl -nle'/(\d+\.\d+\.\d+\.\d+)/ && print \$1'"

alias whois="whois -h whois-servers.net"

# Flush the DNS cache. dscacheutil alone stopped being enough years ago:
# mDNSResponder keeps its own cache (second half added 2026-09-15).
alias flush="dscacheutil -flushcache && sudo killall -HUP mDNSResponder"

alias trimcopy="tr -d '\n' | pbcopy"
alias cleanup="find . -name '*.DS_Store' -type f -ls -delete"
alias fs="stat -f \"%z bytes\""
alias emptytrash="sudo rm -rfv /Volumes/*/.Trashes; rm -rfv ~/.Trash"

# Reload the shell (i.e. invoke as a login shell)
alias reload="exec \$SHELL -l"

# Laravel. Kept although php/composer are absent (2026-09-15): it resolves
# vendor/bin/sail inside a project, so it costs nothing until one exists.
alias sail='[ -f sail ] && bash sail || bash vendor/bin/sail'

# Removed 2026-09-15, each verified absent or broken on the machine:
#   find=gfind          findutils is not installed and install-deps.sh never
#                       installed it, so this alias made `find` unusable.
#   sniff, httpdump     ngrep absent, and both listened on en1 (no address).
#   ftp_server_*        /System/Library/LaunchDaemons/ftp.plist no longer
#                       ships with macOS.
#   postgresql_server_*, redis_*
#                       no such plist present; `brew services` is the way.
#   undopush            `git push -f origin HEAD^:master` — a force-push with
#                       the branch hardcoded.
#   md5sum              a commented-out line that had never run.
```

- [ ] **Step 2: Lint**

Run: `shellcheck -S info shell/aliases.sh`
Expected: no output.

- [ ] **Step 3: Check the escaping survived**

`ips` and `reload` contain `$1` and `$SHELL` that must reach the alias
body unexpanded.

Run:
```bash
env -i HOME="$HOME" PATH=/usr/bin:/bin /bin/bash -ic '. shell/aliases.sh; alias ips reload' 2>/dev/null
```
Expected: `ips` still shows `print $1` and `reload` still shows `exec $SHELL -l`,
not an expanded value or an empty string.

- [ ] **Step 4: Commit**

```bash
git add -A shell/aliases.sh .aliases
git commit -m "🔥 drop the aliases whose tools are gone, move the rest to shell/"
```

---

### Task 5: `shell/functions.sh`

**Files:**
- Create: `shell/functions.sh` (via `git mv .functions shell/functions.sh`, then edit)
- Delete: `.functions`

- [ ] **Step 1: Move and rewrite**

```bash
git mv .functions shell/functions.sh
```

```sh
# shellcheck shell=bash
# shell/functions.sh — was ~/.functions until 2026-09-15. Until then it was
# sourced by bash only; zsh never loaded it, which is the drift this move
# closes.

# Start an HTTP server from a directory, optionally specifying the port.
# python3 since 2026-09-15: the body used SimpleHTTPServer, a Python 2
# module, and `python` no longer exists on macOS. The old version also
# forced Content-Type text/plain and a UTF-8 charset on every file;
# http.server guesses from the extension instead, which is more correct.
server() {
	local port="${1:-8000}"
	open "http://localhost:${port}/"
	python3 -m http.server "$port"
}

# Copy with a progress bar
cp_p() {
	rsync -WavP --human-readable --progress "$1" "$2"
}

# Extract archives - use: extract <file>
# Credits to http://dotfiles.org/~pseup/.bashrc
# Quoting added 2026-09-15 (SC2086): every path with a space used to fail.
extract() {
	if [ -f "$1" ] ; then
		case "$1" in
			*.tar.bz2) tar xjf "$1" ;;
			*.tar.gz) tar xzf "$1" ;;
			*.bz2) bunzip2 "$1" ;;
			*.rar) rar x "$1" ;;
			*.gz) gunzip "$1" ;;
			*.tar) tar xf "$1" ;;
			*.tbz2) tar xjf "$1" ;;
			*.tgz) tar xzf "$1" ;;
			*.zip) unzip "$1" ;;
			*.Z) uncompress "$1" ;;
			*.7z) 7z x "$1" ;;
			*) echo "'$1' cannot be extracted via extract()" ;;
		esac
	else
		echo "'$1' is not a valid file"
	fi
}

# Animated gifs from any video
# from alex sexton   gist.github.com/SlexAxton/4989674
# `magick` since 2026-09-15: ImageMagick 7 deprecated the `convert` name.
gifify() {
	if [ -z "$1" ]; then
		echo "proper usage: gifify <input_movie.mov>. You DO need to include extension."
		return 1
	fi
	if [ "$2" = "--good" ]; then
		ffmpeg -i "$1" -r 10 -vcodec png out-static-%05d.png
		magick -verbose +dither -layers Optimize -resize '600x600>' out-static*.png GIF:- \
			| gifsicle --colors 128 --delay=5 --loop --optimize=3 --multifile - > "$1.gif"
		rm out-static*.png
	else
		ffmpeg -i "$1" -s 600x400 -pix_fmt rgb24 -r 10 -f gif - \
			| gifsicle --optimize=3 --delay=3 > "$1.gif"
	fi
}
```

- [ ] **Step 2: Lint**

Run: `shellcheck -S info shell/functions.sh`
Expected: no output. In particular no SC2086 — that was the point.

- [ ] **Step 3: Test the two behaviours that actually changed**

```bash
env -i HOME="$HOME" PATH="$PATH" /bin/bash -c '
  . shell/functions.sh
  gifify > /tmp/gifify.out 2>&1; rc=$?
  grep -q "proper usage" /tmp/gifify.out && [ $rc -eq 1 ] || { echo "FAIL: gifify guard"; exit 1; }
  echo PASS
'
# Regression test for the quoting fix, kept separate to avoid nested quoting.
d=$(mktemp -d)
touch "$d/a file.txt"
( cd "$d" && zip -q q.zip "a file.txt" && rm "a file.txt" )
env -i HOME="$HOME" PATH="$PATH" FN="$PWD/shell/functions.sh" D="$d" /bin/bash -c '
  . "$FN"; cd "$D" && extract q.zip'
[ -f "$d/a file.txt" ] && echo "PASS: extract handles spaces" || echo "FAIL: extract on a path with a space"
rm -rf "$d"
```
Expected: `PASS`. The second half is the regression test for the quoting
fix — it fails on the pre-refactor version.

- [ ] **Step 4: Commit**

```bash
git add -A shell/functions.sh .functions
git commit -m "♻️ move .functions to shell/ and quote every expansion"
```

---

### Task 6: Role fragments

**Files:**
- Create: `shell/role-workstation.sh`, `shell/role-server.sh`

**Interfaces:**
- Consumes: `path_append` from Task 2. **Never `path_prepend`** — `path.sh` owns the head of `PATH` and the shims-first guarantee.

- [ ] **Step 1: Write `shell/role-workstation.sh`**

```sh
# shellcheck shell=bash
# shell/role-workstation.sh — loaded by shell/index.sh when MACHINE_ROLE is
# "workstation" (the MacBook Pro). Everything here is GUI-bound or
# machine-specific and has no business on the headless Mac mini.
#
# PATH additions MUST use path_append: shell/path.sh owns the head of PATH,
# including the asdf-shims-first guarantee. Prepending here would break it.

# Sublime Text. The alias said "sublime" until 2026-09-15; the binary
# Homebrew actually installs is `subl`.
command -v subl >/dev/null 2>&1 && alias stt="subl"

# colorls is declared by install-deps.sh's Ruby section but was missing from
# the asdf Ruby 3.3.5 on 2026-09-15. Guarded so the alias simply does not
# exist rather than failing when called, and reappears once the gem is back.
command -v colorls >/dev/null 2>&1 && alias lc='colorls -lA --sd'

# Hide/show all desktop icons (useful when presenting)
alias hidedesktop="defaults write com.apple.finder CreateDesktop -bool false && killall Finder"
alias showdesktop="defaults write com.apple.finder CreateDesktop -bool true && killall Finder"

# Hide/show hidden files. The trailing
# "/System/Library/CoreServices/Finder.app" the old aliases passed to
# killall was read as a second process *name*, never matched anything, and
# only made killall exit non-zero — dropped 2026-09-15.
alias showFiles='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder'
alias hideFiles='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder'

# Kubernetes contexts (were inline in .zshrc, so bash never had them)
alias k8s-scaleway="export KUBECONFIG=$HOME/.kube/config_scaleway"
alias k8s-staging="export KUBECONFIG=$HOME/Documents_non_icloud/workspace_devops/k8s-productivity/environments/staging/kubeconfig-k8s-productivity.yaml"

# Docker Desktop and Antigravity ship CLIs outside Homebrew. Both were
# hardcoded as /Users/maxime-lenne/... until 2026-09-15.
[ -d "$HOME/.docker/bin" ] && path_append "$HOME/.docker/bin"
[ -d "$HOME/.antigravity/antigravity/bin" ] && path_append "$HOME/.antigravity/antigravity/bin"
export PATH
```

- [ ] **Step 2: Write `shell/role-server.sh`**

```sh
# shellcheck shell=bash
# shell/role-server.sh — loaded by shell/index.sh when MACHINE_ROLE is
# "server" (the Mac mini).
#
# Deliberately almost empty. It exists so index.sh can source
# "role-$MACHINE_ROLE.sh" without a conditional, and so there is an obvious
# home for the first headless-only need that shows up (colima helpers,
# remote administration shortcuts). Do not delete it for being empty.
:
```

- [ ] **Step 3: Lint both**

Run: `shellcheck -S info shell/role-workstation.sh shell/role-server.sh`
Expected: no output.

- [ ] **Step 4: Verify no role fragment prepends to PATH**

Run: `! grep -n "path_prepend" shell/role-*.sh && echo PASS`
Expected: `PASS`.

- [ ] **Step 5: Commit**

```bash
git add shell/role-workstation.sh shell/role-server.sh
git commit -m "✨ split the GUI-bound shell config into a workstation role"
```

---

### Task 7: `shell/index.sh`, the loader

**Files:**
- Create: `shell/index.sh`

**Interfaces:**
- Consumes: every fragment from Tasks 2-6.
- Produces: `MACHINE_ROLE` (exported), and the guarantee that `~/.env.local` is sourced last.

- [ ] **Step 1: Write the file**

```sh
# shellcheck shell=bash
# shell/index.sh — the one file that decides what a shell loads, and in
# which order. Sourced by both .zshrc and .bashrc.
#
# It exists because those two used to each source their own subset: zsh
# pulled .aliases twice and .functions never, bash pulled all three, and
# GPG_TTY, the asdf shims and the terraform completion were declared in
# both with no one keeping them in step. Add a fragment HERE, once.
#
# Constraint: bash 3.2 and zsh both read this file. No arrays (0-indexed in
# bash, 1-indexed in zsh), no [[ ]], no bashisms, no zshisms.

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"

if [ ! -d "$DOTFILES/shell" ]; then
  echo "dotfiles: $DOTFILES/shell not found — shell configuration not loaded" >&2
  return 0
fi

# Machine role. Same rule as detect_machine_role() in dotfiles-lib.sh, and
# deliberately NOT sourced from it: that file runs tput at load time and
# drops BOLD/GREEN/RESET (a direct collision with shell/bash-prompt.sh)
# plus section/explain/warn/ask into the interactive namespace. The two
# copies must be kept in step — dotfiles-lib.sh carries the matching note.
if [ -z "${MACHINE_ROLE:-}" ]; then
  case "$(hostname | tr '[:upper:]' '[:lower:]')" in
    *mac-mini*|*macmini*) MACHINE_ROLE="server" ;;
    *) MACHINE_ROLE="workstation" ;;
  esac
fi
export MACHINE_ROLE

# Order matters: path first so everything below can find its binaries,
# role last so a machine can override the shared defaults.
for _dotfiles_fragment in path exports aliases functions "role-$MACHINE_ROLE"; do
  if [ -r "$DOTFILES/shell/$_dotfiles_fragment.sh" ]; then
    . "$DOTFILES/shell/$_dotfiles_fragment.sh"
  fi
done
unset _dotfiles_fragment

# Machine-local secrets, LAST so they override anything declared above —
# including the role fragment. Moved here from the end of .exports on
# 2026-09-15: left there, the role fragment loaded afterwards and silently
# broke that guarantee.
#
# ~/.env.local is a symlink to .env at the root of this repo, which
# .gitignore keeps out of every commit. configure_dotfiles.sh seeds it from
# .env.example and links it.
if [ -r "$HOME/.env.local" ]; then
  . "$HOME/.env.local"
fi
```

- [ ] **Step 2: Lint**

Run: `shellcheck -S info shell/index.sh`
Expected: no output. `return 0` outside a function is correct in a sourced
file; if shellcheck flags SC2317 or similar, restructure with an `else`
branch rather than adding a disable comment (the repo forbids those).

- [ ] **Step 3: Test both roles load, in both shells**

```bash
for s in bash zsh; do
  for role in workstation server; do
    out=$(env MACHINE_ROLE=$role DOTFILES="$PWD" HOME="$HOME" "/bin/$s" -c '
      . "$DOTFILES/shell/index.sh"; echo "$MACHINE_ROLE"; command -v extract >/dev/null && echo has-functions')
    echo "$s/$role: $out"
  done
done
```
Expected: four lines, each printing the requested role followed by
`has-functions`. `has-functions` on the zsh lines is the proof that the
old "zsh never sourced .functions" drift is gone.

- [ ] **Step 4: Test that ~/.env.local wins over the role fragment**

```bash
d=$(mktemp -d); echo 'export AIRMAIL_MCP_PORT=1111' > "$d/.env.local"
env HOME="$d" DOTFILES="$PWD" /bin/bash -c '. "$DOTFILES/shell/index.sh"; echo "$AIRMAIL_MCP_PORT"'
rm -rf "$d"
```
Expected: `1111`, not `9876`.

- [ ] **Step 5: Commit**

```bash
git add shell/index.sh
git commit -m "✨ add the single loader both shells source"
```

---

### Task 8: `.zshrc`

**Files:**
- Modify: `.zshrc` (full rewrite)

- [ ] **Step 1: Rewrite**

```sh
ZSH=$HOME/.oh-my-zsh
ZSH_CUSTOM="${DOTFILES:-$HOME/.dotfiles}/custom"

# You can change the theme with another one:
#   https://github.com/robbyrussell/oh-my-zsh/wiki/themes
ZSH_THEME="baboriginal"

plugins=(gitfast last-working-dir common-aliases sublime zsh-syntax-highlighting history-substring-search elixir aterminal history zsh-autosuggestions)

# oh-my-zsh FIRST, so that everything shell/ declares below wins over the
# plugin defaults rather than the other way round.
source "${ZSH}/oh-my-zsh.sh"

# Everything shared with bash: PATH, exports, aliases, functions, the role
# fragment and ~/.env.local. See shell/index.sh for the order.
. "${DOTFILES:-$HOME/.dotfiles}/shell/index.sh"

# AFTER index.sh: undoes the interactive `rm -i` that oh-my-zsh's
# common-aliases plugin installs. Run any earlier and the plugin would just
# put it back.
unalias rm 2>/dev/null

# zsh equivalents of the bash-only HISTCONTROL/HISTIGNORE set in
# shell/exports.sh, so history behaves the same in both shells.
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# --- Completions (zsh-specific; the bash halves live in .bashrc) ---

if command -v brew >/dev/null 2>&1; then
  fpath=("$(brew --prefix asdf)/share/zsh/site-functions" $fpath)
fi

# Docker Desktop's completions, workstation only — the Mac mini runs colima.
if [ "${MACHINE_ROLE:-}" = "workstation" ] && [ -d "$HOME/.docker/completions" ]; then
  fpath=("$HOME/.docker/completions" $fpath)
fi

autoload -Uz compinit
compinit

# terraform ships a bash-style completion; bashcompinit adapts it.
if command -v terraform >/dev/null 2>&1; then
  autoload -U +X bashcompinit && bashcompinit
  complete -o nospace -C "$(command -v terraform)" terraform
fi

command -v scw >/dev/null 2>&1 && eval "$(scw autocomplete script shell=zsh)"

[ -r "$HOME/.oh-my-zsh/completions/_bun" ] && source "$HOME/.oh-my-zsh/completions/_bun"
```

- [ ] **Step 2: Fingerprint and diff against the baseline**

Run:
```bash
"$SCRATCH/fingerprint.sh" zsh "$PWD" > "$SCRATCH/after-zsh.txt"
diff "$SCRATCH/before-zsh.txt" "$SCRATCH/after-zsh.txt"
```
Expected, and **nothing else**:
- gone: `find`, `lc`, `sniff`, `httpdump`, `undopush`, `ftp_server_start`, `ftp_server_stop`, `postgresql_server_start`, `postgresql_server_stop`, `redis_start`, `redis_stop`, `md5sum`
- changed: `localip` (en1 → en0), `flush` (gains `killall -HUP mDNSResponder`), `stt` (sublime → subl), `BUNDLER_EDITOR` (atom → vim), and `ips` — it reads `print ''` today because the unescaped `$1` was consumed as the sourcing file's empty positional parameter, so perl printed whole `ifconfig` lines instead of the captured address; it now reads `print $1`
- added: `cp_p`, `extract`, `gifify`, `server` under `### FUNCTIONS` — zsh never had them
- `### PATH`: no duplicates left, libxml2/libxslt/libiconv and heroku gone
Any other line is a regression. Investigate before continuing.

- [ ] **Step 3: Verify `rm` is not interactive and the binstubs still win**

```bash
"$SCRATCH/fingerprint.sh" zsh "$PWD" | grep -E "^rm=" && echo "FAIL: rm is aliased"
"$SCRATCH/fingerprint.sh" zsh "$PWD" | sed -n '/### PATH/,$p' | sed -n '2,3p'
```
Expected: no `FAIL` line; the two PATH lines printed are `./bin` and
`./node_modules/.bin`.

- [ ] **Step 4: Commit**

```bash
git add .zshrc
git commit -m "♻️ reduce .zshrc to what is genuinely zsh"
```

---

### Task 9: `.bashrc`, `.bash_profile`, `shell/bash-prompt.sh`

**Files:**
- Create: `shell/bash-prompt.sh` (via `git mv .bash_prompt shell/bash-prompt.sh`)
- Modify: `.bashrc` (full rewrite), `.bash_profile` (full rewrite)
- Delete: `.bash_prompt`

- [ ] **Step 1: Move the prompt, unchanged**

```bash
git mv .bash_prompt shell/bash-prompt.sh
```
Change nothing inside it. It is vendored-ish third-party code (gf3's Sexy
Bash Prompt) and rewriting it is not in scope. Add only a two-line header
comment noting the 2026-09-15 move and that `.bashrc` — not the shared
loader — sources it, because it sets `PS1` and is bash-only.

- [ ] **Step 2: Write `.bash_profile`**

```sh
# bash does not read ~/.bashrc in a login shell, and Terminal.app and ssh
# both start one — verified 2026-09-15:
#   bash -li -> .bash_profile only
#   bash -i  -> .bashrc only
#   zsh  -li -> .zshrc
# zsh has no such split, which is why it gets a single .zshrc. So bash gets
# one real file too, .bashrc, and this exists only to reach it.
#
# This also reverses the previous arrangement, where .bashrc sourced
# .bash_profile — the inverse of the convention, and the reason the asdf
# shims had to be re-declared in .bashrc to land after it.
[ -r "$HOME/.bashrc" ] && . "$HOME/.bashrc"
```

- [ ] **Step 3: Write `.bashrc`**

```sh
# The one real bash file. ~/.bash_profile is a stub that sources this, so
# login and non-login interactive shells both end up here.

# Everything shared with zsh: PATH, exports, aliases, functions, the role
# fragment and ~/.env.local. See shell/index.sh for the order.
#
# This sits ABOVE the interactive guard on purpose. .bash_profile is read by
# every login shell, interactive or not, and used to set PATH unconditionally
# — verified 2026-09-15: `HOME=<sandbox> bash -lc` sees the asdf shims today.
# Now that .bash_profile only delegates here, guarding this line would drop
# PATH, exports, aliases and functions for `bash -lc`. The fingerprint harness
# runs -lic and would never catch it.
. "${DOTFILES:-$HOME/.dotfiles}/shell/index.sh"

# Nothing below is useful to a non-interactive shell: a prompt it never
# renders, completions it never offers.
case $- in
  *i*) ;;
  *) return ;;
esac

# PS1. bash-only, so it is not in the shared loader.
. "${DOTFILES:-$HOME/.dotfiles}/shell/bash-prompt.sh"

# --- Completions (bash-specific; the zsh halves live in .zshrc) ---

if command -v brew >/dev/null 2>&1; then
  brew_prefix="$(brew --prefix)"
  [ -r "$brew_prefix/etc/bash_completion" ] && . "$brew_prefix/etc/bash_completion"
  [ -r "$brew_prefix/etc/bash_completion.d/git-completion.bash" ] && \
    . "$brew_prefix/etc/bash_completion.d/git-completion.bash"
  unset brew_prefix
fi

command -v terraform >/dev/null 2>&1 && complete -C "$(command -v terraform)" terraform
command -v asdf >/dev/null 2>&1 && . <(asdf completion bash)
command -v scw >/dev/null 2>&1 && eval "$(scw autocomplete script shell=bash)"
```

- [ ] **Step 4: Verify the login/non-login split still resolves**

```bash
d=$(mktemp -d)
ln -s "$PWD/.bashrc" "$d/.bashrc"; ln -s "$PWD/.bash_profile" "$d/.bash_profile"
for flags in -lic -ic; do
  printf '%s: ' "$flags"
  env HOME="$d" DOTFILES="$PWD" /bin/bash "$flags" 'command -v extract >/dev/null && echo ok || echo BROKEN'
done
rm -rf "$d"
```
Expected: two `ok` lines. A missing one means the stub chain is broken —
that is precisely the failure this design exists to prevent.

- [ ] **Step 5a: Verify `bash -lc` still gets PATH**

The harness runs `-lic`, so it cannot catch this regression. Test it directly.

```bash
d=$(mktemp -d)
ln -s "$PWD/.bashrc" "$d/.bashrc"; ln -s "$PWD/.bash_profile" "$d/.bash_profile"
HOME="$d" DOTFILES="$PWD" /bin/bash -lc 'case ":$PATH:" in *asdf/shims*) echo PASS;; *) echo "FAIL: bash -lc lost PATH";; esac'
rm -rf "$d"
```
Expected: `PASS`. This matches today's behaviour, measured before the
refactor — `.bash_profile` used to set PATH unconditionally for every login
shell, interactive or not.

- [ ] **Step 5: Fingerprint and diff**

Run:
```bash
"$SCRATCH/fingerprint.sh" bash "$PWD" > "$SCRATCH/after-bash.txt"
diff "$SCRATCH/before-bash.txt" "$SCRATCH/after-bash.txt"
```
Expected: the same removals and fixes as Task 8 (`ips` included), plus these **additions**
that bash never had: `HOMEBREW_NO_ANALYTICS`, `LANG`, `LC_ALL`, `LC_CTYPE`,
`RUBY_CONFIGURE_OPTS`, and the `k8s-scaleway` / `k8s-staging` aliases.
Nothing else.

- [ ] **Step 6: Lint everything**

Run: `shellcheck -S info shell/*.sh`
Expected: no output. `.bashrc`, `.bash_profile` and `.zshrc` are not linted
— they have no shebang, and `.claude/hooks/shellcheck-on-write.sh` skips
them deliberately.

- [ ] **Step 7: Commit**

```bash
git add -A .bashrc .bash_profile shell/bash-prompt.sh .bash_prompt
git commit -m "♻️ make .bashrc the single bash file, .bash_profile a stub"
```

---

### Task 10: `configure_dotfiles.sh`

**Files:**
- Modify: `configure_dotfiles.sh:1-11`

- [ ] **Step 1: Replace the symlink loop**

The list loses `.aliases`, `.exports`, `.functions` and `.bash_prompt`, and
the loop stops clobbering.

```sh
#!/bin/bash

# Symlink each dotfile into the home directory.
#
# The list shrank on 2026-09-15: .aliases, .exports, .functions and
# .bash_prompt moved into shell/, which .zshrc and .bashrc reach through
# shell/index.sh. $HOME keeps three shell files instead of nine.

DOTFILES_DIR="$PWD"

# Symlinks this script used to create and no longer should. Left in place
# they would dangle, since their targets no longer exist in the repo.
# Only removed when they really are OUR symlink: a real file means a
# machine that was never set up this way, and it is not ours to delete.
for name in .aliases .exports .functions .bash_prompt; do
  link="$HOME/$name"
  if [ -L "$link" ] && [ ! -e "$link" ]; then
    echo "-----> Removing the now-dangling $link"
    rm "$link"
  elif [ -L "$link" ] && case "$(readlink "$link")" in "$DOTFILES_DIR"/*) true ;; *) false ;; esac; then
    echo "-----> Removing $link (moved into shell/)"
    rm "$link"
  elif [ -e "$link" ]; then
    echo "-----> Leaving $link alone: a real file, not one of ours"
  fi
done

for name in .bashrc .bash_profile .zshrc .gitconfig .gitignore_global; do
  source="$DOTFILES_DIR/$name"
  target="$HOME/$name"

  # Idempotent since 2026-09-15 (the TODO this file used to carry): an
  # unconditional `mv` errored when the target did not exist yet and
  # overwrote the previous backup on every re-run. This change forces a
  # re-run on both machines, so it had to be fixed first.
  if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
    echo "-----> $target already points at $source"
    continue
  fi
  if [ -e "$target" ] || [ -L "$target" ]; then
    backup="$target.backup.$(date +%Y%m%d%H%M%S)"
    echo "-----> Backing up $target to $backup"
    mv "$target" "$backup"
  fi
  echo "-----> Symlinking $source to $target"
  ln -s "$source" "$target"
done
```

Leave the rest of the file (the `.env` / `~/.env.local` block and the
`core.hooksPath` line) untouched, except for one comment fix: the `.env`
block says "which is what `.exports` sources" — it is `shell/index.sh` now.

- [ ] **Step 2: Lint**

Run: `shellcheck -S info configure_dotfiles.sh`
Expected: no output.

- [ ] **Step 3: Test against a fake HOME, twice**

Never against the real `$HOME`.

```bash
d=$(mktemp -d)
ln -s "$PWD/.aliases_gone" "$d/.aliases"        # a dangling link of ours
echo "real" > "$d/.gitconfig"                    # a real file to back up
env HOME="$d" ./configure_dotfiles.sh > "$d/run1.log" 2>&1
env HOME="$d" ./configure_dotfiles.sh > "$d/run2.log" 2>&1
[ ! -e "$d/.aliases" ] || echo "FAIL: dangling link left behind"
ls "$d"/.gitconfig.backup.* >/dev/null 2>&1 || echo "FAIL: no backup taken"
[ "$(ls "$d"/.gitconfig.backup.* | wc -l)" -eq 1 ] || echo "FAIL: second run took a second backup"
grep -q "already points at" "$d/run2.log" || echo "FAIL: second run was not a no-op"
echo done; rm -rf "$d"
```
Expected: `done` with no `FAIL` line.

- [ ] **Step 4: Commit**

```bash
git add configure_dotfiles.sh
git commit -m "🐛 make configure_dotfiles.sh idempotent and clean stale links"
```

---

### Task 11: Documentation, and applying it to this machine

**Files:**
- Modify: `README.md`, `CLAUDE.md`, `docs/TASKs.md`, `dotfiles-lib.sh`

- [ ] **Step 1: `CLAUDE.md` — replace the "two divergent entry points" section**

That section is now false. Replace it with:

```markdown
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
```

Also amend the `PATH` hard constraint, which currently reads as absolute:

```markdown
- **asdf shims must stay first on `PATH`** among *absolute* directories
  (`shell/path.sh` guarantees it). The one deliberate exception is
  `./bin:./node_modules/.bin`, which sit ahead of them so a bare `rails`
  finds the project's binstub — that binstub delegates to bundler and so to
  the asdf Ruby, so the constraint's intent holds. Don't "fix" it.
```

- [ ] **Step 2: `README.md` — rewrite the shell configuration section**

Replace the description of the two entry points with the `shell/` layout
table from this plan's File Structure section, and fix the `~/.env.local`
paragraph: it is sourced by `shell/index.sh`, last, not by `.exports`.

- [ ] **Step 3: `dotfiles-lib.sh` — add the cross-reference**

Above `detect_machine_role()`, add:

```sh
# NOTE: shell/index.sh carries a deliberate copy of this rule for the
# interactive shells, which cannot source this file (it runs tput at load
# time and exports BOLD/GREEN/RESET, colliding with shell/bash-prompt.sh).
# Change one, change the other.
```

- [ ] **Step 4: `docs/TASKs.md` — close one task, open another**

Mark the refactor task done, dated 2026-09-15, naming the spec and this
plan. Then add the finding this work surfaced but did not fix:

```markdown
- Dérive Ruby : `install-deps.sh` installe `bundler`, `rails`, `jekyll` et
  `colorls`, mais seuls `bundler` et `jekyll` sont présents dans le Ruby
  3.3.5 d'asdf (constaté le 2026-09-15). Conséquence visible : `rails` hors
  d'un projet tombe sur `/usr/bin/rails`, le stub Apple en `#!/usr/bin/ruby`,
  et l'alias `lc` reste inactif. Relancer la section Ruby d'`install-deps.sh`
  puis `asdf reshim ruby`.
```

Also mark the `configure_dotfiles.sh` backup task done — Task 10 fixed it.

- [ ] **Step 5: Full verification, both shells, both roles**

```bash
shellcheck -S info shell/*.sh configure_dotfiles.sh dotfiles-lib.sh
bash -n install-deps.sh
./clean-mac.sh --dry-run > /dev/null && echo "clean-mac ok"
for s in zsh bash; do
  "$SCRATCH/fingerprint.sh" "$s" "$PWD" > "$SCRATCH/final-$s.txt"
  echo "== $s =="; diff "$SCRATCH/before-$s.txt" "$SCRATCH/final-$s.txt"
done
```
Expected: no shellcheck output, `clean-mac ok`, and diffs containing only
the changes listed in Task 8 Step 2 and Task 9 Step 5.

- [ ] **Step 6: Commit the documentation**

```bash
git add README.md CLAUDE.md docs/TASKs.md dotfiles-lib.sh
git commit -m "📝 document the single shell loader, close the refactor task"
```

- [ ] **Step 7: Apply to this machine — ask first**

This is the only step that touches the real `$HOME`. **Stop and ask for
explicit confirmation before running it.**

```bash
./configure_dotfiles.sh
```
Then, in a **new** terminal window (not the current session, whose
environment is already loaded):
```bash
echo "$PATH" | tr ':' '\n' | head -4    # ./bin, ./node_modules/.bin, shims, ...
type extract >/dev/null && echo "functions ok"
alias | grep -c .                        # sanity
```
Expected: the `PATH` head as designed and `functions ok`. Leave the old
shell open until this passes — it is the way back if something is wrong.

- [ ] **Step 8: Clean up the worktree**

```bash
git worktree remove "$SCRATCH/before"
```

---

## Notes for the executor

- `git mv` before editing, every time. It keeps `git log --follow` working
  on files that carry years of history.
- If a fingerprint diff shows something not on the expected list, **stop**.
  It is a regression, not a surprise to accept.
- Do not add `# shellcheck disable` lines. The tracked scripts are at a
  green `-S info` baseline and the repo's convention is to keep them there.
- `custom/plugins/` is vendored. Never touch it.
