#!/bin/bash



# First snapshot
read -r cpu user nice system idle iowait irq softirq steal _ < /proc/stat
total=$((user + nice + system + idle + iowait + irq + softirq + steal))
idle_all=$((idle + iowait))

sleep 0.5

# Second snapshot
read -r cpu2 user2 nice2 system2 idle2 iowait2 irq2 softirq2 steal2 _ < /proc/stat
total2=$((user2 + nice2 + system2 + idle2 + iowait2 + irq2 + softirq2 + steal2))
idle_all2=$((idle2 + iowait2))

total_diff=$((total2 - total))
idle_diff=$((idle_all2 - idle_all))

if [ "$total_diff" -le 0 ]; then
    echo "CPU: ?"
    exit 0
fi

usage=$(( (100 * (total_diff - idle_diff)) / total_diff ))

printf -v usage "%2d" "$usage"
echo "CPU: ${usage}%"

# Click action
case "${BLOCK_BUTTON:-}" in
    1)
        if command -v gnome-system-monitor >/dev/null; then
            gnome-system-monitor >/dev/null 2>&1 &
        fi
        ;;
esac
