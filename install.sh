#!/usr/bin/env bash
# Safari Glass — one-shot installer for Firefox and LibreWolf.
#
#   curl -fsSL https://raw.githubusercontent.com/EnvyMeAdams/firefox-safari-glass/main/install.sh | bash
#
# Finds your default profile(s), closes the browser if it's running (your tabs
# come back), installs the theme, and reopens the browser.
set -euo pipefail

REPO="EnvyMeAdams/firefox-safari-glass"
MARKER="Safari Glass"                       # first-line tag in our CSS files

usage() {
  cat <<'EOF'
Usage: install.sh [options]

  -b, --browser NAME   firefox, librewolf, or all (default: all that are found)
  -p, --profile PATH   install into this profile folder instead of auto-detecting
      --no-restart     close the browser if needed, but don't reopen it
  -u, --uninstall      remove the theme and reset the prefs it changed
  -h, --help           show this help

Piped from curl, pass options like this:
  curl -fsSL .../install.sh | bash -s -- --browser librewolf
EOF
}

say()  { printf '\033[1;34m::\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m✓\033[0m  %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

want=all; profile_override=""; restart=1; mode=install
while (($#)); do
  case $1 in
    -b|--browser)   want=${2:?--browser needs a value}; shift 2 ;;
    -p|--profile)   profile_override=${2:?--profile needs a path}; shift 2 ;;
    --no-restart)   restart=0; shift ;;
    -u|--uninstall) mode=uninstall; shift ;;
    -h|--help)      usage; exit 0 ;;
    *)              die "Unknown option: $1 (try --help)" ;;
  esac
done
case $want in all|firefox|librewolf) ;; *) die "--browser must be firefox, librewolf or all" ;; esac

# ---------- theme files: next to this script, or downloaded (curl | bash) ----------
src=""
if [[ -n ${BASH_SOURCE[0]:-} && -f ${BASH_SOURCE[0]} ]]; then
  d=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  [[ -f $d/chrome/userChrome.css && -f $d/user.js ]] && src=$d
fi
if [[ -z $src ]]; then
  command -v curl >/dev/null || die "curl is needed to download the theme"
  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
  say "Downloading Safari Glass"
  curl -fsSL "https://github.com/$REPO/archive/refs/heads/main.tar.gz" \
    | tar xz -C "$tmp" --strip-components=1
  src=$tmp
fi

# ---------- where each browser keeps things ----------
cfg=${XDG_CONFIG_HOME:-$HOME/.config}
bases() {
  case $1 in
    firefox)   printf '%s\n' \
                 "$cfg/mozilla/firefox" \
                 "$HOME/.mozilla/firefox" \
                 "$HOME/.var/app/org.mozilla.firefox/config/mozilla/firefox" \
                 "$HOME/.var/app/org.mozilla.firefox/.mozilla/firefox" ;;
    librewolf) printf '%s\n' \
                 "$cfg/librewolf/librewolf" \
                 "$HOME/.librewolf" \
                 "$HOME/.var/app/io.gitlab.librewolf-community/config/librewolf/librewolf" \
                 "$HOME/.var/app/io.gitlab.librewolf-community/.librewolf" ;;
  esac
}
procs()      { case $1 in firefox) echo "firefox firefox-bin firefox-esr" ;; librewolf) echo "librewolf librewolf-bin" ;; esac; }
flatpak_id() { case $1 in firefox) echo org.mozilla.firefox ;; librewolf) echo io.gitlab.librewolf-community ;; esac; }

