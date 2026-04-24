#!/usr/bin/env bash
# Fixed menu system, i used to use my general purpouse Linux Script Runner.
# This is more KISS:)

set -euo pipefail
#============================ MCserverTUI ============================
# Setup, Configure and Manage Minecraft server with mods/plugins support
# Backup MCservers
# Setup reverse proxy services
# https://github.com/squidnose/MCserverTUI
# This script is under the MIT license
# Commet separation uses 28x "="

#============================ 1 - Setup ============================
#============================ 1.1 - Initial Parameters  ============================
# Term Size
## Set TUI size based on terminal size
## If tput is not found, use default values of 24 and 80 for TUI size
HEIGHT=$(tput lines 2>/dev/null || echo 24)
WIDTH=$(tput cols 2>/dev/null || echo 80)
MENU_HEIGHT=$((HEIGHT - 10))
### use $HEIGHT $WIDTH for --inputbox --msgbox --yesno --infobox --passwordbox
### or $HEIGHT $WIDTH $MENU_HEIGHT for --menu --checklist --radiolist --gauge

# Title
TITLE="MC server TUI"

# Directory to store important config files and logs
HOME_LOCAL_STATE_MCSERVERTUI="$HOME/.local/state/MCserverTUI"
mkdir -p "$HOME_LOCAL_STATE_MCSERVERTUI"

#============================ 1.2 - newt colors ============================
### Color of the TUI
NEWT_COLORS_FILE="$HOME_LOCAL_STATE_MCSERVERTUI/colors.conf"
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

#============================ 1.3 - Checking ============================
# $HOME_LOCAL_STATE_MCSERVERTUI folder
if ! [ -d "$HOME_LOCAL_STATE_MCSERVERTUI" ]; then
    echo "ERROR: Could not find MCserverTUI config folder!"
    echo "This could be a permissions or OS issue!"
    exit 1
fi

## whiptail
if ! command -v whiptail >/dev/null 2>&1; then
    echo "ERROR: Please install the Newt package for whiptail menu support!!!"
    exit 1
fi

## Checking if $HOME parameter is set by OS
if [ -z "$HOME" ]; then
    echo "ERROR: Your Operating system did not set the \$HOME parameter, please set it..."
    exit 1
fi

#============================ 1.4 - Script location ============================
SCRIPT_DIR="$(dirname "$(realpath "$0")")/scripts"
if [ -z "$SCRIPT_DIR" ]; then
    echo "This script has no idea where it is.\n you will have to find a way to get dirname and realpath to work on your OS"
    exit 1
fi

#============================ 1.5 - Save/Change Config file ============================
change_conf_file()
{
if whiptail --title "$TITLE - loggs" --yesno "Do you wish to have loggs enabled?" $HEIGHT $WIDTH; then
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

### Make the direcotries
mkdir -p "$mcdir"
mkdir -p "$backups"
}

#============================ 1.6 - Conf Files ============================
# Config file to read:
## Logging
## mcservers Location
## Backups Location
## If not existing, make a new one
MCSERVERTUI_CONF="$HOME/.local/state/MCserverTUI/MCserverTUI.conf"
if [ -f "$MCSERVERTUI_CONF" ]; then
    source "$MCSERVERTUI_CONF"
else
    change_conf_file
fi

### Check if MCservers directory  exists
if ! [ -d "$mcdir" ]; then
    whiptail --msgbox "$mcdir not found!\nWill re-run directory selection.\nThis could be a sign of coruption or Malice!!!" "$HEIGHT" "$WIDTH"
    change_conf_file
fi
### Check if Backups directory exists
if ! [ -d "$backups" ]; then
    whiptail --msgbox "$backups not found!\nWill re-run directory selection.\nThis could be a sign of coruption or Malice!!!" "$HEIGHT" "$WIDTH"
    change_conf_file
fi

#============================ 1.7 - Logging ============================
# TUI log
MC_TUI_LOGFILE="$HOME/.local/state/MCserverTUI/mcservertui.log"

# For rsync backups
mkdir -p "$HOME/.local/state/Backups-RSYNC-TUI"
LOGFILE_CRON="$HOME/.local/state/Backups-RSYNC-TUI/rsync-periodic-backups.log"
LOGFILE_MANUAL="$HOME/.local/state/Backups-RSYNC-TUI/rsync-manual-backups.log"

