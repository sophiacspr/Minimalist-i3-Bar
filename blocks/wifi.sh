#!/bin/bash



# dependency check
if ! command -v nmcli >/dev/null; then
    echo "Wi-Fi: N/A"
    exit 0
fi

# click opens network editor (optional)
if [ "${BLOCK_BUTTON:-}" = "1" ]; then
    if command -v nm-connection-editor >/dev/null; then
        nm-connection-editor >/dev/null 2>&1 &
    fi
fi

# check wifi enabled
wifi_state=$(nmcli -t -f WIFI g 2>/dev/null || echo "unknown")
if [ "$wifi_state" = "disabled" ]; then
    echo "Wi-Fi: Off"
    exit 0
fi

# current connection (active SSID)
essid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null \
  | awk -F: '$1=="yes"{print $2; exit}')

if [ -z "$essid" ]; then
    echo "Wi-Fi: Disconnected"
else
    safe_essid=$(echo "$essid" | sed 's/\\/\\\\/g; s/"/\\"/g; s/%/%%/g')
    echo "Wi-Fi: $safe_essid"
fi
