# WORK IN PROGRESS!!!!!!!!!!!!!!!!!!!!!!
# MC Server TUI:
## A TUI for Minecraft servers on linux. The default will be for debian but will have the option to easily modify for a different distro. 
### File-Structure:
- ~/mcservers/<server_name> = MC server locations
  - <server_name>
    - run.sh = Run command with the Ram ammout with the nogui option
  - MCserverTUI.sh
  - Modrinth-autodownloader.py https://github.com/aayushdutt/modrinth-collection-downloader
  - Autostart-files
    - server_name_autostart.sh contents:
 ```
#!/bin/bash
tmux new-session -d -s <server_name>
tmux send-keys -t <server_name> "cd ~/mcservers/<server_name>" C-m
tmux send-keys -t <server_name> "./run.sh" C-m
``` 
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
- Automatic start on Reboot(Not done yet)
- Run Server in Tmux window


#### 2.Manage-Servers
Whiptale menu:
- Existing servers(List in ~/mcserver/)
  - When selected server:
  - Open server console
  - Update server and its mods
  
#### Todo
- Add a cronjob to:
    - Autostart Server konsole and put the tmux command into ~/MCserverTUI/Autostart-files/<servername>_autostart.sh
- Manage Backups for all servvers located in ~/mcservers
  - One time manula backup
  - Setup Auto backup with crontab 
- Manage Reverse proxys (Localtonet, Playig.gg, ngrok)
  - Make crontabs for them with Tmux 
- Update-Systems