# Log into terminal, log into file if the user so wants
echlog()
{
    local msg="$*"
    echo "$msg"
    if [ "$loggs" == "true" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') $msg" >> "$MC_TUI_LOGFILE"
    fi
}

#============================ 1.8 - Debuging ============================
clear # Clear the screen before the first menu appears.
echlog "=========================================="
echlog " Debug Output, please check for any errors:"
echlog "=========================================="


#============================ 2 - Text Editors/Readers ============================
choose_editor()
{
    whiptail --title "$TITLE - ✏️ Choose editor" --menu "Select editor:" $HEIGHT $WIDTH $MENU_HEIGHT \
        fold_tui    "Simple reader (Whiptail)" \
        pandoc_tui  "Simple MD renderer (Whiptail)" \
        less        "Simple, read only (q to quit) (CLI)" \
        nano        "Simple terminal editor (CTR+X to quit) (CLI)" \
        mdr         "Simple Terminal Markdown Reader (q to quit) (CLI)" \
        vim         "Advanced terminal editor (No one knows how to quit) (CLI)" \
        kate        "KDEs graphical notepad (GUI)" \
        mousepad    "XFCEs graphical notepad (GUI)" \
        3>&1 1>&2 2>&3
}

fold_tui()
{
    local file="$1"
    local tmpfile
    tmpfile=$(mktemp)
    fold -s -w $((WIDTH-4)) "$file" > "$tmpfile"
    whiptail --title "$(basename "$file")" --textbox \
    "$tmpfile" "$HEIGHT" "$WIDTH" --scrolltext
    rm -f "$tmpfile"
}

pandoc_tui()
{
    local file="$1"
    local tmpfile
    tmpfile=$(mktemp)
    pandoc -t plain "$file" | fold -s -w $((WIDTH-4)) > "$tmpfile"
    whiptail --title "$(basename "$file")" --textbox \
    "$tmpfile" "$HEIGHT" "$WIDTH" --scrolltext
    rm -f "$tmpfile"
}

#============================ 3 - Main menu ============================
while true; do
    # 3.1 Check if the user had not removed mcdir or backups
    [ -z "$mcdir" ] && change_conf_file
    [ -z "$backups" ] && change_conf_file

    CHOICE=$(whiptail --title "$TITLE - 🏠 Main Menu" --menu "Select an action:" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
        info            "ℹ️ Help - What to Do?" \
        new_server      "➕ Setup a New MC server" \
        manage_servers  "🛠️ Manage existing MC servers" \
        backup_servers  "🌐 Manage MC server Backups" \
        tunneling       "🔃 Setup Tunneling services" \
        settings        "⚙️ TUI Settings and Logs" \
        exit            "X  Exit" \
        3>&1 1>&2 2>&3) || CHOICE="exit" ##exit for cancel button
case "$CHOICE" in
    info)
        INFO_FILE=$(whiptail --title "$TITLE - ℹ️ Info" --menu "What are you curious about?" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
            "Dependencies.md"   "List of Dependencies for the TUI and MC" \
            "Plan-MC-server.md" "What do you want to achive?" \
            "General.md"        "Basic usage of MCserverTUI" \
            "New-Server.md"     "Explanations for Setting up a New server" \
            "Downloads-Mods.md" "How Downloading Content Works(.jar files)" \
            "Tunneling.md"      "How to reverse proxy using Tunnels?" \
            "TUI-Settings.md"   "Explanations For Settings" \
            "README.md"         "Front page - Git Readme file" \
        3>&1 1>&2 2>&3) || continue
        EDITOR=$(choose_editor)

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
        echlog "🛠️  Running Manage Servers Script"
        "$SCRIPT_DIR/Manage-Servers.sh"
    ;;
    backup_servers)
        echlog "🌐 Running Manage MC server Backup Script"
        "$SCRIPT_DIR/Backups-RSYNC-TUI/Backup-MC-Servers.sh"
    ;;
    tunneling)
        TUNNELING=$(whiptail --title "$TITLE - 🔃 Tunneling" --menu "Choose a Tunneling service:" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
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
