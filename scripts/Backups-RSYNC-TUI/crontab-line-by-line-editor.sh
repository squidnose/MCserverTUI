#!/usr/bin/env bash
# Backups-Rsync-TUI
# https://codeberg.org/squidnose-code/Backups-RSYNC-TUI
## crontab-line-by-line-editor.sh
## dont use set -e, this makes the script fail for some reason...

#============================ Info ============================
# Features:
## Remove selected lines from crontab

#============================ Initialization ============================
SCRIPT_DIR="$(dirname "$(realpath "$0")")" # Find script location
source "$SCRIPT_DIR"/lib-rsync-tui.sh # Load Library of functions
load_vars # Load variables: Title, Config files and Log files
term_size # set TUI size to console size
color_tui # Set color schemes for newt/whiptail
conf_file # Load config file or make new one. For enableing/diableing logs.
checks_deps # Check for dependencies: whiptail, rsync and crontab
checks_dirs # Check if the OS has folder parameters set
TITLE="Main Menu - $SCRIPT_TITLE"

#============================ User Warning ============================
if ! whiptail --title "$TITLE" --yesno \
" ⚠️ This can be Dangerous if your not carefull ⚠️

Space bar to select, enter to save" "$HEIGHT" "$WIDTH"; then
exit 0
fi

#============================ Functions ============================
# Get current user crontab safely
get_current_crontab()
{
    crontab -l 2>/dev/null || true
} #get_current_crontab()

#============================ Loading existing Crontab Lines ============================
# Read crontab lines into array
mapfile -t CURRENT_LINES < <(get_current_crontab)

# Check If empty crontab
if [[ ${#CURRENT_LINES[@]} -eq 0 ]]; then
    whiptail --title "$TITLE" --msgbox "Your crontab is empty. Nothing to edit." $HEIGHT $WIDTH
    exit 0
fi

#============================ Main Menu ============================
# Build whiptail checklist
# Each line is selectable for removal (default OFF)
MENU_ITEMS=()
INDEX=0
for line in "${CURRENT_LINES[@]}"; do
    ## Skip empty lines visually but keep index consistency
    display="$line"
    [[ -z "$display" ]] && display="(empty line)"
    MENU_ITEMS+=("$INDEX" "$display" "OFF")
    ((INDEX++))
done

## Show checklist
CHOICES=$(whiptail --title "$TITLE" --checklist "Select lines to REMOVE from your crontab:" \
    $HEIGHT $WIDTH $MENU_HEIGHT \
    "${MENU_ITEMS[@]}" 3>&1 1>&2 2>&3)

## Exit if cancelled
[ $? -ne 0 ] && echo "Cancelled." && exit 0

#============================ Remove Selected Lines ============================
# Convert selection indexes to array
read -r -a SELECTED_INDEXES <<< "$(echo "$CHOICES" | tr -d '"')"

# Build new crontab and removed list
NEW_CRONTAB=()
REMOVED_LINES=()

for i in "${!CURRENT_LINES[@]}"; do
    if printf '%s\n' "${SELECTED_INDEXES[@]}" | grep -Fxq "$i"; then
        REMOVED_LINES+=("${CURRENT_LINES[$i]}")
    else
        NEW_CRONTAB+=("${CURRENT_LINES[$i]}")
    fi
done

# If nothing selected
if [[ ${#REMOVED_LINES[@]} -eq 0 ]]; then
    whiptail --title "$TITLE" --msgbox "No lines selected. Nothing changed." $HEIGHT $WIDTH
    exit 0
fi

#============================ Apply New Crontab ============================
# User check
REMOVED_SUMMARY=$(printf "%s\n" "${REMOVED_LINES[@]}")
if whiptail --title "$TITLE" --yesno "Remove the following lines?\n\n$REMOVED_SUMMARY" $HEIGHT $WIDTH; then
    printf "%s\n" "${NEW_CRONTAB[@]}" | crontab -
fi
exit 0
