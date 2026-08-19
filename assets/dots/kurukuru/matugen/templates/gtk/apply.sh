#!/usr/bin/env bash
set -euo pipefail

GTK_IMPORT='@import url("flutterice.css");'

theme_exists() {
    local name="$1"
    local -a paths=(
        "$HOME/.themes"
        "${XDG_DATA_HOME:-$HOME/.local/share}/themes"
        /usr/share/themes
        /usr/local/share/themes
        /run/current-system/sw/share/themes
        "$HOME/.nix-profile/share/themes"
        "${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles/profile/share/themes"
        "/etc/profiles/per-user/${USER:-$(id -un 2>/dev/null || echo "$LOGNAME")}/share/themes"
    )
    if [ -n "${XDG_DATA_DIRS:-}" ]; then
        IFS=':' read -ra xdg_dirs <<< "$XDG_DATA_DIRS"
        for dir in "${xdg_dirs[@]}"; do
            [ -n "$dir" ] && paths+=("$dir/themes")
        done
    fi
    for base in "${paths[@]}"; do
        [ -d "$base/$name" ] && return 0
    done
    return 1
}

ensure_gtk_css_import() {
    local gtk_css="$1" colors_file="$2" label="$3"
    local timestamp="/* matugen-reload: $(date +%s%N 2>/dev/null || date +%s) */"

    if [ ! -f "$colors_file" ]; then
        echo "Error: $label flutterice.css not found at $colors_file" >&2
        return 1
    fi

    if [ -e "$gtk_css" ] || [ -L "$gtk_css" ]; then
        local content
        content=$(cat "$gtk_css")
        # Remove previous reload timestamp comments
        content=$(printf '%s\n' "$content" | sed '/\/\* matugen-reload:.* \*\//d')

        local target="$gtk_css"
        if [ -L "$gtk_css" ]; then
            local resolved
            resolved=$(readlink -f "$gtk_css")
            if [ -w "$resolved" ]; then
                target="$resolved"
            else
                # Read-only symlink (e.g. NixOS): convert to a local file
                rm "$gtk_css"
            fi
        fi

        if [[ "$content" != *"flutterice.css"* ]] || [[ "$content" != *"@import"* ]]; then
            content=$(printf '%s\n\n%s' "$content" "$GTK_IMPORT")
            echo "Appended $label flutterice.css import to gtk.css"
        fi

        # Write content with new timestamp so file hash/content changes (forces GTK4 inotify re-evaluation)
        printf '%s\n%s\n' "$content" "$timestamp" > "$target"
    else
        printf '%s\n%s\n' "$GTK_IMPORT" "$timestamp" > "$gtk_css"
        echo "Created $label gtk.css with flutterice.css import"
    fi

    touch "$gtk_css"
}

reload_nautilus() {
    if command -v nautilus >/dev/null 2>&1; then
        if pgrep -x nautilus >/dev/null 2>&1; then
            echo "Reloading Nautilus..."
            nautilus -q || true
        fi
    fi
}

update_gtk3_settings_ini() {
    local theme="$1" mode="$2"
    local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
    local settings_file="$config_dir/gtk-3.0/settings.ini"
    local prefer_dark="false"
    [ "$mode" = "dark" ] && prefer_dark="true"

    mkdir -p "$(dirname "$settings_file")"

    if [ -L "$settings_file" ]; then
        local resolved
        resolved=$(readlink -f "$settings_file")
        if [ ! -w "$resolved" ]; then
            rm "$settings_file"
        fi
    fi

    if [ ! -f "$settings_file" ]; then
        cat <<EOF > "$settings_file"
[Settings]
gtk-theme-name=$theme
gtk-application-prefer-dark-theme=$prefer_dark
EOF
    else
        # Update or append keys in [Settings]
        if grep -q "gtk-theme-name" "$settings_file"; then
            sed -i "s/^gtk-theme-name=.*/gtk-theme-name=$theme/" "$settings_file"
        else
            sed -i "/\[Settings\]/a gtk-theme-name=$theme" "$settings_file" 2>/dev/null \
                || printf '\ngtk-theme-name=%s\n' "$theme" >> "$settings_file"
        fi

        if grep -q "gtk-application-prefer-dark-theme" "$settings_file"; then
            sed -i "s/^gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=$prefer_dark/" "$settings_file"
        else
            sed -i "/\[Settings\]/a gtk-application-prefer-dark-theme=$prefer_dark" "$settings_file" 2>/dev/null \
                || printf 'gtk-application-prefer-dark-theme=%s\n' "$prefer_dark" >> "$settings_file"
        fi
    fi
}

