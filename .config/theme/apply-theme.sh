#!/usr/bin/env bash
set -euo pipefail

theme_dir="${XDG_CONFIG_HOME:-$HOME/.config}/theme"
palette="$theme_dir/palette.json"
mode="${1:-dark}"

color() { jq -r --arg mode "$mode" --arg key "$1" '.[$mode][$key]' "$palette"; }

bg=$(color bg); bg2=$(color bg2); bg3=$(color bg3)
fg=$(color fg); fg2=$(color fg2); fg3=$(color fg3)
red=$(color red); teal=$(color teal); orange=$(color orange)
blue=$(color blue); green=$(color green); yellow=$(color yellow); purple=$(color purple)
nvim_selection=$(jq -r --arg mode "$mode" 'if $mode == "dark" then (.nvim_dark.sel // .dark.sel) else .[$mode].sel end' "$palette")
nvim_selection_fg=$(jq -r --arg mode "$mode" 'if $mode == "dark" then (.nvim_dark.fg // .dark.fg) else .[$mode].fg end' "$palette")

{
  printf '$theme_bg = rgb(%s)\n' "${bg#\#}"
  printf '$theme_bg2 = rgb(%s)\n' "${bg2#\#}"
  printf '$theme_fg = rgb(%s)\n' "${fg#\#}"
  printf '$theme_accent = rgb(%s)\n' "${blue#\#}"
  printf '$theme_teal = rgb(%s)\n' "${teal#\#}"
  printf '$theme_error = rgb(%s)\n' "${red#\#}"
} > "$theme_dir/hyprland.conf"

{
  printf 'foreground %s\nbackground %s\nselection_foreground %s\nselection_background %s\n' "$fg2" "$bg" "$nvim_selection_fg" "$nvim_selection"
  printf 'cursor %s\ncursor_text_color %s\nurl_color %s\n' "$red" "$bg" "$blue"
  printf 'active_border_color %s\ninactive_border_color %s\n' "$blue" "$bg3"
  printf 'color0 %s\ncolor1 %s\ncolor2 %s\ncolor3 %s\ncolor4 %s\ncolor5 %s\ncolor6 %s\ncolor7 %s\n' "$bg2" "$red" "$green" "$yellow" "$blue" "$purple" "$teal" "$fg2"
  printf 'color8 %s\ncolor9 %s\ncolor10 %s\ncolor11 %s\ncolor12 %s\ncolor13 %s\ncolor14 %s\ncolor15 %s\n' "$fg3" "$red" "$green" "$yellow" "$blue" "$purple" "$teal" "$fg"
} > "$theme_dir/kitty.conf"

{
  printf '@define-color theme_bg %s;\n@define-color theme_bg2 %s;\n@define-color theme_bg3 %s;\n' "$bg" "$bg2" "$bg3"
  printf '@define-color theme_fg %s;\n@define-color theme_fg2 %s;\n@define-color theme_muted %s;\n' "$fg" "$fg2" "$fg3"
  printf '@define-color theme_accent %s;\n@define-color theme_red %s;\n@define-color theme_teal %s;\n' "$blue" "$red" "$teal"
  printf '@define-color theme_orange %s;\n@define-color theme_green %s;\n@define-color theme_yellow %s;\n@define-color theme_purple %s;\n' "$orange" "$green" "$yellow" "$purple"
} > "$theme_dir/colors.css"

jq --arg mode "$mode" '.[$mode] | {
  background:.bg, surface:.bg, surface_dim:.bg, surface_container:.bg2,
  surface_container_low:.bg1, surface_container_high:.bg2,
  surface_container_highest:.bg3, on_background:.fg, on_surface:.fg,
  on_surface_variant:.fg2, outline:.fg3, outline_variant:.bg3,
  primary:.blue, on_primary:.bg, primary_container:.bg2,
  on_primary_container:.fg, secondary:.teal, tertiary:.purple,
  error:.red, source_color:.blue, surface_tint:.blue,
  scrim:"#000000", shadow:"#000000"
}' "$palette" > "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/nucleus-shell/config/colors.json"

dunst_conf="${XDG_CONFIG_HOME:-$HOME/.config}/dunst/dunstrc"
sed -i -E \
  -e "s|^([[:space:]]*background = )\"#[0-9a-fA-F]{6}\"|\\1\"$bg\"|" \
  -e "s|^([[:space:]]*foreground = )\"#[0-9a-fA-F]{6}\"|\\1\"$fg2\"|" \
  -e "s|^([[:space:]]*frame_color = )\"#[0-9a-fA-F]{6}\"|\\1\"$blue\"|" \
  "$dunst_conf"

