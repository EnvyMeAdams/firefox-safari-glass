#!/usr/bin/env bash
# Safari Glass installer — copies the theme into your default Firefox profile.
# Usage: ./install.sh            (auto-detects the default profile)
#        ./install.sh /path/to/profile
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

find_profile() {
  local base ini rel
  # Firefox 147+ uses ~/.config/mozilla/firefox; older installs use ~/.mozilla/firefox
  for base in "${XDG_CONFIG_HOME:-$HOME/.config}/mozilla/firefox" "$HOME/.mozilla/firefox"; do
    for ini in "$base/installs.ini" "$base/profiles.ini"; do
      [[ -f $ini ]] || continue
      # First "Default=" whose value is a path (profiles.ini also has Default=1 flags)
      rel=$(awk -F= '/^Default=/ && $2 != "1" { print $2; exit }' "$ini")
      [[ -n $rel ]] || continue
      [[ $rel == /* ]] && { echo "$rel"; return; }
      echo "$base/$rel"; return
    done
  done
  return 1
}

profile="${1:-$(find_profile || true)}"
if [[ -z $profile || ! -d $profile ]]; then
  echo "Couldn't find your Firefox profile. Open about:profiles, copy the"
  echo "'Root Directory' of the profile in use, and run: ./install.sh <that path>"
  exit 1
fi

if pgrep -x firefox >/dev/null 2>&1 || pgrep -f 'firefox-bin' >/dev/null 2>&1; then
  echo "Firefox is running — quit it fully first (user.js is read at startup)."
  exit 1
fi

echo "Installing into: $profile"
stamp=$(date +%Y%m%d-%H%M%S)

# chrome/ folder (back up anything already there)
mkdir -p "$profile/chrome"
for f in userChrome.css userContent.css; do
  if [[ -f $profile/chrome/$f ]]; then
    cp "$profile/chrome/$f" "$profile/chrome/$f.bak-$stamp"
    echo "  backed up existing $f"
  fi
  cp "$here/chrome/$f" "$profile/chrome/$f"
done

# user.js — merge, don't clobber (keeps arkenfox or your own prefs intact)
userjs="$profile/user.js"
if [[ -f $userjs ]]; then
  cp "$userjs" "$userjs.bak-$stamp"
  # drop any previous safari-glass block, then append the fresh one
  sed -i '/^\/\/ >>> safari-glass >>>/,/^\/\/ <<< safari-glass <<</d' "$userjs"
  printf '\n' >> "$userjs"
  cat "$here/user.js" >> "$userjs"
  echo "  merged prefs into existing user.js (backup saved)"
else
  cp "$here/user.js" "$userjs"
fi

echo "Done. Start Firefox."
