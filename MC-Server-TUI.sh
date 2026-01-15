#!/usr/bin/env bash
## Fixed menu system, i used to use LSR. This is more KISS:)

set -euo pipefail
#============================ Logging ============================
mkdir -p "$HOME/.local/state/MCserverTUI"
MC_TUI_LOGFILE="$HOME/.local/state/MCserverTUI/mcservertui.log"

# For rsync backups
mkdir -p "$HOME/.local/state/Backups-RSYNC-TUI"
LOGFILE_CRON="$HOME/.local/state/Backups-RSYNC-TUI/rsync-periodic-backups.log"
LOGFILE_MANUAL="$HOME/.local/state/Backups-RSYNC-TUI/rsync-manual-backups.log"

echlog() {
    local msg="$*"
    echo "$msg"
    echo "$(date '+%Y-%m-%d %H:%M:%S') $msg" >> "$MC_TUI_LOGFILE"
}
#============================ Debuging ============================
clear # Clear the screen before the first menu appears.
echlog "=========================================="
echlog " Debug Output, please chek for any errors:"
echlog "=========================================="

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
        logs            "📜 View Logs" \
        watch_java      "👁  Watch All java processes" \
        crontab         "⏱  View or Manually Edit $USER"s" crontab" \
        colors          "🎨 Change the Colors of the TUI" \
        exit            "X  Exit" \
        3>&1 1>&2 2>&3) || CHOICE="exit" ##exit for cancel button
case "$CHOICE" in
    info)
        EDITOR=$(choose_editor) || continue
        echlog "ℹ Opening info.md Documentation using $EDITOR"
        "$EDITOR" "$SCRIPT_DIR/0.info.md"
    ;;
    new_server)
        echlog "➕ Running New Server Script"
        "$SCRIPT_DIR/New-Server.sh"
    ;;
    manage_servers)
        echlog "🛠  Running Manage Servers Script"
        "$SCRIPT_DIR/Manage-Servers.sh"
    ;;
    backup_servers)
        echlog "🌐 Running Manage MC server Backup Script"
        "$SCRIPT_DIR/Backups-RSYNC-TUI/Backup-MC-Servers.sh"
    ;;
    logs)
        # Choose a log file
        LOGFILE_CHOICE=$(whiptail --title "Log File Choice" --menu "Choose what log file to load?" $HEIGHT $WIDTH $MENU_HEIGHT \
        "$LOGFILE_CRON"    "Automated Backups with Cron" \
        "$LOGFILE_MANUAL"  "Manual backups and backup Restore operations" \
        "$MC_TUI_LOGFILE"  "MCserverTUI output logs" \
        3>&1 1>&2 2>&3) || continue

        # See if the log file exists
        if [ ! -f "$LOGFILE_CHOICE" ]; then
            whiptail --title "Logfile not found" --msgbox "No logfile found at:$LOGFILE_CHOICE" $HEIGHT $WIDTH
            echlog "Log File: $LOGFILE_CHOICE Not Found!"
        else

        ##Choose editor
        EDITOR=$(choose_editor) || continue
        echo "=========================================="
        echlog "Opening $LOGFILE_CHOICE using $EDITOR"
        "$EDITOR" "$LOGFILE_CHOICE"
        fi
    ;;
    watch_java)
        echlog "👁 wathing java processes "
        watch -n 1 "ps -ef | grep java"
    ;;
    crontab)
        ##Choose editor
        EDITOR=$(choose_editor) || continue
        echlog "⏱ Opening Crontab using $EDITOR"
        ##Open Crontab
        export EDITOR
        crontab -e
    ;;
    colors)
        echlog "🎨 Running Color Changing Script"
        "$SCRIPT_DIR/Colors/set-colors.sh"
    ;;
    exit)
        echlog "=========================================="
        echlog " Thank you for using My MC-server-TUI! "
        echlog "=========================================="
        exit 0
    ;;
    *)
        echlog "=========================================="
        echlog "Error, unknown menu optoin"
        echlog "=========================================="
        echlog " Thank you for using My MC-server-TUI! "
        echlog "=========================================="
        exit 0
    ;;
    esac
done
