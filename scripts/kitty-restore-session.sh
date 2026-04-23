#!/usr/bin/env bash
# Replay ~/.cache/kitty/session.conf if it exists. No-op if missing or empty.
# Launches a detached kitty so we can be safely called from an autostart
# entry or keybinding without blocking.
set -u
SESSION="${XDG_CACHE_HOME:-$HOME/.cache}/kitty/session.conf"

if [[ -s "$SESSION" ]]; then
    setsid kitty --session "$SESSION" >/dev/null 2>&1 < /dev/null &
    disown 2>/dev/null || true
else
    # No session — just open a plain kitty.
    setsid kitty >/dev/null 2>&1 < /dev/null &
    disown 2>/dev/null || true
fi
