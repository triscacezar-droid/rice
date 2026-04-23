#!/usr/bin/env bash
# Fetches weather for conky via wttr.in. Caches for 30 min so we don't
# hammer the API and so we still show something if offline. Prints the
# cached output on stdout.
set -u

LOCATION="${WTTR_LOCATION:-Dublin}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/conky"
CACHE="$CACHE_DIR/weather.txt"
MAX_AGE=1800  # seconds

mkdir -p "$CACHE_DIR"

needs_refresh=1
if [[ -f "$CACHE" ]]; then
    age=$(( $(date +%s) - $(stat -c %Y "$CACHE") ))
    (( age < MAX_AGE )) && needs_refresh=0
fi

if (( needs_refresh )); then
    # wttr.in format: 2 lines, conky-friendly
    #   line1: icon  temp  condition
    #   line2: feels <f>  humidity  wind
    # %0A is a URL-encoded newline — wttr.in's format parameter renders it as
    # a real line break so the output is two clean lines for conky to display.
    # No %c (icon) — wttr's emoji glyphs don't render in JetBrainsMono Nerd Font.
    fetched=$(curl -fsSL --max-time 6 "https://wttr.in/${LOCATION}?format=%t+%C%0A%f+feels+%h+humid+%w" 2>/dev/null || true)
    if [[ -n "$fetched" && "$fetched" != *"Unknown location"* ]]; then
        printf '%s\n' "$fetched" > "$CACHE"
    fi
fi

if [[ -f "$CACHE" ]]; then
    cat "$CACHE"
else
    echo "  offline"
fi
