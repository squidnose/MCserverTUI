#!/bin/bash
#==================================== MC Server Setup Wizard ====================================
TITLE="New Server Setup"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
MC_ROOT="$HOME/mcservers"
mkdir -p "$MC_ROOT"
## Detect terminal size
TERM_HEIGHT=$(tput lines)
TERM_WIDTH=$(tput cols)
## Set TUI size based on terminal size
HEIGHT=$(( TERM_HEIGHT ))
WIDTH=$(( TERM_WIDTH ))
MENU_HEIGHT=$(( HEIGHT - 10 ))
#==================================== 1. Get Info ====================================
SERVER_NAME=$(whiptail --title "$TITLE" --inputbox "Enter a name for your server:" "$HEIGHT" "$WIDTH" 3>&1 1>&2 2>&3)
[ -z "$SERVER_NAME" ] && exit 0
SERVER_DIR="$MC_ROOT/$SERVER_NAME"
mkdir -p "$SERVER_DIR"
MC_VERSION=$(whiptail --title "$TITLE" --inputbox "Enter Minecraft version (e.g., 1.21.10):" "$HEIGHT" "$WIDTH" 3>&1 1>&2 2>&3)
MC_LOADER=$(whiptail --title "$TITLE" --inputbox "Enter loader (vanilla/fabric):" "$HEIGHT" "$WIDTH" 3>&1 1>&2 2>&3)
MOD_COLLECTION=$(whiptail --title "$TITLE" --inputbox "Enter Modrinth collection ID (or leave blank):" "$HEIGHT" "$WIDTH" 3>&1 1>&2 2>&3)
#==================================== 2. Save Info ====================================
CONF_FILE="$SERVER_DIR/server-version.conf"
cat > "$CONF_FILE" <<EOF
version=$MC_VERSION
loader=$MC_LOADER
collection=$MOD_COLLECTION
EOF
echo "Saved config to $CONF_FILE"

#==================================== 3.Offer Modrinth Downloader ====================================
if whiptail --title "$TITLE" --yesno "Would you also like to run Modrinth Collection Downloader?" "$HEIGHT" "$WIDTH"; then
    "$SCRIPT_DIR/more-scripts/modrith-downloader.sh --name $SERVER_NAME"
    echo "Ran Modrinth Collection Downloader with $SERVER_NAME flag."
fi

#==================================== 4.Install a loader ====================================
cd "$SERVER_DIR"

MC_MENU_LOADER=$(whiptail --title "$TITLE" --menu "How would you like to install server jar file" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
    "1" "manual URL" \
    "2" "Oficial Mojang API (Vanila)" \
    "3" "MCjarfiles API (Modded)" \
    3>&1 1>&2 2>&3)
case $MC_MENU_LOADER in
    1)
    JAR_NAME="$SERVER_NAME.jar"
    SERVER_URL=$(whiptail --title "$TITLE" --inputbox "Enter server URL" "$HEIGHT" "$WIDTH" 3>&1 1>&2 2>&3)
    curl -sLo "$JAR_NAME" "$SERVER_URL"
    ;;
    2)
    echo "tbd lol"
    ;;
    2)
    JAR_NAME="$SERVER_NAME.jar"
    curl -sLo "$JAR_NAME" https://mcjarfiles.com/api/get-jar/modded/$MC_LOADER/$MC_VERSION
    ;;
esac
#==================================== 5 Initialize Server Jarfile ====================================
#This will run the server.jar in order for it to settle itsef in. It Creats files that we need to edit
if whiptail --title "$TITLE" --yesno "Would you like to Initialize your server.jar?\nHighly Reccomended!" "$HEIGHT" "$WIDTH"; then
    cd "$SERVER_DIR"
    java -jar $JAR_NAME
fi
#==================================== 6. Server.properties editor====================================
if whiptail --title "$TITLE" --yesno "Would you like edit server.properties?\nSeed, Gamemode, Port, Online Mode, MOTD" "$HEIGHT" "$WIDTH"; then
    cd "$SCRIPT_DIR/more-scripts/"
    bash server_properties_editor.sh --name $SERVER_NAME
    echo "Ran server.properties editor with $SERVER_NAME flag."
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

#==================================== 9. EULA ====================================
if whiptail --title "EULA" --yesno "Do you agree to the Minecraft EULA?" "$HEIGHT" "$WIDTH"; then
    echo "eula=true" > "$SERVER_DIR/eula.txt"
else
    echo "eula=false" > "$SERVER_DIR/eula.txt"
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
        echo "Cron entry already exists. Skipping."
    else
        (crontab -l 2>/dev/null; echo "$CRONLINE") | crontab -
        echo "Autostart enabled and cronjob added."
    fi
fi


#==================================== 11. Start Server ====================================
if whiptail --title "Start Server?" --yesno "Do you with to run and connect your server" "$HEIGHT" "$WIDTH"; then
tmux new-session -d -s "$SERVER_NAME"
tmux send-keys -t "$SERVER_NAME" "cd '$SERVER_DIR'" C-m
tmux send-keys -t "$SERVER_NAME" "./run.sh" C-m
tmux attach -t "$SERVER_NAME"
fi


exit 0
