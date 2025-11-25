#!/bin/bash
#  Minecraft Server Setup Wizard


#==================================== Functions ====================================
#  Modrinth Collection Downloader Wrapper
modrinth_collection_downloader() {

    MODRINTH_MENU_CHOICE=$(whiptail --title "Modrinth Downloader" --menu "Choose Mod Collection" 15 60 4 \
        "1" "Install a custom Modrinth collection" \
        "2" "Install my default collection" \
        "3" "Install Geyser/Floodgate pack" \
        "4" "Cancel" \
        3>&1 1>&2 2>&3)

    case $MODRINTH_MENU_CHOICE in
        1)
            COLLECTION=$(whiptail --inputbox "Enter Modrinth Collection ID:" 10 60 3>&1 1>&2 2>&3)
            python3 modrinth-autodownloader.py -v "$MC_VERSION" -l fabric -c "$COLLECTION"
            ;;
        2)
            python3 modrinth-autodownloader.py -v "$MC_VERSION" -l fabric -c ziTsdV9j
            ;;
        3)
            python3 modrinth-autodownloader.py -v "$MC_VERSION" -l paper -c geyser
            ;;
        *)
            ;;
    esac
}

#  Crontab Setup
crontab_setup() {
    TYPE="$1"
    SERVER_NAME="$2"

    AUTOSTART_FILE=~/MCserverTUI/Autostart-files/${SERVER_NAME}_autostart.sh
    mkdir -p ~/MCserverTUI/Autostart-files

    if [ "$TYPE" = "mcserver" ]; then

        cat <<EOF > "$AUTOSTART_FILE"
#!/bin/bash
tmux new-session -d -s $SERVER_NAME
tmux send-keys -t $SERVER_NAME "cd ~/mcservers/$SERVER_NAME" C-m
tmux send-keys -t $SERVER_NAME "./run.sh" C-m
EOF

        chmod +x "$AUTOSTART_FILE"

        # add cron entry
        (crontab -l 2>/dev/null; echo "@reboot $AUTOSTART_FILE") | crontab -

        echo "Autostart configured for $SERVER_NAME."
    fi
}


#==================================== main Script ====================================
    # ───── Basic Info ─────
    read -p "Server Name: " SERVER_NAME
    read -p "Minecraft Version (enter manually, e.g. 1.21.4): " MC_VERSION
    read -p "Minecraft Loader (vanilla/forge/paper): " MC_LOADER
    read -p "Min RAM (Xms, e.g. 2G): " MC_XMS
    read -p "Max RAM (Xmx, e.g. 4G): " MC_XMX
    read -p "Agree to EULA? (yes/no): " EULA

    SERVER_DIR=~/mcservers/$SERVER_NAME
    mkdir -p "$SERVER_DIR"
    cd "$SERVER_DIR" || exit

    # ───── Download Server ─────
    echo "Downloading server ($MC_LOADER $MC_VERSION)..."

    case "$MC_LOADER" in
        vanilla)
            wget -O server.jar "https://piston-meta.mojang.com/v1/packages/$(curl -s https://piston-meta.mojang.com/mc/game/version_manifest_v2.json | \
                jq -r --arg v "$MC_VERSION" '.versions[] | select(.id==$v) | .url' | \
                xargs curl -s | jq -r '.downloads.server.url')"
            ;;
        paper)
            wget -O server.jar "https://api.papermc.io/v2/projects/paper/versions/$MC_VERSION/builds/$(curl -s https://api.papermc.io/v2/projects/paper/versions/$MC_VERSION | jq '.builds[-1]')/downloads/paper-$MC_VERSION-$(curl -s https://api.papermc.io/v2/projects/paper/versions/$MC_VERSION | jq '.builds[-1]').jar"
            ;;
        forge)
            echo "Downloading Forge installer..."
            wget -O forge-installer.jar "https://maven.minecraftforge.net/net/minecraftforge/forge/${MC_VERSION}/forge-${MC_VERSION}-installer.jar"
            java -jar forge-installer.jar --installServer
            rm forge-installer.jar
            ;;
        *)
            echo "Invalid loader selected!"
            return
            ;;
    esac

    # ───── Write eula.txt ─────
    if [ "$EULA" = "yes" ]; then
        echo "eula=true" > eula.txt
    else
        echo "You must accept eula.txt manually before first run."
        echo "eula=false" > eula.txt
    fi

    # ───── Create run.sh ─────
    cat <<EOF > run.sh
#!/bin/bash
java -Xms${MC_XMS} -Xmx${MC_XMX} -jar server.jar nogui
EOF
    chmod +x run.sh

    echo "Server files created in $SERVER_DIR"

    # ───── Modrinth Downloader ─────
    if whiptail --title "Modrinth Downloader" --yesno "Do you want to run the Modrinth collection downloader?" 10 60; then
        modrinth_collection_downloader
    fi

    # ───── Autostart Cronjob ─────
    if whiptail --title "Autostart" --yesno "Setup server autostart with cron?" 10 60; then
        crontab_setup "mcserver" "$SERVER_NAME"
    fi

    echo "Setup finished!"
