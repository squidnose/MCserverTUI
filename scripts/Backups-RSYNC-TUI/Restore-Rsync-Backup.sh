#!/usr/bin/env bash
# Backups-Rsync-TUI
# https://codeberg.org/squidnose-code/Backups-RSYNC-TUI
## Restore-Rsync-Backup.sh
set -euo pipefail

#============================ Info ============================
# Features:
## Restore from previous backup
## Can be run either in the curent console or a tmux window(Reccomended)

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

#============================ Parsed CLI flags ================================
SRC_PRE="" # Source direcotry from parsed -i flag
DST_PRE="" # Destination direcotry from parsed -o flag

while getopts ":i:o:" opt; do
    case "$opt" in
        i) SRC_PRE="$OPTARG" ;;
        o) DST_PRE="$OPTARG" ;;
        *) error "Invalid option" ;;
    esac
done
echlog "=========================================="
echlog "Restore-Rsync-Backup ran with these parameters:"
echlog "Source: $SRC_PRE"
echlog "Destination: $DST_PRE"

#============================ Wizzard Menu ================================
# Confirmation
(whiptail --title "$TITLE" --yesno "Hi ${USER:-$(id -un 2>/dev/null || echo User)}, do you wish RESTORE from backup?" $HEIGHT $WIDTH;) || exited

# Source directory
SRC=$(whiptail --title "Source - $TITLE" --inputbox "Folder to Restore from:" $HEIGHT $WIDTH "$SRC_PRE" \
    3>&1 1>&2 2>&3) || exited

[ -d "$SRC" ] || error "Source directory does not exist"
SRC=$(normalize_dir "$SRC")

# Destination directory
DST_DIR=$(whiptail --title "Destination - $TITLE" --inputbox "Restoration destination:" $HEIGHT $WIDTH "$DST_PRE" \
    3>&1 1>&2 2>&3) || exited

mkdir -p "$DST_DIR" || error "Cannot create destination directory"
DST_DIR=$(normalize_dir "$DST_DIR")

# Adding the name for the folder with the date
DST="${DST_DIR}"

# Sanity Error Checking
[ -n "$DST" ] || error "Destination is empty"
[ "$DST" != "/" ] || error "Refusing to restore into /"

echlog "Changed to these parameters:"
echlog "Source: $SRC_PRE"
echlog "Destination: $DST_PRE"

# Dry-run preview
if whiptail --title "Preview Restore (Dry Run) - $TITLE" --yesno \
"Do you want to PREVIEW what will change before restoring?

No files will be modified.
This will show:
- Files that will be copied
- Files that will be deleted
- It will only show changes
- Press Q to exit" \
"$HEIGHT" "$WIDTH"; then
    echlog "Dry run mode ran"
    rsync -aAX --delete --dry-run --itemize-changes "$SRC" "$DST" | less

fi

#============================ Backup Restoration Confirmation ============================
whiptail --title "$TITLE" --yesno \
"Restore from backup now?

Source:
$SRC

Destination:
$DST" \
$HEIGHT $WIDTH || exited

#============================ Backup Restoration Execution ============================
RUN_MODE=$(whiptail --title "Run Mode - $TITLE" --menu "How do you want to run the backup restoration?" $HEIGHT $WIDTH $MENU_HEIGHT \
    normal "Run normally (block terminal) - simple" \
    tmux   "Run in tmux (background session) - For big files" \
    3>&1 1>&2 2>&3) || exited

mkdir -p "$DST" || error "Cannot create backup directory" # May be pointles here?

case "$RUN_MODE" in
    normal)
        echlog "Normal (CLI) Backup run mode Selected"
        rsync -aAXv --delete "$SRC" "$DST"
        read -p "Press Enter to Continue"
        ;;
    tmux)
        echlog "TMUX Backup run mode Selected"
        command -v tmux >/dev/null || error "tmux is not installed"
        SESSION="restore-backup-$(date +%Y%m%d%H%M%S)"
        tmux new-session -d -s "$SESSION" "rsync -aAXv --delete \"$SRC\" \"$DST\"; echo; echo 'Restoration finished. Press Enter to exit.'; read"
        if whiptail --title "$TITLE - tmux Session Started" --yesno "Restoration is running in tmux session: $SESSION Do you want to attach now?" $HEIGHT $WIDTH; then
        tmux attach -t "$SESSION"
        else
        whiptail --title "$TITLE" --msgbox "Restoration is running in tmux. Attach later with: tmux attach -t $SESSION" $HEIGHT $WIDTH
        exit 0 # Skips the Completion message part, because it may not be true
        fi
        ;;
    *)
        error "Invalid run mode"
        ;;
esac

#============================ Output msg ================================
whiptail --title "Restoration Complete - $TITLE" --msgbox \
"Restoration from backup completed successfully.

Source:
$SRC

Destination:
$DST" $HEIGHT $WIDTH
echlog "=========================================="
exit 0
