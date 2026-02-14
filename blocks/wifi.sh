#!/bin/bash

# dependency check
if ! command -v nmcli >/dev/null; then
    echo "Wi-Fi: N/A"
    exit 0
fi

# click opens network editor (optional)
if [ "$BLOCK_BUTTON" = "1" ]; then
    if command -v nm-connection-editor >/dev/null; then
        nm-connection-editor >/dev/null 2>&1 &
    fi
fi

# check wifi enabled, if there is an error, then unknown is displayed
wifi_state=$(nmcli -t -f WIFI g 2>/dev/null || echo "unknown")

# wifi disabled
if [ "$wifi_state" = "disabled" ]; then
    echo "Wi-Fi: Off"
    exit 0
fi

# current connection (active SSID) (get all ssid and filter the active ones)
essid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null \
  | awk -F: '$1=="yes"{print $2; exit}')

# wifi not connected, but enabled
if [ -z "$essid" ]; then
    echo "Wi-Fi: Disconnected"
else
	# replace \ with \\
    safe_essid=$(sed 's/"/\\"/g' <<< "$safe_essid")
    # replace % with %%
    safe_essid=$(sed 's/%/%%/g' <<< "$safe_essid")
    # replace " with \"
    safe_essid=$(sed 's/"/\\"/g' <<< "$safe_essid")
    echo "Wi-Fi: $safe_essid"
fi
