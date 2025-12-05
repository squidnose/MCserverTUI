#!/bin/bash
# Crontab Editor with Editor Selection
## Detect terminal size
TERM_HEIGHT=$(tput lines)
TERM_WIDTH=$(tput cols)
## Set TUI size based on terminal size
HEIGHT=$(( TERM_HEIGHT ))
WIDTH=$(( TERM_WIDTH ))
MENU_HEIGHT=$(( HEIGHT - 10 ))
raw_edit_crontab() {
# 1. Capture the menu choice (the number 1, 2, 3, or 4)
CHOICE=$(whiptail --title "Choose an Editor" --menu "Select your preferred editor for Crontab" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
"1" "nano (Beginner-friendly)" \
"2" "vim (vi) (Standard terminal editor)" \
"3" "less (Simple, read only, q to quit)" \
"4" "Cancel" \
3>&1 1>&2 2>&3)

# Check if the user hit Cancel/Esc or chose the 'Cancel' option (4)
if [ $? -ne 0 ] || [ "$CHOICE" == "4" ]; then
    echo "Operation canceled."
    exit 0
fi

# 2. Map the choice number to the actual editor command
SELECTED_EDITOR=""
case "$CHOICE" in
    1) SELECTED_EDITOR="nano" ;;
    2) SELECTED_EDITOR="vi" ;;
    3) SELECTED_EDITOR="less" ;;
esac

# 3. Export the environment variable
# crontab -e looks for the EDITOR or VISUAL environment variable
# to know which program to launch. We must set and export it.
export EDITOR="$SELECTED_EDITOR"

echo "Launching crontab with $EDITOR..."
crontab -e

echo "Crontab edit complete."
}

raw_edit_crontab
exit 0
