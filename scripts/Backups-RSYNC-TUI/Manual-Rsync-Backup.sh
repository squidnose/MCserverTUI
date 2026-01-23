#!/usr/bin/env bash
##Finds the locatoin of bash
set -euo pipefail
##Prevents silent failure

#============================ Logging ============================
mkdir -p "$HOME/.local/state/Backups-RSYNC-TUI"
LOGFILE_MANUAL="$HOME/.local/state/Backups-RSYNC-TUI/rsync-manual-backups.log"
# Echo and Log into file
echlog() {
    local msg="$*"
    echo "$msg"
    # if you dont want logs, comment this line:
    echo "$(date '+%Y-%m-%d %H:%M:%S') $msg" >> "$LOGFILE_MANUAL"
}
#============================ Term Size============================
## Detect terminal size
### incase tput is not found, sets to fixed value
TERM_HEIGHT=$(tput lines 2>/dev/null || echo 24)
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
## Set TUI size based on terminal size
HEIGHT=$(( TERM_HEIGHT  ))
WIDTH=$(( TERM_WIDTH  ))
MENU_HEIGHT=$(( HEIGHT - 10 ))
### use $HEIGHT $WIDTH for --inputbox --msgbox --yesno
### or $HEIGHT $WIDTH $MENU_HEIGHT for --menu

#============================ Variables ============================
TITLE="Manual Rsync Backup"

#============================ Functions ============================
error()
{
    whiptail --title "Error" --msgbox "$1" 8 60
    exit 1
}

normalize_dir() ##Ensure directory path ends with a trailing slash for rsync
{
    local dir="$1"
    [[ "$dir" != */ ]] && dir="${dir}/"
    echo "$dir"
}
exited() #Exit 0 with a echo debug notice
{
    echlog "exited out of Manual-Rsync-Backup mid script"
    echlog "=========================================="
    exit 0
}
#============================ Parse flags ============================
SRC_PRE="" #Source direcotry from parsed -i flag
DST_PRE="" #Destination direcotry from parsed -o flag

while getopts ":i:o:" opt; do
    case "$opt" in
        i) SRC_PRE="$OPTARG" ;;
        o) DST_PRE="$OPTARG" ;;
        *) error "Invalid option" ;;
    esac
done
echlog "=========================================="
echlog "Manual-Rsync-Backup ran with theese parameters:"
echlog "Source: $SRC_PRE"
echlog "Destination: $DST_PRE"

#============================ Confirmation ============================
(whiptail --title "$TITLE" --yesno "Hi ${USER:-$(id -un 2>/dev/null || echo User)}, do you wish to run a MANUAL backup?" 10 60;) || exited

#============================ Source directory ============================
SRC=$(whiptail --title "Source - $TITLE" \
    --inputbox "Folder to back up:" $HEIGHT $WIDTH "$SRC_PRE" \
    3>&1 1>&2 2>&3) || exited

[ -d "$SRC" ] || error "Source directory does not exist"
SRC=$(normalize_dir "$SRC")

#============================ Destination directory ============================
DST_DIR=$(whiptail --title "Destination - $TITLE" \
    --inputbox "Backup destination:" $HEIGHT $WIDTH "$DST_PRE" \
    3>&1 1>&2 2>&3) || exited

mkdir -p "$DST_DIR" || error "Cannot create destination directory"
DST_DIR=$(normalize_dir "$DST_DIR")

#Adding the name for the folder with the date
    DST="${DST_DIR}Manual-$(date +%Y-%m-%d_%H-%M)/"
echlog "Changed to theese parameters:"
echlog "Source: $SRC_PRE"
echlog "Destination: $DST_PRE"

#============================ Dry-run preview ============================
if whiptail --title "Preview Restore (Dry Run)" --yesno \
"Do you want to PREVIEW what will change before restoring?

No files will be modified.
This will show:
- Files that will be copied
- Press Q to exit" \
"$HEIGHT" "$WIDTH"; then
    echlog "Dry run mode ran"
    rsync -aAX --dry-run --itemize-changes "$SRC" "$DST" | less

fi

#============================ Backup confirmation ============================
whiptail --title "$TITLE" --yesno \
"Run manual backup now?

Source:
$SRC

Destination:
$DST" \
$HEIGHT $WIDTH || exited

#============================ Run in tmux? ============================
RUN_MODE=$(whiptail --title "Run Mode" --menu "How do you want to run the backup?" $HEIGHT $WIDTH $MENU_HEIGHT \
    normal "Run normally (block terminal) - simple" \
    tmux   "Run in tmux (background session) - For big files" \
    3>&1 1>&2 2>&3) || exited
#============================ Run rsync ============================
mkdir -p "$DST" || error "Cannot create backup directory"

case "$RUN_MODE" in
    normal)
        echlog "Normal (CLI) Backup run mode Selected"
        rsync -aAXv "$SRC" "$DST"
        read -p "Press Enter to Continue"
        ;;
    tmux)
        echlog "TMUX Backup run mode Selected"
        command -v tmux >/dev/null || error "tmux is not installed"
        SESSION="manual-backup-$(date +%Y%m%d%H%M%S)"
        tmux new-session -d -s "$SESSION" "rsync -aAXv \"$SRC\" \"$DST\"; echo; echo 'Backup finished. Press Enter to exit.'; read"
        if whiptail --title "tmux Session Started" --yesno "Backup is running in tmux session: $SESSION Do you want to attach now?" $HEIGHT $WIDTH; then
        tmux attach -t "$SESSION"
        else
        whiptail --msgbox "Backup is running in tmux. Attach later with: tmux attach -t $SESSION" $HEIGHT $WIDTH
        exit 0 #Skips the Completion message part, because it may not be true
        fi
        ;;
    *)
        error "Invalid run mode"
        ;;
esac
#============================ Completion message ============================
whiptail --title "Backup Complete" --msgbox \
"Manual backup completed successfully.

Source:
$SRC

Destination:
$DST" $HEIGHT $WIDTH
echlog "=========================================="
exit 0
