#!/bin/bash
#==================================== 1. Paramters and Locatoin====================================
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
TITLE="Edit MC server files LSR"

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
    NEW_NAME=$(whiptail --title "Rename the .jar file" \
        --inputbox "Enter a new name for the .jar file:\n(You can edit the existing name)" \
        "$HEIGHT" "$WIDTH" \
        "$script_name" \
        3>&1 1>&2 2>&3)

    if [[ -z "$NEW_NAME" ]]; then
        whiptail --msgbox "No name provided. Aborted." "$HEIGHT" "$WIDTH"
        return 0
    fi
    local EXTRACTED_LOCATION="$(dirname "$script_path")"
    local NEW_NAME_PATH="$EXTRACTED_LOCATION/$NEW_NAME"
    mv "$script_path" "$NEW_NAME_PATH"
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

check_base_dir_permissions()
{

    # Check if directory exists
    if [ ! -d "$SCRIPT_DIR" ]; then
        echo "Error: The directory '$SCRIPT_DIR' does not exist." >&2
        echo "It should contain your script files." >&2
        exit 1
    fi

    # Check read permission
    if [ ! -r "$SCRIPT_DIR" ]; then
        echo "Error: You do not have READ permission for '$SCRIPT_DIR'." >&2
        echo "Use: chmod u+r \"$SCRIPT_DIR\"" >&2
        exit 1
    fi

    # Check execute permission
    if [ ! -x "$SCRIPT_DIR" ]; then
        echo "Error: You do not have EXECUTE permission for '$SCRIPT_DIR'." >&2
        echo "Use: chmod u+x \"$SCRIPT_DIR\"" >&2
        exit 1
    fi
}

