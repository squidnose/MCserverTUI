#!/usr/bin/env bash
# Backups-Rsync-TUI
# https://codeberg.org/squidnose-code/Backups-RSYNC-TUI
## Settings.sh
set -euo pipefail
#============================ Info ============================
# Features
## View Logs
## watch rsync jobs
## edit crontab
## set whether to log or not
## change TUI color themes

#============================ Initialization ============================
SCRIPT_DIR="$(dirname "$(realpath "$0")")" # Find script location
source "$SCRIPT_DIR"/lib-rsync-tui.sh # Load Library of functions
load_vars # Load variables: Title, Config files and Log files
term_size # set TUI size to console size
color_tui # Set color schemes for newt/whiptail
conf_file # Load config file or make new one. For enableing/diableing logs.
checks_deps # Check for dependencies: whiptail, rsync and crontab
checks_dirs # Check if the OS has folder parameters set
TITLE="Main Menu - $SCRIPT_TITLE"

#============================ Main Menu ================================
while true; do
    CHOICE=$(whiptail --title "$TITLE" --menu "Select an action:" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
        logs            "📜 View Logs for TUI's and Backups" \
        watch_rsync     "👁️ Watch All rsync processes" \
        crontab_line    "⏱️ Choose what lines to remove from Crontab" \
        crontab         "⏱️ View or Manually Edit ${USER:-$(id -un 2>/dev/null || echo User)}"s" crontab" \
        logging         "📜 Set: Logging, MCserver Directory, Backups Directory" \
        colors          "🎨 Change the Colors of the TUI" \
        back            "↩️ .. go back" \
        3>&1 1>&2 2>&3) || CHOICE="exit" # exit for cancel button
    case "$CHOICE" in
    logs)
    # Choose a log file
    LOGFILE_CHOICE=$(whiptail --title "Log File Choice - $TITLE" --menu "Choose what log file to load?" $HEIGHT $WIDTH $MENU_HEIGHT \
    "$LOGFILE_CRON"     "Automated Backups with Cron" \
    "$LOGFILE_MANUAL"   "Manual backups and backup Restore operations" \
    "$LOGFILE_CRON_TMP" "Temporary Log files from dry-runs" \
    "$LOGFILE_TUI"      "Output logs from RsyncTUI" \
    3>&1 1>&2 2>&3) || continue

    # See if the log file exists
    if [ ! -f "$LOGFILE_CHOICE" ]; then
        whiptail --title "Logfile not found - $TITLE" --msgbox "No logfile found at:$LOGFILE_CHOICE" $HEIGHT $WIDTH
        echlog "📜 Log File: $LOGFILE_CHOICE Not Found!"
    else

    # Choose editor
    EDITOR=$(choose_editor) || continue
    echlog "📜 Opening $LOGFILE_CHOICE using $EDITOR"
    "$EDITOR" "$LOGFILE_CHOICE"
    fi
    ;;
    watch_rsync)
        echlog "👁️ wathing java processes "
        watch -n 1 "ps -ef | grep rsync"
    ;;
    crontab_line)
        echlog "⏱️ Opening Crontab Line By Line editor"
        "$SCRIPT_DIR/crontab-line-by-line-editor.sh"
    ;;
    crontab)
        # Choose editor
        EDITOR=$(choose_editor) || continue
        echlog "⏱️ Opening Crontab using $EDITOR"
        # Open Crontab
        export EDITOR
        crontab -e
    ;;
    logging)
        if whiptail --title "Logging - $TITLE" --yesno "Do you wish to have loggs enabled?" $HEIGHT $WIDTH; then
            loggs="true"
        else
            loggs="false"
        fi
cat > "$RSYNC_TUI_CONF" <<EOF
loggs="$loggs"
EOF
    ;;
    colors)
        echlog "🎨 Running Color Changing Script"
        "$SCRIPT_DIR/set-colors.sh"
    ;;
    *) break ;;
    esac
done

exit 0
