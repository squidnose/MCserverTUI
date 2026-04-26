#!/usr/bin/env bash
# Install modrinth mods from a Collection
# TUI wraper for https://github.com/aayushdutt/modrinth-collection-downloader

#============================ 1 - MCserverTUI Config File ============================
MCSERVERTUI_CONF="$HOME/.local/state/MCserverTUI/MCserverTUI.conf"
if [ -f "$MCSERVERTUI_CONF" ]; then
    source "$MCSERVERTUI_CONF"
else
    echo "No MCserverTUI config file, please run MC-server-TUI.sh first!"
    exit 1
fi
#New parameters:
MC_ROOT="$mcdir"
## loggs (true or false)
## backups

#============================ 2 - Term size and script Location ============================
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
## Detect terminal size
### in case tput is not found, sets to fixed value
TERM_HEIGHT=$(tput lines 2>/dev/null || echo 24)
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
## Set TUI size based on terminal size
HEIGHT=$(( TERM_HEIGHT ))
WIDTH=$(( TERM_WIDTH ))
MENU_HEIGHT=$(( HEIGHT - 10 ))

TITLE="Modrinth Collection Downloader"
#============================ 3 - Parse CLI flags ============================
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

#============================ 4 - Select a server (Failsafe) ============================
if [ -n "$PASSED_NAME" ]; then
    # Bypass menu, validate directory
    SERVER_NAME="$PASSED_NAME"
    SERVER_DIR="$MC_ROOT/$SERVER_NAME"

    if [ ! -d "$SERVER_DIR" ]; then
        whiptail --title "Error" --msgbox "Server '$SERVER_NAME' does not exist!" "$HEIGHT" "$WIDTH"
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

    SERVER_NAME=$(whiptail --title "$TITLE - Choose Server" --menu "Select a server to manage:" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
        "${MENU_ITEMS[@]}" \
        3>&1 1>&2 2>&3) || exit 0

    SERVER_DIR="$MC_ROOT/$SERVER_NAME"
fi

#============================ 5 - Load config file ============================
CONF_FILE="$SERVER_DIR/server-version.conf"

if [ -f "$CONF_FILE" ]; then
    source "$CONF_FILE"
else
    version=""
    loader=""
    collection=""
fi
#==================================== 5. Run Downloader ====================================
if whiptail --title "$TITLE" --yesno \
    "Download mods using these settings?\nMCserver: $SERVER_NAME\nVersion: $version\nLoader: $loader\nCollection ID: $collection" "$HEIGHT" "$WIDTH"; then

    if [[ "$loader" == "fabric" || \
          "$loader" == "forge" || \
          "$loader" == "neoforge" || \
          "$loader" == "liteloader" || \
          "$loader" == "quilt" || \
          "$loader" == "rift" ]]; then

            # Build arguments dynamically
            ARGS=(-v "$version" -l "$loader")
            [ -n "$collection" ] && ARGS+=(-c "$collection")

    elif [[ "$loader" == "paper" || \
            "$loader" == "purpur" || \
            "$loader" == "folia" || \
            "$loader" == "spigot" || \
            "$loader" == "bukkit" || \
            "$loader" == "sponge" || \
            "$loader" == "velocity" ]]; then

            # Build arguments dynamically
            ARGS=(-v "$version" -l "$loader" -d "./plugins")
            [ -n "$collection" ] && ARGS+=(-c "$collection")

    else
        whiptail --title "Error" --msgbox \
            "Unsupported loader: $loader" "$HEIGHT" "$WIDTH"
        exit 0
    fi

    # Run Python *inside the server directory*
    (
        cd "$SERVER_DIR" || exit
        python3 "$SCRIPT_DIR/modrinth-autodownloader.py" "${ARGS[@]}"
        read -p "Press anything to continue"
    )
fi


whiptail --title "$TITLE" --msgbox "Modrinth download complete for $SERVER_NAME!" "$HEIGHT" "$WIDTH"
exit 0
