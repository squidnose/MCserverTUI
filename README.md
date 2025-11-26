# WORK IN PROGRESS!
# DO NOT USE IN PRODUCTION!!
# DEVELOPMENT USE ONLY!!!
# MC Server TUI:
## A simple TUI for Minecraft servers on linux.
### File-Structure:
- ~/mcservers/<server_name> = MC server locations
  - run.sh | Run shortcut with the Ram ammout with the nogui option
  - autostart.sh | 
  - server-version.conf | MC version, Loader and Modrith colectoin ID
### Scripts and their functions
#### MCserverTUI.sh
- uses My [[Linux-Script-Manager]](https://codeberg.org/squidnose-code/Linux-Script-Runner)
- runs all script located in the scripts dirctory

#### 1.New-Server.sh
- Asks for: 
  - Server name
  - Choose MC version number
  - Choose MC loader type
  - modrinth colection ID(Not manditory)
- saves info into config file located in the servers directory
- Asks if you want to download mods from modrinth via colection ID
  - runs modrith-downloader.sh
  - modrith-downloader.sh is a TUI front end for https://github.com/aayushdutt/modrinth-collection-downloader
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


#### 2.Manage-Servers.sh
Whiptale menu:
- Existing servers(List in ~/mcserver/)
  - When selected server:
  - Open server console
  - Update server and its mods
  
#### Todo
- manage MC server
- config mcserver
  - Port
  - gamemode
  - online mode
  - motd
  - max players
  - dificulty
  - view distance
  - 
- Manage Backups for all servvers located in ~/mcservers
  - One time manula backup
  - Setup Auto backup with crontab 
- Manage Reverse proxys (Localtonet, Playig.gg, ngrok)
  - Make crontabs for them with Tmux 
- Auto Update-System
