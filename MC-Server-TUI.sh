#!/usr/bin/env bash
## Fixed menu system, i used to use LSR. This is more KISS:)

set -euo pipefail
#============================ Script location ============================
clear # Clear the screen before the first menu appears.
echo "=========================================="
echo " Debug Output, please chek for any errors:"
echo "=========================================="

#============================ Script location ============================
SCRIPT_DIR="$(dirname "$(realpath "$0")")/scripts"

#============================ newt colors ============================
export NEWT_COLORS_FILE="$SCRIPT_DIR/Colors/colors.conf"

#============================ Term Size ============================
TERM_HEIGHT=$(tput lines 2>/dev/null || echo 24)
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
HEIGHT="$TERM_HEIGHT"
WIDTH="$TERM_WIDTH"
MENU_HEIGHT=$((HEIGHT - 10))
### use $HEIGHT $WIDTH for --inputbox --msgbox --yesno
### or $HEIGHT $WIDTH $MENU_HEIGHT for --menu
LOGFILE="$HOME/rsync-backups.log"
TITLE="MC server TUI"

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

#============================ Main menu ============================
while true; do
    CHOICE=$(whiptail --title "$TITLE" --menu "Select an action:" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
        info            "ℹ  Help - What to Do?" \
        new_server      "➕ Setup a New MC server" \
        manage_servers  "🛠  Manage existing MC servers" \
        backup_servers  "🌐 Manage MC server Backups" \
        backup_logs     "📜 View Backup Logs" \
        watch_java      "👁  Watch All java processes" \
        crontab         "⏱  View or Manually Edit $USER"s" crontab" \
        colors          "🎨 Change the Colors of the TUI" \
        exit            "X  Exit" \
        3>&1 1>&2 2>&3) || CHOICE="exit" ##exit for cancel button
case "$CHOICE" in
    info)
        EDITOR=$(choose_editor) || continue
        echo "=========================================="
        echo "ℹ Opening info.md Documentation using $EDITOR"
        "$EDITOR" "$SCRIPT_DIR/0.info.md"
    ;;
    new_server)
        echo "=========================================="
        echo "➕ Running New Server Script"
        "$SCRIPT_DIR/New-Server.sh"
    ;;
    manage_servers)
        echo "=========================================="
        echo "🛠  Running Manage Servers Script"
        "$SCRIPT_DIR/Manage-Servers.sh"
    ;;
    backup_servers)
        echo "=========================================="
        echo "🌐 Running Manage MC server Backup Script"
        "$SCRIPT_DIR/Backup-MC-Servers.sh"
    ;;
    backup_logs)
    ##See if the log file exists
        if [ ! -f "$LOGFILE" ]; then
            whiptail --title "Logfile not found" --msgbox "No logfile found at:$LOGFILE" $HEIGHT $WIDTH
            echo "Log File Not Found! A logged backup has probably not been run yet."
        else

    ##Choose editor
        EDITOR=$(choose_editor) || continue
        echo "=========================================="
        echo "📜 Opening $LOGFILE using $EDITOR"
        "$EDITOR" "$LOGFILE"
        fi
    ;;
    watch_java)
        echo "👁 wathing java processes "
        watch -n 1 "ps -ef | grep java"
    ;;
    crontab)
        ##Choose editor
        EDITOR=$(choose_editor) || continue
        echo "=========================================="
        echo "⏱ Opening Crontab using $EDITOR"
        ##Open Crontab
        export EDITOR
        crontab -e
    ;;
    colors)
        echo "🎨 Running Color Changing Script"
        "$SCRIPT_DIR/Colors/set-colors.sh"
    ;;
    exit)
        echo "=========================================="
        echo "=========================================="
        echo " Thank you for using My MC-server-TUI! "
        echo "=========================================="
        exit 0
    ;;
    *)
        echo "Error, unknown menu optoin"
        echo "=========================================="
        echo "=========================================="
        echo " Thank you for using My MC-server-TUI! "
        echo "=========================================="
        exit 0
    ;;
    esac
done
