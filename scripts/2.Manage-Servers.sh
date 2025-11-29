#!/bin/bash
#This script uses a modified version of my LSR
#==================================== MC Server Managment ====================================
#==================================== 1. Parameters ====================================
TITLE="MC server Managment"
MC_ROOT="$HOME/mcservers"
SCRIPT_OG_DIR="$(dirname "$(realpath "$0")")"
## Detect terminal size
TERM_HEIGHT=$(tput lines)
TERM_WIDTH=$(tput cols)
## Set TUI size based on terminal size
HEIGHT=$(( TERM_HEIGHT * 3 / 4 ))
WIDTH=$(( TERM_WIDTH * 4 / 5 ))
MENU_HEIGHT=$(( HEIGHT - 10 ))
#==================================== 2. Select a server ====================================
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
CONF_FILE="$SERVER_DIR/server-version.conf"
#==================================== 3. Load  server config file ====================================

if [ -f "$CONF_FILE" ]; then
    source "$CONF_FILE"
else
    version=""
    loader=""
    collection=""
fi

#==================================== 4. Functions ====================================
lsr() {
#Linux Script Runner Terminal User Interface - Modified
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
display_dynamic_menu "Edit Files for $SERVER_NAME" "$SCRIPT_DIR"
return 0
}
manage_autostart() {
#this function will regenerate autostart.sh
#it will also check if there is a corntab entry
#================ 1. parameters =========================
    local SERVER_NAME="$1"
    local SERVER_DIR="$2"
    local AUTOSTART="$SERVER_DIR/autostart.sh"
#====================== 2. Regenerate autostart.sh ====================================
## Ask to regenerate autostart.sh
if whiptail --title "Regenerate File?" --yesno "autostart.sh already exists.\nReplace it with a fresh one?" 10 60 ; then
cat > "$AUTOSTART" <<EOF
#!/bin/bash
SESSION="$SERVER_NAME"

if ! tmux has-session -t "\$SESSION" 2>/dev/null; then
    tmux new-session -d -s "\$SESSION"
    tmux send-keys -t "\$SESSION" "cd '$SERVER_DIR'" C-m
    tmux send-keys -t "\$SESSION" "./run.sh" C-m
fi
EOF
chmod +x "$AUTOSTART"
echo "autostart.sh regenerated for $SERVER_NAME"
fi

#==================================== 3. Check on crontab  ====================================
## Check if this exact path already exists
local CRONLINE="@reboot $AUTOSTART"
    if crontab -l 2>/dev/null | grep -F "$AUTOSTART" >/dev/null; then
        if whiptail --title "Cron Entry Exists!" --yesno "Do you wish to remove it?" --defaultno 10 60; then
        crontab -l 2>/dev/null | grep -v "$CRONLINE" | crontab -
        return 0
        fi
    else
    if whiptail --title "Add Cron Autostart?" --yesno "Add @reboot entry to start this server on boot?" 10 60; then
        (crontab -l 2>/dev/null; echo "$CRONLINE") | crontab -
            echo "Cron entry added."
        else
            echo "Skipped adding cron entry."
        fi
    fi
    echo "Autostart management complete."
    return 0
}
manage_run_sh() {
#This function will reconfigure run.sh
#================ 1. parameters =========================
    local SERVER_NAME="$1"
    local SERVER_DIR="$2"
    local RUNSCRIPT="$SERVER_DIR/run.sh"

#======================= 2. Ask to regenerate run.sh or autostart.sh even if it exists =========================
## Ask to regenerate run.sh
if whiptail --title "Regenerate run.sh?" --yesno "Replace run.sh with a fresh one?" 10 60 ; then
    ### Ask for new memory amount
    MC_XMS=$(whiptail --title "Minimum RAM (Xms)" --inputbox "Example: 1G, 2G, 3G" 10 60 3>&1 1>&2 2>&3)
    MC_XMX=$(whiptail --title "Maximum RAM (Xmx)" --inputbox "Example: 4G, 6G, 8G" 10 60 3>&1 1>&2 2>&3)
    JAR_NAME="$SERVER_NAME.jar"
    ### Create run.sh
cat > "$RUNSCRIPT" <<EOF
#!/bin/bash
java -Xms$MC_XMS -Xmx$MC_XMX -jar $JAR_NAME nogui
EOF
chmod +x "$RUNSCRIPT"
echo "created run.sh for $SERVER_NAME"
fi

}
startserver_tmux() {
if whiptail --title "Start Server?" --yesno "Do you with to run and connect your server" 10 60; then
tmux new-session -d -s "$SERVER_NAME"
tmux send-keys -t "$SERVER_NAME" "cd '$SERVER_DIR'" C-m
tmux send-keys -t "$SERVER_NAME" "./run.sh" C-m
tmux attach -t "$SERVER_NAME"
fi
}
modrinth_autodownloader() {
#============================ 1. offer Modrinth Atodownloader ====================================
if whiptail --title "Update Server" --yesno "Would you also like to run Modrinth Collection Downloader?" 10 60; then
    bash "$SCRIPT_OG_DIR/more-scripts/modrith-downloader.sh" --name $SERVER_NAME
    echo "Ran Modrinth Collection Downloader with $SERVER_NAME flag."
fi
}
update_server_jar() {
#==================================== 1. Load config file ====================================
if [ -f "$CONF_FILE" ]; then
    source "$CONF_FILE"
else
    version=""
    loader=""
    collection=""
fi
#============================ 2. Update server.jar ====================================
cd "$SERVER_DIR"
MC_MENU_LOADER=$(whiptail --title "Update server" --menu "How would you like to update server jar file" 15 60 6 \
    "1" "manual URL" \
    "2" "Fabric (Manual)" \
    "3" "Dont update " \
    3>&1 1>&2 2>&3)
case $MC_MENU_LOADER in
    1)
    JAR_NAME="$SERVER_NAME.jar"
    rm $JAR_NAME ## remove existing jar file
    SERVER_URL=$(whiptail --title "$TITLE" --inputbox "Enter server URL" 10 60 3>&1 1>&2 2>&3)
    curl -sLo "$JAR_NAME" "$SERVER_URL"
    ;;
    2)
    INSTALLER_VERSOIN=$(whiptail --title "$TITLE" --inputbox "Enter INSTALLER version(1.1.0)" 10 60 3>&1 1>&2 2>&3)
    LOADER_VERSION=$(whiptail --title "$TITLE" --inputbox "Enter LOADER version(0.18.1)" 10 60 3>&1 1>&2 2>&3)
    JAR_NAME="$SERVER_NAME.jar"
    rm $JAR_NAME ## remove existing jar file
    curl -sLo "$JAR_NAME" https://meta.fabricmc.net/v2/versions/loader/$MC_VERSION/$LOADER_VERSION/$INSTALLER_VERSOIN/server/jar

    ;;
