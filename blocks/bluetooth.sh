#!/bin/bash



# check if bluetoothctl is available
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

#  get connected devices (single line)
connected_devices=$(bluetoothctl devices Connected \
  | cut -d ' ' -f 3- | paste -sd ", ")

if [ -z "$connected_devices" ]; then
    echo "Bluetooth: On"
else
    echo "Bluetooth: $connected_devices"
fi
