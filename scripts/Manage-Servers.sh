#!/usr/bin/env bash
#This script uses a modified version of my LSR
#==================================== MC Server Management ====================================
#============================ 00. Logging ============================
mkdir -p "$HOME/.local/state/MCserverTUI"
MC_TUI_LOGFILE="$HOME/.local/state/MCserverTUI/mcservertui.log"

echlog()
{
    local msg="$*"
    echo "$msg"
    echo "$(date '+%Y-%m-%d %H:%M:%S') $msg" >> "$MC_TUI_LOGFILE"
}
#==================================== 01. Parameters ====================================
TITLE="MC server Management"
MC_ROOT="$HOME/mcservers"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
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
if [[ ${#MENU_ITEMS[@]} -eq 0 ]]; then
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
## Ensure tmux exists
        if ! command -v tmux >/dev/null 2>&1; then
            whiptail --msgbox "tmux is required but not installed.\nPlease install tmux first." "$HEIGHT" "$WIDTH"
            exit 0
        fi
#======================= startserver 1. Runs mcserver in Tmux =========================
if whiptail --title "Start Server?" --yesno "Do you wish to run and connect your server" "$HEIGHT" "$WIDTH" ; then
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
    cd "$SCRIPT_DIR/more-scripts/"
    echlog "⚙ $SERVER_NAME MCserver: Loading server.properties file..."
    bash server_properties_editor.sh --name $SERVER_NAME
    echlog "⚙ $SERVER_NAME MCserver: Ran server.properties line editor."
fi
} #edit_server_properties()

content_downloader()
{
#Download Content for MCserver Operations
#============================ 03. Content Downloader ====================================
#========================  A. Load config file ==================================
# I load it a seccond time, because the info could change after runnig this part again
if [ -f "$CONF_FILE" ]; then
    source "$CONF_FILE"
else
    version=""
    loader=""
    collection=""
fi
MC_VERSION="$version"
MC_LOADER="$loader"

#=========================  B. Main Menu ====================================
while true; do
MC_DOWNLOAD_CHOICE=$(whiptail --title "$TITLE" --menu \
"Install Content for:\n$SERVER_NAME MCserver with $MC_LOADER loader" \
"$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
"modrinth"   "Download Mods and Plugins using Modrinth Collection ID" \
"mcjarfiles" "Download Server.jar files using MCjarfiles API" \
"manual"     "Manual File Downloader Manager (Mods and Server.jar)" \
"X"          "Go Back" \
3>&1 1>&2 2>&3) || return 0

    case "$MC_DOWNLOAD_CHOICE" in
        modrinth)
            cd "$SCRIPT_DIR/more-scripts/" || return 0
            bash modrinth-downloader.sh --name "$SERVER_NAME"
            echlog "⬆ $SERVER_NAME MCserver: Ran Modrinth Collection Downloader with $MC_LOADER"
        ;;
        mcjarfiles)
        cd "$SERVER_DIR"
        JAR_NAME="$SERVER_NAME.jar"
        if [[ "$MC_LOADER" == "vanila" || "$MC_LOADER" == "vanilla" ]]; then
            wget -O "$JAR_NAME" https://mcjarfiles.com/api/get-jar/$MC_LOADER/release/$MC_VERSION
        elif [[ "$MC_LOADER" == "paper" || "$MC_LOADER" == "purpur" ]]; then
            wget -O "$JAR_NAME" https://mcjarfiles.com/api/get-jar/servers/$MC_LOADER/$MC_VERSION
        elif [[ "$MC_LOADER" == "fabric" || "$MC_LOADER" == "forge" || "$MC_LOADER" == "neoforge" ]]; then
            wget -O "$JAR_NAME" https://mcjarfiles.com/api/get-jar/modded/$MC_LOADER/$MC_VERSION
        elif [[ "$MC_LOADER" == "velocity" ]]; then
            wget -O "$JAR_NAME" https://mcjarfiles.com/api/get-latest-jar/proxies/$MC_LOADER
        fi
        echlog "⬆ $SERVER_NAME MCserver: MCjarfiles API called using: $MC_LOADER loader, version $MC_VERSION, Saved as $JAR_NAME"
        ;;
        manual)
            cd "$SCRIPT_DIR/more-scripts/" || return 0
            bash manual-downloader.sh --name "$SERVER_NAME"
            echlog "⬆ $SERVER_NAME MCserver: Ran Manual Downloader for $MC_LOADER"
        ;;
        *)
        return 0
        ;;
    esac
