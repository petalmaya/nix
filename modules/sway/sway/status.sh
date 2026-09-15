#!/bin/bash
#
# swaybar status_command script — emits i3bar protocol JSON.
# Reproduces: [media]  ⌨ layout  ⇅ iface (ping ms)  🏋 load  🔊 vol%  ⚡ batt%  date (wWW)  🕐 time
#
# Deps: playerctl, jq, pactl (pulseaudio-utils or pipewire-pulse),
#       swaymsg (comes with sway), ping, awk/cut (coreutils)

set -u

# i3bar protocol header
echo '{"version":1}'
echo '['
echo '[]'

while true; do
    blocks=()

    # --- Media (playerctl) ---
    if command -v playerctl >/dev/null 2>&1; then
        status=$(playerctl status 2>/dev/null)
        if [ -n "$status" ]; then
            case "$status" in
                Playing) icon="▶" ;;
                Paused)  icon="⏸" ;;
                *)       icon="⏹" ;;
            esac
            title=$(playerctl metadata --format '{{artist}} - {{title}}' 2>/dev/null)
            [ -z "$title" ] && title=$(playerctl metadata title 2>/dev/null)
            [ -n "$title" ] && blocks+=("{\"full_text\":\"$icon $title\"}")
        fi
    fi

    # --- Keyboard layout ---
    kbd=$(swaymsg -t get_inputs -r 2>/dev/null \
        | jq -r '[.[] | select(.type=="keyboard")][0].xkb_active_layout_name // empty')
    [ -z "$kbd" ] && kbd="?"
    blocks+=("{\"full_text\":\"⌨ $kbd\"}")

    # --- Network: default iface + ping ---
    iface=$(ip route 2>/dev/null | awk '/^default/ {print $5; exit}')
    [ -z "$iface" ] && iface="none"
    ping_ms=$(ping -c1 -W1 1.1.1.1 2>/dev/null | awk -F'time=' '/time=/ {split($2,a," "); print a[1]}')
    if [ -n "$ping_ms" ]; then
        net_text="⇅ $iface (${ping_ms%.*} ms)"
    else
        net_text="⇅ $iface (down)"
    fi
    blocks+=("{\"full_text\":\"$net_text\"}")

    # --- Load average ---
    load=$(cut -d' ' -f1 /proc/loadavg 2>/dev/null)
    [ -n "$load" ] && blocks+=("{\"full_text\":\"🏋 $load\"}")

    # --- Volume ---
    if command -v pactl >/dev/null 2>&1; then
        vol=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -oP '\d+(?=%)' | head -1)
        mute=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | awk '{print $2}')
        if [ "$mute" = "yes" ]; then
            blocks+=("{\"full_text\":\"🔇 muted\"}")
        elif [ -n "$vol" ]; then
            blocks+=("{\"full_text\":\"🔊 ${vol}%\"}")
        fi
    fi

    # --- Battery / charge ---
    for bat in /sys/class/power_supply/BAT*; do
        [ -d "$bat" ] || continue
        cap=$(cat "$bat/capacity" 2>/dev/null)
        st=$(cat "$bat/status" 2>/dev/null)
        [ "$st" = "Charging" ] && icon="⚡" || icon="🔋"
        [ -n "$cap" ] && blocks+=("{\"full_text\":\"$icon ${cap}%\"}")
        break
    done

    # --- Date + time (with ISO week number) ---
    datetime=$(date "+%Y/%m/%d (w%V) 🕐 %H:%M")
    blocks+=("{\"full_text\":\"$datetime\"}")

    # Join blocks with commas, print as a JSON array line
    (IFS=,; echo "[${blocks[*]}],")

    sleep 1
done
