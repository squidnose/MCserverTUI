#!/bin/bash
#==================================== locations and parameters ====================================
#For server Chooser
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
MC_ROOT="$HOME/mcservers"
## Detect terminal size
### in case tput is not found, sets to fixed value
TERM_HEIGHT=$(tput lines 2>/dev/null || echo 24)
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
## Set TUI size based on terminal size
HEIGHT=$(( TERM_HEIGHT ))
WIDTH=$(( TERM_WIDTH ))
MENU_HEIGHT=$(( HEIGHT - 10 ))
#for funcions
declare -a PARAM_KEYS
declare -a PARAM_VALUES
declare -a RAW_LINES
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
#==================================== 1. Select a server and load the confing file ====================================
if [ -n "$PASSED_NAME" ]; then
    # Bypass menu, validate directory
    SERVER_NAME="$PASSED_NAME"
    SERVER_DIR="$MC_ROOT/$SERVER_NAME"

    if [ ! -d "$SERVER_DIR" ]; then
        whiptail --title "Error" --msgbox "Server '$SERVER_NAME' does not exist!" "$HEIGHT" "$WIDTH"
        exit 0
    fi
    CONF_FILE="$SERVER_DIR/server.properties"
else
    # Build menu items from directories
    MENU_ITEMS=()
    for d in "$MC_ROOT"/*; do
        [ -d "$d" ] || continue
        NAME=$(basename "$d")
        MENU_ITEMS+=("$NAME" "Minecraft server")
    done

    SERVER_NAME=$(whiptail --title "Choose Server" --menu "Select a server to edit the server.properties file" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
        "${MENU_ITEMS[@]}" 3>&1 1>&2 2>&3) || exit 0

    SERVER_DIR="$MC_ROOT/$SERVER_NAME"
    CONF_FILE="$SERVER_DIR/server.properties"
fi


#==================================== 3. Functions====================================
# 1. load the server.properties file
load_properties() {
    PARAM_KEYS=()
    PARAM_VALUES=()
    RAW_LINES=()

    while IFS='' read -r line; do
        RAW_LINES+=("$line")

        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue
        [[ "$line" =~ ^[[:space:]]*# ]] && continue

        # Split key=value
        if [[ "$line" =~ ^([^=]+)=(.*)$ ]]; then
            key="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"
            key="$(echo "$key" | xargs)"     # Trim whitespace
            value="$(echo "$value" | xargs)" # Trim whitespace

            PARAM_KEYS+=("$key")
            PARAM_VALUES+=("$value")
        fi
    done < "$CONF_FILE"
}

# 2. Write modified parameters back to server.properties
write_properties() {
    {
        for i in "${!RAW_LINES[@]}"; do
            line="${RAW_LINES[$i]}"

            # Skip comment/empty lines (write them as-is)
            if [[ ! "$line" =~ ^([^=]+)=(.*)$ ]]; then
                echo "$line"
                continue
            fi

            key="${BASH_REMATCH[1]}"
            key_trimmed="$(echo "$key" | xargs)"

            # Find the index of this key in PARAM_KEYS
            edited_idx=-1
            for j in "${!PARAM_KEYS[@]}"; do
                if [[ "${PARAM_KEYS[$j]}" == "$key_trimmed" ]]; then
                    edited_idx="$j"
                    break
                fi
            done

            if [[ $edited_idx -ge 0 ]]; then
                echo "${PARAM_KEYS[$edited_idx]}=${PARAM_VALUES[$edited_idx]}"
            else
                # Should never happen, but fail-safe
                echo "$line"
            fi
        done
    } > "$CONF_FILE"
}


# 3. Edit a single parameter
edit_parameter() {
    local key="$1"
    local index="$2"
    local old="${PARAM_VALUES[$index]}"

    new_val=$(whiptail --inputbox "Edit value for:\n$key" "$HEIGHT" "$WIDTH" "$old" 3>&1 1>&2 2>&3)
    [[ $? -ne 0 ]] && return 0  # Cancelled
    PARAM_VALUES[$index]="$new_val"
}

# 4. Main editing loop

    while true; do
        load_properties

        MENU_ITEMS=()
        for i in "${!PARAM_KEYS[@]}"; do
            MENU_ITEMS+=("${PARAM_KEYS[$i]}" "${PARAM_VALUES[$i]}")
        done

        choice=$(whiptail --title "server.properties Editor" --menu "Select a parameter to edit:" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
            "${MENU_ITEMS[@]}" 3>&1 1>&2 2>&3)
        # Exit on cancel
        [[ $? -ne 0 ]] && exit 0

        # Find index
        idx=-1
        for i in "${!PARAM_KEYS[@]}"; do
            if [[ "${PARAM_KEYS[$i]}" == "$choice" ]]; then
                idx="$i"
                break
            fi
        done

        edit_parameter "$choice" "$idx"
        write_properties
    done
exit 0
