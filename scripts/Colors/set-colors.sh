#!/usr/bin/env bash
#===================================================
# TUI Theme Switcher for Voidlinux Post Install TUI
#===================================================
#============================ Term Size ============================
TERM_HEIGHT=$(tput lines 2>/dev/null || echo 24)
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
HEIGHT="$TERM_HEIGHT"
WIDTH="$TERM_WIDTH"
MENU_HEIGHT=$((HEIGHT - 10))
### use $HEIGHT $WIDTH for --inputbox --msgbox --yesno
### or $HEIGHT $WIDTH $MENU_HEIGHT for --menu

CONF_FILE="$(dirname "$(realpath "$0")")/colors.conf"

while true; do
    CHOICE=$(whiptail --title "Theme Selector" --menu "Choose a color preset:" $HEIGHT $WIDTH $MENU_HEIGHT  \
        1 "Matrix (Green on Black)" \
        2 "Commodore 64 (Blue/Light Blue)" \
        3 "PC CGA (Magenta & Cyan)" \
        4 "Ubuntu Orange" \
        5 "Linux Mint Green" \
        6 "KDE Breeze (Blue/Cyan)" \
        7 "Default (reset / no colors)" \
        8 "Exit" 3>&1 1>&2 2>&3)

    case $CHOICE in
        1) # Matrix
            cat > "$CONF_FILE" <<EOF
# Matrix
root=,black
window=,black
title=brightgreen,black
border=green,black
textbox=brightgreen,black
button=black,green
compactbutton=green,black
listbox=green,black
actlistbox=black,brightgreen
helpline=green,black
roottext=brightgreen,black
EOF
            whiptail --msgbox "Matrix theme applied!" $HEIGHT $WIDTH
            ;;
        2) # Commodore 64
            cat > "$CONF_FILE" <<EOF
# Commodore 64
root=blue,blue
window=lightgray,blue
title=lightblue,blue
border=lightblue,blue
textbox=lightgray,blue
button=blue,lightgray
compactbutton=lightblue,blue
listbox=lightblue,blue
actlistbox=blue,lightblue
helpline=lightblue,blue
roottext=lightblue,blue
EOF
            whiptail --msgbox "Commodore 64 theme applied!" $HEIGHT $WIDTH
            ;;
        3) # PC CGA
            cat > "$CONF_FILE" <<EOF
# PC CGA
root=,black
window=,black
title=magenta,black
border=cyan,black
textbox=cyan,black
button=black,magenta
compactbutton=magenta,black
listbox=cyan,black
actlistbox=black,cyan
helpline=magenta,black
roottext=cyan,black
EOF
            whiptail --msgbox "PC CGA theme applied!" $HEIGHT $WIDTH
            ;;
        4) # Ubuntu Orange
            cat > "$CONF_FILE" <<EOF
# Ubuntu Orange
root=,black
window=,black
title=brightred,black
border=yellow,black
textbox=brightred,black
button=black,brightred
compactbutton=brightred,black
listbox=brightred,black
actlistbox=black,brightred
helpline=brightred,black
roottext=brightred,black
EOF
            whiptail --msgbox "Ubuntu Orange theme applied!" $HEIGHT $WIDTH
            ;;
        5) # Linux Mint Green
            cat > "$CONF_FILE" <<EOF
# Linux Mint Green
root=,black
window=,black
title=brightgreen,black
border=green,black
textbox=green,black
button=black,brightgreen
compactbutton=green,black
listbox=brightgreen,black
actlistbox=black,green
helpline=brightgreen,black
roottext=green,black
EOF
            whiptail --msgbox "Linux Mint Green theme applied!" $HEIGHT $WIDTH
            ;;
        6) # KDE Breeze
            cat > "$CONF_FILE" <<EOF
# KDE Breeze
root=,black
window=,black
title=brightcyan,black
border=blue,black
textbox=cyan,black
button=black,brightcyan
compactbutton=cyan,black
listbox=brightcyan,black
actlistbox=black,cyan
helpline=cyan,black
roottext=cyan,black
EOF
            whiptail --msgbox "KDE Breeze theme applied!" $HEIGHT $WIDTH
            ;;
        7) # Default
            echo "# Default (empty)" > "$CONF_FILE"
            whiptail --msgbox "Default theme applied (no colors)." $HEIGHT $WIDTH
            ;;
        8) # Exit
            exit 0
            ;;
        *)
            exit 0
            ;;
    esac
done
