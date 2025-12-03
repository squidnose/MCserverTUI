#!/bin/bash
#==================================== location ====================================
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
MC_ROOT="$HOME/mcservers"

#==================================== 0. Parse CLI flags ====================================
PASSED_NAME=""
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --name|-n)
            PASSED_NAME="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1"
            exit 1
            ;;
    esac
done
#==================================== 1. Select a server ====================================
if [ -n "$PASSED_NAME" ]; then
    # Bypass menu, validate directory
    SERVER_NAME="$PASSED_NAME"
    SERVER_DIR="$MC_ROOT/$SERVER_NAME"

    if [ ! -d "$SERVER_DIR" ]; then
        whiptail --title "Error" --msgbox "Server '$SERVER_NAME' does not exist!" 10 60
        exit 0
    fi

else
    # Build menu items from directories
    MENU_ITEMS=()
    for d in "$MC_ROOT"/*; do
        [ -d "$d" ] || continue
        NAME=$(basename "$d")
        MENU_ITEMS+=("$NAME" "Minecraft server")
    done

    SERVER_NAME=$(whiptail --title "Choose Server" --menu "Select a server to manage:" 20 60 10 \
        "${MENU_ITEMS[@]}" \
        3>&1 1>&2 2>&3) || exit 0

    SERVER_DIR="$MC_ROOT/$SERVER_NAME"
fi

#==================================== 2. Load config file ====================================
CONF_FILE="$SERVER_DIR/server-version.conf"

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
    3>&1 1>&2 2>&3) || exit 0

MC_LOADER=$(whiptail --title "Loader" --inputbox \
    "Enter loader, supported:\nforge, fabric, quilt, neoforge, liteloader" 10 60 "$loader" \
    3>&1 1>&2 2>&3) || exit 0

MC_COLLECTION=$(whiptail --title "Collection" --inputbox \
    "Modrinth collection ID (optional):" 10 60 "$collection" \
    3>&1 1>&2 2>&3) || exit 0

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
