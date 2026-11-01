#!/usr/bin/env bash
# Backups-Rsync-TUI
# https://codeberg.org/squidnose-code/Backups-RSYNC-TUI
## Backup-Manager.sh
set -euo pipefail

#============================ Info ============================
# Features:
## Analyze size of backup using ncdu or du
## Rename backup
## Move backup
## Copy backup
## Remove backup
## Compress Backup (Archives only: .zip, .tar.xz, 7z)
## De-compress backups

#============================ Initialization ============================
SCRIPT_DIR="$(dirname "$(realpath "$0")")" # Find script location
source "$SCRIPT_DIR"/tui-lib.sh # Load Library of functions
load_vars # Load variables: Title, Config files and Log files
term_size # set TUI size to console size
color_tui # Set color schemes for newt/whiptail
conf_file # Load config file or make new one. For enableing/diableing logs.
checks_deps # Check for dependencies: whiptail, rsync and crontab
checks_dirs # Check if the OS has folder parameters set
TITLE="Main Menu - $SCRIPT_TITLE"


#============================ Parse flags ============================
CHOSEN_BACKUP="" # The chosen backup (Directory)
while getopts ":i:" opt; do
    case "$opt" in
        i) CHOSEN_BACKUP="$OPTARG" ;;
        *) error "Invalid option" && exit 1 ;;
    esac
done

# If no input is found, ask for an input
if [ -z "$CHOSEN_BACKUP" ]; then
    # Source directory
    CHOSEN_BACKUP=$(whiptail --title "$TITLE" --inputbox "Backup/Folder to manage:" $HEIGHT $WIDTH 3>&1 1>&2 2>&3) || exit 0
    [[ "$CHOSEN_BACKUP" != */ ]] && CHOSEN_BACKUP="${CHOSEN_BACKUP}/" # Normalize dir, but outside funciton
fi
# debug
echlog "=========================================="
echlog "Running - Backup-Manger.sh"
echlog "Chosen Backup: $CHOSEN_BACKUP"

#============================ Menu Functions ============================
# Move or Copy backup
mv_cp()
{
    # Either mv or cp -r
    local OPERATION="${1}"
    local LABEL="${2}"
    CHOSEN_BACKUP_PLACE="$CHOSEN_BACKUP"
    echlog "$LABEL operation selected"

    # First select using NNN file manager
    if whiptail --title "$LABEL - $TITLE" --yesno "Would you like to choose the direcotry using NNN?\nThe Current backups dir is: $CHOSEN_BACKUP" "$HEIGHT" "$WIDTH"; then
        CHOSEN_BACKUP_PLACE=$(select_directory "$HOME")
    fi

    # Then either manually enter or check that you choose correctly
    # The preloaded default is the Current backup dir
    CHOSEN_BACKUP_PLACE=$(whiptail --title "$LABEL - $TITLE" --inputbox "Is this a good Direcotry?" "$HEIGHT" "$WIDTH" "$CHOSEN_BACKUP_PLACE" 3>&1 1>&2 2>&3) || return 0
    echlog "Chosen backup dir to $LABEL to: $CHOSEN_BACKUP_PLACE"
    # Checks if it is the same dir
    if [ -z "$CHOSEN_BACKUP_PLACE" ]; then
        error "$LABEL - Directory cannot be empty!"
        return 0
    fi

    # Checks if it is the same dir
    if ! [ "$CHOSEN_BACKUP" == "$CHOSEN_BACKUP_PLACE" ]; then
        ## The actual operation itself
        $OPERATION "$CHOSEN_BACKUP" "$CHOSEN_BACKUP_PLACE" || { error "$LABEL operation failed!"; return 0; }
        ## Successe mesage box
        whiptail --title "$LABEL - $TITLE" --msgbox "$LABEL operation is done: $CHOSEN_BACKUP_PLACE" "$HEIGHT" "$WIDTH"
        echlog "Made new: $CHOSEN_BACKUP_PLACE"
        ## Ask if the user wants to manage the new backup or the old one (CP only)
        if [ "$OPERATION" == "cp -r" ]; then
           if whiptail --title "$LABEL - $TITLE" --yesno "Switch to new backup: $CHOSEN_BACKUP_PLACE\n(no to stay)" "$HEIGHT" "$WIDTH"; then
                CHOSEN_BACKUP="$CHOSEN_BACKUP_PLACE"
                echlog "Switched to the new backup"
            fi
        else ## or if mv, then automatically move to new backup
            whiptail --title "$TITLE" --msgbox "You will now be moved to manageing the new backup:\n $CHOSEN_BACKUP_PLACE" "$HEIGHT" "$WIDTH"
            CHOSEN_BACKUP="$CHOSEN_BACKUP_PLACE"
        fi
    else
        error "$LABEL - You chose the same directory, no changes made!"
    fi
} #mv_cp()

