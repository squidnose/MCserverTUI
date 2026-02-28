#!/usr/bin/env bash
set -euo pipefail

#================================
# 0 - Periodic Rsync Backups
#================================
# This script generates rsync-based cron backup jobs.
# Assumptions:
# - Jobs may run in parallel
# - Backup destinations must not overlap
# - Source directories may be read concurrently

#================================
# 1 - Setup
#================================
## 1.1 Detect terminal size
### Automaticly detects terminal size
### incase tput is not found, sets to fixed value
TERM_HEIGHT=$(tput lines 2>/dev/null || echo 24)
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
HEIGHT=$(( TERM_HEIGHT  ))
WIDTH=$(( TERM_WIDTH  ))
MENU_HEIGHT=$(( HEIGHT - 10 ))
### use $HEIGHT $WIDTH for --inputbox --msgbox --yesno
### or $HEIGHT $WIDTH $MENU_HEIGHT for --menu

### Logs whenever backup is made (Opt-Out)
LOGFILE_CRON="$HOME/.local/state/Backups-RSYNC-TUI/rsync-periodic-backups.log"
### Menu Title
TITLE="New Rsync Backup Entry"

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

## 2.3 If exited mid script
exited() #Exit 0 with a echo debug notice
{
    echo "exited out of Periodic-Rsync-Backup mid script"
    exit 0
}

## 2.4 Hour selection
hour_select24()
{
HOUR=$(whiptail --title "Hour Selection - $TITLE" \
    --menu "Hour of backup (24h format):" \
    "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
    00 ":00" \
    01 ":00" \
    02 ":00" \
    03 ":00" \
    04 ":00" \
    05 ":00" \
    06 ":00" \
    07 ":00" \
    08 ":00" \
    09 ":00" \
    10 ":00" \
    11 ":00" \
    12 ":00" \
    13 ":00" \
    14 ":00" \
    15 ":00" \
    16 ":00" \
    17 ":00" \
    18 ":00" \
    19 ":00" \
    20 ":00" \
    21 ":00" \
    22 ":00" \
    23 ":00" \
    3>&1 1>&2 2>&3) || exited
}

### 2.5 Day selection
day_select7() {
    DOW=$(whiptail --title "Day Selection - $TITLE" \
        --menu "Select day of week:" \
        "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
        0 "Sunday" \
        1 "Monday" \
        2 "Tuesday" \
        3 "Wednesday" \
        4 "Thursday" \
        5 "Friday" \
        6 "Saturday" \
        3>&1 1>&2 2>&3) || exited

    case "$DOW" in
        0) DOW_NAME="Sunday" ;;
        1) DOW_NAME="Monday" ;;
        2) DOW_NAME="Tuesday" ;;
        3) DOW_NAME="Wednesday" ;;
        4) DOW_NAME="Thursday" ;;
        5) DOW_NAME="Friday" ;;
        6) DOW_NAME="Saturday" ;;
        *) DOW_NAME="Unknown" ;;
    esac
}


#================================
# 3 - Parse flags
#================================
SRC_PRE="" #Source direcotry from parsed -i flag
DST_PRE="" #Destination direcotry from parsed -o flag

while getopts ":i:o:" opt; do
    case "$opt" in
        i) SRC_PRE="$OPTARG" ;;
        o) DST_PRE="$OPTARG" ;;
        *) error "Invalid option" ;;
    esac
done

#================================
# 4 - Wizzard Menu
#================================
## 4.1 Confirmation
(whiptail --title "$TITLE" --yesno "Hi ${USER:-$(id -un 2>/dev/null || echo User)}, do you wish setup a NEW backup option?" 10 60;) || exited

## 4.2 Source directory
SRC=$(whiptail --title "Source - $TITLE" \
    --inputbox "Folder to back up:" $HEIGHT $WIDTH "$SRC_PRE" \
    3>&1 1>&2 2>&3) || exited

[ -d "$SRC" ] || error "Source directory does not exist"
SRC=$(normalize_dir "$SRC")

## 4.3 Destination directory
DST_DIR=$(whiptail --title "Destination - $TITLE" \
    --inputbox "Backup destination:" $HEIGHT $WIDTH "$DST_PRE" \
    3>&1 1>&2 2>&3) || exited

mkdir -p "$DST_DIR" || error "Cannot create destination directory"
DST_DIR=$(normalize_dir "$DST_DIR")