esac
}
change_server_name() {
if whiptail --title "Change Name of $SERVER_NAME?" --yesno "Do you want to change the name of your Server?\n This will also force stop your server!\nSTOP YOU SERVER BEFORE CHANGEING THE NAME!!!" 10 60; then
{
#===================== 1. Force Stop the old server=====================
tmux kill-session -t "$SERVER_NAME"
#===================== 2.Ask for the new name =====================
SERVER_NAME_NEW=$(whiptail --title "$TITLE" --inputbox \
    "Enter a NEW name for your server:" 10 60 \
    3>&1 1>&2 2>&3) || return 0
OLD_AUTOSTART="$HOME/mcservers/$SERVER_NAME/autostart.sh"
#===================== 3. Remove cron entry for old name =====================
    if crontab -l >/dev/null 2>&1; then
        crontab -l | grep -v "@reboot $OLD_AUTOSTART" | crontab -
    fi
#===================== 4. Remove run.sh and autostart.sh ============================
    cd $SERVER_DIR
    rm run.sh
    rm autostart.sh
#===================== 5. Rename server jar ============================
    JAR_NAME_OLD="$SERVER_NAME.jar"
    JAR_NAME_NEW="$SERVER_NAME_NEW.jar"
    mv $JAR_NAME_OLD $JAR_NAME_NEW
#===================== 6. Rename server directory ============================
    cd "$HOME/mcservers" || return 0
    mv "$SERVER_NAME" "$SERVER_NAME_NEW"
    # Update internal variable
    SERVER_NAME="$SERVER_NAME_NEW"
    SERVER_DIR="$HOME/mcservers/$SERVER_NAME"
#===================== 6. Regenerate autostart ==============================
    manage_autostart "$SERVER_NAME" "$SERVER_DIR"
    manage_run_sh "$SERVER_NAME" "$SERVER_DIR"
} fi
}

#==================================== 5. Main Menu ====================================
while true; do
    # 1. Read the user's choice into the variable MENU_CHOICES
    MENU_CHOICES=$(whiptail --title "$TITLE" --menu "What would you like to do with $SERVER_NAME" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
        "1" "Open Console (tmux attach)" \
        "2" "Start Server" \
        "3" "Stop Server" \
        "4" "Update Server (Modrinth Mods and $SERVER_NAME.jar file)" \
        "5" "Edit Files (LSR)" \
        "6" "Add or Reconfigure Autostart Fetures" \
        "7" "Add or Reconfigure Memory ammout" \
        "8" "Change server Name" \
        "9" "Exit" \
        3>&1 1>&2 2>&3)
    if [ $? -ne 0 ]; then
        echo "Menu canceled. Exiting."
        exit 0
    fi
    case $MENU_CHOICES in
    1) tmux attach -t "$SERVER_NAME" ;;
    2) startserver_tmux ;;
    3) tmux send-keys -t "$SERVER_NAME" "stop" C-m ;;
    4)
    modrinth_autodownloader
    update_server_jar
    ;;
    5) lsr ;;
    6) manage_autostart "$SERVER_NAME" "$SERVER_DIR" ;;
    7) manage_run_sh "$SERVER_NAME" "$SERVER_DIR" ;;
    8) change_server_name ;;
    9) exit 0 ;;
    *) echo "Invalid option selected. \nHow did you get here???" ;;
    esac
done
exit 0
