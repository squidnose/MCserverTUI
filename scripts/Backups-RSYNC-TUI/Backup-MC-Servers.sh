#!/usr/bin/env bash
set -euo pipefail
#================================
# 0 - Backup Minecraft Servers TUI
## Custom wrapper for Backups RsyncTUI
## https://codeberg.org/squidnose-code/Backups-RSYNC-TUI
## Set Periodic Backups of MCservers
## Run a Manual Backups
## Restore from Backup
## Manually manage Backup retention and compression

#================================
# 1 - Setup
#================================
## 1.1 Term Size
#================================
TERM_HEIGHT=$(tput lines 2>/dev/null || echo 24)
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
HEIGHT="$TERM_HEIGHT"
WIDTH="$TERM_WIDTH"
MENU_HEIGHT=$((HEIGHT - 10))
### use $HEIGHT $WIDTH for --inputbox --msgbox --yesno
### or $HEIGHT $WIDTH $MENU_HEIGHT for --menu

### Menu Titel
TITLE="MCserver Backup"

## 1.2 Script location
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
if [ -z "$SCRIPT_DIR" ]; then
    echo "This script has no idea where it is.\n you will have to find a way to get dirname and realpath to work on your OS"
    exit 1
fi

## 1.3 Config file
MCSERVERTUI_CONF="$HOME/.local/state/MCserverTUI/MCserverTUI.conf"
if [ -f "$MCSERVERTUI_CONF" ]; then
    source "$MCSERVERTUI_CONF"
else
    echo "No MCserverTUI config file, please run MC-server-TUI.sh first!"
    exit 1
fi
#New parameters:
MC_ROOT="$mcdir"
## loggs (true or false)
MC_BACKUPS="$backups"

#================================
# 2 - Helper Functions
#================================
## 2.1 Editor
choose_editor()
{
    whiptail --title "Choose editor" --menu "Select editor:" $HEIGHT $WIDTH $MENU_HEIGHT \
        mdr         "Simple Terminal Markdown Reader (q to quit)" \
        nano        "Simple terminal editor (CTR+X to quit)" \
        less        "Simple, read only (q to quit)" \
        vim         "Advanced terminal editor (No one knows how to quit)" \
        kate        "KDEs graphical notepad" \
        mousepad    "XFCEs graphical notepad" \
        3>&1 1>&2 2>&3
}

## 2.2 Choose a backup snapshot, used by Restore and Manage backups
choose_backup_snapshot()
{
    ### Build list of available backups
    BACKUP_ITEMS=()
    for d in "$BACKUP_DIR"/*; do
        [ -e "$d" ] || continue
        NAME=$(basename "$d")
        BACKUP_ITEMS+=("$NAME" "Backup snapshot")
    done

    ### Make sure that there are backups
    [ "${#BACKUP_ITEMS[@]}" -gt 0 ] || {
        whiptail --msgbox "No backup snapshots found in:\n\n$BACKUP_DIR" "$HEIGHT" "$WIDTH"
        continue
    }
    SNAPSHOT=$(whiptail --title "Select Backup Snapshot" \
    --menu "Choose a backup snapshot to restore from:" \
    "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" "${BACKUP_ITEMS[@]}" \
    3>&1 1>&2 2>&3) || return 0
    echo "$BACKUP_DIR/$SNAPSHOT"
}
#================================
## 3 -  Select a server to Backup
#================================
# Build menu items from directories
MENU_ITEMS=()
for d in "$MC_ROOT"/*; do
    [ -d "$d" ] || continue
    NAME=$(basename "$d")
    MENU_ITEMS+=("$NAME" "Minecraft server")
done

SERVER_NAME=$(whiptail --title "Choose Server" --menu "Select a server to Configure backups of" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
    "${MENU_ITEMS[@]}" 3>&1 1>&2 2>&3) || exit 0

SERVER_DIR="$MC_ROOT/$SERVER_NAME"
BACKUP_DIR="$MC_BACKUPS/$SERVER_NAME"

#================================
## 4 - Main Menu
#================================
while true; do
    CHOICE=$(whiptail --title "Choose Backup Options" --menu "Select an action:" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
        info        "ℹ️ Help - How does this work?" \
        new_backup  "➕ Create a new Periodic Backup" \
        manual      "🛠️ Run a manual backup" \
        restore     "🔄 Restore from backup" \
        manage      "⚙️ Backup rentension and compression" \
        go_back     "X Go back .." \
        3>&1 1>&2 2>&3) || exit 0

case "$CHOICE" in
    info)
        EDITOR=$(choose_editor) || continue
        echo "=========================================="
        echo "ℹ️ Opening How-To-Backup.md Documentation using $EDITOR"
        "$EDITOR" "$SCRIPT_DIR/How-To-Backup.md"
    ;;
    new_backup)
        echo "=========================================="
        echo "➕ Running New Rsync Backup Script"
        "$SCRIPT_DIR/Periodic-Rsync-Backup.sh" -i "$SERVER_DIR" -o "$BACKUP_DIR"
    ;;
    manual)
        echo "=========================================="
        echo "🛠️ Running Manual Backup Script"
        "$SCRIPT_DIR/Manual-Rsync-Backup.sh" -i "$SERVER_DIR" -o "$BACKUP_DIR"
    ;;
    restore)
        #Ask to do a manual bacup before restoration
        if whiptail --title "Manual Backup before restoration" --yesno \
        "Restoring from backup will delete the exiting contens of $SERVER_DIR

        Do you wish to run a manual backup before you restore from backup?" \
        "$HEIGHT" "$WIDTH"; then
            echo "=========================================="
            echo "Running Manual Backup Script"
            "$SCRIPT_DIR/Manual-Rsync-Backup.sh" -i "$SERVER_DIR" -o "$BACKUP_DIR"
        whiptail --msgbox \
        "You have now made a Manual backup of the existing contents of $SERVER_DIR
        You will now setup a Restoration from a backup snapshot" $HEIGHT $WIDTH
        fi
        SRC=$(choose_backup_snapshot)
        echo "=========================================="
        echo "🔄 Running Restore Backup Script using $SRC backup"
        "$SCRIPT_DIR/Restore-Rsync-Backup.sh" -i "$SRC" -o "$SERVER_DIR"
    ;;
    manage)
        echo "=========================================="
        echo "⚙️ Running Manage Backup Script"
        SRC=$(choose_backup_snapshot)
        "$SCRIPT_DIR/Backup-Manager.sh" -i "$SRC"
    ;;
    *) exit 0 ;;
esac
done
