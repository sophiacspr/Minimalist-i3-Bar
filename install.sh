#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REQ_FILE="$REPO_DIR/requirements.apt"

TARGET_DIR="$HOME/.config/i3blocks-unified"
I3_CONFIG="$HOME/.config/i3/config"

MARKER_START="# >>> i3blocks-unified START >>>"
MARKER_END="# <<< i3blocks-unified END <<<"

if [ ! -f "$REQ_FILE" ]; then
  echo "Error: requirements file not found: $REQ_FILE"
  exit 1
fi

echo "[1/6] Installing dependencies..."

sudo apt update

PACKAGES=$(grep -vE '^\s*#|^\s*$' "$REQ_FILE")

sudo apt install -y $PACKAGES


echo "[2/6] Backing up existing configs..."

BACKUP_DIR="$HOME/.config/i3blocks-unified-backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

if [ -d "$HOME/.config/i3blocks" ]; then
  cp -r "$HOME/.config/i3blocks" "$BACKUP_DIR/"
fi

if [ -f "$I3_CONFIG" ]; then
  cp "$I3_CONFIG" "$BACKUP_DIR/i3-config.bak"
fi

echo "[3/6] Copying files..."

rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"

cp -r "$REPO_DIR/blocks" "$TARGET_DIR/"
cp "$REPO_DIR/i3blocks.conf" "$TARGET_DIR/"

chmod +x "$TARGET_DIR/blocks/"*.sh

echo "[4/6] Generating env file..."

BATTERY_NAME=$(ls /sys/class/power_supply | grep BAT | head -n1 || true)
INTERFACE_WIFI=$(nmcli -t -f DEVICE,TYPE device status | grep wifi | cut -d: -f1 | head -n1 || true)

cat > "$TARGET_DIR/i3blocks.env" <<EOF
BATTERY_NAME="${BATTERY_NAME:-BAT0}"
INTERFACE_WIFI="${INTERFACE_WIFI:-wlp2s0}"
THEME_ACCENT="#88c0d0"
EOF

echo "[5/6] Injecting i3 bar config..."

SNIPPET_FILE="$REPO_DIR/config/i3bar_snippet.conf"

echo "[5/6] Injecting i3 bar config..."

if [ ! -f "$SNIPPET_FILE" ]; then
  echo "Error: missing snippet file: $SNIPPET_FILE"
  exit 1
fi

if ! grep -q "i3blocks-unified START" "$I3_CONFIG"; then
    {
        echo ""
        echo "$MARKER_START"
        cat "$SNIPPET_FILE"
        echo "$MARKER_END"
    } >> "$I3_CONFIG"
fi


echo "[6/6] Reloading i3..."

i3-msg reload >/dev/null || true
i3-msg restart >/dev/null || true

echo "Install complete."
echo "Backup stored in: $BACKUP_DIR"
