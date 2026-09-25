#!/usr/bin/env bash
# Install the keys write hook on the laptop: script to ~/.local/bin, launchd
# agent to ~/Library/LaunchAgents, then (re)load it. Idempotent.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
label=com.ash4d.hermes-keys-sync
plist=$HOME/Library/LaunchAgents/$label.plist

mkdir -p "$HOME/.local/bin" "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
ln -sfn "$here/hermes-keys-sync" "$HOME/.local/bin/hermes-keys-sync"
sed "s|__HOME__|$HOME|g" "$here/$label.plist" > "$plist"
plutil -lint "$plist" >/dev/null

launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$plist"
launchctl print "gui/$(id -u)/$label" | grep -E '^\s+state ='
