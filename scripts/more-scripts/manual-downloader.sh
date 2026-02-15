#!/usr/bin/env bash
set -euo pipefail

#==================================== 1. Location ====================================
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
MC_ROOT="$HOME/mcservers"

## Detect terminal size
TERM_HEIGHT=$(tput lines 2>/dev/null || echo 24)
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
HEIGHT=$(( TERM_HEIGHT ))
WIDTH=$(( TERM_WIDTH ))
MENU_HEIGHT=$(( HEIGHT - 10 ))

#==================================== 1.1 Dependecies ====================================
## Ensure jq exists
if ! command -v jq >/dev/null 2>&1; then
    whiptail --msgbox "jq is required but not installed.\nPlease install jq first." "$HEIGHT" "$WIDTH"
    exit 0
fi

#==================================== 2. Parse CLI flags ====================================
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

#==================================== 2.1 Select a server ====================================
if [ -n "$PASSED_NAME" ]; then
    SERVER_NAME="$PASSED_NAME"
    SERVER_DIR="$MC_ROOT/$SERVER_NAME"

    if [ ! -d "$SERVER_DIR" ]; then
        whiptail --title "Error" --msgbox "Server '$SERVER_NAME' does not exist!" "$HEIGHT" "$WIDTH"
        exit 0
    fi
