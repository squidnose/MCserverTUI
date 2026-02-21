#!/usr/bin/env bash
set -euo pipefail

#================================
# 0 - Manual Rsync Backups
#================================
## Run manual backups
## Can be run either in curent console or a tmux window

#================================
# 1 - Setup
#================================
## 1.1 Term Size and dir location
### Automaticly detects terminal size
### incase tput is not found, sets to fixed value
TERM_HEIGHT=$(tput lines 2>/dev/null || echo 24)
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
HEIGHT="$TERM_HEIGHT"
WIDTH="$TERM_WIDTH"
MENU_HEIGHT=$((HEIGHT - 10))
### use $HEIGHT $WIDTH for --inputbox --msgbox --yesno
### or $HEIGHT $WIDTH $MENU_HEIGHT for --menu

### Direcotry for Logs and Config files
LOGDIR="$HOME/.local/state/Backups-RSYNC-TUI"
mkdir -p "$LOGDIR"

### Menu Title
TITLE="Manual Rsync Backup"

## 1.2 Script location
### Finds out where the script is located
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
if [ -z "$SCRIPT_DIR" ]; then
    echo "This script has no idea where it is.\n you will have to find a way to get dirname and realpath to work on your OS"
    exit 1
fi

## 1.3 Config file
### Conf file
RSYNC_TUI_CONF="$HOME/.local/state/MCserverTUI/MCserverTUI.conf"
### Load config file exit 1
if [ -f "$RSYNC_TUI_CONF" ]; then
    source "$RSYNC_TUI_CONF"
else
    echo "No config file found! Please run rsyncTUI.sh!!!"
    exit 1
fi

## 1.5 Logging
### Logs from Manual and Restore backups
LOGFILE_MANUAL="$LOGDIR/rsync-manual-backups.log"
### Echo and Log into file
echlog()
{
    local msg="$*"
    echo "$msg"
    if [ "$loggs" == "true" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') $msg" >> "$LOGFILE_MANUAL"
    fi
}

#================================
# 2 - Helper Functions
#================================
## 2.1 Legacy Error handlerer (Will be removed)
error()
{
    whiptail --title "Error" --msgbox "$1" 8 60
    exit 0
}

## 2.2 Ensure directory path ends with a trailing slash for rsync
normalize_dir()
{
    local dir="$1"
    [[ "$dir" != */ ]] && dir="${dir}/"
    echo "$dir"
}

## 2.3 Exit 0 with a echo debug notice
exited()
{
    echlog "exited out of Manual-Rsync-Backup mid script"
    echlog "=========================================="
    exit 0
}

#================================
# 3 - Parse flags
#================================
SRC_PRE="" ### Source direcotry from parsed -i flag
DST_PRE="" ### Destination direcotry from parsed -o flag

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

#================================
# 4 - Wizzard Menu
#================================
## 4.1 Confirmation
(whiptail --title "$TITLE" --yesno "Hi ${USER:-$(id -un 2>/dev/null || echo User)}, do you wish to run a MANUAL backup?" 10 60;) || exited

## 4.2 Source directory
SRC=$(whiptail --title "$TITLE - Source" \
    --inputbox "Folder to back up:" $HEIGHT $WIDTH "$SRC_PRE" \
    3>&1 1>&2 2>&3) || exited

[ -d "$SRC" ] || error "Source directory does not exist"
SRC=$(normalize_dir "$SRC")

## 4.3 Destination directory
DST_DIR=$(whiptail --title "$TITLE - Destination" \
    --inputbox "Backup destination:" $HEIGHT $WIDTH "$DST_PRE" \
    3>&1 1>&2 2>&3) || exited

mkdir -p "$DST_DIR" || error "Cannot create destination directory"
DST_DIR=$(normalize_dir "$DST_DIR")

### Adding the name for the folder with the date
    DST="${DST_DIR}Manual-$(date +%Y-%m-%d_%H-%M)/"
echlog "Changed to theese parameters:"
echlog "Source: $SRC_PRE"
echlog "Destination: $DST_PRE"

## 4.4 Dry-run preview
if whiptail --title "$TITLE - Preview Restore (Dry Run)" --yesno \
"Do you want to PREVIEW what will change before restoring?

No files will be modified.
This will show:
- Files that will be copied
- Press Q to exit" \
"$HEIGHT" "$WIDTH"; then
    echlog "Dry run mode ran"
    rsync -aAX --dry-run --itemize-changes "$SRC" "$DST" | less

fi

#================================
# 5 - Backup confirmation
#================================
whiptail --title "$TITLE" --yesno \
"Run manual backup now?

Source:
$SRC

Destination:
$DST" \
$HEIGHT $WIDTH || exited

## 4.6 Run in tmux?
RUN_MODE=$(whiptail --title "$TITLE - Run Mode" --menu "How do you want to run the backup?" $HEIGHT $WIDTH $MENU_HEIGHT \
    normal "Run normally (block terminal) - simple" \
    tmux   "Run in tmux (background session) - For big files" \
    3>&1 1>&2 2>&3) || exited

#================================
# 6 - Run rsync
#================================
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
        if whiptail --title "$TITLE - tmux Session Started" --yesno "Backup is running in tmux session: $SESSION Do you want to attach now?" $HEIGHT $WIDTH; then
        tmux attach -t "$SESSION"
        else
        whiptail --msgbox "Backup is running in tmux. Attach later with: tmux attach -t $SESSION" $HEIGHT $WIDTH
        exit 0 ### Skips the Completion message part, because it may not be true
        fi
        ;;
    *)
        error "Invalid run mode"
        ;;
esac
#================================
# 7 - Completion message
#================================
whiptail --title "$TITLE - Backup Complete" --msgbox \
"Manual backup completed successfully.

Source:
$SRC

Destination:
$DST" $HEIGHT $WIDTH
echlog "=========================================="
exit 0
