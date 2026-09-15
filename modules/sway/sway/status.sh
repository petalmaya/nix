#!/usr/bin/env bash
#
# swaybar status_command script — emits i3bar protocol JSON.
# Reproduces: [media]  ⌨ layout  ⇅ iface (ping ms)  🏋 load  🔊 vol%  ⚡ batt%  date (wWW)  🕐 time
#
# Deps: playerctl, jq, pactl (pipewire-pulse), swaymsg, ip (iproute2), ping (iputils), awk/cut
# Fixes: proper i3bar framing (leading comma, no trailing comma), jq-escaped JSON,
#        portable grep, $HOME-expanded status_command, and set -u safety.
#

set -u

# i3bar protocol header — must be exactly {"version":1} then [ then []
echo '{"version":1}'
echo '['
echo '[]'

# Helper: build a single i3bar block safely via jq (handles quotes/emoji/escaping)
# Usage: make_block "text with \"quotes\" and emoji 🔊"
make_block() {
    local text="$1"
    if command -v jq >/dev/null 2>&1; then
        jq -cn --arg t "$text" '{"full_text": $t}'
    else
        # fallback: minimal escaping if jq missing (should not happen; jq is in sway pkgs)
        local esc=${text//\\/\\\\}
        esc=${esc//\"/\\\"}
        esc=${esc//$'\n'/ }
        esc=${esc//$'\r'/ }
        printf '{"full_text":"%s"}' "$esc"
    fi
}

while true; do
    blocks=()

    # --- Media (playerctl) ---
    if command -v playerctl >/dev/null 2>&1; then
        status=$(playerctl status 2>/dev/null || true)
        if [ -n "${status:-}" ]; then
            case "$status" in
                Playing) icon="▶" ;;
                Paused)  icon="⏸" ;;
                *)       icon="⏹" ;;
            esac
            title=$(playerctl metadata --format '{{artist}} - {{title}}' 2>/dev/null || true)
            if [ -z "${title:-}" ]; then
                title=$(playerctl metadata title 2>/dev/null || true)
            fi
            if [ -n "${title:-}" ]; then
                blocks+=("$(make_block "$icon $title")")
            fi
        fi
    fi

    # --- Keyboard layout ---
    kbd=""
    if command -v swaymsg >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
        kbd=$(swaymsg -t get_inputs -r 2>/dev/null | jq -r '[.[] | select(.type=="keyboard")][0].xkb_active_layout_name // empty' 2>/dev/null || true)
    fi
    if [ -z "${kbd:-}" ]; then
        kbd="?"
    fi
    blocks+=("$(make_block "⌨ $kbd")")

    # --- Network: default iface + ping ---
    iface=""
    if command -v ip >/dev/null 2>&1; then
        iface=$(ip route 2>/dev/null | awk '/^default/ {print $5; exit}' || true)
    fi
    if [ -z "${iface:-}" ]; then
        iface="none"
    fi
    ping_ms=""
    if command -v ping >/dev/null 2>&1; then
        ping_ms=$(ping -c1 -W1 1.1.1.1 2>/dev/null | awk -F'time=' '/time=/ {split($2,a," "); print a[1]}' || true)
    fi
    if [ -n "${ping_ms:-}" ]; then
        # strip decimal part without assuming bash substring on empty
        ping_int=${ping_ms%%.*}
        net_text="⇅ $iface (${ping_int} ms)"
    else
        net_text="⇅ $iface (down)"
    fi
    blocks+=("$(make_block "$net_text")")

    # --- Load average ---
    load=$(cut -d' ' -f1 /proc/loadavg 2>/dev/null || true)
    if [ -n "${load:-}" ]; then
        blocks+=("$(make_block "🏋 $load")")
    fi

    # --- Volume ---
    if command -v pactl >/dev/null 2>&1; then
        # portable grep: no -P (PCRE) — not guaranteed on minimal systems; use -o '[0-9]*%'
        vol=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -o '[0-9]*%' | head -1 | tr -d '%' || true)
        mute=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | awk '{print $2}' || true)
        if [ "${mute:-}" = "yes" ]; then
            blocks+=("$(make_block "🔇 muted")")
        elif [ -n "${vol:-}" ]; then
            blocks+=("$(make_block "🔊 ${vol}%")")
        fi
    fi

    # --- Battery / charge ---
    for bat in /sys/class/power_supply/BAT*; do
        [ -d "$bat" ] || continue
        cap=$(cat "$bat/capacity" 2>/dev/null || true)
        st=$(cat "$bat/status" 2>/dev/null || true)
        if [ "${st:-}" = "Charging" ]; then
            icon="⚡"
        else
            icon="🔋"
        fi
        if [ -n "${cap:-}" ]; then
            blocks+=("$(make_block "$icon ${cap}%")")
        fi
        break
    done

    # --- Date + time (with ISO week number) ---
    datetime=$(date "+%Y/%m/%d (w%V) 🕐 %H:%M" 2>/dev/null || date)
    blocks+=("$(make_block "$datetime")")

    # Join blocks with commas and emit a single JSON array line WITH leading comma.
    # i3bar requires: first line after [] is ",[...]" (comma prefix), no trailing comma.
    # Previous buggy version used "[...]," (trailing comma, no leading comma) which
    # makes sway report "Error reading from status bar" due to JSON parse failure.
    if [ ${#blocks[@]} -eq 0 ]; then
        echo ",[]"
    else
        (IFS=,; echo ",[${blocks[*]}]")
    fi

    sleep 1
done
