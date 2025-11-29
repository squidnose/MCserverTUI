# WORK IN PROGRESS!
# MC Server TUI:
## A simple TUI for Minecraft servers on linux.
## File-Structure:
- ~/mcservers/<server_name> = MC server locations
  - run.sh | Run shortcut with the Ram ammout with the nogui option
  - autostart.sh | Autostart script with tmux commands
  - server-version.conf | MC version, Loader and Modrith colectoin ID
## Dependecnies
- [whiptale (newt package)](https://man.archlinux.org/man/whiptail.1.en) - For the menu system
- Crontab support, Tested with cronie - For automation and server startup
- tmux - for MC server console
- python - for [Modrinth Colection Downloader](https://github.com/aayushdutt/modrinth-collection-downloader)
- opejnjdk8, 17 and 21 - for Minecraft (My script doesnt use it)
## Scripts and their functions
### setup.sh
- Will setup Dependecnies and services for some linux distros.
- Not all are supported
### MCserverTUI.sh
- uses My [[Linux-Script-Manager]](https://codeberg.org/squidnose-code/Linux-Script-Runner)
- runs all script located in the scripts dirctory
## scripts
### 1.New-Server.sh
- Asks for: 
  - Server name
  - Choose MC version number
  - Choose MC loader type
  - modrinth colection ID(Not manditory)
- saves info into config file located in the servers directory
- Asks if you want to download mods from modrinth via colection ID
  - runs modrith-downloader.sh
- Asks how to install a server jar
  - manually via URL
  - fabric, asks for:
    - Installer version
    - Loader version
- Choose max and min memory for server
  - you need to use either 1G or 1024M format (Example for 1 GB)
- Ask if you Agree with the eula
- Automatic start on Reboot
  - Puts autostart file into the MC servers direcotry 
- Run Server in Tmux window


### 2.Manage-Servers.sh
Whiptale menu:
- Existing servers(List in ~/mcserver/)
- When selected server:
  - Open server console
  - Start server 
  - Stop server
  - Update Server (Modrinth Mods and server jar file)
  - Edit server files 
  - Add or Configure Autostart Features 
  - Add or Configure memory config
  - Change server Name 
### 3.Crontab-Management.sh
- asks for you to select a text editor
- opens user crontab using crontab -e
## More scripts
- modrinth-autodownloader.py 
  - Modrinth colectoin downloader in python. 
  - This is not my code, i used: https://github.com/aayushdutt/modrinth-collection-downloader
- modrith-downloader.sh
  - modrith-downloader.sh is a TUI front for modrinth-autodownloader.py 
### Colors
- set-colors.sh
  - sets a color theme from presets
  - Uses newt colors as standard for whiptale
  - saves choice in colors.conf
  

## Todo
- Manage Backups for all servvers located in ~/mcservers
  - One time manula backup
  - Setup Auto backup with crontab 
- Manage Reverse proxys (Localtonet, Playig.gg, ngrok)
  - Make crontabs for them with Tmux 
- Auto Update-System
- config mcserver (Should I????)
  - Port
  - gamemode
  - online mode
  - motd
  - max players
  - dificulty
  - view distance
