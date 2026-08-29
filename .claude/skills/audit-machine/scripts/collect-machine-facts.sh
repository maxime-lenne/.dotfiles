#!/bin/bash
#
# collect-machine-facts.sh — read-only inventory of the current Mac.
#
# Dumps everything docs/audit-<machine>.md needs, as one plain-text
# report on stdout with `===== SECTION =====` markers. Strictly
# read-only: it never installs, deletes, or reconfigures anything, so
# it is safe to run unattended and safe to re-run.
#
# Options:
#   --no-disk   skip the disk-usage section (the slow part: it walks
#               ~/Library/Caches and friends with du)
#   -h, --help  show this help
#
# Written for bash 3.2, the version macOS still ships at /bin/bash.

set -uo pipefail

WITH_DISK=true
for arg in "$@"; do
  case "$arg" in
    --no-disk) WITH_DISK=false ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  esac
done

section() { printf '\n===== %s =====\n' "$1"; }
have()    { command -v "$1" >/dev/null 2>&1; }

# Report a missing tool rather than emitting silence: "npm is not
# installed" and "npm has no global packages" are different findings,
# and the audit needs to tell them apart.
absent()  { echo "(not installed: $1)"; }

TMPDIR_FACTS="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_FACTS"' EXIT

# ------------------------------------------------------------------
section "IDENTITY"
# ------------------------------------------------------------------
echo "date:      $(date '+%Y-%m-%d %H:%M')"
echo "hostname:  $(scutil --get LocalHostName 2>/dev/null || hostname)"
echo "model:     $(sysctl -n hw.model 2>/dev/null)"
echo "chip:      $(sysctl -n machdep.cpu.brand_string 2>/dev/null)"
echo "memory:    $(( $(sysctl -n hw.memsize 2>/dev/null || echo 0) / 1073741824 )) GB"
sw_vers 2>/dev/null

# ------------------------------------------------------------------
section "HOMEBREW FORMULAE (installed on request)"
# ------------------------------------------------------------------
if have brew; then
  brew list --formula --installed-on-request 2>/dev/null | sort > "$TMPDIR_FACTS/req.txt"
  brew list --formula 2>/dev/null | sort > "$TMPDIR_FACTS/all.txt"
  echo "requested: $(wc -l < "$TMPDIR_FACTS/req.txt" | tr -d ' ')"
  echo "total:     $(wc -l < "$TMPDIR_FACTS/all.txt" | tr -d ' ') (the difference is transitive dependencies)"
  echo
  cat "$TMPDIR_FACTS/req.txt"

  section "HOMEBREW CASKS"
  brew list --cask 2>/dev/null | sort > "$TMPDIR_FACTS/casks.txt"
  echo "count: $(wc -l < "$TMPDIR_FACTS/casks.txt" | tr -d ' ')"
  echo
  cat "$TMPDIR_FACTS/casks.txt"

  # Tap formulae are a blind spot in Homebrew's own inventories: they
  # are absent from `brew list --installed-on-request` AND from
  # `brew info --json=v2 --installed`, while being perfectly real
  # binaries on PATH. That is how terraform, vault, k9s and supabase
  # vanished from the 2026-08-28 audit, which then read as if they had
  # been uninstalled. Recover them as a set difference against
  # `brew list --formula`, which does see them.
  section "HOMEBREW — INVISIBLE TO THE ON-REQUEST INVENTORY"
  if have python3; then
    brew info --json=v2 --installed 2>/dev/null \
      | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    data = {}
for f in data.get('formulae', []):
    print((f.get('full_name') or f.get('name')).split('/')[-1])
" | sort > "$TMPDIR_FACTS/json.txt"
    comm -23 "$TMPDIR_FACTS/all.txt" "$TMPDIR_FACTS/json.txt" > "$TMPDIR_FACTS/invisible.txt"
    if [ -s "$TMPDIR_FACTS/invisible.txt" ]; then
      echo "Installed and on PATH, but missing from both on-request inventories:"
      sed 's/^/  /' "$TMPDIR_FACTS/invisible.txt"
      echo "(add these to the requested count; they are real, deliberate installs)"
    else
      echo "(none)"
    fi
  else
    echo "(needs python3)"
  fi

  section "HOMEBREW OUTDATED"
  brew outdated 2>/dev/null || echo "(none)"

  section "HOMEBREW TAPS"
  brew tap 2>/dev/null
else
  section "HOMEBREW"
  absent brew
fi

# ------------------------------------------------------------------
section "MAC APP STORE"
# ------------------------------------------------------------------
if have mas; then
  mas list 2>/dev/null | sort -f || echo "(none)"
else
  absent mas
fi

