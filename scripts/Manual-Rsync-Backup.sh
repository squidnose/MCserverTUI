#!/usr/bin/env bash
##Finds the locatoin of bash
set -euo pipefail
##Prevents silent failure

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
TITLE="New Rsync Backup Entry"

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
    echo "exited out of Manual-Rsync-Backup mid script"
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

#============================ Confirmation ============================
(whiptail --title "$TITLE" --yesno "Hi $USER, do you wish setup a NEW backup option?" 10 60;) || exited

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

#============================ Backup confirmation ============================
whiptail --title "Confirm Manual Backup" --yesno \
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
        echo "Backup in progress, please wait..."
        rsync -aAX "$SRC" "$DST"
        ;;
    tmux)
        command -v tmux >/dev/null || error "tmux is not installed"
        SESSION="manual-backup-$(date +%Y%m%d%H%M%S)"
        tmux new-session -d -s "$SESSION" "rsync -aAX \"$SRC\" \"$DST\"; echo; echo 'Backup finished. Press Enter to exit.'; read"
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

exit 0