done

} #content_downloader()

lsr()
{
    cd "$SCRIPT_DIR/more-scripts/"
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
#!/usr/bin/env bash
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

# Helper for manage_run_sh()
validate_mem(){ [[ "$1" =~ ^[0-9]+[MG]$ ]] }

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

    ### Validate that memory doesnt have spaces or small M or G
    ### If the user did not do a good job, replace with blank
    if ! validate_mem "$MC_XMS"; then
        MC_XMS=""
    fi
    if ! validate_mem "$MC_XMX"; then
        MC_XMX=""
    fi

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
#!/usr/bin/env bash
java $RUN_MC_XMS $RUN_MC_XMX -jar "$JAR_NAME" nogui
EOF
chmod +x "$RUNSCRIPT"
echlog "$SERVER_NAME MCserver: created run.sh for $SERVER_NAME"
fi

} #manage_run_sh()

change_name()
{
if whiptail --title "Change Name of $SERVER_NAME?" --yesno \
"Do you want to change the name of your Server?
This will also force stop your server!\n
STOP YOUR SERVER BEFORE CHANGING THE NAME!!!" "$HEIGHT" "$WIDTH" ; then
{
echlog "✏ $SERVER_NAME MCserver: Started renaming process"
#===================== name 1. Force Stop the old server=====================
tmux kill-session -t "$SERVER_NAME"
echlog "✏ $SERVER_NAME MCserver: Killed $SERVER_NAME tmux session"

#===================== name 2.Ask for the new name =====================
# If the name exists, complain
while true; do
    SERVER_NAME_NEW=$(whiptail --title "$TITLE" --inputbox \
    "Enter a NEW name for your server:" "$HEIGHT" "$WIDTH" 3>&1 1>&2 2>&3) || return 0

    # If empty then return 0
    [ -z "$SERVER_NAME_NEW" ] && return 0

    ## Incase name exists, it will complain:)
    if [ -d "$MC_ROOT/$SERVER_NAME_NEW" ]; then
        whiptail --title "Server Already Exists" --msgbox \
"A server named '$SERVER_NAME_NEW' already exists in:\n$MC_ROOT\n
    Choose A diferent name!\n
You will be now prompted to enter the name again or press cancel to exit " "$HEIGHT" "$WIDTH"
        continue
    else
        break
    fi
done
OLD_AUTOSTART="$HOME/mcservers/$SERVER_NAME/autostart.sh"

#===================== name 3. Remove cron entry for old name =====================
    if crontab -l >/dev/null 2>&1; then
        crontab -l | grep -v "@reboot $OLD_AUTOSTART" | crontab -
    fi
echlog "✏ $SERVER_NAME MCserver: Removed cron entry for old name"
#===================== name 4. Remove run.sh and autostart.sh ============================
    cd "$SERVER_DIR"
    rm run.sh
    rm autostart.sh
echlog "✏ $SERVER_NAME MCserver: Removed run.sh and autostart.sh with old names"
#===================== name 5. Rename server jar ============================
    JAR_NAME_OLD="$SERVER_NAME.jar"
    JAR_NAME_NEW="$SERVER_NAME_NEW.jar"
    mv "$JAR_NAME_OLD" "$JAR_NAME_NEW"
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
} #change_name()

#Remove server
remove()
{
# First confirmation
whiptail --title "⚠ Remove Server ⚠" --yesno \
"You are about to PERMANENTLY DELETE:\n\n$SERVER_NAME\n\nThis cannot be undone!" \
"$HEIGHT" "$WIDTH" || return 0

echlog "🗑 $SERVER_NAME MCserver: Removal process started"
# Second confirmation (strong warning)
if whiptail --title "Final Warning" --yesno \
"Are you REALLY sure you want to delete:\n\n$SERVER_DIR ?" "$HEIGHT" "$WIDTH"; then

    # Stop running server if active
    if tmux has-session -t "$SERVER_NAME" 2>/dev/null; then
        tmux kill-session -t "$SERVER_NAME"
        echlog "🗑 $SERVER_NAME MCserver: Killed tmux session before deletion"
    fi

    # Remove cron autostart if exists
    AUTOSTART="$SERVER_DIR/autostart.sh"
    if crontab -l 2>/dev/null | grep -F "$AUTOSTART" >/dev/null; then
        crontab -l 2>/dev/null | grep -v "$AUTOSTART" | crontab -
        echlog "🗑 $SERVER_NAME MCserver: Removed cron autostart entry"
    fi

    # Delete directory
    rm -rf "$SERVER_DIR"
    echlog "🗑 $SERVER_NAME MCserver: Server directory deleted"
    whiptail --msgbox "Server '$SERVER_NAME' has been permanently removed." "$HEIGHT" "$WIDTH"
    exit 0
    else
        echlog "🗑 $SERVER_NAME MCserver: Deletion cancelled"
    fi
}

#==================================== 05. Main Menu ====================================
while true; do
    MENU_CHOICES=$(whiptail --title "$TITLE" --menu "What would you like to do with $SERVER_NAME" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
    "1" "🖥  Open Console (tmux attach)" \
    "2" "▶  Start Server" \
    "3" "⏹  Stop Server" \
    "4" "⚙  Edit server.properties" \
    "5" "⬆  Install/Update content (Server.jar, mods and plugins)" \
    "6" "📂 Edit Files (LSR)" \
    "7" "⏱  Add or Reconfigure Autostart Features" \
    "8" "🧠 Add or Reconfigure Memory Amount" \
    "9" "⚠️ Change (Rename | Remove)" \
    "T" "📟 Terminal Utils" \
    "0" "X  Go Back .." \
        3>&1 1>&2 2>&3)
    if [ $? -ne 0 ]; then
        echlog "X $SERVER_NAME MCserver: Menu canceled. Exiting."
        exit 0
    fi
    case $MENU_CHOICES in
    1)
        ## Ensure tmux exists
        if ! command -v tmux >/dev/null 2>&1; then
            whiptail --msgbox "tmux is required but not installed.\nPlease install tmux first." "$HEIGHT" "$WIDTH"
            exit 0
        fi
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
        content_downloader
    ;;
    6)
        lsr ;;
    7)
        manage_autostart "$SERVER_NAME" "$SERVER_DIR" ;; #internal
    8)
        manage_run_sh "$SERVER_NAME" "$SERVER_DIR" ;; #internal
    9)
        CHANGE=$(whiptail --title "$TITLE" --menu \
        "Choose an Operation:" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
        "change_name"   "Change the Name of this MCserver" \
        "remove"        "⚠️Removes the server⚠️" \
        3>&1 1>&2 2>&3)
        [ -z "$CHANGE" ] && return 0
        #Run the selected function
        $CHANGE
        ;;
    T)
        TERMINAL_UTIL=$(whiptail --title "$TITLE" --menu \
        "What terminal util for $SERVER_NAME woudld you like to run?\nQ to Quit" \
        "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
        "ncdu"  "Disk Space Usage Analyzer" \
        "nnn"   "File Explorer" \
        3>&1 1>&2 2>&3)
        echlog "📟 $SERVER_NAME opened using $TERMINAL_UTIL"
        cd "$SERVER_DIR"
        $TERMINAL_UTIL
    ;;
    0)
        echlog "X $SERVER_NAME MCserver: Exited Mange Servers"
        exit 0 ;;
    *) echlog "$SERVER_NAME MCserver: Invalid option selected. \nHow did you get here???" ;;
    esac
done
exit 0