## Generic Function to run a script
run_script()
{
    ### The full path to the script to run (passed as argument $1).
    local script_path="$1"
    ### Extract the script's file name from the full path.
    local script_name="$(basename "$script_path")"

    ### Check if the script file actually exists
    if [ ! -f "$script_path" ]; then
        whiptail --msgbox "Error: Script '$script_name' not found at '$script_path'. How did you do that... LOL" "$HEIGHT" "$WIDTH"
        return 1
    fi

    ### Executable permissions check
    if [ ! -x "$script_path" ]; then
        whiptail --msgbox "Script '$script_name' is not executable. Attempting to add permissions..." "$HEIGHT" "$WIDTH"
        chmod +x "$script_path"
        if [ $? -ne 0 ]; then #Grab the exit status of the previous command(chmod) if failed then message
            whiptail --msgbox "Error: Failed to make '$script_name' executable. Cannot run. Check your permissions." "$HEIGHT" "$WIDTH"
            return 1
        fi
    fi

### Confirmation Logic
    if ! (whiptail --title "Confirm Run" --yesno "Are you sure you want to run '$script_name'?" 10 60); then
        echo "User cancelled running '$script_name'." >&2
        return 0 # User chose not to run, return to menu
    fi

### Script Execution
    echo "=========================================="
    echo "Running $script_path"
    "$script_path"
    echo "Ran $script_path"
    read -p "Done, press enter to continue"
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

display_dynamic_menu()
{
    ### 1. Parameters
    local title="$1"
    local current_path="$2"
    local original_path="$2" # Keep track of the original starting path

    ### 2. Main menu loop (runs until user exits)
    while true; do

    ## Detect terminal size (Again, encase user re-sizes terminal)
    TERM_HEIGHT=$(tput lines 2>/dev/null || echo 24)
    TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
    ## Set TUI size based on terminal size
    HEIGHT=$((TERM_HEIGHT))
    WIDTH=$((TERM_WIDTH))
    MENU_HEIGHT=$(( HEIGHT - 10 ))

    ### 3. Build dynamic menu options based on current folder
    local menu_options=()

        ### Add "Go back" option unless we're at the root of the script directory.
        ### This provides a way to navigate up a level in the folder structure.
        if [[ "$current_path" != "$original_path" ]]; then
            menu_options+=("..-back" "Go back to the previous menu")
        fi

    ### 4. Find folders, scripts, and text files in the current directory.
        ### I use find with -maxdepth 1 to only look in the current directory.
        local items
        items=$(find "$current_path" -maxdepth 1 -mindepth 1 | sort)

    ### 5. Process each item found and add it to our menu options array.
        #Determine item type using a single case block
        while read -r item; do
            local item_name
            item_name=$(basename "$item")
            #### Directory ####
            if [ -d "$item" ]; then
                menu_options+=("$item_name" "(Folder) Enter this folder")
                continue
            fi
###======================== Filtre File Types - 1/2 Edit to extend supported file types ========================
            case "$item_name" in
                *.sh)
                    menu_options+=("$item_name" "(Script) Run this script")
                    ;;
                *.md)
                    menu_options+=("$item_name" "(Markdown) Read/Edit using $EDITOR")
                    ;;
                *.txt)
                    menu_options+=("$item_name" "(Text) Read/Edit using $EDITOR")
                    ;;
                *.conf)
                    menu_options+=("$item_name" "(Config) Read/Edit using $EDITOR")
                    ;;
                *.jar)
                    menu_options+=("$item_name" "(Jar) Replace/Rename/Remove jar file")
                    ;;
                *)
                    menu_options+=("$item_name" "(File) Edit or Run")
                    ;;
            esac
        done <<< "$items"
        # Add an "Exit" option to the menu. This option is be available at all levels.
        menu_options+=("Exit" "Exit the script")


    ### 6. Display the Menu
        # Use whiptail to display the menu to the user.
        # The user's selection is stored in the 'choice' variable.
        local choice
        choice=$(whiptail --title "$TITLE" --backtitle "$BACKTITLE" --menu "$title" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
                "${menu_options[@]}" 3>&1 1>&2 2>&3)

        ### Check the exit status of whiptail.
        ### If it's not 0, it breaks the loop.
        ### In the case the user pressed Escape.
        if [ $? -ne 0 ]; then
            break
        fi

        ### Process the user's choice based on the selected option.
    case "$choice" in
        Exit)
            ### The user explicitly chose to exit the script.
            echo "=========================================="
            echo "=========================================="
            echo "  Thank you for using My Linux-Script-Runner TUI!   "
            echo "=========================================="
            read -p "Press Enter To continue"
            exit 0
        ;;
       "..-back")
            ### The user chose to go back. We update the current path to the parent directory.
            current_path=$(dirname "$current_path") #Goes back using dirname
            title="Go Back" # Updates the title for the next menu display.
        ;;
        *)
        ### Run a script
            local chosen_path="$current_path/$choice" # Reconstructs the full path of what the user selected.
            ### Folders - the path is updated
            if [ -d "$chosen_path" ]; then
                current_path="$chosen_path"
                title="Inside: $choice" # Update the title to reflect the new location.
            else
###======================== Other Files - 2/2 dit to extend supported file types ========================
                case "$choice" in
                    *.sh) run_script "$chosen_path" ;; #For scripts
                    *.md|*.txt|*.conf|*.yaml) $EDITOR "$chosen_path" ;; #(for files)
                    *.jar) modify_jar "$chosen_path" ;;
                    *)  ## Unknown / Other Files
                        ##Offer action menu: Run or Edit
                        local action
                        action=$(whiptail --title "$TITLE" --backtitle "$BACKTITLE" --menu "What would you like to do with:\n\n$choice" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
                            "edit"  "Edit using $EDITOR" \
                            "run"   "Run as script/binary" \
                            3>&1 1>&2 2>&3)
                        case "$action" in
                            run) run_script "$chosen_path" ;;
                            edit) $EDITOR "$chosen_path" ;;
                        esac
                    ;;
                esac

            fi
        ;;
    esac
done
}


#==================================== Main Script Logic ====================================

clear # Clear the screen before the first menu appears.
echo "=========================================="
echo " Debug Output, please chek for any errors:"
echo "=========================================="
# 1. Check initial directory permissions (dependency check now in install_deps.sh)
check_base_dir_permissions

# 2. Set all .sh scripts to executable
find scripts/ -type f -name "*.sh" -exec chmod +x {} \;

# 3. Start the dynamic menu navigation from the root 'scripts' directory
display_dynamic_menu "Main Menu" "$SCRIPT_DIR"
exit 0
