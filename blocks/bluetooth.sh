#!/bin/bash

# check dependency for bluetoothctl
if ! command -v bluetoothctl >/dev/null; then
    echo "Bluetooth: N/A"
    exit 0
fi

# check if bluetooth is available
if ! bluetoothctl show >/dev/null 2>&1; then
    echo "Bluetooth: Unavailable"
    exit 0
fi


# click opens Bluetooth settings using blueman manager
if [ "$BLOCK_BUTTON" == "1" ]; then
    # check if blueman is available
    if ! command -v blueman-manager >/dev/null; then
        exit 0
    fi
	setsid blueman-manager >/dev/null 2>&1 &
fi

# get power status
power_status=$(bluetoothctl show | awk '/Powered:/ {print $2}')

# check power on
if [ -z "$power_status" ] || [ "$power_status" != "yes" ]; then
    echo "Bluetooth: Off"
    exit 0
fi

#  get connected devices
# extract lines with connected devices
device_lines="$(bluetoothctl devices Connected 2>/dev/null)"

# extract device names
device_names="$(
    echo "$device_lines" |
    cut -d ' ' -f 3- # split at space and third field onwards (remove "Device XX:XX:XX:XX:XX:XX")
)"
# remove leading whitespaces from the names 
device_names="$(echo "$device_names" | sed 's/^[[:space:]]*//')" # ^ matches start
# remove trailing whitespaces from the names
device_names="$(echo "$device_names" | sed 's/[[:space:]]*$//')" # $ matches end

connected_devices="$(
    echo "$device_names" |
    awk '
        NR == 1 { out = $0; next }
        { out = out ", " $0 }
        END { print out }
    '
)"  # first line: initialize out with device name, then append ", " and next device name for other lines, finally print the result

# print status
if [ -z "$connected_devices" ]; then
    echo "Bluetooth: On"
else
    echo "Bluetooth: $connected_devices"
fi
