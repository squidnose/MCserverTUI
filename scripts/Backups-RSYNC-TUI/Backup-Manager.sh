#!/usr/bin/env bash
set -euo pipefail

## The new comment implementaion, use 32x = fron and bottom

#================================
# 0 - Backup Manager
#================================
## Size usage analysis (folder only)
## Rename backup
## Move backup
## Copy backup
## Remove backup
## Compress Backup
## De-compress backup (Archives only: .zip, .tar.xz, 7z)
## TBD Periodic Compression
## TBD Periodic Backup pruning

#================================
# 1 - Config and Logs
#================================
## 1.1 - Size of terminal
### Automaticly detects terminal size
### incase tput is not found, sets to fixed value
TERM_HEIGHT=$(tput lines 2>/dev/null || echo 24)
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
HEIGHT="$TERM_HEIGHT"
WIDTH="$TERM_WIDTH"
MENU_HEIGHT=$((HEIGHT - 10))
### use $HEIGHT $WIDTH for --inputbox --msgbox --yesno
### or $HEIGHT $WIDTH $MENU_HEIGHT for --menu
### call term_resize to resize terminal

## 1.2 Back Title
TITLE="Backup Manager"

## 1.3 - Script location
### Finds out where the script is located
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
if [ -z "$SCRIPT_DIR" ]; then
    echo "This script has no idea where it is.\n you will have to find a way to get dirname and realpath to work on your OS"
    exit 1
fi

## 1.4 Config file
### Confing file of the TUI
### For Checking if user want logs from the TUI

### Directory for Logs and Config files:
LOGDIR="$HOME/.local/state/Backups-RSYNC-TUI" #
mkdir -p "$LOGDIR"
### Log File for the TUI:
RSYNC_TUI_CONF="$LOGDIR/rsync-tui.conf"
### Load config file
### If none found, exit 1 (no config generation logic here)
if [ -f "$RSYNC_TUI_CONF" ]; then
    source "$RSYNC_TUI_CONF"
else
    echo "No config file found! Please run rsyncTUI.sh!!!"
    exit 1
fi

