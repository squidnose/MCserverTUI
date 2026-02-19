#!/usr/bin/env bash
## Fixed menu system, i used to use LSR. This is more KISS:)

set -euo pipefail
#============================ Term Size ============================
TERM_HEIGHT=$(tput lines 2>/dev/null || echo 24)
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
HEIGHT="$TERM_HEIGHT"
WIDTH="$TERM_WIDTH"
MENU_HEIGHT=$((HEIGHT - 10))
### use $HEIGHT $WIDTH for --inputbox --msgbox --yesno
### or $HEIGHT $WIDTH $MENU_HEIGHT for --menu
TITLE="MC server TUI"

#============================ 1. Checking ============================
## whiptail
if ! command -v whiptail >/dev/null 2>&1; then
    echo "Please install the Newt package for whiptail menu support!!!"
    exit 1
fi

## Checking if $HOME parameter is set by OS
if [ -z "$HOME" ]; then
    echo "Your Operating system did not set the \$HOME parameter, please set it..."
    exit 1
fi

#============================ 1.1 Script location ============================
SCRIPT_DIR="$(dirname "$(realpath "$0")")/scripts"
if [ -z "$SCRIPT_DIR" ]; then
    echo "This script has no idea where it is.\n you will have to find a way to get dirname and realpath to work on your OS"
    exit 1
fi
#============================ 1.2 newt colors ============================
# Color of the TUI
NEWT_COLORS_FILE="$HOME/.local/state/MCserverTUI/colors.conf"
if [ -f "$NEWT_COLORS_FILE" ]; then
    export NEWT_COLORS_FILE
else
cat > "$NEWT_COLORS_FILE" <<EOF
# Matrix
root=,black
window=,black
title=brightgreen,black
border=green,black
textbox=brightgreen,black
button=black,green
compactbutton=green,black
listbox=green,black
actlistbox=black,brightgreen
helpline=green,black
roottext=brightgreen,black
EOF
export NEWT_COLORS_FILE
whiptail --msgbox "Colors set to Matrix Green, you can later change this in settings" "$HEIGHT" "$WIDTH"
fi

#============================ 1.3 Save/Change Config file ============================
change_conf_file()
{
if whiptail --title "$TITLE - Logging" --yesno "Do you wish to have loggs enabled?" $HEIGHT $WIDTH; then
    loggs="true"
else
    loggs="false"
fi

mcdir=$(whiptail --title "$TITLE - mcdir" --inputbox \
    "Input the directory for your MCservers:" "$HEIGHT" "$WIDTH" "$HOME/mcservers" \
    3>&1 1>&2 2>&3) || exit 0

backups=$(whiptail --title "$TITLE - backups" --inputbox \
    "Input the directory for backups:" "$HEIGHT" "$WIDTH" "$HOME/Backups/mcservers" \
    3>&1 1>&2 2>&3) || exit 0

cat > "$MCSERVERTUI_CONF" <<EOF
loggs="$loggs"
mcdir="$mcdir"
backups="$backups"
EOF
}

#============================ 1.4 Conf Files ============================
#Directory to store important config data
mkdir -p "$HOME/.local/state/MCserverTUI"

# Confing file to read:
## Logging
## mcservers Location
## Backups Location
#If not existing, make a new one
MCSERVERTUI_CONF="$HOME/.local/state/MCserverTUI/MCserverTUI.conf"
if [ -f "$MCSERVERTUI_CONF" ]; then
    source "$MCSERVERTUI_CONF"
else
    change_conf_file
fi

#============================ 1.5 Logging ============================
MC_TUI_LOGFILE="$HOME/.local/state/MCserverTUI/mcservertui.log"

# For rsync backups
mkdir -p "$HOME/.local/state/Backups-RSYNC-TUI"
LOGFILE_CRON="$HOME/.local/state/Backups-RSYNC-TUI/rsync-periodic-backups.log"
LOGFILE_MANUAL="$HOME/.local/state/Backups-RSYNC-TUI/rsync-manual-backups.log"

echlog()
{
    local msg="$*"
    echo "$msg"
    if [ $loggs == "true" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') $msg" >> "$MC_TUI_LOGFILE"
    fi
}

#============================ 1.6 Final Check ============================
[ -z "$mcdir" ] && exit 1
[ -z "$backups" ] && exit 1

#============================ 1.7 Debuging ============================
clear # Clear the screen before the first menu appears.
echlog "=========================================="
echlog " Debug Output, please check for any errors:"
echlog "=========================================="


#============================ 2 Helpers ============================
choose_editor()
{
    whiptail --title "Choose editor" --menu "Select editor:" $HEIGHT $WIDTH $MENU_HEIGHT \
        nano        "Simple terminal editor (CTR+X to quit)" \
        less        "Simple, read only (q to quit)" \
        mdr         "Simple Terminal Markdown Reader (q to quit)" \
        vim         "Advanced terminal editor (No one knows how to quit)" \
        kate        "KDEs graphical notepad" \
        mousepad    "XFCEs graphical notepad" \
        3>&1 1>&2 2>&3
}

#============================ 3. Main menu ============================
while true; do
    CHOICE=$(whiptail --title "$TITLE" --menu "Select an action:" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
        info            "ℹ️ Help - What to Do?" \
        new_server      "➕ Setup a New MC server" \
        manage_servers  "🛠 Manage existing MC servers" \
        backup_servers  "🌐 Manage MC server Backups" \
        tunneling       "🔃 Setup Tunneling services" \
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
    tunneling)
        TUNNELING=$(whiptail --title "🔃 Tunneling - $TITLE" --menu "Choose a Tunneling service:" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
            "Localtonet.sh" "Localtonet.com - Linux (Glibc and Musl) and Macos" \
            "Playit-gg.sh"  "playit.gg - Linux GlibC Only" \
            "Telebit.sh"    "Telebit.cloud - Linux and MacOS(Autostart not ready yet)" \
        3>&1 1>&2 2>&3) || continue
        echlog "🔃 Running $TUNNELING Tunneling manager"
        "$SCRIPT_DIR/Tunneling-Services/$TUNNELING"
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
