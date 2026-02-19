#!/usr/bin/env bash
#==================================== 1. Parameters ====================================
AUTOSTART="$HOME/Tunneling-Services/telebit-autostart.sh"
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
PLAYIT_CHOICE=$(whiptail --title "Telebit" --menu "What do you want to do:" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
"1" "Update/Install it (Runs in Tmux)" \
"2" "Setup Autostart.sh script" \
"3" "Add or remove Cronjob for autostart" \
"4" "Manually start Telebit via autostart script + open tmux" \
"5" "Open tmux window with Telebit" \
"6" "Remove Telebit" \
"7" "Cancel" \
3>&1 1>&2 2>&3)
case "$PLAYIT_CHOICE" in
1)
if ! tmux has-session -t "telebit" 2>/dev/null; then
    tmux new-session -d -s "telebit"
    tmux send-keys -t "telebit" "curl https://get.telebit.io/ | bash" C-m
    tmux attach -t "telebit"
fi
;;

2)
#Select Protocol
PROTOCOL=$(whiptail --title "Telebit - Protocol Selection" --menu \
"Select a Protocol to use" \
"$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
"tcp"   "For java MCservers" \
"http"  "For HTTPS websites and folder sharing" \
"ssh"   "SSH Access" \
3>&1 1>&2 2>&3) || continue

PORT_FILE=$(whiptail --inputbox "Entry Port number or Folder directory(http only!):" "$HEIGHT" "$WIDTH" \
        3>&1 1>&2 2>&3) || continue
    [ -z "$PORT_FILE" ] && continue
COMMAND="$HOME/telebit $PROTOCOL $PORT_FILE"
rm "$AUTOSTART"
cat > "$AUTOSTART" <<EOF
#!/usr/bin/env bash

if ! tmux has-session -t "telebit" 2>/dev/null; then
    tmux new-session -d -s "telebit"
    tmux send-keys -t "telebit" "$COMMAND" C-m
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
    if whiptail --title "Add Cron Autostart?" --yesno "Add @reboot entry to start Telebit on boot?" \
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
if tmux has-session -t "telebit"; then
    if whiptail --title "Telebit is Running" --yesno "Tmux Window with telebit exists, do you widh to close it?" "$HEIGHT" "$WIDTH"; then
        tmux kill-session -t "telebit"
    else
        continue
    fi
fi
$AUTOSTART
tmux attach -t telebit
;;

5) tmux attach -t telebit ;;

6)
if whiptail --title "Remove Telebit!?" --yesno "Do you wish to remove it?" --defaultno "$HEIGHT" "$WIDTH"; then
echo "Killing the TMUX session"
tmux kill-session -t "telebit"
echo "Removing Telebit shortcut"
rm "$HOME/telebit"
echo "Removing Telebit Folder"
rm -rf "$HOME/Applications/telebit"
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