is_browser_exe() {        # does this executable belong to browser $1?
  local base=${2##*/} n
  base=${base% (deleted)}
  for n in $(procs "$1"); do [[ $base == "$n" ]] && return 0; done
  return 1
}

browser_pids() {          # every process of this browser, matched by its executable
  local b=$1 pid exe     # (Firefox often renames its main process "MainThread",
  for pid in $(pgrep -u "$UID" .); do      #  so matching by name misses it)
    exe=$(readlink "/proc/$pid/exe" 2>/dev/null) || continue
    is_browser_exe "$b" "$exe" && echo "$pid"
  done
  return 0
}

main_pid() {              # the browser process whose parent isn't the browser
  local b=$1 pid ppid exe
  for pid in $(browser_pids "$b"); do
    ppid=$(awk '/^PPid:/ { print $2 }' "/proc/$pid/status" 2>/dev/null) || continue
    exe=$(readlink "/proc/$ppid/exe" 2>/dev/null || true)
    is_browser_exe "$b" "$exe" || { echo "$pid"; return 0; }
  done
  return 1
}

running_profile() {       # ask the running browser which profile it has open
  local pid fd target
  pid=$(main_pid "$1") || return 1
  for fd in /proc/"$pid"/fd/*; do
    target=$(readlink "$fd" 2>/dev/null) || continue
    if [[ $target == */places.sqlite ]]; then
      target=${target%/places.sqlite}
      [[ -d $target ]] && { echo "$target"; return 0; }
    fi
  done
  return 1
}

