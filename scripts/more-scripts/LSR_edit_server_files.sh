#!/bin/bash
#==================================== 1. Paramters and Locatoin====================================
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
MC_ROOT="$HOME/mcservers"
## Detect terminal size
TERM_HEIGHT=$(tput lines)
TERM_WIDTH=$(tput cols)
## Set TUI size based on terminal size
HEIGHT=$(( TERM_HEIGHT ))
WIDTH=$(( TERM_WIDTH ))
MENU_HEIGHT=$(( HEIGHT - 10 ))
TITLE="Edit MC server files LSR"
#==================================== 2. Center Text Function ====================================
center_text() {
    local text="$1"
    local width="$2"
    local len=${#text}

    # compute left padding
    local pad=$(( (width - len) / 2 ))

    # return padded string
    printf "%*s%s" "$pad" "" "$text"
}
#==================================== 3. Parse CLI flags ====================================
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
#==================================== 4. Select a server ====================================
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

    SERVER_NAME=$(whiptail --title "Choose Server" --menu "Select a server to manage:" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
        "${MENU_ITEMS[@]}" \
        3>&1 1>&2 2>&3) || exit 0

    SERVER_DIR="$MC_ROOT/$SERVER_NAME"
fi

#==================================== 5. Load config file ====================================
CONF_FILE="$SERVER_DIR/server-version.conf"

if [ -f "$CONF_FILE" ]; then
    source "$CONF_FILE"
else
    version=""
    loader=""
    collection=""
fi
#==================================== 6. Choose a editor ====================================
CHOICE=$(whiptail --title "Choose an Editor" --menu "Select your preferred editor for editing/viewing files" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
"1" "nano (Beginner-friendly)" \
"2" "vim (vi) (Standard terminal editor)" \
"3" "less (Simple, read only, q to quit)" \
"4" "Cancel" \
3>&1 1>&2 2>&3)

# Check if the user hit Cancel/Esc or chose the 'Cancel' option (4)
if [ $? -ne 0 ] || [ "$CHOICE" == "4" ]; then
    echo "Operation canceled."
    exit 0
fi

# 2. Map the choice number to the actual editor command
SELECTED_EDITOR=""
case "$CHOICE" in
    1) SELECTED_EDITOR="nano" ;;
    2) SELECTED_EDITOR="vi" ;;
    3) SELECTED_EDITOR="less" ;;
esac
#==================================== 7. Linux Scrit Runner - Jar editor edition ====================================
#Linux Script Runner Terminal User Interface - Modified
## SCRIPT_DIR should point to the base directory containing your numbered script folders.
SCRIPT_DIR="$SERVER_DIR"




#==================================== LSR Functions ====================================
## Check initial SCRIPT_DIR permissions and existence
check_base_dir_permissions() {

    # Check if directory exists
    if [ ! -d "$SCRIPT_DIR" ]; then
        echo "Error: The directory '$SCRIPT_DIR' does not exist." >&2
        echo "It should contain your script files." >&2
        return 0
    fi

    # Check read permission
    if [ ! -r "$SCRIPT_DIR" ]; then
        echo "Error: You do not have READ permission for '$SCRIPT_DIR'." >&2
        echo "Use: chmod u+r \"$SCRIPT_DIR\"" >&2
        return 0
    fi

    # Check execute permission
    if [ ! -x "$SCRIPT_DIR" ]; then
        echo "Error: You do not have EXECUTE permission for '$SCRIPT_DIR'." >&2
        echo "Use: chmod u+x \"$SCRIPT_DIR\"" >&2
        return 0
    fi
}
modify_jar() {
    ### The full path to the jar file to change (passed as argument $1).
    local script_path="$1"
    ### Extract the script's file name from the full path.
    local script_name="$(basename "$script_path")"
    ### Check if the jar file actually exists
    if [ ! -f "$script_path" ]; then
        whiptail --msgbox "Error: jar file '$script_name' not found at '$script_path'. How did you do that... LOL" "$HEIGHT" "$WIDTH"
        return 1
    fi

### Jarfile Modification
    echo "=========================================="
JARFILE_CHOICE=$(whiptail --title "$script_name" --menu "What do you want to do:" "$HEIGHT" "$WIDTH" 5 \
"1" "Replace from URL" \
"2" "Rename the .jar file" \
"3" "Remove the .jar file!" \
3>&1 1>&2 2>&3)
case $JARFILE_CHOICE in
1)
    local URL
    URL=$(whiptail --title "Replace the .jar file" --inputbox "Enter the direct download URL for the new .jar file:" "$HEIGHT" "$WIDTH" 3>&1 1>&2 2>&3)
    if [[ -z "$URL" ]]; then
        whiptail --msgbox "No URL provided. Aborted." "$HEIGHT" "$WIDTH"
        return 0
    fi
    if curl -fLo "$script_path" "$URL"; then whiptail --msgbox "JAR successfully replaced!" "$HEIGHT" "$WIDTH"
        else whiptail --msgbox "Download failed! Old file NOT removed." "$HEIGHT" "$WIDTH"
    fi
