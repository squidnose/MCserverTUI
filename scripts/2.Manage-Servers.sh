#!/bin/bash
#This script uses a modified version of my LSR
#==================================== MC Server Managment ====================================
TITLE="MC server Managment"
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
    3>&1 1>&2 2>&3) || return 0

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

#==================================== 3. Menu - Modified LSR ====================================
#Linux Script Runner Terminal User Interface - Modified
#==================================== Parameters ====================================
lsr() {
## Detect terminal size
TERM_HEIGHT=$(tput lines)
TERM_WIDTH=$(tput cols)
## Set TUI size based on terminal size
HEIGHT=$(( TERM_HEIGHT * 3 / 4 ))
WIDTH=$(( TERM_WIDTH * 4 / 5 ))
MENU_HEIGHT=$(( HEIGHT - 10 ))

## SCRIPT_DIR should point to the base directory containing your numbered script folders.
SCRIPT_DIR="$SERVER_DIR"

## Colors
## Uses NEWT colors file to run with diferent colors
#export NEWT_COLORS_FILE="$SCRIPT_DIR/0.Tools/5.Config-Files/colors.conf"

## Title


#==================================== Functions ====================================
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
        items=$(find "$current_path" -maxdepth 1 -mindepth 1 \( -type d -o -type f -name "*.sh" -o -type f ! -name "*.sh" \) | sort)

    ### 5. Process each item found and add it to our menu options array.
        while read -r item; do # Reads one line at a time from the input
            local item_name
            item_name=$(basename "$item")

        ### If the item is a directory, add it to the menu with a label indicating it's a folder.
            if [ -d "$item" ]; then
                menu_options+=("$item_name" "(Folder) Enter this folder")

        ### If the item is a file edit with nano
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

            current_path=$(dirname "$current_path") #Goes back using dirname
            title="Go Back" # Updates the title for the next menu display.
       ### Run a script
       else
            local chosen_path="$current_path/$choice" # Reconstructs the full path of what the user selected.

            ### For folders, the path is updated
            if [ -d "$chosen_path" ]; then
                current_path="$chosen_path"
                title="Inside: $choice" # Update the title to reflect the new location.
            ### For Files to read using less
            elif [ -f "$chosen_path" ]; then
                nano "$chosen_path"
                # The script will continue after 'less' is closed by the user (by pressing 'q').
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
display_dynamic_menu "Main Menu" "$SCRIPT_DIR"
return 0
}

#==================================== 4. Main Menu ====================================
while true; do
    # 1. Read the user's choice into the variable MENU_CHOICES
    MENU_CHOICES=$(whiptail --title "$TITLE" --menu "What would you like to do with $SERVER_NAME" 15 60 5 \
        "1" "Open Console (tmux attach)" \
        "2" "Edit Files (lsr)" \
        "3" "Open Crontab (System wide)" \
        "4" "Exit" \
        3>&1 1>&2 2>&3)
    if [ $? -ne 0 ]; then
        echo "Menu canceled. Exiting."
        exit 0
    fi
    case $MENU_CHOICES in
    1) tmux attach -t "$SERVER_NAME" ;;
    2) lsr ;;
    3) crontab -e ;;
    4) exit 0 ;;
    *) echo "Invalid option selected." ;;
    esac
done