## 1.5 Logging
### Log file, for the TUI
LOGFILE_TUI="$LOGDIR/rsync-tui.log"
### Echo into terminal and Log into file(if logs are enabled)
echlog()
{
    local msg="$*"
    echo "$msg"
    if [ "$loggs" == "true" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') $msg" >> "$LOGFILE_TUI"
    fi
}

#================================
# 2. Helper Functions
#================================
## 2.1 Select Direcotry for NNN file manager integration
select_directory()
{
    ### Start at the users Home directory
    local START_DIR="$HOME"
    ### Info on usage
    whiptail --title "$TITLE - Select Directory" --msgbox \
    "Directory selection controls:

    Enter       : open directory
    left arrow  : go back a directory
    right arrow : go forward a directory
    Space       : select directory
    q           : confirm selection

    You will now enter the directory browser." \
    "$HEIGHT" "$WIDTH" 3>&1 1>&2 2>&3 || exit 0
    echlog "started NNN directory selection"
    ### Create a temporary file to store the selected path
    local TMPFILE
    TMPFILE=$(mktemp)
    ### d - open directories only (no file selection)
    ### Q - quit automatically after selection
    ### -p "$TMPFILE" - tells nnn to write the selected path into this file when exiting
    NNN_OPTS="dQ" nnn -p "$TMPFILE" "$START_DIR"
    echlog "NNN choice: $TMPFILE"
    ### If content exists then output it:
    [ -s "$TMPFILE" ] && cat "$TMPFILE"
    ### Remove the tmp file
    rm -f "$TMPFILE"
}

## 2.2 Move or Copy backup
mv_cp()
{
    ### Either mv or cp -r (theoretically any command is possible)
    local OPERATION="${1}"
    local LABEL="${2}"
    CHOSEN_BACKUP_PLACE="$CHOSEN_BACKUP"
    echlog "$LABEL operation selected"
    ### First select using NNN file manager
    if whiptail --title "$TITLE - $LABEL" --yesno \
    "Would you like to choose the direcotry using NNN?\nThe curent backups dir is: $CHOSEN_BACKUP" \
    "$HEIGHT" "$WIDTH"; then
        CHOSEN_BACKUP_PLACE=$(select_directory)
    fi

    ### Then either manuall enter or check that you choose corectly
    ### The preloaded default is the curent backup dir
    CHOSEN_BACKUP_PLACE=$(whiptail --title "$TITLE - $LABEL" --inputbox \
    "Is this a good Direcotry?" "$HEIGHT" "$WIDTH" "$CHOSEN_BACKUP_PLACE" \
    3>&1 1>&2 2>&3) || return 0
    ### If the chosen dir is the same as the source, then cancel operation
    if ! [ "$CHOSEN_BACKUP" == "$CHOSEN_BACKUP_PLACE" ]; then
        ### The actual operation itself
        $OPERATION "$CHOSEN_BACKUP" "$CHOSEN_BACKUP_PLACE"
        ### Successe mesage box
        whiptail --title "$TITLE - $LABEL - Done!" --msgbox \
        "$LABEL operation is done: $CHOSEN_BACKUP_PLACE" "$HEIGHT" "$WIDTH"
        echlog "Made new: $CHOSEN_BACKUP_PLACE"
        ### Ask if the user wants to manage the new backup or the old one
        if whiptail --title "$TITLE - Switch to New?" --yesno \
        "Switch to new backup: $CHOSEN_BACKUP_PLACE\n(no to stay)" "$HEIGHT" "$WIDTH"; then
            CHOSEN_BACKUP="$CHOSEN_BACKUP_PLACE"
            echlog "Switched to the new backup"
        fi
    else
        echlog "Selected the same directory..."
        whiptail --title "$TITLE - Same Directory!" --msgbox \
        "You chose the same directory, no changes made!" "$HEIGHT" "$WIDTH"
    fi
}

## 2.3 Compression of backup
compress_backup()
{
    ### Only theese archive formats:
    FORMAT=$(whiptail --title "$TITLE" --menu \
    "Choose archive format for: $CHOSEN_BACKUP" \
    "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
        tar     ".tar.xz (high compression, Linux standard)" \
        zip     ".zip (widely compatible)" \
        7zip    ".7z (best compression, needs 7zip)" \
        3>&1 1>&2 2>&3) || return 0

    ### Normalize path and derive proper archive name
    SRC="${CHOSEN_BACKUP%/}"
    BASENAME="$(basename "$SRC")"
    PARENT="$(dirname "$SRC")"

    ### Set file suffix
    case "$FORMAT" in
        zip) ARCHIVE="$PARENT/$BASENAME.zip" ;;
        tar) ARCHIVE="$PARENT/$BASENAME.tar.xz" ;;
        7zip) ARCHIVE="$PARENT/$BASENAME.7z" ;;
    esac

    ### Double Check output
    ARCHIVE=$(whiptail --title "$TITLE - Archive output" --inputbox \
        "Does this look good?" "$HEIGHT" "$WIDTH" "$ARCHIVE" \
    3>&1 1>&2 2>&3) || return 0

    ### Run either in the curent terminal or in a tmux window
    RUN_MODE=$(whiptail --title "$TITLE - Run Mode" --menu \
    "How do you want to run the compression?" $HEIGHT $WIDTH $MENU_HEIGHT \
        normal "Run normally (block terminal)" \
        tmux   "Run in tmux (background session)" \
    3>&1 1>&2 2>&3) || return 0
    case "$RUN_MODE" in
    normal)
        echlog "Normal compression mode selected"
        case "$FORMAT" in
            tar) tar -cJf "$ARCHIVE" -C "$SRC" . ;;
            zip) ( cd "$SRC" && zip -r "$ARCHIVE" . ) ;;
            7zip) ( cd "$SRC" && 7z a "$ARCHIVE" . ) ;;
        esac
        read -p "Press Enter to Continue"
    ;;
    tmux)
        echlog "TMUX compression run mode selected"
        command -v tmux >/dev/null || error "tmux is not installed"
        SESSION="compress-$(date +%Y%m%d%H%M%S)"
        case "$FORMAT" in
            tar) CMD="tar -cJf \"$ARCHIVE\" -C \"$SRC\" ." ;;
            zip) CMD="cd \"$SRC\" && zip -r \"$ARCHIVE\" ." ;;
            7zip) CMD="cd \"$SRC\" && 7z a \"$ARCHIVE\" ." ;;
        esac
        tmux new-session -d -s "$SESSION" "$CMD; echo; echo 'Compression finished. Press Enter to exit.'; read"
        if whiptail --title "$TITLE - tmux Session Started" --yesno \
        "Compression is running in tmux session: $SESSION

        Attach now?" $HEIGHT $WIDTH; then
            tmux attach -t "$SESSION"
        else
            whiptail --msgbox \
            "Compression is running in tmux.
            Attach later with:
            tmux attach -t $SESSION" $HEIGHT $WIDTH
            return 0
        fi
    ;;
    esac

    ### Confirmation
    whiptail --msgbox "Compression completed:\n$ARCHIVE" "$HEIGHT" "$WIDTH"

    ### Keep the original backup?
    if whiptail --title "$TITLE - Keep Original?" --yesno \
    "Compression finished.

    Keep the original uncompressed backup?" "$HEIGHT" "$WIDTH"; then
        echlog "Kept original backup: $CHOSEN_BACKUP"
        ### Switch to new backup?
        if whiptail --title "$TITLE - Switch to New?" --yesno \
        "Switch to new backup?" "$HEIGHT" "$WIDTH"; then
            CHOSEN_BACKUP="$ARCHIVE"
        fi
    else
        rm -rf "$CHOSEN_BACKUP"
        echlog "Original backup removed: $CHOSEN_BACKUP"
        ### Switch to new backup?
        if whiptail --title "$TITLE - Switch to New?" --yesno \
        "Switch to new backup?(no to exit)" "$HEIGHT" "$WIDTH"; then
            CHOSEN_BACKUP="$ARCHIVE"
        else
            exit 0
        fi
    fi
}