;;
2)
    local NEW_NAME
    NEW_NAME=$(whiptail --title "Rename the .jar file" --inputbox "Enter a new name for the .jar file:\n dont forget to add .jar file name!!!" "$HEIGHT" "$WIDTH" 3>&1 1>&2 2>&3)
    if [[ -z "$NEW_NAME" ]]; then
        whiptail --msgbox "No name provided. Aborted." "$HEIGHT" "$WIDTH"
        return 0
    fi
    #I should probably add a waring about not adding the .jar suffix...
    local EXTRACTED_LOCATOIN="$(dirname "$script_path")"
    local NEW_NAME_SPACE="$EXTRACTED_LOCATOIN/$NEW_NAME"
    echo $NEW_NAME_SPACE
    echo $script_path
    mv $script_path $NEW_NAME_SPACE
;;
3)
if whiptail --title "REMOVE $script_name?" --yesno "Would you like to remove $script_name?" 10 60; then
rm $script_path
fi
;;
*) return 0 ;;
esac
    echo "=========================================="
    return 0
}
#Display menu logic
#What does it do:
    #scan directories
    #build dynamic menus
    #handle navigation
    #read text files
    #manage exit logic
    #Filters directory items

display_dynamic_menu() {
    ### 1. Parameters
    local title="$1"
    local current_path="$2"
    local original_path="$2" # Keep track of the original starting path

    ### 2. Main menu loop (runs until user exits)
    while true; do

    ### 3. Build dynamic menu options based on current folder
    local menu_options=()

        ### Add "Go back" option unless we're at the root of the script directory.
        ### This provides a way to navigate up a level in the folder structure.
        if [[ "$current_path" != "$original_path" ]]; then
            menu_options+=("..-back" "Go back to the previous menu")
        fi

    ### 4. Find folders, scripts, and text files in the current directory.
        ### I use find with -maxdepth 1 to only look in the current directory.
        ### Finds all files that are either .sh or not .sh.
        ### This output is then sorted into .sh and non .sh files/folders.
        local items
        items=$(find "$current_path" -maxdepth 1 -mindepth 1 \( -type d -o -type f -name "*.jar" -o -type f ! -name "*.jar" \) | sort)

    ### 5. Process each item found and add it to our menu options array.
        while read -r item; do # Reads one line at a time from the input
            local item_name
            item_name=$(basename "$item")

        ### If the item is a directory, add it to the menu with a label indicating it's a folder.
            if [ -d "$item" ]; then
                menu_options+=("$item_name" "(Folder) Enter this folder")

        ### If the item is a script with a '.sh' extension, add it to the menu with a script label.
            elif [ -f "$item" ] && [[ "$item_name" == *.jar ]]; then
                menu_options+=("$item_name" "(.jar file) Replace/Rename/Remove")

        ### If the item is a file but not a '.jar' script, we'll assume it's a text file to be read.
           elif [ -f "$item" ]; then
                menu_options+=("$item_name" "(File) Edit this file")
            fi
        done <<< "$items" # The loop runs once for each path found by find.

        # Add an "Exit" option to the menu. This option is be available at all levels.
        menu_options+=("Exit" "Exit the script")

    ### 6. Display the Menu
        # Use whiptail to display the menu to the user.
        # The user's selection is stored in the 'choice' variable.
        local choice
        choice=$(whiptail --title "$TITLE" --backtitle "$BACKTITLE" \
                          --menu "$title" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
                          "${menu_options[@]}" 3>&1 1>&2 2>&3)

        ### Check the exit status of whiptail.
        ### If it's not 0, it breaks the loop.
        ### In the case the user pressed Escape.
        if [ $? -ne 0 ]; then
            break
        fi

        ### Process the user's choice based on the selected option.
        if [[ "$choice" == "Exit" ]]; then
        ### The user explicitly chose to exit the script.
        echo "Done managing servers"
        return 0
        ### The user chose to go back. We update the current path to the parent directory.
        elif [[ "$choice" == "..-back" ]]; then
title
            current_path=$(dirname "$current_path") #Goes back using dirname
            title="Go Back" # Updates the title for the next menu display.
       ### Run a script
       else
            local chosen_path="$current_path/$choice" # Reconstructs the full path of what the user selected.

            ### For folders, the path is updated
            if [ -d "$chosen_path" ]; then
                current_path="$chosen_path"
                title="Inside: $choice" # Update the title to reflect the new location.
            ### For .jar files, the modify_jar funciton is called with the path parsed
            elif [ -f "$chosen_path" ] && [[ "$chosen_path" == *.jar ]]; then
                modify_jar "$chosen_path"
            ### For non .jar Files, edit with the SELECTED_EDITOR
            elif [ -f "$chosen_path" ]; then
                $SELECTED_EDITOR "$chosen_path"
            ### Fallback for when a selected file or folder is no longer available.
            else
                whiptail --msgbox "Error: '$choice' could not be found or is not a valid script." "$HEIGHT" "$WIDTH"
            fi
        fi
    done
}


#==================================== Main LSR Logic ====================================

# 1. Check initial directory permissions (dependency check now in install_deps.sh)
check_base_dir_permissions

# 2. Start the dynamic menu navigation from the root 'scripts' directory
display_dynamic_menu "Edit Files for $SERVER_NAME" "$SCRIPT_DIR"
exit 0