# Compression of backup
compress_backup()
{
    # Format selection
    FORMAT=$(whiptail --title "Backup Compression - $TITLE" --menu "Choose archive format for: $CHOSEN_BACKUP" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
        tar     ".tar.xz (high compression, Linux standard)" \
        zip     ".zip (widely compatible)" \
        7zip    ".7z (best compression, needs 7zip)" \
        3>&1 1>&2 2>&3) || return 0
    echlog "Compression format chosen: $FORMAT "

    ## Normalize path
    SRC="${CHOSEN_BACKUP%/}"
    BASENAME="$(basename "$SRC")"
    PARENT="$(dirname "$SRC")"

    # Set file suffix
    case "$FORMAT" in
        zip) ARCHIVE="$PARENT/$BASENAME.zip" ;;
        tar) ARCHIVE="$PARENT/$BASENAME.tar.xz" ;;
        7zip) ARCHIVE="$PARENT/$BASENAME.7z" ;;
    esac

    # Double Check output
    ARCHIVE=$(whiptail --title "Backup Compression - $TITLE" --inputbox "Confirm, does this look good?" "$HEIGHT" "$WIDTH" "$ARCHIVE" 3>&1 1>&2 2>&3) || return 0
    echlog "Will save as: $ARCHIVE"

    # Run either in the curent terminal or in a tmux window
    RUN_MODE=$(whiptail --title "Backup Compression - $TITLE" --menu "How do you want to run the compression?" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
        normal "Run normally (this terminal)" \
        tmux   "Run in tmux (background terminal session)" \
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
        SESSION="compress-$(date +%Y%m%d%H%M%S)"
        case "$FORMAT" in
            tar) CMD="tar -cJf \"$ARCHIVE\" -C \"$SRC\" ." ;;
            zip) CMD="cd \"$SRC\" && zip -r \"$ARCHIVE\" ." ;;
            7zip) CMD="cd \"$SRC\" && 7z a \"$ARCHIVE\" ." ;;
        esac
        tmux new-session -d -s "$SESSION" "$CMD; echo; echo 'Compression finished. Press Enter to exit.'; read"
        if whiptail --title "Backup Compression - $TITLE" --yesno \
        "Compression is running in tmux session: $SESSION

        Attach now?" "$HEIGHT" "$WIDTH"; then
            tmux attach -t "$SESSION"
        else
            whiptail --title "Backup Compression - $TITLE" --msgbox \
            "Compression is running in tmux.
            Attach later with:
            tmux attach -t $SESSION" "$HEIGHT" "$WIDTH"
            return 0
        fi
    ;;
    esac

    # Confirmantion
    whiptail --title "Backup Compression - $TITLE" --msgbox "Compression completed:\n$ARCHIVE" "$HEIGHT" "$WIDTH"
    ## Keep the original backup?
    if whiptail --title "Backup Compression - $TITLE" --yesno "Compression finished.\n\nKeep the original uncompressed backup?" "$HEIGHT" "$WIDTH"; then
        echlog "Kept original backup: $CHOSEN_BACKUP"
        ## Switch to new backup?
        if whiptail --title "Backup Compression - $TITLE" --yesno "Switch to new backup?\n(for managing)" "$HEIGHT" "$WIDTH"; then
            CHOSEN_BACKUP="$ARCHIVE"
        fi
    else
        rm -rf "$CHOSEN_BACKUP"
        echlog "Original backup removed: $CHOSEN_BACKUP"
        ## Switch to new backup?
        if whiptail --title "Backup Compression - $TITLE" --yesno "Switch to new backup?\n(no exits to main menu)" "$HEIGHT" "$WIDTH"; then
            CHOSEN_BACKUP="$ARCHIVE"
        else
            exit 0 # Yes, keep this here, you cant manage a backup you just removed...
        fi
    fi
}

