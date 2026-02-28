#!/usr/bin/env bash
## Loosly based of of: Linux-Kernel-Parameters-TUI https://codeberg.org/squidnose-code/Linux-Kernel-Parameters-TUI

#================================
# 0. Crontab Line by Line Editor
## Remove user-selected lines from their crontab
#================================

#================================
## 1 Term Size and Parameters
#================================
TERM_HEIGHT=$(tput lines 2>/dev/null || echo 24)
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
HEIGHT="$TERM_HEIGHT"
WIDTH="$TERM_WIDTH"
MENU_HEIGHT=$((HEIGHT - 10))
### use $HEIGHT $WIDTH for --inputbox --msgbox --yesno
### or $HEIGHT $WIDTH $MENU_HEIGHT for --menu

## Directory where this script lives
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

#================================
# 2. User Warning
#================================
if ! whiptail --title "Line by Line Crontab editor" --yesno \
" ⚠️ This can be Dangerous if your not carefull ⚠️

If you wish to remove a backup option,
remove the comment# and the line right below it." "$HEIGHT" "$WIDTH"; then
exit 0
fi


#================================
# 3. Functions
#================================
## Get current user crontab safely
get_current_crontab() {
    crontab -l 2>/dev/null || true
}

#================================
# 4. Loading existing Crontab Lines
#================================
## Read crontab lines into array
mapfile -t CURRENT_LINES < <(get_current_crontab)

## If empty crontab
if [[ ${#CURRENT_LINES[@]} -eq 0 ]]; then
    whiptail --msgbox "Your crontab is empty. Nothing to edit." $HEIGHT $WIDTH
    exit 0
fi

#================================
# 5. Menu
#================================
## Build whiptail checklist
## Each line is selectable for removal (default OFF)
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
CHOICES=$(whiptail --title "Crontab Line Editor" \
    --checklist "Select lines to REMOVE from your crontab:" $HEIGHT $WIDTH $MENU_HEIGHT \
    "${MENU_ITEMS[@]}" \
    3>&1 1>&2 2>&3)

## Exit if cancelled
[ $? -ne 0 ] && echo "Cancelled." && exit 0

#================================
# 6. Remove Selected Lines
#================================
## Convert selection indexes to array
read -r -a SELECTED_INDEXES <<< "$(echo "$CHOICES" | tr -d '"')"

## Build new crontab and removed list
NEW_CRONTAB=()
REMOVED_LINES=()

for i in "${!CURRENT_LINES[@]}"; do
    if printf '%s\n' "${SELECTED_INDEXES[@]}" | grep -Fxq "$i"; then
        REMOVED_LINES+=("${CURRENT_LINES[$i]}")
    else
        NEW_CRONTAB+=("${CURRENT_LINES[$i]}")
    fi
done

## If nothing selected
if [[ ${#REMOVED_LINES[@]} -eq 0 ]]; then
    whiptail --msgbox "No lines selected. Nothing changed." $HEIGHT $WIDTH
    exit 0
fi

#================================
# 7. Apply New Crontab
#================================
## Write new crontab
printf "%s\n" "${NEW_CRONTAB[@]}" | crontab -

#================================
# 8. Summary
#================================
REMOVED_SUMMARY=$(printf "%s\n" "${REMOVED_LINES[@]}")

whiptail --title "Crontab Updated" \
    --msgbox "Removed the following lines:\n\n$REMOVED_SUMMARY" \
    $HEIGHT $WIDTH
