#!/usr/bin/env bash
# Cycle focus through all running kitty OS windows. Uses kitty's remote
# control socket (abstract unix: @kitty) so it works under native Wayland
# where wmctrl can't reach the window manager.
#
# No kitty running  -> launch one.
# One kitty window  -> focus it.
# Many windows      -> cycle to the next in order; remember cursor between calls.
set -u

SOCK="unix:@kitty"
STATE="${XDG_RUNTIME_DIR:-/tmp}/kitty-surface.state"

mapfile -t ids < <(
    kitten @ --to="$SOCK" ls 2>/dev/null \
        | python3 -c "import sys,json
try:
    data = json.load(sys.stdin)
    print('\n'.join(str(w['id']) for w in data))
except Exception:
    pass" 2>/dev/null
)

if (( ${#ids[@]} == 0 )); then
    setsid kitty >/dev/null 2>&1 < /dev/null &
    exit 0
fi

last=$(cat "$STATE" 2>/dev/null || echo "")
idx=-1
for i in "${!ids[@]}"; do
    [[ "${ids[$i]}" == "$last" ]] && { idx=$i; break; }
done
next=$(( (idx + 1) % ${#ids[@]} ))
target="${ids[$next]}"

kitten @ --to="$SOCK" focus-window --match="id:$target" >/dev/null 2>&1
echo "$target" > "$STATE"
