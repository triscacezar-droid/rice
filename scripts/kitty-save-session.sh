#!/usr/bin/env bash
# Snapshot the current kitty layout into a session file that
# `kitty --session` can replay. For any window running `claude`,
# look up the most recent transcript in ~/.claude/projects and bake
# a `claude -r <uuid>` resume into the restore command.
#
# Requires kitty IPC: kitty.conf must have `allow_remote_control yes`
# and `listen_on unix:@kitty`. Kittys started before those lines existed
# don't expose a socket and will be missing from the snapshot.

set -u
SOCK="unix:@kitty"
OUT="${XDG_CACHE_HOME:-$HOME/.cache}/kitty/session.conf"
mkdir -p "$(dirname "$OUT")"

json=$(kitten @ --to="$SOCK" ls 2>/dev/null) || exit 0
[[ -z "$json" ]] && exit 0

printf '%s' "$json" | /usr/bin/env python3 - "$OUT" <<'PY'
import json, os, sys, shlex

data = json.load(sys.stdin)
out_path = sys.argv[1]
home = os.path.expanduser("~")
sessions_dir = os.path.join(home, ".claude", "sessions")

def claude_session_id(pid: int | None) -> str | None:
    # Claude Code writes one ~/.claude/sessions/<PID>.json per running
    # process. `sessionId` is the resume token to pass to `claude -r`.
    if not pid:
        return None
    path = os.path.join(sessions_dir, f"{pid}.json")
    try:
        with open(path) as f:
            return json.load(f).get("sessionId")
    except (OSError, ValueError):
        return None

def fg_non_shell(window: dict):
    for p in window.get("foreground_processes", []):
        cmdline = p.get("cmdline") or []
        if not cmdline:
            continue
        exe = os.path.basename(cmdline[0])
        if exe in ("zsh", "bash", "sh", "fish", "dash"):
            continue
        return p  # full process dict, we need the pid
    return None

def launch_cmd(cwd: str, fg_proc):
    if fg_proc:
        cmdline = fg_proc.get("cmdline") or []
        if cmdline and os.path.basename(cmdline[0]) == "claude":
            uuid = claude_session_id(fg_proc.get("pid"))
            if uuid:
                resume = f"claude --dangerously-skip-permissions -r {uuid}"
                # Wrap so the shell stays alive after claude exits.
                return f"zsh -ic {shlex.quote(resume + '; exec zsh -i')}"
    return "zsh -i"

lines: list[str] = []
for os_idx, os_win in enumerate(data):
    if os_idx > 0:
        lines.append("new_os_window")
    tabs = os_win.get("tabs", [])
    for tab_idx, tab in enumerate(tabs):
        title = tab.get("title") or ""
        if tab_idx > 0:
            if title:
                lines.append(f"new_tab {title}")
            else:
                lines.append("new_tab")
        else:
            if title:
                lines.append(f"tab_title {title}")
        layout = tab.get("layout") or "tall"
        lines.append(f"layout {layout}")
        for w in tab.get("windows", []):
            cwd = w.get("cwd") or home
            cmd = launch_cmd(cwd, fg_non_shell(w))
            lines.append(f"launch --cwd={cwd} {cmd}")

with open(out_path, "w") as f:
    f.write("\n".join(lines) + "\n")
PY
