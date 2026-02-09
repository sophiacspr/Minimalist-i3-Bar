#!/bin/bash

BASE="$HOME/.config/i3blocks-unified/blocks"
CONTROL="$BASE/volume_control.sh"
STATUS="$BASE/volume_status.sh"

case "${BLOCK_BUTTON:-}" in
    1) "$CONTROL" mute ;;
    4) "$CONTROL" up ;;
    5) "$CONTROL" down ;;
esac

"$STATUS"
exit 0
