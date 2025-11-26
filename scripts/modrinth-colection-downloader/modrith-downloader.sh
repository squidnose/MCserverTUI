#!/bin/bash
#==================================== location ====================================
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
MC_ROOT="$HOME/mcservers"

#==================================== 1. Select a server ====================================
# Build menu items from directories
MENU_ITEMS=()
for d in "$MC_ROOT"/*; do
    [ -d "$d" ] || continue
    NAME=$(basename "$d")
    MENU_ITEMS+=("$NAME" "Minecraft server")
done

SERVER_NAME=$(whiptail --title "Choose Server" --menu "Select a server to manage:" 20 60 10 \
    "${MENU_ITEMS[@]}" \
    3>&1 1>&2 2>&3) || exit 1

SERVER_DIR="$MC_ROOT/$SERVER_NAME"
CONF_FILE="$SERVER_DIR/server-version.conf"

#==================================== 2. Load config file ====================================

if [ -f "$CONF_FILE" ]; then
    source "$CONF_FILE"
else
    version=""
    loader=""
    collection=""
fi

#========================= 3. Ask for updated values (pre-filled) ==============================
MC_VERSION=$(whiptail --title "Minecraft Version" --inputbox \
    "Enter version:" 10 60 "$version" \
    3>&1 1>&2 2>&3) || exit 1

MC_LOADER=$(whiptail --title "Loader" --inputbox \
    "Enter loader (fabric/vanilla/etc):" 10 60 "$loader" \
    3>&1 1>&2 2>&3) || exit 1

MC_COLLECTION=$(whiptail --title "Collection" --inputbox \
    "Modrinth collection ID (optional):" 10 60 "$collection" \
    3>&1 1>&2 2>&3) || exit 1

#============================ 4. Save updated config ====================================

cat > "$CONF_FILE" <<EOF
version=$MC_VERSION
loader=$MC_LOADER
collection=$MC_COLLECTION
EOF

#==================================== 5. Run Downloader ====================================
if whiptail --title "Run Modrinth Downloader" --yesno \
    "Download mods using these settings?" 10 60; then

    # Build arguments dynamically
    ARGS=(-v "$MC_VERSION" -l "$MC_LOADER")

    [ -n "$MC_COLLECTION" ] && ARGS+=(-c "$MC_COLLECTION")

    # Run Python *inside the server directory*
    (
        cd "$SERVER_DIR" || exit
        python3 "$SCRIPT_DIR/modrinth-autodownloader.py" "${ARGS[@]}"
    )
fi

whiptail --title "Done" --msgbox "Modrinth download complete for $SERVER_NAME!" 10 60
exit 0