firefox_theme="${XDG_CONFIG_HOME:-$HOME/.config}/mozilla/firefox/tygqmu3q.default-release/chrome/theme.css"
{
  printf ':root {\n'
  printf '  --tui-bg: %s; --tui-bg-2: %s; --tui-bg-3: %s;\n' "$bg" "$bg2" "$bg3"
  printf '  --tui-fg: %s; --tui-fg-2: %s; --tui-muted: %s;\n' "$fg" "$fg2" "$fg3"
  printf '  --tui-accent: %s; --tui-error: %s; --tui-ok: %s; --tui-warn: %s;\n' "$blue" "$red" "$green" "$yellow"
  printf '}\n'
} > "$firefox_theme"

firefox_user_js="${XDG_CONFIG_HOME:-$HOME/.config}/mozilla/firefox/tygqmu3q.default-release/user.js"
sed -i -E \
  -e "s|^(user_pref\(\"browser\.display\.background_color\", )[[:space:]]*\"#[0-9a-fA-F]{6}\"\);|\\1\"$bg\"\);|" \
  -e "s|^(user_pref\(\"browser\.display\.background_color\.dark\", )[[:space:]]*\"#[0-9a-fA-F]{6}\"\);|\\1\"$bg\"\);|" \
  "$firefox_user_js"

fish_theme="${XDG_CONFIG_HOME:-$HOME/.config}/fish/conf.d/theme.fish"
{
  printf 'set -g fish_color_normal %s\n' "${fg2#\#}"
  printf 'set -g fish_color_command %s\n' "${fg#\#}"
  printf 'set -g fish_color_keyword %s\n' "${red#\#}"
  printf 'set -g fish_color_quote %s\n' "${fg2#\#}"
  printf 'set -g fish_color_redirection %s\n' "${red#\#}"
  printf 'set -g fish_color_end %s\n' "${red#\#}"
  printf 'set -g fish_color_error %s\n' "${red#\#}"
  printf 'set -g fish_color_param %s\n' "${fg2#\#}"
  printf 'set -g fish_color_comment %s\n' "${fg3#\#}"
  printf 'set -g fish_color_match --background=%s\n' "${bg3#\#}"
  printf 'set -g fish_color_selection --background=%s\n' "${bg2#\#}"
  printf 'set -g fish_color_operator %s\n' "${red#\#}"
  printf 'set -g fish_color_escape %s\n' "${fg#\#}"
  printf 'set -g fish_color_autosuggestion %s\n' "${fg3#\#}"
  printf 'set -g fish_color_cwd %s\n' "${red#\#}"
  printf 'set -g fish_color_cwd_root %s\n' "${red#\#}"
  printf 'set -g fish_pager_color_prefix %s\n' "${red#\#}"
  printf 'set -g fish_pager_color_completion %s\n' "${fg2#\#}"
  printf 'set -g fish_pager_color_description %s\n' "${fg3#\#}"
} > "$fish_theme"

starship_conf="${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"
sed -i -E \
  -e "s|^(bg = ).*|\\1\"$bg\"|" \
  -e "s|^(surface = ).*|\\1\"$bg2\"|" \
  -e "s|^(fg = ).*|\\1\"$fg\"|" \
  -e "s|^(muted = ).*|\\1\"$fg3\"|" \
  -e "s|^(accent = ).*|\\1\"$red\"|" \
  "$starship_conf"

alacritty_theme="${XDG_CONFIG_HOME:-$HOME/.config}/alacritty/theme.toml"
{
  printf '# Generated by ~/.config/theme/apply-theme.sh. Do not edit directly.\n'
  printf '[colors.primary]\nbackground = "%s"\nforeground = "%s"\n\n' "$bg" "$fg2"
  printf '[colors.cursor]\ncursor = "%s"\ntext = "%s"\n\n' "$red" "$bg"
  printf '[colors.vi_mode_cursor]\ncursor = "%s"\ntext = "%s"\n\n' "$fg" "$bg"
  printf '[colors.selection]\nbackground = "%s"\ntext = "%s"\n\n' "$nvim_selection" "$nvim_selection_fg"
  printf '[colors.search.matches]\nbackground = "%s"\nforeground = "%s"\n\n' "$nvim_selection" "$nvim_selection_fg"
  printf '[colors.search.focused_match]\nbackground = "%s"\nforeground = "%s"\n\n' "$red" "$bg"
  printf '[colors.normal]\nblack = "%s"\nred = "%s"\ngreen = "%s"\nyellow = "%s"\nblue = "%s"\nmagenta = "%s"\ncyan = "%s"\nwhite = "%s"\n\n' "$bg2" "$red" "$fg" "$fg2" "$red" "$fg3" "$fg2" "$fg2"
  printf '[colors.bright]\nblack = "%s"\nred = "%s"\ngreen = "%s"\nyellow = "%s"\nblue = "%s"\nmagenta = "%s"\ncyan = "%s"\nwhite = "%s"\n' "$fg3" "$red" "$fg" "$fg2" "$red" "$fg3" "$fg2" "$fg"
} > "$alacritty_theme"

printf 'Applied %s theme from %s\n' "$mode" "$palette"