## 2.4 De-compress Archive
de_compress_backup()
{
    ### Only for archives
    DEST_DIR="${CHOSEN_BACKUP%.*}"
    case "$CHOSEN_BACKUP" in
        *.tar.xz) DEST_DIR="${CHOSEN_BACKUP%.tar.xz}" ;;
        *.zip)    DEST_DIR="${CHOSEN_BACKUP%.zip}" ;;
        *.7z)     DEST_DIR="${CHOSEN_BACKUP%.7z}" ;;
        *)  whiptail --msgbox "Unsupported archive format!" "$HEIGHT" "$WIDTH"
            return 0
        ;;
    esac

    ### Double Check output
    DEST_DIR=$(whiptail --title "$TITLE - De-compress Archive" --inputbox \
        "Is this a good output Directory?" "$HEIGHT" "$WIDTH" "$DEST_DIR" \
    3>&1 1>&2 2>&3) || return 0

    ### Check if destination allready exists
    if [ -e "$DEST_DIR" ]; then
        whiptail --msgbox "Destination already exists:\n$DEST_DIR" "$HEIGHT" "$WIDTH"
        return 0
    fi

    ### De-compressing the Archive
    echlog "Decompressing archive: $CHOSEN_BACKUP → $DEST_DIR"
    mkdir -p "$DEST_DIR"
    case "$CHOSEN_BACKUP" in
        *.tar.xz)
            tar -xJf "$CHOSEN_BACKUP" -C "$DEST_DIR"
            ;;
        *.zip)
            ### Unzip may not be on the system
            command -v unzip >/dev/null || {
                whiptail --msgbox "unzip not installed!" "$HEIGHT" "$WIDTH"
                return 0
            }
            unzip "$CHOSEN_BACKUP" -d "$DEST_DIR"
            ;;
        *.7z)
            ### 7zip may not be on the system
            command -v 7z >/dev/null || {
                whiptail --msgbox "7z not installed!" "$HEIGHT" "$WIDTH"
                return 0
            }
            7zip x "$CHOSEN_BACKUP" -o"$DEST_DIR"

            ;;
        esac

        ### Confirmation
        whiptail --msgbox "Decompression completed:\n$DEST_DIR" "$HEIGHT" "$WIDTH"
        ### Keep the original backup?
        if whiptail --title "Keep Archive?" --yesno \
        "Decompression finished.

        Keep the compressed archive?" "$HEIGHT" "$WIDTH"; then
            echlog "User kept archive: $CHOSEN_BACKUP"
            ### Switch to new backup?
            if whiptail --title "Switch to New?" --yesno \
            "Switch to new backup?" "$HEIGHT" "$WIDTH"; then
                CHOSEN_BACKUP="$DEST_DIR"
            fi
        else
            rm -f "$CHOSEN_BACKUP"
            echlog "Archive removed: $CHOSEN_BACKUP"
            ### Switch to new backup?
            if whiptail --title "Switch to New?" --yesno \
            "Switch to new backup?(no to exit)" "$HEIGHT" "$WIDTH"; then
                CHOSEN_BACKUP="$DEST_DIR"
            else
                exit 0
            fi
        fi
}

