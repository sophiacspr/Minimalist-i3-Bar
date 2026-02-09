#!/bin/bash



SINK='@DEFAULT_AUDIO_SINK@'

# dependency check
if ! command -v wpctl >/dev/null; then
    echo "--%🔈"
    exit 0
fi

VOL_RAW=$(wpctl get-volume "$SINK" 2>/dev/null || true)

if [ -z "$VOL_RAW" ]; then
    echo "--%🔈"
    exit 0
fi

# detect mute
MUTE=no
echo "$VOL_RAW" | grep -q MUTED && MUTE=yes

# extract numeric volume (second field)
VOL_VAL=$(echo "$VOL_RAW" | awk '{print $2}')

if ! [[ "$VOL_VAL" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    echo "--%🔈"
    exit 0
fi

VOL=$(awk "BEGIN { printf \"%d\", $VOL_VAL * 100 }")

# padding
printf -v VOL "%3d" "$VOL"

if [ "$MUTE" = yes ]; then
    echo "${VOL}%🔇"
else
    echo "${VOL}%🔊"
fi
