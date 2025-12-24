#!/bin/bash
clear
echo "Wellcome to my MCserverTUI script"
echo "Before you run my script, we are going to need some dependecies"
echo "Select You linux distro:"
echo "1. Ubuntu 22.04 and Higher(Tested)"
echo "2. Debian 12(MC 1.17 - 1.20.4)"
echo "3. Debian 13(MC 1.20.5+)"
echo "4. Voidlinux(Tested)"
echo "5. Archlinux(Extra Repo needed)"
echo "6. Fedora(MC 1.20.5+)"
echo "7. Not on the list?"
read -r -p "Enter your choice (1-6):" CHOICE
case $CHOICE in
1)
echo "Installing MCserverTUI dependecies"
sudo apt install newt python3 tmux curl wget
echo "Installing Minecraft Java dependecies"
sudo apt install openjdk-8-jdk-headless openjdk-8-jre-headless openjdk-17-jdk-headless openjdk-17-jre-headless openjdk-21-jdk-headless openjdk-21-jre-headless
echo "Manually install nerd fonts for nicer looking TUI"
;;
2)
echo "Installing MCserverTUI dependecies"
sudo apt install newt python3 tmux curl wget
echo "Installing Minecraft Java dependecies"
sudo apt install openjdk-17-jdk-headless openjdk-17-jre-headless
echo "DEBIAN 12 DOESNT SUPPORT JAVA 21 FOR MC 1.20.5 AND NEWER"
echo "DEBIAN 12 DOESNT SUPPORT JAVA 8 FOR MC 1.16.5 AND OLDER"
echo "Either manually install Java 21 and 8 or use a diferent distro..."
echo "Manually install nerd fonts for nicer looking TUI"
;;
3)
echo "Installing MCserverTUI dependecies"
sudo apt install newt python3 tmux curl wget
echo "Installing Minecraft Java dependecies"
sudo apt install openjdk-21-jdk-headless openjdk-21-jre-headless
echo "DEBIAN 13 DOESNT SUPPORT JAVA 17 or 8 FOR MC 1.20.4 AND OLDER"
echo "Either manually install Java 17 and 8 or use a diferent distro..."
echo "Manually install nerd fonts for nicer looking TUI"
;;
4)
echo "Installing MCserverTUI dependecies"
sudo xbps-install -Syu newt cronie python3 tmux curl wget
echo "Enabling Crontab service"
sudo ln -s /etc/sv/cronie/ /var/service/
echo "Installing Minecraft Java dependecies"
sudo xbps-install -Syu openjdk8 openjdk8-jre openjdk17 openjdk17-jre openjdk21 openjdk21-jre
echo "Installing nerd font symbols"
sudo xbps-install -Syu nerd-fonts-symbols-ttf
;;
5)
echo "Installing MCserverTUI dependecies"
sudo pacman -S newt cronie python tmux curl wget
echo "Enabling Crontab service"
sudo systemctl enable cronie.service
echo "Installing Minecraft Java dependecies"
sudo pacman -S  jdk8-openjdk jre8-openjdk-headless jdk17-openjdk jre17-openjdk-headless jdk21-openjdk jre21-openjdk-headless
echo "Installing nerd font symbols"
sudo pacman -S ttf-nerd-fonts-symbols
;;
6)
echo "Installing MCserverTUI dependecies"
sudo dnf install newt cronie python3 tmux curl wget
echo "Enabling Crontab service"
sudo systemctl enable cronie.service
echo "Installing Minecraft Java dependecies"
sudo dnf install java-21-openjdk
echo "Fedora DOESNT SUPPORT JAVA 17 or 8 FOR MC 1.20.4 AND OLDER"
echo "Either manually install Java 17 and 8 or use a diferent distro..."
echo "Manually install nerd fonts for nicer looking TUI"
;;
7)
echo "If you distro is not listed or it did not work."
echo "Manually install theese dependecies:"
echo "For my TUI: newt(Whiptale) and crontab support(check by running crontab -e)"
echo "For Minecraft: Java 8, 17 and 21";;
*)
echo "If you distro is not listed or it did not work."
echo "Manually install theese dependecies:"
echo "For my TUI: newt(Whiptale) and crontab support(check by running crontab -e)"
echo "For Minecraft: Java 8, 17 and 21"
echo "Search for openjdk in you package manager"
esac
read -p "MAKE SURE TO READ THE MANUAL OR WATCH THE VIDEOS!!!"


