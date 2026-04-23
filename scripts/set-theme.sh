#!/usr/bin/env bash
# Switch the system-wide color theme across Alacritty, Kitty, Cursor, and GNOME.
#
# Usage:  set-theme.sh <theme>
# Themes: gruvbox_dark  gruvbox_light  catppuccin_mocha  tokyo_night  dracula  nord
#
# Apps that stay gruvbox-only regardless: zathura, yazi, lazygit, starship
# (their theming is hand-authored; to change, edit the config file directly
# or replace it with a variant theme — see README).

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THEME="${1:-}"

if [[ -z "$THEME" ]]; then
    echo "usage: $0 <theme>"
    echo "themes:"
    for t in "$DOTFILES/configs/alacritty/themes/"*.toml; do
        echo "  - $(basename "$t" .toml)"
    done
    exit 1
fi

ALACRITTY_THEME_FILE="$DOTFILES/configs/alacritty/themes/${THEME}.toml"
if [[ ! -f "$ALACRITTY_THEME_FILE" ]]; then
    echo "error: no alacritty theme '$THEME' (file $ALACRITTY_THEME_FILE missing)"
    exit 1
fi

# ---- Mapping from our theme name → Kitty theme name ----
declare -A KITTY_NAME=(
    [gruvbox_dark]="Gruvbox Dark"
    [gruvbox_light]="Gruvbox Light"
    [catppuccin_mocha]="Catppuccin-Mocha"
    [tokyo_night]="Tokyo Night"
    [tokyo_night_storm]="Tokyo Night Storm"
    [dracula]="Dracula"
    [nord]="Nord"
    [rose_pine]="Rosé Pine"
    [everforest]="Everforest Dark Medium"
    [kanagawa]="Kanagawa"
)
# ---- Mapping → Cursor IDE color theme ----
# Install the extension first, otherwise Cursor falls back to default:
#   gruvbox:           jdinhlife.gruvbox
#   catppuccin:        Catppuccin.catppuccin-vsc
#   tokyo night:       enkia.tokyo-night
#   dracula:           dracula-theme.theme-dracula
#   nord:              arcticicestudio.nord-visual-studio-code
#   rose pine:         mvllow.rose-pine
#   everforest:        sainnhe.everforest
#   kanagawa:          metaphore.kanagawa  (or  qufiwefefwoyn.kanagawa)
declare -A CURSOR_NAME=(
    [gruvbox_dark]="Gruvbox Dark Medium"
    [gruvbox_light]="Gruvbox Light Medium"
    [catppuccin_mocha]="Catppuccin Mocha"
    [tokyo_night]="Tokyo Night"
    [tokyo_night_storm]="Tokyo Night Storm"
    [dracula]="Dracula"
    [nord]="Nord"
    [rose_pine]="Rosé Pine"
    [everforest]="Everforest Dark"
    [kanagawa]="Kanagawa"
)
# ---- Mapping → GNOME color-scheme ----
declare -A GNOME_SCHEME=(
    [gruvbox_dark]="prefer-dark"
    [gruvbox_light]="prefer-light"
    [catppuccin_mocha]="prefer-dark"
    [tokyo_night]="prefer-dark"
    [tokyo_night_storm]="prefer-dark"
    [dracula]="prefer-dark"
    [nord]="prefer-dark"
    [rose_pine]="prefer-dark"
    [everforest]="prefer-dark"
    [kanagawa]="prefer-dark"
)

echo "==> Switching to '$THEME'"

# ---- Alacritty ----
ALACRITTY_CONFIG="$DOTFILES/configs/alacritty/alacritty.toml"
if [[ -f "$ALACRITTY_CONFIG" ]]; then
    echo "    alacritty: import themes/${THEME}.toml"
    # Replace the first path inside the import = [...] array.
    sed -i -E "s|\"~/.config/alacritty/themes/[^\"]+\"|\"~/.config/alacritty/themes/${THEME}.toml\"|" \
        "$ALACRITTY_CONFIG"
fi

# ---- Kitty ----
if command -v kitten >/dev/null && [[ -n "${KITTY_NAME[$THEME]:-}" ]]; then
    echo "    kitty:     ${KITTY_NAME[$THEME]}"
    kitten themes --reload-in=all "${KITTY_NAME[$THEME]}" >/dev/null 2>&1 \
        || echo "               (kitty theme apply failed — non-fatal)"
fi

# ---- Cursor IDE ----
CURSOR_SETTINGS="$HOME/.config/Cursor/User/settings.json"
if [[ -f "$CURSOR_SETTINGS" && -n "${CURSOR_NAME[$THEME]:-}" ]]; then
    echo "    cursor:    ${CURSOR_NAME[$THEME]}"
    # Minimal JSON edit without jq dependency.
    if grep -q '"workbench.colorTheme"' "$CURSOR_SETTINGS"; then
        sed -i -E "s|(\"workbench.colorTheme\":\s*)\"[^\"]*\"|\1\"${CURSOR_NAME[$THEME]}\"|" \
            "$CURSOR_SETTINGS"
    fi
fi

# ---- GNOME ----
if command -v gsettings >/dev/null && [[ -n "${GNOME_SCHEME[$THEME]:-}" ]]; then
    echo "    gnome:     color-scheme=${GNOME_SCHEME[$THEME]}"
    gsettings set org.gnome.desktop.interface color-scheme "${GNOME_SCHEME[$THEME]}"
fi

echo "==> Done. Open a fresh terminal window for Kitty/Alacritty to pick up the font color change."
