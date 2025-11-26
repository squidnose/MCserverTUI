#!/bin/bash
#
# MC Server Setup Wizard
#

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
MC_ROOT="$HOME/mcservers"

mkdir -p "$MC_ROOT"

# ---------------------------------------
# Whiptail Slider Function
# ---------------------------------------
slider() {
    local prompt="$1"
    local default="$2"
    whiptail --title "$prompt" --gauge "Use arrow keys then ENTER" 10 60 0 < <(
        for i in $(seq 0 5 100); do
            echo $i
            sleep 0.01
        done
    ) >/dev/null 2>&1
    whiptail --title "$prompt" --inputbox "$prompt" 10 60 "$default" 3>&1 1>&2 2>&3
}

# ---------------------------------------
# 1. Get Basic Info
# ---------------------------------------
SERVER_NAME=$(whiptail --title "Server Name" --inputbox "Enter a name for your server:" 10 60 3>&1 1>&2 2>&3)
[ -z "$SERVER_NAME" ] && exit 1

SERVER_DIR="$MC_ROOT/$SERVER_NAME"
mkdir -p "$SERVER_DIR"

MC_VERSION=$(whiptail --title "Version" --inputbox "Enter Minecraft version (e.g., 1.21.10):" 10 60 3>&1 1>&2 2>&3)
MC_LOADER=$(whiptail --title "Loader" --inputbox "Enter loader (vanilla/fabric):" 10 60 3>&1 1>&2 2>&3)

MOD_COLLECTION=$(whiptail --title "Modrinth Collection" --inputbox "Enter Modrinth collection ID (or leave blank):" 10 60 3>&1 1>&2 2>&3)

# ---------------------------------------
# Save Config
# ---------------------------------------
CONF_FILE="$SERVER_DIR/server-version.conf"

cat > "$CONF_FILE" <<EOF
version=$MC_VERSION
loader=$MC_LOADER
collection=$MOD_COLLECTION
EOF

echo "Saved config to $CONF_FILE"

# ---------------------------------------
# 2. Offer Modrinth Downloader
# ---------------------------------------
if whiptail --title "Modrinth Downloader" --yesno "Install Modrinth Collection Downloader?" 10 60; then
    cp "$SCRIPT_DIR/modrinth-autodownloader.py" "$SERVER_DIR/modrinth-autodownloader.py"
    echo "Downloaded Modrinth tool."
fi

# ---------------------------------------
# 3. Install Loader (Fabric or Vanilla)
# ---------------------------------------
cd "$SERVER_DIR"

if [ "$MC_LOADER" = "fabric" ]; then
    JAR_NAME="fabric-$MC_VERSION.jar"
    echo "Installing Fabric loader…"

    curl -sLo fabric-installer.jar https://meta.fabricmc.net/v2/versions/installer/0.11.2/installer.jar

    java -jar fabric-installer.jar server -mc-version "$MC_VERSION" -downloadMinecraft
    mv fabric-server-launch.jar "$JAR_NAME"

elif [ "$MC_LOADER" = "vanilla" ]; then
    JAR_NAME="vanilla-$MC_VERSION.jar"
    echo "Downloading Vanilla server jar…"

    curl -sLo "$JAR_NAME" "https://piston-meta.mojang.com/v1/packages/$(curl -s https://piston-meta.mojang.com/mc/game/version_manifest.json | jq -r ".versions[] | select(.id==\"$MC_VERSION\") | .url" | xargs curl -s | jq -r '.downloads.server.jar.url')"

else
    echo "Unknown loader: $MC_LOADER"
    exit 1
fi

# ---------------------------------------
# 4. Memory Settings
# ---------------------------------------
MC_XMS=$(slider "Minimum RAM (Xms)" "1G")
MC_XMX=$(slider "Maximum RAM (Xmx)" "4G")

# ---------------------------------------
# 5. Create run.sh
# ---------------------------------------
cat > "$SERVER_DIR/run.sh" <<EOF
#!/bin/bash
java -Xms$MC_XMS -Xmx$MC_XMX -jar $JAR_NAME nogui
EOF

chmod +x "$SERVER_DIR/run.sh"

# ---------------------------------------
# 6. EULA
# ---------------------------------------
if whiptail --title "EULA" --yesno "Do you agree to the Minecraft EULA?" 10 60; then
    echo "eula=true" > "$SERVER_DIR/eula.txt"
else
    echo "eula=false" > "$SERVER_DIR/eula.txt"
fi

# ---------------------------------------
# 7. Cron Autostart
# ---------------------------------------
if whiptail --title "Autostart" --yesno "Add cron autostart?" 10 60; then
    AUTOSTART="$HOME/MCserverTUI/Autostart-files/${SERVER_NAME}_autostart.sh"
    mkdir -p "$HOME/MCserverTUI/Autostart-files"

    cat > "$AUTOSTART" <<EOF
#!/bin/bash
tmux new-session -d -s "$SERVER_NAME"
tmux send-keys -t "$SERVER_NAME" "cd '$SERVER_DIR'" C-m
tmux send-keys -t "$SERVER_NAME" "./run.sh" C-m
EOF

    chmod +x "$AUTOSTART"

    (crontab -l 2>/dev/null; echo "@reboot $AUTOSTART") | crontab -

    echo "Autostart enabled."
fi

whiptail --title "Done!" --msgbox "Server setup complete! Folder: $SERVER_DIR" 10 60
exit 0