ini_profile() {           # default profile according to installs.ini / profiles.ini
  local base=$1 ini rel
  for ini in "$base/installs.ini" "$base/profiles.ini"; do
    [[ -f $ini ]] || continue
    # [Install…] sections: Default=<path>
    rel=$(awk -F= '/^Default=/ && $2 != "1" { print $2; exit }' "$ini")
    # [Profile…] sections: the one marked Default=1, else the first one
    [[ -n $rel ]] || rel=$(awk '
      function flush() { if (path != "") { if (def && d == "") d = path; if (f == "") f = path }; path = ""; def = 0 }
      /^\[/        { flush() }
      /^Path=/     { path = substr($0, 6) }
      /^Default=1/ { def = 1 }
      END          { flush(); print (d != "" ? d : f) }' "$ini")
    [[ -n $rel ]] || continue
    [[ $rel == /* ]] || rel="$base/$rel"
    [[ -d $rel ]] && { echo "$rel"; return 0; }
  done
  return 1
}

find_profile() {
  local b=$1 base p
  running_profile "$b" && return 0
  while read -r base; do
    [[ -d $base ]] || continue
    ini_profile "$base" && return 0
    # no usable ini: take the most recently used profile folder
    # shellcheck disable=SC2012  # profile folder names are safe
    p=$(ls -1td "$base"/*/prefs.js 2>/dev/null | head -1 || true)
    [[ -n $p ]] && { echo "${p%/prefs.js}"; return 0; }
  done < <(bases "$b")
  return 1
}

launch_cmd() {            # how to reopen this browser later
  local b=$1 p=$2 n
  if [[ $p == "$HOME/.var/app/"* ]]; then echo "flatpak run $(flatpak_id "$b")"; return; fi
  for n in $(procs "$b"); do command -v "$n" >/dev/null && { echo "$n"; return 0; }; done
  return 0
}

close_browser() {         # returns 0 if it was running and is now closed
  local b=$1 pid i
  pid=$(main_pid "$b") || return 1
  say "Closing $b — your tabs will come back"
  kill -TERM "$pid" 2>/dev/null || true
  for ((i = 0; i < 30; i++)); do
    main_pid "$b" >/dev/null || return 0
    sleep 0.5
  done
  warn "$b didn't close within 15s, forcing it"
  # shellcheck disable=SC2046
  kill -KILL $(browser_pids "$b") 2>/dev/null || true
  sleep 1
  return 0
}

restore_tabs_next_launch() {   # same trick Firefox uses for its own restarts
  printf 'user_pref("browser.sessionstore.resume_session_once", true);\n' >> "$1/prefs.js"
}

strip_block() {
  [[ -f $1 ]] && sed -i '/^\/\/ >>> safari-glass >>>/,/^\/\/ <<< safari-glass <<</d' "$1"
  return 0
}

install_into() {
  local p=$1 f
  mkdir -p "$p/chrome"
  for f in userChrome.css userContent.css; do
    # keep the user's own CSS (not an older Safari Glass) so uninstall can bring it back
    if [[ -f $p/chrome/$f ]] && ! grep -q "$MARKER" "$p/chrome/$f" && [[ ! -e $p/chrome/$f.pre-safari-glass ]]; then
      cp "$p/chrome/$f" "$p/chrome/$f.pre-safari-glass"
      ok "backed up your existing $f"
    fi
    cp "$src/chrome/$f" "$p/chrome/$f"
  done

  # user.js: merge, don't clobber (arkenfox and friends stay intact)
  local u=$p/user.js
  strip_block "$u"
  if [[ -s $u && -n $(tail -c1 "$u") ]]; then echo >> "$u"; fi
  cat "$src/user.js" >> "$u"
}

uninstall_from() {
  local p=$1 f name
  for f in userChrome.css userContent.css; do
    if [[ -f $p/chrome/$f.pre-safari-glass ]]; then
      mv "$p/chrome/$f.pre-safari-glass" "$p/chrome/$f"; ok "restored your original $f"
    elif [[ -f $p/chrome/$f ]] && grep -q "$MARKER" "$p/chrome/$f"; then
      rm -f "$p/chrome/$f"
    fi
  done
  strip_block "$p/user.js"
  # user.js only *sets* prefs; drop them from prefs.js so the browser falls back to defaults
  if [[ -f $p/prefs.js ]]; then
    # shellcheck disable=SC2013  # pref names never contain spaces
    for name in $(grep -o 'user_pref("[^"]*"' "$src/user.js" | cut -d'"' -f2); do
      sed -i "/^user_pref(\"${name//./\\.}\",/d" "$p/prefs.js"
    done
  fi
}

# ---------- pick targets ----------
targets=()
if [[ -n $profile_override ]]; then
  [[ -d $profile_override ]] || die "No such folder: $profile_override"
  b=firefox; [[ $profile_override == *librewolf* ]] && b=librewolf
  [[ $want != all ]] && b=$want
  targets+=("$b|$(cd "$profile_override" && pwd)")
else
  for b in firefox librewolf; do
    [[ $want == all || $want == "$b" ]] || continue
    if p=$(find_profile "$b"); then targets+=("$b|$p"); fi
  done
fi
if ((${#targets[@]} == 0)); then
  warn "No Firefox or LibreWolf profile found. Looked in:"
  for b in firefox librewolf; do bases "$b"; done | sed 's/^/     /' >&2
  die "Open about:profiles, copy the 'Root Directory' in use, and run: install.sh --profile <that folder>"
fi

# ---------- do it ----------
reopen=()
for t in "${targets[@]}"; do
  b=${t%%|*}; p=${t#*|}
  say "$b → $p"
  cmd=$(launch_cmd "$b" "$p")

  if close_browser "$b"; then
    restore_tabs_next_launch "$p"
    [[ -n $cmd ]] && reopen+=("$cmd")
  fi

  if [[ $mode == install ]]; then install_into "$p"; ok "installed into $b"
  else uninstall_from "$p"; ok "removed from $b"; fi
done

if ((restart)) && ((${#reopen[@]})); then
  if [[ -n ${WAYLAND_DISPLAY:-}${DISPLAY:-} ]]; then
    for cmd in "${reopen[@]}"; do
      say "Reopening ${cmd##* }"
      # shellcheck disable=SC2086
      setsid -f $cmd >/dev/null 2>&1 < /dev/null
    done
  else
    warn "No graphical session here, so open the browser yourself. Your tabs will be restored."
  fi
fi

if [[ $mode == install ]]; then ok "Done. Enjoy the glass."; else ok "Done. Safari Glass removed."; fi
