#!/bin/bash
#This script uses a modified version of my LSR
#==================================== MC Server Managment ====================================
#==================================== 01. Parameters ====================================
TITLE="MC server Managment"
MC_ROOT="$HOME/mcservers"
SCRIPT_OG_DIR="$(dirname "$(realpath "$0")")"
## Detect terminal size
TERM_HEIGHT=$(tput lines)
TERM_WIDTH=$(tput cols)
## Set TUI size based on terminal size
HEIGHT=$(( TERM_HEIGHT ))
WIDTH=$(( TERM_WIDTH ))
MENU_HEIGHT=$(( HEIGHT - 10 ))
#==================================== Center Text Fucntion ====================================
center_text() {
#Center text so that it is not on the left
    local text="$1"
    local width="$2"
    local len=${#text}

    # compute left padding
    local pad=$(( (width - len) / 2 ))

    # return padded string
    printf "%*s%s" "$pad" "" "$text"
}
#==================================== 02. Select a server ====================================
# Build menu items from directories
MENU_ITEMS=()
for d in "$MC_ROOT"/*; do
    [ -d "$d" ] || continue ## Only include directories
    NAME=$(basename "$d") ## Extract just the name of the directory
    MENU_ITEMS+=("$NAME" "Minecraft server") ## Add them to the menu
done
## Check if mcserver exist:
if [[ -z $MENU_ITEMS ]]; then
whiptail --msgbox "No Servers Found, please make a New one:)\nOr put your existing MCserver directory in ~/mcservers/" "$HEIGHT" "$WIDTH"
exit 0
fi

SERVER_NAME=$(whiptail --title "Choose Server" --menu "Select a server to manage:" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
    "${MENU_ITEMS[@]}" \
    3>&1 1>&2 2>&3) || exit 0
SERVER_DIR="$MC_ROOT/$SERVER_NAME"
#==================================== 03. Load server config file ====================================
CONF_FILE="$SERVER_DIR/server-version.conf"
if [ -f "$CONF_FILE" ]; then
    source "$CONF_FILE"
else
    version=""
    loader=""
    collection=""
fi
#==================================== 04. Functions ====================================
startserver_tmux() {
#======================= startserver 1. Runs mcserver in Tmux =========================
if whiptail --title "Start Server?" --yesno "Do you with to run and connect your server" "$HEIGHT" "$WIDTH" ; then
tmux new-session -d -s "$SERVER_NAME"
tmux send-keys -t "$SERVER_NAME" "cd '$SERVER_DIR'" C-m
tmux send-keys -t "$SERVER_NAME" "./run.sh" C-m
tmux attach -t "$SERVER_NAME"
fi
}

edit_server_properties() {
#============================ server properties 1. Run server.properties editor ====================================
if whiptail --title "$TITLE" --yesno "Would you like edit server.properties?\nSeed, Gamemode, Port, Online Mode, MOTD" "$HEIGHT" "$WIDTH" ; then
    cd "$SCRIPT_OG_DIR/more-scripts/"
    echo "Loading server.properties file..."
    bash server_properties_editor.sh --name $SERVER_NAME
    echo "Ran server.properties editor with $SERVER_NAME flag."
fi
}

modrinth_autodownloader() {
#============================ Modrinth Atodownloader ====================================
#==================================== Modrinth 1. Load config file ====================================
if [ -f "$CONF_FILE" ]; then
    source "$CONF_FILE"
else
    version=""
    loader=""
    collection=""
fi
MC_VERSION="$version"
MC_LOADER="$loader"
#============================ Modrinth 2. Run Only if supported loader ====================================
if [[ "$MC_LOADER" == "fabric" || "$MC_LOADER" == "forge" || "$MC_LOADER" == "neoforge" || "$MC_LOADER" == "liteloader" || "$MC_LOADER" == "quilt" || "$MC_LOADER" == "rift" ]]; then
if whiptail --title "$TITLE" --yesno "Would you also like to run Modrinth Collection Downloader?" "$HEIGHT" "$WIDTH"; then
    cd "$SCRIPT_DIR/more-scripts/"
    bash modrith-downloader.sh --name $SERVER_NAME
    echo "Ran Modrinth Collection Downloader with $SERVER_NAME flag."
fi
fi
}

update_server_jar() {
#==================================== update 1. Load config file ====================================
if [ -f "$CONF_FILE" ]; then
    source "$CONF_FILE"
else
    version=""
    loader=""
    collection=""
fi
MC_VERSION="$version"
MC_LOADER="$loader"
#============================ update 2. Update server.jar ====================================
cd "$SERVER_DIR"
MC_MENU_LOADER=$(whiptail --title "$TITLE" --menu "How would you like to update/install server jar file" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
    "1" "manual URL" \
    "2" "MCjarfiles API(Modded and Vanila)" \
    "3" "Dont update" \
    3>&1 1>&2 2>&3)
case $MC_MENU_LOADER in
    1)
    JAR_NAME="$SERVER_NAME.jar"
    SERVER_URL=$(whiptail --title "$TITLE" --inputbox "Enter server URL" "$HEIGHT" "$WIDTH" 3>&1 1>&2 2>&3)
    wget -O "$JAR_NAME" "$SERVER_URL"
    echo "manual server jar url"
    ;;
    2)
    JAR_NAME="$SERVER_NAME.jar"
    if [[ "$MC_LOADER" == "vanila" || "$MC_LOADER" == "vanilla" ]]; then
    wget -O "$JAR_NAME" https://mcjarfiles.com/api/get-jar/$MC_LOADER/release/$MC_VERSION
    fi
    if [[ "$MC_LOADER" == "paper" || "$MC_LOADER" == "purpur" ]]; then
    wget -O "$JAR_NAME" https://mcjarfiles.com/api/get-jar/servers/$MC_LOADER/$MC_VERSION
    fi
    if [[ "$MC_LOADER" == "fabric" || "$MC_LOADER" == "forge" || "$MC_LOADER" == "neoforge" ]]; then
    wget -O "$JAR_NAME" https://mcjarfiles.com/api/get-jar/modded/$MC_LOADER/$MC_VERSION
    fi
    echo "MCjarfiles API called"
    ;;
    3) return 0
    ;;
esac
}

lsr() {
cd "$SCRIPT_OG_DIR/more-scripts/"
    bash LSR_edit_server_files.sh --name $SERVER_NAME
    echo "Ran LSR jar file editor with $SERVER_NAME flag."
}

manage_autostart() {
#this function will regenerate autostart.sh
#it will also check if there is a corntab entry
#================ Autostart 1. parameters =========================
    local SERVER_NAME="$1"
    local SERVER_DIR="$2"
    local AUTOSTART="$SERVER_DIR/autostart.sh"
#====================== Autostart 2. Regenerate autostart.sh ====================================
## Ask to regenerate autostart.sh
if whiptail --title "Regenerate File?" --yesno "autostart.sh already exists.\nReplace it with a fresh one?" "$HEIGHT" "$WIDTH" ; then
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

#==================================== Autostart 3. Check on crontab  ====================================
local CRONLINE="@reboot $AUTOSTART"
## Check for existing crontab entry. If it exists, offer to remove it
   if crontab -l 2>/dev/null | grep -F "$AUTOSTART" >/dev/null; then
        if whiptail --title "Crontab Entry" --yesno "A crontab @reboot entry for $SERVER_NAME exists\nDo you wish to disable automatic start on boot?" --defaultno "$HEIGHT" "$WIDTH"; then
            crontab -l 2>/dev/null | grep -v "$CRONLINE" | crontab -
        return 0
        fi
    else
    ### If the crontab entry doesnt exist, make it
    if whiptail --title "Crontab Entry" --yesno "Add crontab @reboot entry for $SERVER_NAME\nThis will make the server start on boot?" "$HEIGHT" "$WIDTH" ; then
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
#================ run.sh 1. parameters =========================
    local SERVER_NAME="$1"
    local SERVER_DIR="$2"
    local RUNSCRIPT="$SERVER_DIR/run.sh"

#======================= run.sh 2. Ask to regenerate run.sh even if it exists =========================
## Ask to regenerate run.sh
if whiptail --title "Regenerate run.sh?" --yesno "Replace run.sh with a fresh one?" "$HEIGHT" "$WIDTH" ; then
    ### Ask for new memory amount
    MC_XMS=$(whiptail --title "Minimum RAM (Xms)" --inputbox "Example: 1G, 2G, 3G" "$HEIGHT" "$WIDTH" 3>&1 1>&2 2>&3)
    MC_XMX=$(whiptail --title "Maximum RAM (Xmx)" --inputbox "Example: 4G, 6G, 8G" "$HEIGHT" "$WIDTH" 3>&1 1>&2 2>&3)
    JAR_NAME="$SERVER_NAME.jar"
#======================= run.sh 3. More variables =========================
### fixes bug, when if no memory amout was selected, only -Xms or -Xmx, it caused a failed start
    if [[ -n "$MC_XMS" ]]; then
        RUN_MC_XMS="-Xms$MC_XMS"
    else
        RUN_MC_XMS=""
    fi

    if [[ -n "$MC_XMX" ]]; then
        RUN_MC_XMX="-Xmx$MC_XMX"
    else
        RUN_MC_XMX=""
    fi
#======================= run.sh 4. Creates run.sh =========================
cat > "$RUNSCRIPT" <<EOF
#!/bin/bash
java $RUN_MC_XMS $RUN_MC_XMX -jar $JAR_NAME nogui
EOF
chmod +x "$RUNSCRIPT"
echo "created run.sh for $SERVER_NAME"
fi

}

change_server_name() {
if whiptail --title "Change Name of $SERVER_NAME?" --yesno "Do you want to change the name of your Server?\n This will also force stop your server!\nSTOP YOU SERVER BEFORE CHANGEING THE NAME!!!" "$HEIGHT" "$WIDTH" ; then
{
#===================== name 1. Force Stop the old server=====================
tmux kill-session -t "$SERVER_NAME"
#===================== name 2.Ask for the new name =====================
SERVER_NAME_NEW=$(whiptail --title "$TITLE" --inputbox "Enter a NEW name for your server:" "$HEIGHT" "$WIDTH" 3>&1 1>&2 2>&3) || return 0
OLD_AUTOSTART="$HOME/mcservers/$SERVER_NAME/autostart.sh"
#===================== name 3. Remove cron entry for old name =====================
    if crontab -l >/dev/null 2>&1; then
        crontab -l | grep -v "@reboot $OLD_AUTOSTART" | crontab -
    fi
#===================== name 4. Remove run.sh and autostart.sh ============================
    cd $SERVER_DIR
    rm run.sh
    rm autostart.sh
#===================== name 5. Rename server jar ============================
    JAR_NAME_OLD="$SERVER_NAME.jar"
    JAR_NAME_NEW="$SERVER_NAME_NEW.jar"
    mv $JAR_NAME_OLD $JAR_NAME_NEW
#===================== name 6. Rename server directory ============================
    cd "$HOME/mcservers" || return 0
    mv "$SERVER_NAME" "$SERVER_NAME_NEW"
    # Update internal variable
    SERVER_NAME="$SERVER_NAME_NEW"
    SERVER_DIR="$HOME/mcservers/$SERVER_NAME"
#===================== name 7. Regenerate autostart ==============================
    manage_autostart "$SERVER_NAME" "$SERVER_DIR"
    manage_run_sh "$SERVER_NAME" "$SERVER_DIR"
} fi
}

#==================================== 05. Main Menu ====================================
while true; do
    # 1. Read the user's choice into the variable MENU_CHOICES
    MENU_CHOICES_TITLE=$(center_text "What would you like to do with $SERVER_NAME" "$WIDTH")
    MENU_CHOICES=$(whiptail --title "$TITLE" --menu "$MENU_CHOICES_TITLE" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
        "1" "Open Console (tmux attach)" \
        "2" "Start Server" \
        "3" "Stop Server" \
        "4" "Edit server.properties" \
        "5" "Update $SERVER_NAME.jar file (And modrinth mods)" \
        "6" "Edit Files (LSR)" \
        "7" "Add or Reconfigure Autostart Fetures" \
        "8" "Add or Reconfigure Memory ammout" \
        "9" "Change server Name" \
        "0" "Exit" \
        3>&1 1>&2 2>&3)
    if [ $? -ne 0 ]; then
        echo "Menu canceled. Exiting."
        exit 0
    fi
    case $MENU_CHOICES in
    1) tmux attach -t "$SERVER_NAME" ;;
    2) startserver_tmux ;;
    3) tmux send-keys -t "$SERVER_NAME" "stop" C-m ;;
    4) edit_server_properties ;; #external
    5)
    modrinth_autodownloader #external
    update_server_jar #internal
    ;;
    6) lsr ;;
    7) manage_autostart "$SERVER_NAME" "$SERVER_DIR" ;; #internal
    8) manage_run_sh "$SERVER_NAME" "$SERVER_DIR" ;; #internal
    9) change_server_name ;; #internal
    0) exit 0 ;;
    *) echo "Invalid option selected. \nHow did you get here???" ;;
    esac
done
exit 0
