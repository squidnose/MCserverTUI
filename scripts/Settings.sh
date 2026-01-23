#!/usr/bin/env bash
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
echlog " Debug Output, please check for any errors:"
echlog "=========================================="

#============================ Script location ============================
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

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
TITLE="MC server TUI - Settings"

#============================ Helpers ============================
choose_editor()
{
    whiptail --title "Choose editor" --menu "Select editor:" $HEIGHT $WIDTH $MENU_HEIGHT \
        less        "Simple, read only (q to quit)" \
        nano        "Simple terminal editor (CTR+X to quit)" \
        vim         "Advanced terminal editor (No one knows how to quit)" \
        kate        "KDEs graphical notepad" \
        mousepad    "XFCEs graphical notepad" \
        3>&1 1>&2 2>&3
}

#============================ Helpers ============================
while true; do
    CHOICE=$(whiptail --title "$TITLE" --menu "Select an action:" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
        logs            "📜 View Logs for TUI's and Backups" \
        watch_java      "👁  Watch All java processes" \
        crontab         "⏱  View or Manually Edit ${USER:-$(id -un 2>/dev/null || echo User)}"s" crontab" \
        colors          "🎨 Change the Colors of the TUI" \
        go_back         "..  Go Back" \
        3>&1 1>&2 2>&3) || CHOICE="exit" ##exit for cancel button
    case "$CHOICE" in
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
        echlog "📜 Log File: $LOGFILE_CHOICE Not Found!"
    else

    ##Choose editor
    EDITOR=$(choose_editor) || continue
    echlog "📜 Opening $LOGFILE_CHOICE using $EDITOR"
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
    *) exit 0 ;;
    esac
done