# De-compress Archive
de_compress_backup()
{
    # Check extension
    case "$CHOSEN_BACKUP" in
        *.tar.xz) DEST_DIR="${CHOSEN_BACKUP%.tar.xz}" ;;
        *.zip)    DEST_DIR="${CHOSEN_BACKUP%.zip}" ;;
        *.7z)     DEST_DIR="${CHOSEN_BACKUP%.7z}" ;;
        *)  error "Unsupported archive format!" "$HEIGHT" "$WIDTH"
            return 1
        ;;
    esac

    # Double Check output
    DEST_DIR=$(whiptail --title "Backup Archive De-Compression - $TITLE" --inputbox "Is this a good output Directory?" "$HEIGHT" "$WIDTH" "$DEST_DIR" 3>&1 1>&2 2>&3) || return 0
    echlog "To decompress: $CHOSEN_BACKUP"

    # Check if destination allready exists
    if [ -e "$DEST_DIR" ]; then
        error "Destination already exists!\n$DEST_DIR"
        return 0
    fi

    # De-compressing the Archive
    echlog "Decompressing archive: $CHOSEN_BACKUP → $DEST_DIR"
    mkdir -p "$DEST_DIR"
    case "$CHOSEN_BACKUP" in
        *.tar.xz)
            tar -xJf "$CHOSEN_BACKUP" -C "$DEST_DIR"
            ;;
        *.zip)
            ## Unzip may not be on the system
            command -v unzip >/dev/null || {
                error "unzip not installed!"
                return 0
            }
            unzip "$CHOSEN_BACKUP" -d "$DEST_DIR"
            ;;
        *.7z)
            ## 7zip may not be on the system
            command -v 7z >/dev/null || {
                error "7z not installed!"
                return 0
            }
            7z x "$CHOSEN_BACKUP" -o"$DEST_DIR"
            ;;
    esac

    # Check if direcotry was made and created
    if [ -d "$DEST_DIR" ]; then
        whiptail --title "Backup Archive De-Compression - $TITLE" --msgbox "Decompression completed:\n$DEST_DIR" "$HEIGHT" "$WIDTH"
    else
        error "De-compression failed, no output directory created! This may be due to permissions..."
        return 0
    fi

    # Keep the original backup?
    if whiptail --title "Backup Archive De-Compression - $TITLE" --yesno "Decompression finished.\n\nKeep the compressed archive?" "$HEIGHT" "$WIDTH"; then
        echlog "User kept archive: $CHOSEN_BACKUP"
        ## Switch to new backup?
        if whiptail --title "Backup Archive De-Compression - $TITLE" --yesno "Switch to new backup?" "$HEIGHT" "$WIDTH"; then
            CHOSEN_BACKUP="$DEST_DIR"
        fi
    else
        rm -f "$CHOSEN_BACKUP"
        echlog "Archive removed: $CHOSEN_BACKUP"
        ## Switch to new backup?
        if whiptail --title "Backup Archive De-Compression - $TITLE" --yesno "Switch to new backup?(no exists to Main Menu)" "$HEIGHT" "$WIDTH"; then
            CHOSEN_BACKUP="$DEST_DIR"
        else
            exit 0 # Yes, keep this here, you cant manage a backup you just removed...
        fi
    fi
}

#============================ Main Menu ============================
while true; do
    CHOICE=$(whiptail --title "$TITLE" --menu \
    "Select an action for: $CHOSEN_BACKUP" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
        size        "💽 Space Usage Analysis" \
        move        "🚛 Move or rename Backup" \
        copy        "🗃️ Copy backup" \
        remove      "🔃 Remove Backup" \
        compress    "🗜️ Compress Backup" \
        de_compress "📂 Decompress Backup(Archives Only)" \
        exit        "X  Exit" \
        3>&1 1>&2 2>&3) || break

case "$CHOICE" in
    size)
        case "$CHOSEN_BACKUP" in
            *.tar.xz | *.zip | *.7z) size=$(du -sh "$CHOSEN_BACKUP") && whiptail --title "Size - $TITLE" --msgbox "$size" "$HEIGHT" "$WIDTH"
            ;;
            *)  ncdu "$CHOSEN_BACKUP" || error "ncdu not installed!"
            ;;
        esac
     ;;
    move) mv_cp "mv" "Move";;
    copy) mv_cp "cp -r" "Copy";;
    remove)
        if whiptail --title "$CHOSEN_BACKUP - $TITLE" --yesno "Are you sure you want to REMOVE this backup:\n$CHOSEN_BACKUP" "$HEIGHT" "$WIDTH"; then
            if whiptail --title "$CHOSEN_BACKUP - $TITLE" --yesno "⚠️Are you REALLY sure you want to REMOVE this backup???\n$CHOSEN_BACKUP" "$HEIGHT" "$WIDTH"; then
                rm -rf "$CHOSEN_BACKUP"
                echlog "removed backup: $CHOSEN_BACKUP"
                break
            fi
        fi
    ;;
    compress) compress_backup || continue ;;
    de_compress) de_compress_backup || continue ;;
    *) break ;;
    esac
done

echlog "Exiting Backup-Manager.sh"
echlog "=========================================="
exit 0
