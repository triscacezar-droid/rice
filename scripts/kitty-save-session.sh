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
import json, os, sys, glob, shlex

data = json.load(sys.stdin)
out_path = sys.argv[1]
home = os.path.expanduser("~")
projects_root = os.path.join(home, ".claude", "projects")

def claude_resume_uuid(cwd: str) -> str | None:
    # Claude Code encodes the project path as absolute-path-with-slashes → dashes.
    encoded = cwd.replace("/", "-")
    proj = os.path.join(projects_root, encoded)
    if not os.path.isdir(proj):
        return None
    jsonls = glob.glob(os.path.join(proj, "*.jsonl"))
    if not jsonls:
        return None
    return os.path.splitext(os.path.basename(max(jsonls, key=os.path.getmtime)))[0]

def fg_non_shell(window: dict):
    for p in window.get("foreground_processes", []):
        cmdline = p.get("cmdline") or []
        if not cmdline:
            continue
        exe = os.path.basename(cmdline[0])
        if exe in ("zsh", "bash", "sh", "fish", "dash"):
            continue
        return cmdline
    return None

def launch_cmd(cwd: str, fg_cmdline):
    # If the window is running claude, snapshot the resume UUID and wrap it
    # in `zsh -ic '...; exec zsh -i'` so the shell stays after claude exits.
    if fg_cmdline and os.path.basename(fg_cmdline[0]) == "claude":
        uuid = claude_resume_uuid(cwd)
        if uuid:
            resume = f"claude --dangerously-skip-permissions -r {uuid}"
            # Inner command is single-quoted for zsh -ic; UUID is hex/dash-safe.
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
