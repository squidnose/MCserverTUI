#!/bin/bash
echo "install dependecies"
#sudo apt install -y tmux git newt openjdk21-jre-headless
echo "makeing directories"
mkdir ~/mcservers
echo "Installing the script"
git clone https://github.com/squidnose/MCserverTUI

echo "Opening the script"
cd ~
./MCserverTUI/MC-Server-TUI.sh