#================================
# 3 - Parse flags
#================================
## 3.1 Getting the -i (input) parsed dir for backup management
### Chosen Backup to manage
CHOSEN_BACKUP=""
while getopts ":i:" opt; do
    case "$opt" in
        i) CHOSEN_BACKUP="$OPTARG" ;;
        *) error "Invalid option" ;;
    esac
done

### If no input is found, exit (No selection logic here)
if [ -z "$CHOSEN_BACKUP" ]; then
    whiptail --msgbox "You did not provide a backup dir!" "$HEIGHT" "$WIDTH"
    echlog "Use the -i flag to input a backup to manage"
    exit 0
fi
#================================
# 4 - Main Menu
#================================
while true; do
    CHOICE=$(whiptail --title "$TITLE" --menu \
    "Select an action for: $CHOSEN_BACKUP" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
        ncdu        "💽 Space Usage Analylis(Folders only)" \
        move        "🚛 Move or rename Backup" \
        copy        "🗃️ Copy backup" \
        remove      "🔃 Remove Backup" \
        compress    "🗜️ Compress Backup" \
        de_compress "📂 Decompress Backup(Archives Only)" \
        tim_compres "⏱️ (TBD) Periodic Compression" \
        prune       "🗄️ (TBD) Periodic Backup Pruning" \
        exit        "X  Exit" \
        3>&1 1>&2 2>&3) || exit 0

case "$CHOICE" in
    ncdu) ncdu "$CHOSEN_BACKUP" ;;
    move) mv_cp "mv" "Move" ;;
    copy) mv_cp "cp -r" "Copy" ;;
    remove)
        if whiptail --title "$CHOSEN_BACKUP" --yesno \
        "Are you sure you want to REMOVE this backup???" "$HEIGHT" "$WIDTH"; then
            if whiptail --title "$CHOSEN_BACKUP" --yesno \
            "⚠️Are you REALLY sure you want to REMOVE this backup???" "$HEIGHT" "$WIDTH"; then
                rm -rf "$CHOSEN_BACKUP"
                exit 0
            fi
        fi
    ;;
    compress) compress_backup ;;
    de_compress) de_compress_backup ;;
    tim_compres) whiptail --msgbox "Periodic Compression not yet implemented!" "$HEIGHT" "$WIDTH"
    ;;
    prune) whiptail --msgbox "Backup Pruning not yet implemented!" "$HEIGHT" "$WIDTH"
    ;;
    *) exit 0 ;;
    esac
done