sync_system_appearance() {
    local mode="$1" update_gtk_theme="${2:-true}"
    local has_gsettings has_dconf
    has_gsettings=$(command -v gsettings || true)
    has_dconf=$(command -v dconf || true)

    local target_theme
    [ "$mode" = "light" ] && target_theme="adw-gtk3" || target_theme="adw-gtk3-dark"

    local theme_available=false
    if [ "$update_gtk_theme" = "true" ]; then
        if theme_exists "$target_theme"; then
            theme_available=true
            echo "Using GTK theme: $target_theme"
        else
            echo "Theme '$target_theme' not found on system paths, skipping gtk-theme setting"
        fi
    fi

    # Update GTK3 settings.ini for standalone GTK3 apps
    if [ "$theme_available" = "true" ]; then
        update_gtk3_settings_ini "$target_theme" "$mode"
    fi

    if [ -z "$has_gsettings" ] && [ -z "$has_dconf" ]; then
        echo "No gsettings or dconf found, skip system appearance sync"
        return
    fi

    if [ -n "$has_gsettings" ]; then
        local schemas
        schemas=$(gsettings list-schemas 2>/dev/null || true)
        if [[ "$schemas" == *"org.gnome.desktop.interface"* ]]; then
            # Color scheme
            gsettings set org.gnome.desktop.interface color-scheme "prefer-$mode" \
                || echo "Error running gsettings set color-scheme" >&2

            # Theme bouncing: toggle temporarily to trigger GSettings/D-Bus 'changed::gtk-theme' signal
            # This forces all running GTK3 and GTK4 apps to flush their style cache and reload gtk.css live!
            if [ "$theme_available" = "true" ]; then
                local bounce_theme="Adwaita"
                [ "$target_theme" = "Adwaita" ] && bounce_theme="HighContrast"
                gsettings set org.gnome.desktop.interface gtk-theme "$bounce_theme" 2>/dev/null || true
                gsettings set org.gnome.desktop.interface gtk-theme "$target_theme" \
                    || echo "Error running gsettings set gtk-theme" >&2
            else
                # Even if custom theme is not installed, bounce current theme to trigger CSS reload
                local cur_theme
                cur_theme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'" || echo "Adwaita")
                local bounce_theme="HighContrast"
                [ "$cur_theme" = "HighContrast" ] && bounce_theme="Adwaita"
                gsettings set org.gnome.desktop.interface gtk-theme "$bounce_theme" 2>/dev/null || true
                gsettings set org.gnome.desktop.interface gtk-theme "$cur_theme" 2>/dev/null || true
            fi

            # Notify xsettingsd if active
            if pgrep -x xsettingsd >/dev/null 2>&1; then
                killall -HUP xsettingsd 2>/dev/null || true
            fi
            return
        fi
    fi

    if [ -n "$has_dconf" ]; then
        dconf write /org/gnome/desktop/interface/color-scheme "'prefer-$mode'" \
            || echo "Error running dconf write color-scheme" >&2
        if [ "$theme_available" = "true" ]; then
            dconf write /org/gnome/desktop/interface/gtk-theme "'$target_theme'" \
                || echo "Error running dconf write gtk-theme" >&2
        fi
    fi
}

main() {
    local appearance_only=false mode=""

    if [ "${1:-}" = "--appearance-only" ]; then
        appearance_only=true
        shift
    fi
    if [ $# -ne 1 ] || { [ "$1" != "dark" ] && [ "$1" != "light" ]; }; then
        echo "Usage: apply.sh [--appearance-only] (dark|light)" >&2
        exit 1
    fi
    mode="$1"

    if [ "$appearance_only" = "true" ]; then
        sync_system_appearance "$mode" "false"
        reload_nautilus
        return
    fi

    # Standard XDG Config Directory fallback
    local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"

    if [ ! -d "$config_dir" ]; then
        echo "Error: Config directory not found: $config_dir" >&2
        exit 1
    fi

    local gtk3_dir="$config_dir/gtk-3.0"
    local gtk4_dir="$config_dir/gtk-4.0"

    mkdir -p "$gtk3_dir" "$gtk4_dir"

    local gtk3_ok=true gtk4_ok=true
    if ! ensure_gtk_css_import \
            "$gtk3_dir/gtk.css" "$gtk3_dir/flutterice.css" "GTK3"; then
        gtk3_ok=false
    fi
    if ! ensure_gtk_css_import \
            "$gtk4_dir/gtk.css" "$gtk4_dir/flutterice.css" "GTK4"; then
        gtk4_ok=false
    fi

    [ "$gtk3_ok" = "true" ] && echo "GTK3 colors applied successfully"
    [ "$gtk4_ok" = "true" ] && echo "GTK4 colors applied successfully"

    if [ "$gtk3_ok" = "true" ] && [ "$gtk4_ok" = "true" ]; then
        sync_system_appearance "$mode" "true"
    else
        sync_system_appearance "$mode" "false"
        reload_nautilus
        exit 1
    fi

    reload_nautilus
}

main "$@"