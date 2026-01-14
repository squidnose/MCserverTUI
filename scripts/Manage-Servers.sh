#!/bin/bash
#This script uses a modified version of my LSR
#==================================== MC Server Managment ====================================
#============================ Logging ============================
STATE_DIR="$HOME/.local/state/MCserverTUI"
MC_TUI_LOGFILE="$STATE_DIR/mcservertui.log"
mkdir -p "$STATE_DIR"

echlog() {
    local msg="$*"
    echo "$msg"
    echo "$(date '+%Y-%m-%d %H:%M:%S') $msg" >> "$MC_TUI_LOGFILE"
}
#==================================== 01. Parameters ====================================
TITLE="MC server Managment"
MC_ROOT="$HOME/mcservers"
SCRIPT_OG_DIR="$(dirname "$(realpath "$0")")"
## Detect terminal size
### in case tput is not found, sets to fixed value
TERM_HEIGHT=$(tput lines 2>/dev/null || echo 24)
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
## Set TUI size based on terminal size
HEIGHT=$(( TERM_HEIGHT ))
WIDTH=$(( TERM_WIDTH ))
MENU_HEIGHT=$(( HEIGHT - 10 ))

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
echlog "🛠 $SERVER_NAME MCserver: Opening for managing"
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
startserver_tmux()
{
#======================= startserver 1. Runs mcserver in Tmux =========================
if whiptail --title "Start Server?" --yesno "Do you with to run and connect your server" "$HEIGHT" "$WIDTH" ; then
echlog "▶ $SERVER_NAME MCserver: Started MCserver in tmux window labled $SERVER_NAME"
tmux new-session -d -s "$SERVER_NAME"
tmux send-keys -t "$SERVER_NAME" "cd '$SERVER_DIR'" C-m
tmux send-keys -t "$SERVER_NAME" "./run.sh" C-m
tmux attach -t "$SERVER_NAME"
fi
} #startserver_tmux()

edit_server_properties()
{
#============================ server properties 1. Run server.properties editor ====================================
if whiptail --title "$TITLE" --yesno "Would you like edit server.properties?\nSeed, Gamemode, Port, Online Mode, MOTD" "$HEIGHT" "$WIDTH" ; then
    cd "$SCRIPT_OG_DIR/more-scripts/"
    echlog "⚙ $SERVER_NAME MCserver: Loading server.properties file..."
    bash server_properties_editor.sh --name $SERVER_NAME
    echlog "⚙ $SERVER_NAME MCserver: Ran server.properties line editor."
fi
} #edit_server_properties()

modrinth_autodownloader()
{
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
        bash modrinth-downloader.sh --name $SERVER_NAME
        echlog "⬆ $SERVER_NAME MCserver: Ran Modrinth Collection Downloader with"
    else
        echlog "⬆ $SERVER_NAME MCserver: Did NOT run Modrinth colection downloader"
    fi
else
echlog "⬆ $SERVER_NAME MCserver: Loader presumed to be Vanila, no mods will be downloaded"
fi
} #modrinth_autodownloader()

update_server_jar()
{
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
    "1" "MCjarfiles API(Modded and Vanila)" \
    "2" "manual URL" \
    "3" "Dont update" \
    3>&1 1>&2 2>&3)
case $MC_MENU_LOADER in
    1)
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
    echlog "⬆ $SERVER_NAME MCserver: MCjarfiles API called using: $MC_LOADER loader, version $MC_VERSION, Saved as $JAR_NAME"
    ;;
    2)
    JAR_NAME="$SERVER_NAME.jar"
    SERVER_URL=$(whiptail --title "$TITLE" --inputbox "Enter server URL" "$HEIGHT" "$WIDTH" 3>&1 1>&2 2>&3)
    wget -O "$JAR_NAME" "$SERVER_URL"
    echlog "⬆ $SERVER_NAME MCserver: Manual server jar url entered: $SERVER_URL"
    ;;
    3)
    echlog "⬆ $SERVER_NAME MCserver: Did NOT update server jar file"
    return 0
    ;;
esac
} #update_server_jar()

lsr()
{
    cd "$SCRIPT_OG_DIR/more-scripts/"
    bash LSR_edit_server_files.sh --name $SERVER_NAME
    echlog "📂 $SERVER_NAME MCserver: Ran LSR file browser/editor."
} #lsr()

manage_autostart()
{
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
echlog "⏱ $SERVER_NAME MCserver: autostart.sh regenerated"
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
            echlog "⏱ $SERVER_NAME MCserver: Cron entry added."
        else
            echlog "⏱ $SERVER_NAME MCserver: Skipped adding cron entry."
        fi
    fi
    echlog "⏱ $SERVER_NAME MCserver: Autostart management complete."
    return 0
} #manage_autostart()

