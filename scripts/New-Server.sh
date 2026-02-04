#!/usr/bin/env bash
#============================ Logging ============================
STATE_DIR="$HOME/.local/state/MCserverTUI"
MC_TUI_LOGFILE="$STATE_DIR/mcservertui.log"
mkdir -p "$STATE_DIR"

echlog() {
    local msg="$*"
    echo "$msg"
    echo "$(date '+%Y-%m-%d %H:%M:%S') $msg" >> "$MC_TUI_LOGFILE"
}
#==================================== MC Server Setup Wizard ====================================
TITLE="New Server Setup"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
MC_ROOT="$HOME/mcservers"
mkdir -p "$MC_ROOT"
## Detect terminal size
### in case tput is not found, sets to fixed value
TERM_HEIGHT=$(tput lines 2>/dev/null || echo 24)
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
## Set TUI size based on terminal size
HEIGHT=$(( TERM_HEIGHT ))
WIDTH=$(( TERM_WIDTH ))
MENU_HEIGHT=$(( HEIGHT - 10 ))

#==================================== 1. Get Info ====================================
SERVER_NAME=$(whiptail --title "$TITLE" --inputbox "Enter a name for your server:" "$HEIGHT" "$WIDTH" 3>&1 1>&2 2>&3)
[ -z "$SERVER_NAME" ] && exit 0
SERVER_DIR="$MC_ROOT/$SERVER_NAME"
mkdir -p "$SERVER_DIR"
MC_VERSION=$(whiptail --title "$TITLE" --inputbox "Enter Minecraft version (e.g., 1.21.11):" "$HEIGHT" "$WIDTH" 3>&1 1>&2 2>&3)
MC_LOADER_CHOICE=$(whiptail --title "$TITLE" --menu "Choose a Loader/Server SW:" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
    "1" "Vanilla - From Mojang" \
    "2" "Fabric - More perfomance and Good mods" \
    "3" "Forge - Slower but really good mods" \
    "4" "NeoForge - Better version of Forge" \
    "5" "Paper - Lightweigt but sometimes less precise" \
    "6" "Purpur - Better version of Paper" \
    "7" "Velocity - Proxy for connecting multiple servers and diferent versions" \
    "8" "Enter a loader name manually" \
    3>&1 1>&2 2>&3)
case $MC_LOADER_CHOICE in
    1) MC_LOADER="vanilla" ;;
    2) MC_LOADER="fabric" ;;
    3) MC_LOADER="forge" ;;
    4) MC_LOADER="neoforge" ;;
    5) MC_LOADER="paper" ;;
    6) MC_LOADER="purpur" ;;
    7) MC_LOADER="velocity" ;;
    *) MC_LOADER=$(whiptail --title "$TITLE" --inputbox "Enter loader exampes:\nvanilla, fabric, forge, paper" "$HEIGHT" "$WIDTH" 3>&1 1>&2 2>&3) ;;

esac
MOD_COLLECTION=$(whiptail --title "$TITLE" --inputbox "Enter Modrinth Mods collection ID (or leave blank):" "$HEIGHT" "$WIDTH" 3>&1 1>&2 2>&3)
echlog "New $MC_LOADER server named $SERVER_NAME on version $MC_VERSION with this modrinth ID: $MOD_COLLECTION"

#==================================== 2. Save Info ====================================
CONF_FILE="$SERVER_DIR/server-version.conf"
cat > "$CONF_FILE" <<EOF
version=$MC_VERSION
loader=$MC_LOADER
collection=$MOD_COLLECTION
EOF
echlog "Saved config to $CONF_FILE"

#============================ 3. Modrinth Downloader - Run Only if supported loader ====================================
if [[   "$MC_LOADER" == "fabric" || \
        "$MC_LOADER" == "forge" ||  \
        "$MC_LOADER" == "neoforge" || \
        "$MC_LOADER" == "liteloader" || \
        "$MC_LOADER" == "quilt" || \
        "$MC_LOADER" == "rift" || \
        "$MC_LOADER" == "paper" || \
        "$MC_LOADER" == "purpur" || \
        "$MC_LOADER" == "folia" || \
        "$MC_LOADER" == "spigot" || \
        "$MC_LOADER" == "velocity" ]]; then
    if whiptail --title "$TITLE" --yesno \
"Would you also like to run Modrinth Collection Downloader?\n\
For $SERVER_NAME MCserver with $MC_LOADER loader." "$HEIGHT" "$WIDTH"; then
        cd "$SCRIPT_DIR/more-scripts/"
        bash modrinth-downloader.sh --name $SERVER_NAME
        echlog "⬆ $SERVER_NAME MCserver: Ran Modrinth Collection Downloader with $MC_LOADER"
    else
        echlog "⬆ $SERVER_NAME MCserver: Did NOT run Modrinth colection downloader"
    fi
