#!/usr/bin/env bash

SCRIPT_PATH="$(realpath "$0")"
REPO_DIR="$(dirname "$SCRIPT_PATH")"

# also pull from this repository for the blocks and i3 config snippet to get the newest version of the files

if [ -d "$REPO_DIR/.git" ]; then
    echo "[0/6] Updating repository..."
    git -C "$REPO_DIR" pull --ff-only
fi

REQ_FILE="$REPO_DIR/requirements.apt"

TARGET_DIR="$HOME/.config/i3blocks-unified"
I3_CONFIG="$HOME/.config/i3/config"

MARKER_START="# >>> i3blocks-unified START >>>"
MARKER_END="# <<< i3blocks-unified END <<<"

# check if requirements file exists
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

# backup existing i3blocks config and i3 config if they exist
if [ -d "$HOME/.config/i3blocks" ]; then
  cp -r "$HOME/.config/i3blocks" "$BACKUP_DIR/"
fi

if [ -f "$I3_CONFIG" ]; then
  cp "$I3_CONFIG" "$BACKUP_DIR/i3-config.bak"
fi

echo "[3/6] Copying files..."

# replace existing i3blocks-unified config with the new one
rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"

# copy blocks and i3blocks.conf to the target directory
cp -r "$REPO_DIR/blocks" "$TARGET_DIR/"
cp "$REPO_DIR/i3blocks.conf" "$TARGET_DIR/"

# make the block scripts executable
chmod +x "$TARGET_DIR/blocks/"*.sh

echo "[4/6] Generating env file..."

# generate env file with battery name of the user's battery
BATTERY_NAME=$(ls /sys/class/power_supply | grep BAT | head -n1 || true)

cat > "$TARGET_DIR/i3blocks.env" <<EOF
BATTERY_NAME="${BATTERY_NAME:-BAT0}"
EOF

echo "[5/6] Injecting i3 bar config snippet into existing config file..."

SNIPPET_FILE="$REPO_DIR/i3bar_snippet.conf"

if [ ! -f "$SNIPPET_FILE" ]; then
  echo "Error: missing snippet file: $SNIPPET_FILE"
  exit 1
fi

# find other start for i3b blocks from the user and comment it out to avoid conflicts with the new config
# match any bar {
# ... }
comment_out_bar_blocks() {
    local input="$1"
    local output="${input}.tmp"

    local in_bar=0
    local line=""
    local depth=0

    # Read config line by line
    while IFS= read -r line; do

        # not in a bar block, check if a bar block starts here
        if [[ "$in_bar" -eq 0 ]]; then

            case "$line" in
                # Ignore already commented bar start lines
                \#*[[:space:]]bar[[:space:]]*\{* )
                    printf '%s\n' "$line" >> "$output"
                    continue
                    ;;

                # Active bar start, add # to it
                [[:space:]]*bar[[:space:]]*\{* )
                    in_bar=1 # mark that we are now inside a bar block
                    printf '# %s\n' "$line" >> "$output"
                    continue
                    ;;
            esac
        fi

        # if we are inside a bar block, comment out all lines until we find the closing }
        if [[ "$in_bar" -eq 1 ]]; then
            printf '# %s\n' "$line" >> "$output"

            # count braces in this line
            local opens closes

            opens="$(grep -o "{" <<< "$line" | wc -l)"  # count { in the line
            closes="$(grep -o "}" <<< "$line" | wc -l)" # count } in the line

            # Update nesting depth
            depth=$((depth + opens - closes))

            # bar block ended (matching closing })
            if [[ "$depth" -le 0 ]]; then
                in_bar=0
                depth=0
            fi

        else
            # outside of a bar block, just print the line as is
            printf '%s\n' "$line" >> "$output"
        fi

    done < "$input"

    # Replace original file
    mv "$output" "$input"
}

# call the function to comment out existing bar blocks in the user's i3 config
comment_out_bar_blocks "$I3_CONFIG"

# find starting point for the new snippet in the existing config, if it does not exist already (such that not appended multiple times)
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
