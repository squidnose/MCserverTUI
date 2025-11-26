#!/bin/bash

# Always use the script folder, not working directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

CONF_FILE="$SCRIPT_DIR/server-versoin.conf"
DOWNLOADER="$SCRIPT_DIR/modrinth-autodownloader.py"

# Load config
load_config() {
    if [ -f "$CONF_FILE" ]; then
        source "$CONF_FILE"
    else
        VERSION=""
        LOADER=""
        COLLECTION=""
    fi
}

# Save config
save_config() {
    cat <<EOF > "$CONF_FILE"
VERSION=$VERSION
LOADER=$LOADER
COLLECTION=$COLLECTION
EOF
}

# Input helper
input_prefill() {
    whiptail --inputbox "$1" 10 60 "$2" 3>&1 1>&2 2>&3
}

# Main logic
load_config

VERSION=$(input_prefill "Minecraft Version:" "$VERSION")
LOADER=$(input_prefill "Loader (fabric/forge/paper/etc):" "$LOADER")
COLLECTION=$(input_prefill "Modrinth Collection ID:" "$COLLECTION")

save_config

if [ ! -f "$DOWNLOADER" ]; then
    whiptail --msgbox "Error: modrinth-autodownloader.py not found in $SCRIPT_DIR" 10 60
    exit 1
fi

python3 "$DOWNLOADER" -v "$VERSION" -l "$LOADER" -c "$COLLECTION"
exit 0
