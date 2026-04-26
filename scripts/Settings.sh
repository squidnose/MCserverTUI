#!/usr/bin/env bash
set -euo pipefail

#============================ Settings.sh ============================
# Settings for MCserverTUI.sh

#============================ 1 - MCserverTUI Config File ============================
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
## backups

#============================ 2 - Logging ============================
# For rsync backups
mkdir -p "$HOME/.local/state/Backups-RSYNC-TUI"
LOGFILE_CRON="$HOME/.local/state/Backups-RSYNC-TUI/rsync-periodic-backups.log"
LOGFILE_MANUAL="$HOME/.local/state/Backups-RSYNC-TUI/rsync-manual-backups.log"

#Logging what is run
MC_TUI_LOGFILE="$HOME/.local/state/MCserverTUI/mcservertui.log"
echlog()
{
    local msg="$*"
    echo "$msg"
    if [ "$loggs" == "true" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') $msg" >> "$MC_TUI_LOGFILE"
    fi
}

#============================ 3 - Script location ============================
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

#============================ 4 - Term Size & Title ============================
TERM_HEIGHT=$(tput lines 2>/dev/null || echo 24)
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
HEIGHT="$TERM_HEIGHT"
WIDTH="$TERM_WIDTH"
MENU_HEIGHT=$((HEIGHT - 10))
### use $HEIGHT $WIDTH for --inputbox --msgbox --yesno
### or $HEIGHT $WIDTH $MENU_HEIGHT for --menu
TITLE="MC server TUI - Settings"

#============================  5 - Text Editors/Readers ============================
choose_editor()
{
    whiptail --title "$TITLE - ✏️ Choose editor" --menu "Select editor:" $HEIGHT $WIDTH $MENU_HEIGHT \
        less        "Simple, read only (q to quit) (CLI)" \
        nano        "Simple terminal editor (CTR+X to quit) (CLI)" \
        vim         "Advanced terminal editor (No one knows how to quit) (CLI)" \
        kate        "KDEs graphical notepad (GUI)" \
        mousepad    "XFCEs graphical notepad (GUI)" \
        3>&1 1>&2 2>&3
}

#============================ 6 - Main Menu ============================
while true; do
    CHOICE=$(whiptail --title "$TITLE" --menu "Select an action:" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
        logs            "📜 View Logs from TUI's and Backups" \
        watch_java      "👁️ Watch All java processes" \
        crontab         "⏱️ Edit or View ${USER:-$(id -un 2>/dev/null || echo User)}"s" crontab line by line" \
        term_util       "📟 Open $MC_ROOT with Terminal Tools(Eg: Disk Usage)" \
        config          "📂 Set: Logging, MCserver Directory, Backups Directory" \
        colors          "🎨 Change the Colors of the TUI" \
        go_back         ".. Go Back" \
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
        echlog "👁️ wathing java processes "
        watch -n 1 "ps -ef | grep java"
    ;;
    crontab)
        echlog "⏱️ Opening Crontab using Line By Line Editor"
        "$SCRIPT_DIR/more-scripts/crontab-line-by-line-editor.sh"
    ;;
    term_util)
        TERMINAL_UTIL=$(whiptail --title "$TITLE" --menu \
        "What terminal util for All MCservers woudld you like to run?\nQ to Quit" \
        "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
        "ncdu"  "Disk Space Usage Analyzer" \
        "nnn"   "File Explorer" \
        "crontab -e" "Manually edit crontab with systems default editor" \
        3>&1 1>&2 2>&3)
        echlog "📟 using $TERMINAL_UTIL"
        cd $MC_ROOT
        $TERMINAL_UTIL
    ;;
    config)
        if whiptail --title "$TITLE - Logging📂" --yesno "Do you wish to have loggs enabled?" $HEIGHT $WIDTH; then
            loggs="true"
        else
            loggs="false"
        fi

        mcdir=$(whiptail --title "$TITLE - mcdir📂" --inputbox \
            "Input the directory for your MCservers:" "$HEIGHT" "$WIDTH" "$mcdir" \
            3>&1 1>&2 2>&3) || exit 0

        backups=$(whiptail --title "$TITLE - backups📂" --inputbox \
            "Input the directory for backups:" "$HEIGHT" "$WIDTH" "$backups" \
            3>&1 1>&2 2>&3) || exit 0

cat > "$MCSERVERTUI_CONF" <<EOF
loggs="$loggs"
mcdir="$mcdir"
backups="$backups"
EOF
    ;;
    colors)
        echlog "🎨 Running Color Changing Script"
        "$SCRIPT_DIR/Colors/set-colors.sh"
    ;;
    *) exit 0 ;;
    esac
done
