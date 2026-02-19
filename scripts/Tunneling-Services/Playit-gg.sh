#!/usr/bin/env bash
#==================================== 1. Parameters ====================================
AUTOSTART="$HOME/Tunneling-Services/playitgg-autostart.sh"
BINNARY="$HOME/Tunneling-Services/bin/playitgg"
CRONLINE="@reboot $AUTOSTART"
## Detect terminal size
### in case tput is not found, sets to fixed value
TERM_HEIGHT=$(tput lines 2>/dev/null || echo 24)
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
## Set TUI size based on terminal size
HEIGHT=$(( TERM_HEIGHT ))
WIDTH=$(( TERM_WIDTH ))
MENU_HEIGHT=$(( HEIGHT - 10 ))

#==================================== 2. Main Menu ====================================
while true; do
PLAYIT_CHOICE=$(whiptail --title "Playit.gg" --menu "What do you want to do:" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
"1" "Update/Install it" \
"2" "Setup Autostart.sh script" \
"3" "Add or remove Cronjob for autostart" \
"4" "Manually start Playit.gg via autostart script + open tmux" \
"5" "Open tmux window with playit.gg" \
"6" "Remove playit.gg" \
"7" "Cancel" \
3>&1 1>&2 2>&3)
case "$PLAYIT_CHOICE" in
1)
#==================================== Download Playit.gg Binnary ====================================
ARCH=$(whiptail --title "Select Architecture" --menu \
"Choose your system architecture:" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
    "amd64"   "x86_64 systems (Most PCs & Servers)" \
    "aarch64" "ARM64 (Raspberry Pi 4-5+, Apple M-series via Linux)" \
    "armv7"   "32-bit ARM (older Raspberry Pi)" \
    "i686"    "32-bit x86 systems" \
    3>&1 1>&2 2>&3) || continue

case "$ARCH" in
    amd64)   FILE="playit-linux-amd64" ;;
    aarch64) FILE="playit-linux-aarch64" ;;
    armv7)   FILE="playit-linux-armv7" ;;
    i686)    FILE="playit-linux-i686" ;;
    *) exit 0 ;;
esac

DOWNLOAD_URL="https://github.com/playit-cloud/playit-agent/releases/latest/download/$FILE"

whiptail --infobox "Downloading Playit.gg agent for $ARCH..." "$HEIGHT" "$WIDTH"
mkdir -p "$(dirname "$BINNARY")"
if curl -fL "$DOWNLOAD_URL" -o "$BINNARY"; then
    chmod +x "$BINNARY"
    whiptail --msgbox "Playit.gg agent downloaded successfully!\nSaved as: $BINNARY" "$HEIGHT" "$WIDTH"
else
    whiptail --msgbox "Download failed!\nCheck your internet connection or GitHub availability." "$HEIGHT" "$WIDTH"
    exit 0
fi
;;

2)
rm "$AUTOSTART"
cat > "$AUTOSTART" <<EOF
#!/usr/bin/env bash
SESSION="playitgg"

if ! tmux has-session -t "\$SESSION" 2>/dev/null; then
    tmux new-session -d -s "\$SESSION"
    tmux send-keys -t "\$SESSION" "$BINNARY" C-m
fi
EOF
chmod +x "$AUTOSTART"
whiptail --title "Done" --msgbox "Autostart File Setup, next setup a cronjob to autostart." "$HEIGHT" "$WIDTH"
;;

3)
#==================================== Check on crontab  ====================================
#If the crontab line exists, then ask if the user wants to remove it
if crontab -l 2>/dev/null | grep -F "$AUTOSTART" >/dev/null; then
    if whiptail --title "Cron Entry Exists!" --yesno "Do you wish to remove it?" --defaultno "$HEIGHT" "$WIDTH"; then
        crontab -l 2>/dev/null | grep -v "$CRONLINE" | crontab -
        continue
    fi
else
    if whiptail --title "Add Cron Autostart?" --yesno "Add @reboot entry to start Playit.gg on boot?" \
    "$HEIGHT" "$WIDTH"; then
        (crontab -l 2>/dev/null; echo "$CRONLINE") | crontab -
        echo "Cron entry added."
    else
        echo "Skipped adding cron entry."
    fi
fi
echo "Autostart management complete."
;;

4)
$AUTOSTART
tmux attach -t playitgg
;;

5) tmux attach -t playitgg ;;

6)
if whiptail --title "Remove Playit.gg!?" --yesno "Do you wish to remove it?" --defaultno "$HEIGHT" "$WIDTH"; then
echo "Killing the TMUX session"
tmux kill-session -t "playitgg"
echo "Removing Playit Binnary"
rm "$BINNARY"
echo "Removing crontab service"
crontab -l 2>/dev/null | grep -v "$CRONLINE" | crontab -
echo "Removing autostart script"
rm "$AUTOSTART"
fi
;;

*) exit 0 ;;
esac
done
exit 0