## 4.4 Backup period
PERIOD=$(whiptail --title "Schedule - $TITLE" --menu "Backup period:" $HEIGHT $WIDTH $MENU_HEIGHT \
    daily   "Every day" \
    weekly  "Once a week" \
    monthly "Once a month" \
    3>&1 1>&2 2>&3) || exit 0

## 4.5 Backup type
MODE=$(whiptail --title "Backup Mode - $TITLE" --menu "Backup style:" $HEIGHT $WIDTH $MENU_HEIGHT \
    mirror     "Overwrite (rsync --delete)" \
    timestamp  "Keep timestamped backups" \
    3>&1 1>&2 2>&3) || exit 0
### Adding the name for the folder based on backup type
if [ "$MODE" = "mirror" ]; then
    DST="${DST_DIR}${PERIOD}"
fi
if [ "$MODE" = "timestamp" ]; then
    DST="${DST_DIR}${PERIOD}-\$(date +\\%Y-\\%m-\\%d_\\%H-\\%M)/"
fi

## 4.6 Cron schedule
#Setting default time, in case it is not set
MIN="00" #Minutes - Permanently set to 00, could be optoin to set in the future
DOM="*"  #Day Of the Month - default set to any *
MON="*"  #Month - Permanently set to any *, could be optoin to set in the future
DOW="*"  #Day Of the Week - default set to any *
# IMPORTANT:
# If both DOM and DOW are restricted, cron runs when EITHER matches.
# Therefore:
# - Weekly jobs must leave DOM='*'
# - Monthly jobs must leave DOW='*'

case "$PERIOD" in
    daily)
        hour_select24
        TIME_DISPLAY="Daily backups, done at $HOUR"
        ;;
    weekly)
        hour_select24
        day_select7
        TIME_DISPLAY="Weekly backups, done at $HOUR hours on $DOW_NAME"s""
        ;;
    monthly)
        hour_select24
        DOM=$(whiptail --title "Day of Month" --inputbox "Run on which day of month? (1–28 recommended)" "$HEIGHT" "$WIDTH" "1" \
        3>&1 1>&2 2>&3)
        TIME_DISPLAY="Monthly backups, done at $HOUR hours on the $DOM. day of the month"
        ;;
esac


## 4.7 rsync command
RSYNC_OPTS="-aAX"
[ "$MODE" = "mirror" ] && RSYNC_OPTS="$RSYNC_OPTS --delete"

## 4.8 Log Mode - set the cronline backup
LOG_MODE=$(whiptail --title "Logging - $TITLE" --menu "Enable logging?" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
    yes "Log backup output (recommended)" \
    no  "No logging (lower disk usage)" \
    3>&1 1>&2 2>&3) || exited

case "$LOG_MODE" in
    yes)
        CMD="sh -c 'echo \"[\$(date)] Backup start | period=$PERIOD | source=$SRC | destination=$DST_DIR\" >> \"$LOGFILE_CRON\"; \
        rsync $RSYNC_OPTS \"$SRC\" \"$DST\" >> \"$LOGFILE_CRON\" 2>&1'"
        ;;
    no)
        CMD="sh -c 'rsync $RSYNC_OPTS \"$SRC\" \"$DST\"'"
        LOGFILE_CRON="None - Logging disabled" ### Log file now no longer represents a file or location.
        ;;
    *)
        error "Invalid logging option"
        ;;
esac

CRONLINE="$MIN $HOUR $DOM $MON $DOW $CMD"
#================================
# 5 - Final confirmation
#================================
whiptail --title "Confirm Job  - $TITLE" --yesno \
"=== Install the following cron job? ===
source=$SRC
destination=$DST_DIR
$TIME_DISPLAY

=== Cronline: ===
$CRONLINE

=== Log file: ===
$LOGFILE_CRON" $HEIGHT $WIDTH || exited

#================================
# 6 - Install cron job
#================================
(
    crontab -l 2>/dev/null
    echo "#Backup | $TIME_DISPLAY | source=$SRC | destination=$DST_DIR | Logs:$LOGFILE_CRON"
    echo "$CRONLINE"
) | crontab -
echo "Made this cronline: $CRONLINE"
whiptail --msgbox "Backup job installed successfully." $HEIGHT $WIDTH
exit 0
