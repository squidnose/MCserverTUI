#!/bin/bash

### Detect script directory
scriptdir="$(cd "$(dirname "$0")" && pwd)"

### Base server folder
MC_BASE="$HOME/mcservers"

### ------------------------------
### Ask user for basic info
### ------------------------------
SERVER_NAME=$(whiptail --title "Server Name" --inputbox "Enter server name:" 10 60 3>&1 1>&2 2>&3)
[ -z "$SERVER_NAME" ] && exit 1

SERVER_DIR="$MC_BASE/$SERVER_NAME"
mkdir -p "$SERVER_DIR"

MC_VERSION=$(whiptail --title "Minecraft Version" --inputbox "Enter MC version (example 1.21.10):" 10 60 3>&1 1>&2 2>&3)

LOADER=$(whiptail --title "Loader" --inputbox "Enter loader (vanilla / fabric):" 10 60 fabric 3>&1 1>&2 2>&3)

MOD_COLLECTION=$(whiptail --title "Modrinth Collection" --inputbox "Enter Modrinth collection ID (or leave blank):" 10 60 3>&1 1>&2 2>&3)

### ------------------------------
### Save server-version.conf
### ------------------------------
cat <<EOF > "$SERVER_DIR/server-version.conf"
scriptdir="$scriptdir"
server_name="$SERVER_NAME"
mc_version="$MC_VERSION"
loader="$LOADER"
mod_collection="$MOD_COLLECTION"
EOF

### ------------------------------
### Ask whether to install Modrinth downloader
### ------------------------------
if whiptail --title "Modrinth Downloader" --yesno "Install Modrinth collection downloader?" 10 60; then
    cp "$scriptdir/modrinth-autodownloader.py" "$SERVER_DIR/modrinth-autodownloader.py"
    echo "Downloader installed."
fi

### ------------------------------
### Install Loader (Vanilla or Fabric)
### ------------------------------
cd "$SERVER_DIR"

if [[ "$LOADER" == "vanilla" ]]; then
    JAR_NAME="vanilla-$MC_VERSION.jar"
    curl -L "https://piston-meta.mojang.com/v1/packages/${MC_VERSION}.json" -o version.json
    DOWNLOAD_URL=$(jq -r '.downloads.server.url' version.json)
    curl -o "$JAR_NAME" "$DOWNLOAD_URL"

elif [[ "$LOADER" == "fabric" ]]; then
    JAR_NAME="fabric-$MC_VERSION.jar"
    curl -o fabric-installer.jar https://meta.fabricmc.net/v2/versions/installer/latest/server/jar
    java -jar fabric-installer.jar server -mc-version "$MC_VERSION" -downloadMinecraft -dir "$SERVER_DIR"
    mv fabric-server-launch.jar "$JAR_NAME"
fi

### ------------------------------
### RAM selection sliders
### ------------------------------
XMS=$(whiptail --title "Min RAM" --slider "Select Xms in MB:" 10 60 512 512 16384 3>&1 1>&2 2>&3)
XMX=$(whiptail --title "Max RAM" --slider "Select Xmx in MB:" 10 60 2048 512 32768 3>&1 1>&2 2>&3)

### ------------------------------
### Create run.sh
### ------------------------------
cat <<EOF > "$SERVER_DIR/run.sh"
#!/bin/bash
cd "\$(dirname "\$0")"
java -Xms${XMS}M -Xmx${XMX}M -jar $JAR_NAME nogui
EOF

chmod +x "$SERVER_DIR/run.sh"

### ------------------------------
### EULA
### ------------------------------
if whiptail --title "EULA" --yesno "Agree to EULA?" 10 60; then
    echo "eula=true" > "$SERVER_DIR/eula.txt"
else
    echo "eula=false" > "$SERVER_DIR/eula.txt"
fi

### ------------------------------
### Autostart (cron + tmux)
### ------------------------------
if whiptail --title "Autostart" --yesno "Enable autostart on reboot?" 10 60; then
    AUTOSTART="$HOME/MCserverTUI/Autostart-files/${SERVER_NAME}_autostart.sh"
    mkdir -p "$HOME/MCserverTUI/Autostart-files"

    cat <<EOF > "$AUTOSTART"
#!/bin/bash
tmux new-session -d -s $SERVER_NAME
tmux send-keys -t $SERVER_NAME "cd $SERVER_DIR" C-m
tmux send-keys -t $SERVER_NAME "./run.sh" C-m
EOF
    chmod +x "$AUTOSTART"

    (crontab -l; echo "@reboot $AUTOSTART") | crontab -
fi

whiptail --title "Done!" --msgbox "$SERVER_NAME setup complete." 10 60
