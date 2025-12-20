#!/usr/bin/env bash
set -euo pipefail

#============================ Term Size ============================
TERM_HEIGHT=$(tput lines 2>/dev/null || echo 24)
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
HEIGHT="$TERM_HEIGHT"
WIDTH="$TERM_WIDTH"
MENU_HEIGHT=$((HEIGHT - 10))
### use $HEIGHT $WIDTH for --inputbox --msgbox --yesno
### or $HEIGHT $WIDTH $MENU_HEIGHT for --menu

#============================ Locations ============================
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
MC_ROOT="$HOME/mcservers"

#============================ Helpers ============================
choose_editor()
{
    whiptail --title "Choose editor" --menu "Select editor:" $HEIGHT $WIDTH $MENU_HEIGHT \
        nano        "Simple terminal editor (Beginner-friendly)" \
        less        "Simple, read only, q to quit" \
        vim         "Advanced terminal editor (Standard terminal editor)" \
        kate        "KDEs graphical notepad" \
        mousepad    "XFCEs graphical notepad" \
        3>&1 1>&2 2>&3
}
#====================== Select a server to Backup =============================
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
BACKUP_DIR="$HOME/Backups/mcservers/$SERVER_NAME"

#============================ Main Menu ============================
while true; do
    CHOICE=$(whiptail --title "Choose Backup Options" --menu "Select an action:" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
        info        "Help - How does this work?" \
        new_backup  "Create a new Periodic Backup" \
        manual      "Run a manual backup" \
        exit        "Exit" \
        3>&1 1>&2 2>&3) || exit 0

case "$CHOICE" in
    info)
        EDITOR=$(choose_editor) || continue
        echo "=========================================="
        echo "Opening info.md Documentation using $EDITOR"
        "$EDITOR" "$SCRIPT_DIR/README.md"
    ;;
    new_backup)
        echo "=========================================="
        echo "Running New Rsync Backup Script"
        "$SCRIPT_DIR/Periodic-Rsync-Backup.sh" -i $SERVER_DIR -o $BACKUP_DIR
    ;;
    manual)
        echo "=========================================="
        echo "Running Manual Backup Script"
        "$SCRIPT_DIR/Manual-Rsync-Backup.sh" -i $SERVER_DIR -o $BACKUP_DIR
    ;;
    exit) exit 0 ;;
    *) exit 0 ;;
esac
done
