#!/bin/bash
clear
echo "Wellcome to my MCserverTUI script"
echo "Before you run my script, we are going to need some Dependencies"
echo "Select You linux distro:"
echo "1. Ubuntu 22.04 and Higher(Tested)"
echo "2. Debian 12(MC 1.17 - 1.20.4)"
echo "3. Debian 13(MC 1.20.5+)"
echo "4. Voidlinux(Tested)"
echo "5. Archlinux(the Extra Repo is needed)"
echo "x. Not on the list?"
read -r -p "Enter your choice (1-5):" CHOICE
case $CHOICE in
1)
echo "Installing MCserverTUI Dependencies"
sudo apt install newt python3 tmux curl wget nano nnn ncdu
echo "Installing Java 8, 17, 21  Minecraft Dependencies"
sudo apt install openjdk-8-jdk-headless openjdk-8-jre-headless openjdk-17-jdk-headless openjdk-17-jre-headless openjdk-21-jdk-headless openjdk-21-jre-headless
echo "Installing Java 25 Minecraft Dependency"
sudo apt install openjdk-25-jdk-headless
;;
2)
echo "Installing MCserverTUI Dependencies"
sudo apt install newt python3 tmux curl wget nano nnn ncdu
echo "Installing Minecraft Java Dependencies"
sudo apt install openjdk-17-jdk-headless openjdk-17-jre-headless
echo "DEBIAN 12 DOESNT SUPPORT JAVA 25 FOR MC 26.1 AND NEWER"
echo "DEBIAN 12 DOESNT SUPPORT JAVA 21 FOR MC 1.20.5 - 1.21.11"
echo "DEBIAN 12 DOESNT SUPPORT JAVA 8 FOR MC 1.16.5 AND OLDER"
echo "Install manually using: https://sdkman.io/install/"
;;
3)
echo "Installing MCserverTUI Dependencies"
sudo apt install newt python3 tmux curl wget nano nnn ncdu
echo "Installing Minecraft Java Dependencies"
sudo apt install openjdk-21-jdk-headless openjdk-21-jre-headless openjdk-25-jdk-headless openjdk-25-jre-headless
echo "DEBIAN 13 DOESNT SUPPORT JAVA 8 FOR MC 1.16.5 AND OLDER"
echo "DEBIAN 13 DOESNT SUPPORT JAVA 17 FOR MC 1.17 - 1.20.4"
echo "Install manually using: https://sdkman.io/install/"
;;
4)
echo "Installing MCserverTUI Dependencies(Newt, Cronie, python3, tmux, curl, wget)"
sudo xbps-install -Su newt cronie python3 tmux curl wget
echo "Installing Nano, Less and mdr text editors/viewers"
sudo xbps-install -Su nano less mdr nnn ncdu
echo "Enabling Crontab service"
sudo ln -s /etc/sv/cronie/ /var/service/
echo "Installing Minecraft Java Dependencies"
sudo xbps-install -Su openjdk8 openjdk8-jre openjdk17 openjdk17-jre openjdk21 openjdk21-jre openjdk25 openjdk25-jre
;;
5)
echo "Installing MCserverTUI Dependencies"
sudo pacman -S newt cronie python tmux curl wget nano nnn ncdu
echo "Enabling Crontab service"
sudo systemctl enable cronie.service
echo "Installing Minecraft Java Dependencies"
sudo pacman -S  jdk8-openjdk jre8-openjdk-headless jdk17-openjdk jre17-openjdk-headless jdk21-openjdk jre21-openjdk-headless jdk25-openjdk jre25-openjdk-headless
;;
*)
clear
echo "If you distro is not listed or it did not work."
echo "Manually install theese Dependencies:"
echo " newt (Whiptale - for TUI menu system)"
echo " dialog (For detecting the terminal size)"
echo " tmux (for server console)"
echo " python3 (For modrinth colection downloader)"
echo " curl and wget (for downloading files)"
echo " crontab support(check by running crontab -e)"
echo "   Search crontab support for your distro"
echo " nano, vim, less, kate, mousepad (Text editor/viewer of choice)"
echo " mdr (For rendering MarkDown .md files in terminal)"
echo " nnn and ncdu (cool terminal utils)"
echo " Java 8, 17, 21 and 25 (For Minecraft)"
echo "   Search for openjdk in you package manager"
echo "   If you can not find a desired openjdk version, use this:"
echo "   https://sdkman.io/install/"
esac


