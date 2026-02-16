#!/usr/bin/env bash
clear
echo "Wellcome to my MCserverTUI script"
echo "Before you run my script, we are going to need some Dependencies"
echo "Select You linux distro:"
echo "1. Ubuntu (24.04 Tested)"
echo "2. Debian (Lacks All Java versions)"
echo "3. Voidlinux (Tested - Developed on)"
echo "4. Freebsd (15.0 tested)"
echo "5. Archlinux (the Extra Repo is needed)"
echo "x. Not on the list?"
read -r -p "Enter your choice (1-5):" CHOICE
case $CHOICE in
1)
echo "Installing MCserverTUI Dependencies (Newt, ncurses, python3, tmux, curl, wget, jq)"
sudo apt install newt ncurses python3 tmux curl wget ncdu jq
echo "Installing Terminal Utils (nano, nnn, ncdu, glow, less)"
sudo apt install nano nnn ncdu glow less
echo "Installing Java 8, 17, 21  Minecraft Dependencies"
sudo apt install openjdk-8-jdk-headless openjdk-8-jre-headless openjdk-17-jdk-headless openjdk-17-jre-headless openjdk-21-jdk-headless openjdk-21-jre-headless
echo "Installing Java 25 Minecraft Dependency"
sudo apt install openjdk-25-jdk-headless
;;
2)
echo "Installing MCserverTUI Dependencies (Newt, ncurses, python3, tmux, curl, wget, jq)"
sudo apt install newt ncurses python3 tmux curl wget ncdu jq
echo "Installing Terminal Utils (nano, nnn, ncdu, glow, less)"
sudo apt install nano nnn ncdu glow less
echo "Installing Minecraft Java 8 Dependency (Debian SID)"
sudo apt install openjdk-8-jdk-headless
echo "Installing Minecraft Java 17 Dependency (Debian 11,12 and SID)"
sudo apt install openjdk-17-jdk-headless
echo "Installing Minecraft Java 21 and 25 Dependency (Debian13+)"
sudo apt install openjdk-21-jdk-headless openjdk-25-jre-headless
echo "=============================================================="
echo "DEBIAN 12 and 13 DO NOT SUPPORT JAVA 8 FOR MC 1.16.5 AND OLDER"
echo "DEBIAN 12 DOES NOT SUPPORT JAVA 21 and 25 FOR MC 1.20.5 AND NEWER"
echo "DEBIAN 13 DOESNT SUPPORT JAVA 17 FOR MC 1.17 - 1.20.4"
echo "=============================================================="
echo "Install manually using: https://sdkman.io/install/"
echo "=============================================================="
;;
3)
echo "Installing MCserverTUI Dependencies (Newt, ncurses, Cronie, python3, tmux, curl, wget, jq)"
sudo xbps-install -Su newt ncurses cronie python3 tmux curl wget jq
echo "Installing Terminal Utils (nano, nnn, ncdu, mdr, glow, less)"
sudo xbps-install -Su nano nnn ncdu mdr glow less
echo "Enabling Crontab service"
sudo ln -s /etc/sv/cronie/ /var/service/
echo "Installing Minecraft Java Dependencies"
sudo xbps-install -Su openjdk8 openjdk8-jre openjdk17 openjdk17-jre openjdk21 openjdk21-jre openjdk25 openjdk25-jre
;;
4)
echo "Installing MCserverTUI Dependencies (Newt, ncurses, python3, tmux, curl, wget, jq)"
sudo pkg install newt ncurses python3 tmux curl wget jq
echo "Installing Text editors/viewers (nano, nnn, ncdu, glow, less)"
sudo pkg install nano nnn ncdu glow less
echo "Installing Minecraft Java Dependencies"
sudo pkg install openjdk8 openjdk17 openjdk21 openjdk25
;;
5)
echo "Installing MCserverTUI Dependencies (Newt, ncurses, Cronie, python3, tmux, curl, wget, jq)"
sudo pacman -S newt ncurses cronie python tmux curl wget jq
echo "Installing Text editors/viewers (nano, nnn, ncdu, glow, less)"
sudo pacman -S nano nnn ncdu glow less
echo "Enabling Crontab service"
sudo systemctl enable cronie.service
echo "Installing Minecraft Java Dependencies"
sudo pacman -S  jdk8-openjdk jre8-openjdk-headless jdk17-openjdk jre17-openjdk-headless jdk21-openjdk jre21-openjdk-headless jdk25-openjdk jre25-openjdk-headless
;;
*)
clear
echo "If you distro is not listed or it did not work."
echo "Manually install theese Dependencies:"
echo " newt - Whiptale - for TUI menu system"
echo " ncurses - For detecting the terminal size"
echo " tmux - for server console"
echo " python3 - For modrinth colection downloader"
echo " curl and wget - for downloading files"
echo " crontab support - check by running crontab -e"
echo "   Search crontab support for your distro"
echo " nano, mdr, glow, vim, less, kate, mousepad - Text editor/viewer of choice"
echo " nnn and ncdu - usefull terminal utils"
echo " jq - For managing .json files for manual downloader "
echo " Java 8, 17, 21 and 25 (For Minecraft)"
echo "   Search for openjdk in you package manager"
echo "   If you can not find a desired openjdk version, use this:"
echo "   https://sdkman.io/install/"
esac


