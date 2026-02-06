# Manage Servers
- Offers tools to manage your existing server
- Manages Existing servers in ~/mcservers/ directory
- You are prompted to choose a server based on the directory names in ~/mcservers/

## What can it do?
- **Open server console** - Opens tmux; CTR+B , D to exit
- **Start server** - Runs run.sh in new tmux window
- **Stop server** - Sends stop to server
- **Edit server.properties** - each line is configurable, a text editor may be easier
- **Update Server** - Update server jar file and Modrinth Mods/Plugins
- **Edit server files** - Uses my [[Linux-Script-Runner]](https://codeberg.org/squidnose-code/Linux-Script-Runner)
  - Opens Folders
  - Edits files
  - Modify .jar files:
    - replace .jar file from URL
    - rename .jar files
    - remove .jar files
- **Add or Configure Autostart Features** using tmux and cron
- **Add or Configure memory config** edits run.sh
- **Change server Name** stops servers
- **Terminal Utils** generic terminal tools that may help with managing your MCserver

## Manage-Servers.sh - Equivalent commands
- Commands that the script runs and you can to. 
- usefull when MCserverTUI doesn’t work for you:
  - Open server console (replace $SERVER_NAME your server name): tmux attach -t "$SERVER_NAME" 
  - Edit the crontab file: crontab -e 
