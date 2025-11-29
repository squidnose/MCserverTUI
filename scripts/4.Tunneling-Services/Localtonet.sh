#!/bin/bash
#==================================== 1. Parameters ====================================
AUTOSTART="$HOME/Tunneling-Services/localtonet-autostart.sh"
CRONLINE="@reboot $AUTOSTART"
#==================================== 2. Main Menu ====================================
while true; do
LOCALTONET_CHOICE=$(whiptail --title "localtonet" --menu "What do you want to do:" 20 80 8 \
"1" "Update/Install it" \
"2" "Setup Autostart.sh script with Token" \
"3" "Add or Romove Cronjob for autostart" \
"4" "Manually start Localtonet via autostart script + open tmux" \
"5" "Open tmux window with localtonet" \
"6" "Remove localtonet" \
"7" "Cancel" \
3>&1 1>&2 2>&3)
case "$LOCALTONET_CHOICE" in
1) curl -fsSL https://localtonet.com/install.sh | sh ;;
2)
rm $AUTOSTART
LOCALTONET_TOKEN=$(whiptail --title "localtonet" --inputbox "Enter your token" 10 60 3>&1 1>&2 2>&3)
cat > "$AUTOSTART" <<EOF
#!/bin/bash
tmux new-session -d -s "localtonet"
tmux send-keys -t "localtonet" "localtonet --authtoken "$LOCALTONET_TOKEN"" C-m
tmux attach -t "localtonet"
EOF
chmod +x "$AUTOSTART"
;;
3)
#==================================== Check on crontab  ====================================
    if crontab -l 2>/dev/null | grep -F "$AUTOSTART" >/dev/null; then
        if whiptail --title "Cron Entry Exists!" --yesno "Do you wish to remove it?" --defaultno 10 60; then
        crontab -l 2>/dev/null | grep -v "$CRONLINE" | crontab -
        return 0
        fi
    else
    if whiptail --title "Add Cron Autostart?" --yesno "Add @reboot entry to start this server on boot?" 10 60; then
        (crontab -l 2>/dev/null; echo "$CRONLINE") | crontab -
            echo "Cron entry added."
        else
            echo "Skipped adding cron entry."
        fi
    fi
    echo "Autostart management complete."
    return 0
;;
4)
$HOME/Tunneling-Services/localtonet-autostart.sh
tmux attach -t localtonet
;;
5) tmux attach -t localtonet ;;
6)
if whiptail --title "Remove LocalToNet!?" --yesno "Do you wish to remove it?" --defaultno 10 60; then
echo "Removing Localtonet Binnary"
sudo rm /usr/local/bin/localtonet
echo "Removing contab service"
crontab -l 2>/dev/null | grep -v "$CRONLINE" | crontab -
echo "Removing autostart script with token"
rm $AUTOSTART
fi
;;
7) exit 0 ;;
*) exit 0 ;;
esac
done
exit 0
