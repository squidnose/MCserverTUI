#!/bin/bash
# Variables
TITLE="MC-SERVER-TUI"
MENU_TITLE="Choose a Menu Option"
MENU_HEIGHT=30
MENU_WIDTH=70
MENU_ITEM_HEIGHT=6

manage_existing_servers() {
    ls ~/mcservers
    # TODO: Add menu to select and attach to tmux server console
}

server_setup_wizard() {
    read -p "Server Name: " SERVER_NAME
    read -p "Minecraft Version (enter manually): " MC_VERSION
    read -p "Minecraft Loader (vanilla/forge/paper): " MC_LOADER
    read -p "Min RAM (Xms): " MC_XMS
    read -p "Max RAM (Xmx): " MC_XMX
    read -p "Agree to EULA? (yes/no): " EULA

    if whiptail --title "Modrinth Downloader" --yesno "Do you want to run the Modrinth collection downloader?" 10 60; then
        modrinth_collection_downloader
    fi

    if whiptail --title "Autostart" --yesno "Setup server autostart with cron?" 10 60; then
        crontab_setup "mcserver" "$SERVER_NAME"
    fi
}

modrinth_collection_downloader() {
    MODRINTH_MENU_CHOICE=$(whiptail --title "$TITLE" --menu "$MENU_TITLE" $MENU_HEIGHT $MENU_WIDTH $MENU_ITEM_HEIGHT \
        "1" "Install a custom Modrinth collection" \
        "2" "Install my default collection" \
        "3" "Install Geyser-Floodgate" \
        "4" "Cancel" \
        3>&1 1>&2 2>&3)

    case $MODRINTH_MENU_CHOICE in
        1) python3 modrinth-autodownloader.py -v 1.21.5 -l fabric -c custom ;;
        2) python3 modrinth-autodownloader.py -v 1.21.5 -l fabric -c ziTsdV9j ;;
        3) python3 modrinth-autodownloader.py -v 1.21.5 -l paper -c geyser ;;
        *) ;;
    esac
}

crontab_setup() {
    TYPE="$1"
    SERVER_NAME="$2"

    if [ "$TYPE" = "mcserver" ]; then
        echo "@reboot ~/MCserverTUI/Autostart-files/${SERVER_NAME}_autostart.sh" | crontab -
        echo "Autostart configured for $SERVER_NAME"
    elif [ "$TYPE" = "console" ]; then
        # TODO
        :
    elif [ "$TYPE" = "backup" ]; then
        # TODO
        :
    fi
}

# Main Menu
MENU_CHOICE=$(whiptail --title "$TITLE" --menu "$MENU_TITLE" $MENU_HEIGHT $MENU_WIDTH $MENU_ITEM_HEIGHT \
    "1" "Existing Servers" \
    "2" "New Server" \
    "3" "Manage Backups" \
    "4" "Manage Reverse Proxies" \
    "5" "Update-System" \
    "6" "Exit" \
    3>&1 1>&2 2>&3)

case $MENU_CHOICE in
    1) manage_existing_servers ;;
    2) server_setup_wizard ;;
    3) echo "TODO: backup management" ;;
    4) echo "TODO: reverse proxy management" ;;
    5) echo "TODO: system updater" ;;
    6) exit 0 ;;
esac
