#!/bin/bash
#==================================== MC Server Setup Wizard ====================================
TITLE="New Server Setup"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
MC_ROOT="$HOME/mcservers"
mkdir -p "$MC_ROOT"

#==================================== 1. Get Info ====================================
SERVER_NAME=$(whiptail --title "$TITLE" --inputbox "Enter a name for your server:" 10 60 3>&1 1>&2 2>&3)
[ -z "$SERVER_NAME" ] && return 0
SERVER_DIR="$MC_ROOT/$SERVER_NAME"
mkdir -p "$SERVER_DIR"
MC_VERSION=$(whiptail --title "$TITLE" --inputbox "Enter Minecraft version (e.g., 1.21.10):" 10 60 3>&1 1>&2 2>&3)
MC_LOADER=$(whiptail --title "$TITLE" --inputbox "Enter loader (vanilla/fabric):" 10 60 3>&1 1>&2 2>&3)
MOD_COLLECTION=$(whiptail --title "$TITLE" --inputbox "Enter Modrinth collection ID (or leave blank):" 10 60 3>&1 1>&2 2>&3)
#==================================== 2. Save Info ====================================
CONF_FILE="$SERVER_DIR/server-version.conf"
cat > "$CONF_FILE" <<EOF
version=$MC_VERSION
loader=$MC_LOADER
collection=$MOD_COLLECTION
EOF
echo "Saved config to $CONF_FILE"

#==================================== 3.Offer Modrinth Downloader ====================================
if whiptail --title "$TITLE" --yesno "Would you also like to run Modrinth Collection Downloader?" 10 60; then
    "$SCRIPT_DIR/modrinth-colection-downloader/modrith-downloader.sh"
    echo "Ran Modrinth Collection Downloader."
fi

#==================================== 4.Install a loader ====================================
cd "$SERVER_DIR"

MC_MENU_LOADER=$(whiptail --title "$TITLE" --menu "How would you like to install server jar file" 15 60 6 \
    "1" "manual URL" \
    "2" "Fabric (Manual)" \
    3>&1 1>&2 2>&3)
case $MC_MENU_LOADER in
    1)
    JAR_NAME="$SERVER_NAME.jar"
    SERVER_URL=$(whiptail --title "$TITLE" --inputbox "Enter server URL" 10 60 3>&1 1>&2 2>&3)
    curl -sLo "$JAR_NAME" "$SERVER_URL"
    ;;
    2)

    INSTALLER_VERSOIN=$(whiptail --title "$TITLE" --inputbox "Enter INSTALLER version(1.1.0)" 10 60 3>&1 1>&2 2>&3)
    LOADER_VERSION=$(whiptail --title "$TITLE" --inputbox "Enter LOADER version(0.18.1)" 10 60 3>&1 1>&2 2>&3)
    JAR_NAME="$SERVER_NAME.jar"
    curl -sLo "$JAR_NAME" https://meta.fabricmc.net/v2/versions/loader/$MC_VERSION/$LOADER_VERSION/$INSTALLER_VERSOIN/server/jar

    ;;
esac

#==================================== 5. Memory Config ====================================
MC_XMS=$(whiptail --title "Minimum RAM (Xms)" --inputbox "Example: 1G, 2G, 3G" 10 60 3>&1 1>&2 2>&3)
MC_XMX=$(whiptail --title "Maximum RAM (Xmx)" --inputbox "Example: 4G, 6G, 8G" 10 60 3>&1 1>&2 2>&3)

#==================================== 6. Create run.sh ====================================
cat > "$SERVER_DIR/run.sh" <<EOF
#!/bin/bash
java -Xms$MC_XMS -Xmx$MC_XMX -jar $JAR_NAME nogui
EOF

chmod +x "$SERVER_DIR/run.sh"

#==================================== 7. EULA ====================================
if whiptail --title "EULA" --yesno "Do you agree to the Minecraft EULA?" 10 60; then
    echo "eula=true" > "$SERVER_DIR/eula.txt"
else
    echo "eula=false" > "$SERVER_DIR/eula.txt"
fi

#==================================== 8. Cron Autostart ====================================
if whiptail --title "Enable automatic startup?" --yesno "Add cronjob for autostart?" 10 60; then

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


#==================================== 9. Start Server ====================================
if whiptail --title "Start Server?" --yesno "Do you with to run and connect your server" 10 60; then
tmux new-session -d -s "$SERVER_NAME"
tmux send-keys -t "$SERVER_NAME" "cd '$SERVER_DIR'" C-m
tmux send-keys -t "$SERVER_NAME" "./run.sh" C-m
tmux attach -t "$SERVER_NAME"
fi


exit 0