# ------------------------------------------------------------------
# Cross-reference every installed .app against the three things that
# could legitimately own it (a cask, the App Store, Apple itself).
# What's left over is installed outside any package manager — the
# drift the audit exists to surface, and the reason this section is
# worth the extra machinery rather than eyeballing /Applications.
# ------------------------------------------------------------------
section "APPS BY PROVENANCE"
if have python3 && have brew; then
  brew info --json=v2 --installed > "$TMPDIR_FACTS/brewinfo.json" 2>/dev/null
  mas list 2>/dev/null > "$TMPDIR_FACTS/mas.txt" || : > "$TMPDIR_FACTS/mas.txt"
  system_profiler -json SPApplicationsDataType > "$TMPDIR_FACTS/apps.json" 2>/dev/null

  python3 - "$TMPDIR_FACTS" <<'PY'
import json, os, sys, re

tmp = sys.argv[1]

def load(name):
    p = os.path.join(tmp, name)
    try:
        with open(p) as f:
            return json.load(f)
    except Exception:
        return None

brewinfo = load("brewinfo.json") or {}
apps = load("apps.json") or {}

def norm(s):
    """Squash a token or app name to letters and digits, so that
    'fuse-t' and 'fuse-t.app' compare equal."""
    return re.sub(r"[^a-z0-9]", "", s.lower().replace(".app", ""))


def walk_app_paths(node):
    """Yield every string ending in .app anywhere inside an artifact.

    Casks come in two shapes. Copy-install casks declare `app: [...]`,
    which is authoritative. Pkg-install casks (zoom, microsoft-teams,
    fuse-t...) declare no app at all — they run an installer — but
    their `uninstall`/`zap` stanzas name the paths they will delete,
    which is the only machine-readable trace of what they own. Missing
    that second shape made this script report pkg-based casks as
    manual installs, i.e. accuse the user of installing Teams twice."""
    if isinstance(node, str):
        if node.endswith(".app"):
            yield node
    elif isinstance(node, dict):
        for v in node.values():
            for r in walk_app_paths(v):
                yield r
    elif isinstance(node, list):
        for v in node:
            for r in walk_app_paths(v):
                yield r


# .app basenames a cask owns, mapped back to its token.
cask_apps = {}
cask_tokens_norm = {}
ghost = []
for cask in brewinfo.get("casks", []):
    token = cask.get("token", "?")
    artifacts = cask.get("artifacts", []) or []
    cask_tokens_norm[norm(token)] = token

    # Authoritative: what a copy-install cask puts in /Applications.
    declared = []
    for art in artifacts:
        if isinstance(art, dict):
            for name in art.get("app", []) or []:
                if isinstance(name, str):
                    declared.append(name)

    # Best-effort: paths named anywhere in the artifact stanzas.
    for name in list(declared) + list(walk_app_paths(artifacts)):
        cask_apps[os.path.basename(name).lower()] = token

    # Only a *declared* app can be missing: a pkg cask never promised
    # a path in /Applications, so its silence isn't evidence of a
    # ghost. Ghost = registered in brew, app deliberately deleted —
    # it pollutes `brew outdated` and a later `brew upgrade` will
    # happily reinstall it.
    if declared and not any(
        os.path.exists(os.path.join(d, os.path.basename(n)))
        for n in declared
        for d in ("/Applications", os.path.expanduser("~/Applications"))
    ):
        ghost.append((token, ", ".join(os.path.basename(n) for n in declared)))

mas_names = set()
with open(os.path.join(tmp, "mas.txt")) as f:
    for line in f:
        m = re.match(r"^\d+\s+(.*?)\s+\(", line.strip())
        if m:
            mas_names.add(m.group(1).strip().lower())

manual, by_cask, by_mas, by_apple = [], [], [], []
for app in apps.get("SPApplicationsDataType", []) or []:
    name = app.get("_name", "")
    path = app.get("path", "")
    src = app.get("obtained_from", "")
    version = app.get("version", "")
    # Only user-facing app directories: system frameworks and the
    # hundreds of bundled Apple helpers are noise here.
    if not (path.startswith("/Applications/") or path.startswith(os.path.expanduser("~/Applications/"))):
        continue
    # Helpers bundled *inside* another app (Google Drive's FinderHelper,
    # an updater tucked into Contents/) ship and uninstall with their
    # parent. Listing them as separate manual installs is noise.
    if ".app/" in os.path.dirname(path):
        continue
    base = os.path.basename(path).lower()
    entry = "%s (%s) — %s" % (name, version or "?", path)
    if src == "apple":
        by_apple.append(entry)
    elif base in cask_apps:
        by_cask.append("%s [cask: %s]" % (entry, cask_apps[base]))
    elif norm(base) in cask_tokens_norm:
        # Last resort for pkg casks that name no path at all: the app
        # is called what the cask is called (fuse-t → fuse-t.app).
        by_cask.append("%s [cask: %s, matched by name]" % (entry, cask_tokens_norm[norm(base)]))
    elif src == "mac_app_store" or name.strip().lower() in mas_names:
        by_mas.append(entry)
    else:
        manual.append("%s [obtained_from: %s]" % (entry, src or "unknown"))

