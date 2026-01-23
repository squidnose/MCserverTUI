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
        mdr         "Simple Terminal Markdown Reader (q to quit)" \
        nano        "Simple terminal editor (CTR+X to quit)" \
        less        "Simple, read only (q to quit)" \
        vim         "Advanced terminal editor (No one knows how to quit)" \
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
        info        "ℹ️ Help - How does this work?" \
        new_backup  "➕ Create a new Periodic Backup" \
        manual      "🛠 Run a manual backup" \
        restore     "🔄 Restore from backup" \
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
        echo "🛠 Running Manual Backup Script"
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

        # Build list of available backups
        BACKUP_ITEMS=()
        for d in "$BACKUP_DIR"/*; do
            [ -d "$d" ] || continue
            NAME=$(basename "$d")
            BACKUP_ITEMS+=("$NAME" "Backup snapshot")
        done

        # Make sure that there are backups
        [ "${#BACKUP_ITEMS[@]}" -gt 0 ] || {
            whiptail --msgbox "No backup snapshots found in:\n\n$BACKUP_DIR" "$HEIGHT" "$WIDTH"
            continue
        }

        SNAPSHOT=$(whiptail --title "Select Backup Snapshot" --menu "Choose a backup snapshot to restore from:" \
            "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
            "${BACKUP_ITEMS[@]}" \
            3>&1 1>&2 2>&3) || continue
            SRC="$BACKUP_DIR/$SNAPSHOT/"
            DST="$SERVER_DIR/"
        echo "=========================================="
        echo "🔄 Running Restore Backup Script using $SNAPSHOT backup"
        "$SCRIPT_DIR/Restore-Rsync-Backup.sh" -i "$SRC" -o "$DST"
    ;;

    go_back) exit 0 ;;
    *) exit 0 ;;
esac
done