else
    echlog "⬆ $SERVER_NAME MCserver: Loader presumed to be Vanila, no mods will be downloaded"
fi

#==================================== 4.Install a loader ====================================
cd "$SERVER_DIR"

MC_MENU_LOADER=$(whiptail --title "$TITLE" --menu "How would you like to install server jar file" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
    "1" "manual URL" \
    "2" "MCjarfiles API(Modded and Vanilla)" \
    3>&1 1>&2 2>&3)
case $MC_MENU_LOADER in
    1)
    JAR_NAME="$SERVER_NAME.jar"
    SERVER_URL=$(whiptail --title "$TITLE" --inputbox "Enter server URL" "$HEIGHT" "$WIDTH" 3>&1 1>&2 2>&3)
    wget -O "$JAR_NAME" "$SERVER_URL"
    echlog "manual server jar url"
    ;;
    2)
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

esac
if [[ $MC_LOADER != "velocity" ]] then
#==================================== 5 Initialize Server Jarfile ====================================
#This will run the server.jar in order for it to settle itsef in. It Creats files that we need to edit
if whiptail --title "$TITLE" --yesno "Would you like to Initialize your server.jar?\nHighly Reccomended\nYou may need to press crtl+c if you hang at eula.txt" "$HEIGHT" "$WIDTH"; then
    cd "$SERVER_DIR"
    java -jar $JAR_NAME
fi

#==================================== 6. Server.properties editor====================================
if whiptail --title "$TITLE" --yesno "Would you like edit server.properties?\nSeed, Gamemode, Port, Online Mode, MOTD" "$HEIGHT" "$WIDTH"; then
    cd "$SCRIPT_DIR/more-scripts/"
    bash server_properties_editor.sh --name $SERVER_NAME
    echlog "Ran server.properties editor with $SERVER_NAME flag."
fi
fi
#==================================== 7. Memory Config ====================================
MC_XMS=$(whiptail --title "Minimum RAM (Xms)" --inputbox "Example: 1G, 2G, 3G" "$HEIGHT" "$WIDTH" 3>&1 1>&2 2>&3)
MC_XMX=$(whiptail --title "Maximum RAM (Xmx)" --inputbox "Example: 4G, 6G, 8G" "$HEIGHT" "$WIDTH" 3>&1 1>&2 2>&3)
## Make variables
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

#==================================== 8. Create run.sh ====================================
cat > "$SERVER_DIR/run.sh" <<EOF
#!/bin/bash
java $RUN_MC_XMS $RUN_MC_XMX -jar $JAR_NAME nogui
EOF

chmod +x "$SERVER_DIR/run.sh"

if [[ $MC_LOADER != "velocity" ]] then
#==================================== 9. EULA ====================================
if whiptail --title "EULA" --yesno "Do you agree to the Minecraft EULA?" "$HEIGHT" "$WIDTH"; then
    echo "eula=true" > "$SERVER_DIR/eula.txt"
else
    echo "eula=false" > "$SERVER_DIR/eula.txt"
fi

fi

#==================================== 10. Cron Autostart ====================================
if whiptail --title "Enable automatic startup?" --yesno "Add cronjob for autostart?" "$HEIGHT" "$WIDTH"; then

    AUTOSTART="$SERVER_DIR/autostart.sh"

    # Create autostart script in the server folder
    cat > "$AUTOSTART" <<EOF
#!/bin/bash
# Autostart script for server: $SERVER_NAME

SESSION="$SERVER_NAME"

# Start tmux only if not already running
if ! tmux has-session -t "\$SESSION" 2>/dev/null; then
    tmux new-session -d -s "\$SESSION"
    tmux send-keys -t "\$SESSION" "cd '$SERVER_DIR'" C-m
    tmux send-keys -t "\$SESSION" "./run.sh" C-m
fi
EOF

    chmod +x "$AUTOSTART"

    # Add cron entry only if not already present
    CRONLINE="@reboot $AUTOSTART"

    if (crontab -l 2>/dev/null | grep -F "$CRONLINE" >/dev/null); then
        echlog "Cron entry already exists. Skipping."
    else
        (crontab -l 2>/dev/null; echo "$CRONLINE") | crontab -
        echlog "Autostart enabled and cronjob added."
    fi
fi


#==================================== 11. Start Server ====================================
if whiptail --title "Start Server?" --yesno "Do you with to run and connect your server?\nAfter you exit tmux, you will drop back into the main menu." "$HEIGHT" "$WIDTH"; then
tmux new-session -d -s "$SERVER_NAME"
tmux send-keys -t "$SERVER_NAME" "cd '$SERVER_DIR'" C-m
tmux send-keys -t "$SERVER_NAME" "./run.sh" C-m
tmux attach -t "$SERVER_NAME"
fi


exit 0
