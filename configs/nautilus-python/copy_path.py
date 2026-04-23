import traceback
from urllib.parse import unquote
from typing import List

import gi
gi.require_version("Nautilus", "4.0")
gi.require_version("Gdk", "4.0")
from gi.repository import Nautilus, GObject, Gdk  # noqa: E402


LOG = "/tmp/nautilus_copy_path.log"


def _log(msg: str) -> None:
    try:
        with open(LOG, "a") as f:
            f.write(msg + "\n")
    except Exception:
        pass


def _path_of(file) -> str | None:
    try:
        uri = file.get_uri()
    except Exception:
        return None
    if not uri.startswith("file://"):
        return None
    return unquote(uri[len("file://"):])


def _copy_text(_menu, text: str) -> None:
    try:
        display = Gdk.Display.get_default()
        if display is None:
            _log("no default display")
            return
        clipboard = display.get_clipboard()
        clipboard.set(text)
    except Exception:
        _log(f"copy failed:\n{traceback.format_exc()}")


class CopyPathExtension(GObject.GObject, Nautilus.MenuProvider):

    def get_file_items(self, *args) -> List[Nautilus.MenuItem]:
        try:
            files = args[-1] if args else []
            if not files:
                return []
            paths = [p for p in (_path_of(f) for f in files) if p]
            if not paths:
                return []
            n = len(paths)
            label = "Copy Path" if n == 1 else f"Copy {n} Paths"
            item = Nautilus.MenuItem(
                name="CopyPathExtension::copy_path",
                label=label,
                tip="Copy absolute path(s) to clipboard",
            )
            item.connect("activate", _copy_text, "\n".join(paths))
            return [item]
        except Exception:
            _log(f"get_file_items failed:\n{traceback.format_exc()}")
            return []

    def get_background_items(self, *args) -> List[Nautilus.MenuItem]:
        try:
            folder = args[-1] if args else None
            if folder is None:
                return []
            path = _path_of(folder)
            if not path:
                return []
            item = Nautilus.MenuItem(
                name="CopyPathExtension::copy_folder_path",
                label="Copy Folder Path",
                tip="Copy this folder's absolute path to clipboard",
            )
            item.connect("activate", _copy_text, path)
            return [item]
        except Exception:
            _log(f"get_background_items failed:\n{traceback.format_exc()}")
            return []
