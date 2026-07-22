#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${1:-}" != "--apply" ]]; then
    printf '%s\n' \
        'This will restore the snapshot into your home directory.' \
        'Existing paths will be backed up first.' \
        'Run: ./restore.sh --apply'
    exit 0
fi

timestamp="$(date +%Y%m%d-%H%M%S)"
backup_dir="${HOME}/.xiaou0_dotfiles_backup_${timestamp}"
mkdir -p "$backup_dir"

paths=(
    .config/theme
    .config/hypr
    .config/waybar
    .config/wofi
    .config/dunst
    .config/nvim
    .config/kitty
    .config/fish
    .config/alacritty
    .config/yazi
    .config/cava
    .config/starship.toml
    .config/quickshell
    .config/silicon/themes
    .config/LiteLoaderQQNT/plugins/obsidian-ember
    .config/LiteLoaderQQNT/data/LiteLoader/config.json
    .config/mozilla/firefox/profiles.ini
    .config/mozilla/firefox/installs.ini
    .config/mozilla/firefox/tygqmu3q.default-release/chrome
    .config/mozilla/firefox/tygqmu3q.default-release/user.js
    .local/share/applications/qq.desktop
)

cd "$HOME"
for path in "${paths[@]}"; do
    if [[ -e "$path" || -L "$path" ]]; then
        cp -a --parents "$path" "$backup_dir"
    fi
done

cp -a "$repo_dir/.config/." "$HOME/.config/"
mkdir -p "$HOME/.local/share/applications"
cp -a "$repo_dir/.local/share/applications/." "$HOME/.local/share/applications/"

printf 'Restored. Previous files: %s\n' "$backup_dir"
printf '%s\n' 'Restart the affected applications or log in again.'
