# dotfiles — Ubuntu + GNOME rice

Everything installed and configured during the 2026-04-23 ricing session.
Target: Ubuntu 24.04 LTS with GNOME 46 on Wayland.
Theme: **Gruvbox Dark** throughout.

## One-command install on a fresh machine

```bash
git clone <this-repo> ~/dotfiles
cd ~/dotfiles
./install.sh
```

The installer is idempotent — safe to run again after partial failures or to
pick up changes.

## What this setup gives you

### Shell & terminal
- **Kitty** 0.46 and **Alacritty** 0.13 — both themed Gruvbox Dark with
  JetBrainsMono Nerd Font 11pt. Kitty is the primary terminal (supports inline
  images via graphics protocol, tabs, splits). Alacritty is the minimal
  alternative with 5 other preloaded themes you can swap via one-line edit.
- **Zsh** + **oh-my-zsh** + `zsh-autosuggestions` + `zsh-syntax-highlighting`.
- **Starship prompt** with the `gruvbox-rainbow` preset — shows git branch,
  Python venv, exit codes, language versions.
- **Fastfetch** runs on each interactive shell open (distro splash).
- **Atuin** replaces `Ctrl+R` history search with fuzzy TUI + SQLite-backed
  history.
- **CLI replacements**: `eza` (ls), `bat` (cat), `fzf` (fuzzy), `fd` (find),
  `rg` (grep), `zoxide` (smarter cd, `z <partial>` jumps to frequently-visited
  dirs), `lazygit` (terminal git UI), `btop` (system monitor), `yazi` (TUI
  file manager with inline image preview in Kitty).

### Editors / PDF
- **Cursor** IDE with the `jdinhlife.gruvbox` extension set to Gruvbox Dark
  Medium.
- **Zathura** for PDFs with gruvbox recolor — keyboard-driven, `Ctrl+r` toggles
  between themed and original colors.

### GUI (GNOME 46)
- **Papirus-Dark** icon theme.
- **Gruvbox-Orange-Dark** GTK theme.
- **Bibata-Modern-Classic** cursor theme.
- Gruvbox wallpaper pool in `~/Pictures/Wallpapers/`.
- GNOME extensions: **Vitals** (CPU/RAM/GPU/temps in top bar), **Blur My Shell**,
  **Clipboard Indicator**, **Caffeine**.
- **Nautilus Copy Path** right-click extension (custom Python extension,
  uses Gdk.Clipboard directly — no `wl-copy` subprocess because that hangs
  from inside GTK apps).

### Not covered by the installer (do manually)
- **Discord → Vencord** mod — run the interactive installer:
  `sh -c "$(curl -sS https://raw.githubusercontent.com/Vencord/Installer/main/install.sh)"`
- **Firefox** gruvbox — install the "Gruvbox" theme addon and Dark Reader,
  or apply gruvbox userChrome CSS.

## Post-install manual steps

1. **Log out and back in** — required on Wayland for new GNOME extensions to
   load (Vitals etc.).
2. **Change default shell**:
   ```
   chsh -s $(which zsh)
   ```
   Asks for your user password (not sudo). Logout/login to pick up.

## Changing the color theme

Run one command:

```bash
~/dotfiles/scripts/set-theme.sh gruvbox_dark        # default
~/dotfiles/scripts/set-theme.sh gruvbox_light
~/dotfiles/scripts/set-theme.sh catppuccin_mocha
~/dotfiles/scripts/set-theme.sh tokyo_night
~/dotfiles/scripts/set-theme.sh tokyo_night_storm
~/dotfiles/scripts/set-theme.sh dracula
~/dotfiles/scripts/set-theme.sh nord
~/dotfiles/scripts/set-theme.sh rose_pine
~/dotfiles/scripts/set-theme.sh everforest
~/dotfiles/scripts/set-theme.sh kanagawa
```

Run the script with no args for the current list.

**What the script changes:**
- Alacritty — rewrites the `import = [...]` line to point at the chosen theme.
- Kitty — invokes `kitten themes --reload-in=all "<Theme Name>"` (live reload across all running kitty windows).
- Cursor IDE — edits the `workbench.colorTheme` field in `settings.json`.
- GNOME — switches `color-scheme` to `prefer-dark` / `prefer-light` as appropriate.

**What the script does NOT change** (these four are gruvbox-only — hand-themed):
- Zathura (`configs/zathura/zathurarc`)
- Yazi (`configs/yazi/theme.toml`)
- Lazygit (`configs/lazygit/config.yml`)
- Starship (`configs/starship/starship.toml`)

To re-theme those, edit the file directly or replace it with a variant from
each project's theme gallery. They use tool-specific formats so a universal
switcher for all of them would be overkill.

**Cursor IDE caveat:** switching to a non-gruvbox theme assumes the matching
Cursor extension is installed. Install them with:
```bash
cursor --install-extension Catppuccin.catppuccin-vsc
cursor --install-extension enkia.tokyo-night
cursor --install-extension dracula-theme.theme-dracula
cursor --install-extension arcticicestudio.nord-visual-studio-code
cursor --install-extension mvllow.rose-pine
cursor --install-extension sainnhe.everforest
cursor --install-extension metaphore.kanagawa
```

## Directory layout

```
~/dotfiles/
├── README.md              # this file
├── install.sh             # idempotent installer
├── scripts/
│   └── set-theme.sh       # one-command system-wide theme switcher
├── configs/               # canonical config files (symlinked to ~/.config/*)
│   ├── kitty/kitty.conf
│   ├── alacritty/alacritty.toml
│   ├── alacritty/themes/*.toml
│   ├── starship/starship.toml
│   ├── zathura/zathurarc
│   ├── yazi/theme.toml
│   ├── lazygit/config.yml
│   ├── nautilus-python/copy_path.py
│   └── zshrc
```

Editing a config in `~/dotfiles/configs/` propagates to the live location
because the installer creates symlinks (not copies).

Personal aliases and anything machine-specific (API tokens, local paths,
workflow shortcuts) belong in `~/.zshrc.local` — sourced automatically by
this `zshrc` and gitignored so it never leaks into the public repo.

## Gotchas discovered during setup

- **Nautilus + `wl-copy`**: a Python Nautilus extension that shells out to
  `wl-copy` will hang for seconds (freezing the file manager) because of
  pipe-handling edge cases from inside GTK. Use `Gdk.Display.get_default().get_clipboard().set(text)`
  instead — zero subprocess, instant.
- **Gruvbox-GTK-Theme needs `sassc`**: the install script compiles SCSS
  on first run. `sudo apt install sassc` or it silently ships a broken link.
- **GNOME extensions on Wayland**: newly installed extensions don't load
  until logout/login. No `Alt+F2 r` shortcut like on X11.
- **Kitty font changes** need a full process restart, not just `Ctrl+Shift+F5`
  config reload.
- **libadwaita 1.5 vs 1.6**: the Gruvbox GTK theme uses `--accent-color` CSS
  custom properties that are only in libadwaita 1.6 (GNOME 47+). On 24.04 /
  GNOME 46 / libadwaita 1.5, these log harmless CSS parse warnings.
- **gnome-extensions-cli** UUIDs are case-sensitive. `Vitals@CoreCoding.com`
  works; `vitals@CoreCoding.com` errors "not found".
- **fastfetch is not in Ubuntu 24.04 apt** — install from upstream deb.
- **eza is not in Ubuntu 24.04 apt** — install the static binary from
  GitHub releases.