else
    MENU_ITEMS=()
    for d in "$MC_ROOT"/*; do
        [ -d "$d" ] || continue
        NAME=$(basename "$d")
        MENU_ITEMS+=("$NAME" "Minecraft server")
    done

    SERVER_NAME=$(whiptail --title "Choose Server" --menu "Select a server to manage downloads for:" \
        "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
        "${MENU_ITEMS[@]}" \
        3>&1 1>&2 2>&3) || exit 0

    SERVER_DIR="$MC_ROOT/$SERVER_NAME"
fi

CONFIG_FILE="$SERVER_DIR/manual-downloads.json"

#==================================== 3. Ensure config exists ====================================
if [ ! -f "$CONFIG_FILE" ]; then
    echo '{ "entries": [] }' > "$CONFIG_FILE"
fi

#==================================== 3. Functions ====================================
save_json() {
    echo "$1" > "$CONFIG_FILE"
}

load_json() {
    cat "$CONFIG_FILE"
}

#==================================== 3.1 Add Entry ====================================
add_entry() {
    NAME=$(whiptail --inputbox "Entry name(ideally without spaces):" "$HEIGHT" "$WIDTH" \
        3>&1 1>&2 2>&3) || return 0
    [ -z "$NAME" ] && return 0

    URL=$(whiptail --inputbox "Download URL:" "$HEIGHT" "$WIDTH" \
        3>&1 1>&2 2>&3) || return 0
    [ -z "$URL" ] && return 0

    # Select Relative Path from presets
    PATH_CHOICE=$(whiptail --title "Select Download Location" --menu \
    "Choose where the file should be downloaded inside the server folder:" \
    "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
        "mods" "Fabric, Forge" \
        "plugins" "Paper, Spigot, Velocity" \
        "geyser-velocity" "plugins/Geyser-Velocity/extensions - Geyser extensions (Velocity)" \
        "geyser-spigot" "plugins/Geyser-Spigot/extensions - Geyser extensions (Spigot)" \
        "manual" "Manual input" \
        3>&1 1>&2 2>&3) || return 0

    case "$PATH_CHOICE" in
        mods) PATH_REL="mods";;
        plugins) PATH_REL="plugins" ;;
        geyser-velocity) PATH_REL="plugins/Geyser-Velocity/extensions" ;;
        geyser-spigot) PATH_REL="plugins/Geyser-Spigot/extensions" ;;
        manual)
            PATH_REL=$(whiptail --inputbox \
            "Enter custom relative path (e.g. plugins/my-plugin, configs, datapacks):" \
            "$HEIGHT" "$WIDTH" \
            3>&1 1>&2 2>&3) || return 0

            [ -z "$PATH_REL" ] && PATH_REL="."
        ;;
    esac

    FILENAME=$(whiptail --inputbox "Filename:" "$HEIGHT" "$WIDTH" "$NAME.jar" \
        3>&1 1>&2 2>&3) || return 0

    JSON=$(load_json)
    NEW_JSON=$(echo "$JSON" | jq \
        --arg name "$NAME" \
        --arg url "$URL" \
        --arg path "$PATH_REL" \
        --arg file "$FILENAME" \
        '.entries += [{name:$name, url:$url, path:$path, filename:$file}]')

    save_json "$NEW_JSON"
}

#==================================== 3.2 Edit Entry ====================================
edit_entry() {
    INDEX="$1"
    JSON=$(load_json)

    ENTRY=$(echo "$JSON" | jq ".entries[$INDEX]")

    NAME=$(echo "$ENTRY" | jq -r '.name')
    URL=$(echo "$ENTRY" | jq -r '.url')
    PATH_REL=$(echo "$ENTRY" | jq -r '.path')
    FILE=$(echo "$ENTRY" | jq -r '.filename')

    NAME=$(whiptail --inputbox "Entry name:" "$HEIGHT" "$WIDTH" "$NAME" 3>&1 1>&2 2>&3) || return 0
    URL=$(whiptail --inputbox "Download URL:" "$HEIGHT" "$WIDTH" "$URL" 3>&1 1>&2 2>&3) || return 0
    PATH_REL=$(whiptail --inputbox "Relative path(mods, plugins, plugins/Geyser-Velocity):" "$HEIGHT" "$WIDTH" "$PATH_REL" 3>&1 1>&2 2>&3) || return 0
    FILE=$(whiptail --inputbox "Filename, You must add suffix! (.jar):" "$HEIGHT" "$WIDTH" "$FILE" 3>&1 1>&2 2>&3) || return 0

    NEW_JSON=$(echo "$JSON" | jq \
        --arg name "$NAME" \
        --arg url "$URL" \
        --arg path "$PATH_REL" \
        --arg file "$FILE" \
        ".entries[$INDEX] = {name:\$name, url:\$url, path:\$path, filename:\$file}")

    save_json "$NEW_JSON"
}

#==================================== 3.3 Remove Entry ====================================
remove_entry() {
    INDEX="$1"
    JSON=$(load_json)
    NEW_JSON=$(echo "$JSON" | jq "del(.entries[$INDEX])")
    save_json "$NEW_JSON"
}

#==================================== 3.4 List Entries ====================================
manage_entries() {
    while true; do
        JSON=$(load_json)

        MAP=()
        COUNT=$(echo "$JSON" | jq '.entries | length')

        for ((i=0; i<COUNT; i++)); do
            NAME=$(echo "$JSON" | jq -r ".entries[$i].name")
            MAP+=("$i" "$NAME")
        done

        MAP=("add" "+ Add entry" "${MAP[@]}")

        CHOICE=$(whiptail --title "Manage Download Entries" --menu \
            "Server: $SERVER_NAME" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
            "${MAP[@]}" 3>&1 1>&2 2>&3) || return 0

        case "$CHOICE" in
            add) add_entry ;;
            *)
                ACTION=$(whiptail --menu "Entry Options" "$HEIGHT" "$WIDTH" 5 \
                    "edit" "Edit entry" \
                    "remove" "Remove entry" \
                    "back" "Back" \
                    3>&1 1>&2 2>&3) || continue

                case "$ACTION" in
                    edit) edit_entry "$CHOICE" ;;
                    remove) remove_entry "$CHOICE" ;;
                    *) ;;
                esac
            ;;
        esac
    done
}

#==================================== 3.5 Download All ====================================
download_all() {
    JSON=$(load_json)
    COUNT=$(echo "$JSON" | jq '.entries | length')

    [ "$COUNT" -eq 0 ] && {
        whiptail --msgbox "No entries configured." "$HEIGHT" "$WIDTH"
        return 0
    }

    SUCCESS=()
    FAIL=()

    for ((i=0; i<COUNT; i++)); do
        NAME=$(echo "$JSON" | jq -r ".entries[$i].name")
        URL=$(echo "$JSON" | jq -r ".entries[$i].url")
        PATH_REL=$(echo "$JSON" | jq -r ".entries[$i].path")
        FILE=$(echo "$JSON" | jq -r ".entries[$i].filename")

        TARGET_DIR="$SERVER_DIR/$PATH_REL"
        mkdir -p "$TARGET_DIR"
        FULL_PATH="$TARGET_DIR/$FILE"

        whiptail --infobox "Downloading:\n$NAME\n\nFrom:\n$URL\n\nTo:\n$FULL_PATH" "$HEIGHT" "$WIDTH"

        if curl -fL -o "$FULL_PATH" "$URL"; then
            SUCCESS+=("$NAME")
        else
            FAIL+=("$NAME")

            CHOICE=$(whiptail --menu "Download failed for $NAME" "$HEIGHT" "$WIDTH" 5 \
                "edit" "Edit entry" \
                "skip" "Skip to next" \
                "abort" "Abort all" \
                3>&1 1>&2 2>&3) || continue

            case "$CHOICE" in
                edit) edit_entry "$i" ;;
                abort) break ;;
                *) ;;
            esac
        fi
    done

    SUMMARY="Download Summary\n\nSuccessful:\n"
    for s in "${SUCCESS[@]}"; do SUMMARY+="$s\n"; done

    SUMMARY+="\nFailed:\n"
    for f in "${FAIL[@]}"; do SUMMARY+="$f\n"; done

    whiptail --msgbox "$SUMMARY" "$HEIGHT" "$WIDTH"
}

#==================================== 4. Main Menu ====================================
while true; do
    CHOICE=$(whiptail --title "Download Manager - $SERVER_NAME" --menu \
        "Select an option:" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
        manage "Manage download entries" \
        run    "Download all entries" \
        exit   "Exit" \
        3>&1 1>&2 2>&3) || exit 0

    case "$CHOICE" in
        manage) manage_entries ;;
        run) download_all ;;
        exit) exit 0 ;;
    esac
done

