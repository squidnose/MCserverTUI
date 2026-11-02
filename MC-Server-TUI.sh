#!/usr/bin/env bash
# MCserverTUI
# https://github.com/squidnose/MCserverTUI
## MC-server-TUI.sh
set -euo pipefail
# Main Menu

#============================ Info ============================
# Features
## Setup, Configure and Manage Minecraft server with mods/plugins support
## Backup MCservers using: https://codeberg.org/squidnose-code/Backups-RSYNC-TUI
## Setup reverse proxy services

#============================ Initialization ============================
SCRIPT_DIR="$(dirname "$(realpath "$0")")/scripts" # Find script location
source "$SCRIPT_DIR/Backups-RSYNC-TUI/lib-rsync-tui.sh" # Load Library of functions from rsyncTUI
source "$SCRIPT_DIR/lib-MCserverTUI.sh" # Load Library of aditional/modified functions from MCserverTUI
load_vars # Load variables: Title, Config files and Log files
term_size # set TUI size to console size
color_tui # Set color schemes for newt/whiptail
conf_file # Load config file or make new one. For enableing/diableing logs.
checks_deps # Check for dependencies: whiptail, rsync and crontab
checks_dirs # Check if the OS has folder parameters set
TITLE="Main Menu - $SCRIPT_TITLE"

#============================ Debug============================
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
