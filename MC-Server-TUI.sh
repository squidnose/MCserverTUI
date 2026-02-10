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
echlog " Debug Output, please check for any errors:"
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
        mdr         "Simple Terminal Markdown Reader (q to quit)" \
        nano        "Simple terminal editor (CTR+X to quit)" \
        less        "Simple, read only (q to quit)" \
        vim         "Advanced terminal editor (No one knows how to quit)" \
        kate        "KDEs graphical notepad" \
        mousepad    "XFCEs graphical notepad" \
        3>&1 1>&2 2>&3
}

#============================ Main menu ============================
while true; do
    CHOICE=$(whiptail --title "$TITLE" --menu "Select an action:" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
        info            "ℹ️ Help - What to Do?" \
        new_server      "➕ Setup a New MC server" \
        manage_servers  "🛠 Manage existing MC servers" \
        backup_servers  "🌐 Manage MC server Backups" \
        settings        "⚙️ TUI Settings and Logs" \
        exit            "X  Exit" \
        3>&1 1>&2 2>&3) || CHOICE="exit" ##exit for cancel button
case "$CHOICE" in
    info)
        INFO_FILE=$(whiptail --title "ℹ️ - $TITLE" --menu "What are you curious about?" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
            "Plan-MCserver.md"  "What do you want to achive?" \
            "Main-Menu.md"      "Basic usage and terminology" \
            "New-Server.md"     "How to setup a New MCserver" \
            "Manage-Servers.md" "How to manage MCservers" \
            "Tunneling.md"      "Manage reverse proxy Tunnels" \
            "README.md"         "Front page - Git Readme file" \
        3>&1 1>&2 2>&3)
        EDITOR=$(choose_editor) || continue

        if [[ "$INFO_FILE" == "README.md" ]]; then
            echlog "ℹ️ Opening $INFO_FILE Documentation using $EDITOR"
            "$EDITOR" "$INFO_FILE"
        else
            echlog "ℹ️ Opening $INFO_FILE Documentation using $EDITOR"
            "$EDITOR" "$SCRIPT_DIR/Docs/$INFO_FILE"
        fi
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
    settings)
        echlog "⚙️ Opening Settings"
        "$SCRIPT_DIR/Settings.sh"
    ;;
    exit)
        echlog "=========================================="
        echlog " Thank you for using My MC-server-TUI! "
        echlog "=========================================="
        exit 0
    ;;
    *)
        echlog "=========================================="
        echlog " Error, unknown menu optoin"
        echlog "=========================================="
        echlog " Thank you for using My MC-server-TUI! "
        echlog "=========================================="
        exit 0
    ;;
    esac
done