def dump(title, rows):
    print("\n--- %s (%d) ---" % (title, len(rows)))
    for r in sorted(rows, key=str.lower):
        print("  " + r)

dump("INSTALLED MANUALLY — outside any package manager", manual)
dump("GHOST CASKS — registered in brew, app missing on disk", ["%s → %s" % g for g in ghost])
print("\n--- owned by a cask: %d, from the App Store: %d, shipped by Apple: %d ---"
      % (len(by_cask), len(by_mas), len(by_apple)))
PY
else
  echo "(needs python3 and brew; falling back to a raw listing)"
  ls -1 /Applications ~/Applications 2>/dev/null
fi

# ------------------------------------------------------------------
section "LANGUAGE-LEVEL GLOBAL INSTALLS"
# ------------------------------------------------------------------
echo "--- asdf ---"
if have asdf; then
  asdf --version 2>/dev/null
  asdf plugin list 2>/dev/null || echo "(no plugins)"
  asdf list 2>/dev/null
  [ -f "$HOME/.tool-versions" ] && { echo "$HOME/.tool-versions:"; sed 's/^/  /' "$HOME/.tool-versions"; }
else
  absent asdf
fi

echo "--- uv ---"
if have uv; then
  uv --version 2>/dev/null
  uv python list --only-installed 2>/dev/null
  echo "uv tools:"; uv tool list 2>/dev/null || echo "  (none)"
else
  absent uv
fi

echo "--- bun ---"
if have bun; then
  echo "bun $(bun --version 2>/dev/null)"
  bun pm ls -g 2>/dev/null || echo "  (no global packages)"
else
  absent bun
fi

echo "--- npm / pnpm / yarn ---"
if have npm; then npm ls -g --depth=0 2>/dev/null; else absent npm; fi
if have pnpm; then pnpm ls -g --depth=0 2>/dev/null; else absent pnpm; fi
if have yarn; then yarn global list 2>/dev/null; else absent yarn; fi

echo "--- ruby / gem ---"
if have ruby; then echo "ruby: $(ruby -v 2>/dev/null) [$(command -v ruby)]"; else absent ruby; fi
if have gem; then gem list --local --no-versions 2>/dev/null | head -40; else absent gem; fi

echo "--- other language managers ---"
for tool in cargo go pipx composer; do
  if have "$tool"; then echo "$tool: present ($(command -v "$tool"))"; else absent "$tool"; fi
done

# The declared stack is asdf/uv/bun; these three were retired on
# 2026-08-28. Anything found here is either a machine that never went
# through the migration or an installer that silently put one back.
echo "--- legacy version managers (should all be absent) ---"
for d in "$HOME/.nvm" "$HOME/.pyenv" "$HOME/.rvm"; do
  if [ -d "$d" ]; then echo "PRESENT: $d"; else echo "absent:  $d"; fi
done

# ------------------------------------------------------------------
section "BACKGROUND SERVICES"
# ------------------------------------------------------------------
if have brew; then brew services list 2>/dev/null || echo "(none)"; else absent brew; fi

# ------------------------------------------------------------------
section "DISK USAGE"
# ------------------------------------------------------------------
if $WITH_DISK; then
  # Under APFS, `/` is the sealed system volume and reports ~12 GB used
  # however full the Mac actually is. The number that matters to a human
  # lives on the data volume, so report that one first and label both.
  echo "Data volume (the real one):"
  df -h /System/Volumes/Data 2>/dev/null
  echo "Sealed system volume (small by design, not a usage figure):"
  df -h / 2>/dev/null
  echo
  echo "Largest known contributors (du -sh, may take a minute):"
  for d in \
    "$HOME/Library/Containers/com.docker.docker" \
    "$HOME/Library/Caches" \
    "$HOME/Library/Application Support/JetBrains" \
    "$HOME/Library/Developer" \
    "/Applications/Xcode.app" \
    "/opt/homebrew" \
    "$HOME/.cache" \
    "$HOME/.ollama" \
    "$HOME/.bun" \
    "$HOME/.asdf" \
    "$HOME/.gem" \
    "$HOME/.nvm" "$HOME/.pyenv" "$HOME/.rvm"
  do
    [ -e "$d" ] && du -sh "$d" 2>/dev/null
  done
  # Docker's disk image reports its apparent size in `ls` and its real
  # allocation in `du` — the gap is the whole point of the finding, so
  # report both rather than picking one.
  raw="$HOME/Library/Containers/com.docker.docker/Data/vms/0/data/Docker.raw"
  if [ -f "$raw" ]; then
    echo
    apparent_gb=$(( $(stat -f %z "$raw" 2>/dev/null || echo 0) / 1073741824 ))
    echo "Docker.raw: apparent ${apparent_gb} GB, actual $(du -h "$raw" 2>/dev/null | awk '{print $1}')"
  fi
else
  echo "(skipped: --no-disk)"
fi

section "END"
