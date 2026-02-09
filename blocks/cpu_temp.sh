#!/bin/bash



# dependency check
if ! command -v sensors >/dev/null; then
    echo "N/A"
    exit 0
fi

# try common CPU temperature patterns
temp=$(
    sensors 2>/dev/null | awk '
        /^Package id 0:/ {print $4; exit}
        /^Tctl:/         {print $2; exit}
        /^Core 0:/       {print $3; exit}
    '
)

if [ -z "$temp" ]; then
    echo "N/A"
else
    echo "$temp"
fi