manage_run_sh()
{
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
echlog "🧠 $SERVER_NAME MCserver: New run.sh made with: $MC_XMS min, $MC_XMX max, using $JAR_NAME name"
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
echlog "$SERVER_NAME MCserver: created run.sh for $SERVER_NAME"
fi

} #manage_run_sh()

change_server_name()
{
if whiptail --title "Change Name of $SERVER_NAME?" --yesno "Do you want to change the name of your Server?\n This will also force stop your server!\nSTOP YOU SERVER BEFORE CHANGEING THE NAME!!!" "$HEIGHT" "$WIDTH" ; then
{
echlog "✏ $SERVER_NAME MCserver: Started renaming process"
#===================== name 1. Force Stop the old server=====================
tmux kill-session -t "$SERVER_NAME"
echlog "✏ $SERVER_NAME MCserver: Killed $SERVER_NAME tmux session"
#===================== name 2.Ask for the new name =====================
SERVER_NAME_NEW=$(whiptail --title "$TITLE" --inputbox "Enter a NEW name for your server:" "$HEIGHT" "$WIDTH" 3>&1 1>&2 2>&3) || return 0
OLD_AUTOSTART="$HOME/mcservers/$SERVER_NAME/autostart.sh"
#===================== name 3. Remove cron entry for old name =====================
    if crontab -l >/dev/null 2>&1; then
        crontab -l | grep -v "@reboot $OLD_AUTOSTART" | crontab -
    fi
echlog "✏ $SERVER_NAME MCserver: Removed cron entry for old name"
#===================== name 4. Remove run.sh and autostart.sh ============================
    cd $SERVER_DIR
    rm run.sh
    rm autostart.sh
echlog "✏ $SERVER_NAME MCserver: Removed run.sh and autostart.sh with old names"
#===================== name 5. Rename server jar ============================
    JAR_NAME_OLD="$SERVER_NAME.jar"
    JAR_NAME_NEW="$SERVER_NAME_NEW.jar"
    mv $JAR_NAME_OLD $JAR_NAME_NEW
echlog "✏ $SERVER_NAME MCserver: Renamed the jar file with new name"
#===================== name 6. Rename server directory ============================
    cd "$HOME/mcservers" || return 0
    mv "$SERVER_NAME" "$SERVER_NAME_NEW"
    # Update internal variable
    SERVER_NAME="$SERVER_NAME_NEW"
    SERVER_DIR="$HOME/mcservers/$SERVER_NAME"
echlog "✏ $SERVER_NAME MCserver: Renamed the server direcotry"
#===================== name 7. Regenerate autostart ==============================
    manage_autostart "$SERVER_NAME" "$SERVER_DIR"
    manage_run_sh "$SERVER_NAME" "$SERVER_DIR"
} fi
} #change_server_name()

#==================================== 05. Main Menu ====================================
while true; do
    MENU_CHOICES=$(whiptail --title "$TITLE" --menu "What would you like to do with $SERVER_NAME" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
    "1" "🖥  Open Console (tmux attach)" \
    "2" "▶  Start Server" \
    "3" "⏹  Stop Server" \
    "4" "⚙  Edit server.properties" \
    "5" "⬆  Update $SERVER_NAME.jar file (and mods)" \
    "6" "📂 Edit Files (LSR)" \
    "7" "⏱  Add or Reconfigure Autostart Features" \
    "8" "🧠 Add or Reconfigure Memory Amount" \
    "9" "✏  Change Server Name" \
    "0" "X  Exit" \
        3>&1 1>&2 2>&3)
    if [ $? -ne 0 ]; then
        echlog "X $SERVER_NAME MCserver: Menu canceled. Exiting."
        exit 0
    fi
    case $MENU_CHOICES in
    1)
        echlog "🖥 $SERVER_NAME MCserver: Opening Server Console..."
        tmux attach -t "$SERVER_NAME"

    ;;
    2)
        startserver_tmux
    ;;
    3)
        echlog "⏹ $SERVER_NAME MCserver: Stopped $SERVER_NAME server"
        tmux send-keys -t "$SERVER_NAME" "stop" C-m

    ;;
    4)
        edit_server_properties
    ;; #external script
    5)
        modrinth_autodownloader #external script
        update_server_jar #internal functoin
    ;;
    6)
        lsr ;;
    7)
        manage_autostart "$SERVER_NAME" "$SERVER_DIR" ;; #internal
    8)
        manage_run_sh "$SERVER_NAME" "$SERVER_DIR" ;; #internal
    9)
        change_server_name ;; #internal
    0)
        echlog "X $SERVER_NAME MCserver: Exited Mange Servers"
        exit 0 ;;
    *) echlog "$SERVER_NAME MCserver: Invalid option selected. \nHow did you get here???" ;;
    esac
done
exit 0
