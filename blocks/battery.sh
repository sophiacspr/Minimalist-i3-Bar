#!/bin/bash



ENV_FILE="$HOME/.config/i3blocks-unified/i3blocks.env"
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
fi

# BATTERY_NAME must be provided
if [ -z "${BATTERY_NAME:-}" ]; then
    echo "Battery: N/A"
    exit 0
fi

BAT="/sys/class/power_supply/$BATTERY_NAME"

if [ ! -d "$BAT" ]; then
    echo "Battery: N/A"
    exit 0
fi

# optional power profile support
if command -v powerprofilesctl >/dev/null; then
    profile=$(powerprofilesctl get 2>/dev/null || echo "unknown")
else
    profile="default"
fi

# cycle on click (only if supported)
if [ "${BLOCK_BUTTON:-}" = "1" ] && command -v powerprofilesctl >/dev/null; then
    case "$profile" in
        power-saver) powerprofilesctl set balanced || true ;;
        balanced)    powerprofilesctl set performance || true ;;
        performance) powerprofilesctl set power-saver || true ;;
    esac
    profile=$(powerprofilesctl get 2>/dev/null || echo "unknown")
fi

capacity=$(cat "$BAT/capacity" 2>/dev/null || echo "")
status=$(cat "$BAT/status" 2>/dev/null || echo "")

# validate numeric capacity
if ! [[ "$capacity" =~ ^[0-9]+$ ]]; then
    echo "Battery: ?"
    exit 0
fi

# update status 
if [ "$status" = "Charging" ]; then
    echo "${capacity}%🔌 (${profile})"
else
    if [ "$capacity" -lt 20 ]; then
        echo "${capacity}%🪫 (${profile})"
    else
        echo "${capacity}%🔋 (${profile})"
    fi
fi