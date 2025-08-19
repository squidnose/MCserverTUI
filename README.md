# WORK IN PROGRESS!!!!!!!!!!!!!!!!!!!!!!
# MC Server TUI:
## A TUI for Minecraft servers on linux. The default will be for debian but will have the option to easily modify for a different distro. 
### File-Structure:
- ~/mcservers/<server_name> = MC server locations
  - <server_name>
    - run.sh = Run command with the Ram ammout with the nogui option
- ~/MCserverTUI/ = Location of the script and its files
  - MCserverTUI.sh
  - Modrinth-autodownloader.py https://github.com/aayushdutt/modrinth-collection-downloader
  - Autostart-fileshttps://github.com/aayushdutt/modrinth-collection-downloader
    - server_name_autostart.sh contents
 ```
#!/bin/bash
tmux new-session -d -s <server_name>
tmux send-keys -t <server_name> "cd ~/mcservers/<server_name>" C-m
tmux send-keys -t <server_name> "./run.sh" C-m
``` 
### Apart of setup.sh
–	Install required: Tmux, Whiptale, openJDK8, openJDK17, openJDK21. (Seperate)
–	Install the TUI into ~/MCserverTUI
–	Ask to run the MCserverTUI
### Apart of: MCserverTUI.sh
Whiptale menu:
- Existing servers(List in ~/mcserver/)
  - When selected server:
  - Open server console
  - Update server and its mods
- New Server
  - Server name
  - Choose MC version (Manually)
  - Choose MC loader
    - Vanila
    - Forge
    - Paper
  - Choose max and min memory for server
  - Agree to eula
  - Have Mod presets to download Modrith mods: (Use the Modrith collection down-loader: https://github.com/aayushdutt/modrinth-collection-downloader
    - Custom modrinth colection
    - My MC server(https://modrinth.com/collection/ziTsdV9j)
    - Geyser
    - Create
  - Add a cronjob to:
    - Autostart Server konsole and put the tmux command into ~/MCserverTUI/Autostart-files/<servername>_autostart.sh
- Manage Backups for all servvers located in ~/mcservers
  - One time manula backup
  - Setup Auto backup with crontab 
- Manage Reverse proxys (Localtonet, Playig.gg, ngrok)
  - Make crontabs for them with Tmux 
- Update-Systems
- Exit
