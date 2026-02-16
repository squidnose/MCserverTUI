# Basics

## Tmux Key Binds !!IMPORTANT!!!
- Tmux is used for the server console.
- Tmux keybinds are weird, because you need to press 2 keybinds after another:
  **CTRL + B (let go) D**
  - This will exit from the tmux window without stopping the running server. 

---

# Download Content
- MCserverTUI allows for Manual and Automatic MC jar file downloads.
- I use 2 APIs:
  - Mods and Plugins: Modrinth API (using the modrinth collection downloader)
  - Server jars: MCjarfiles API

## Modrinth Colection ID
- Modrinth collection ID is meant for moded servers and is not mandatory.
  - The ID comes from the URL address, example:
  - https://modrinth.com/collection/ziTsdV9j
  - where the ID is: ziTsdV9j
- Modrinth autodownloader automatically installs server mods or plugins.
  - You need to enter a collection ID for it to work

## MCjarfiles API
- MCjarfiles API - an automatic way to install server jar file 
    - Can be used for: Vanilla, Fabric, Forge, Neoforge, Paper, Purpur and Velocity(Proxy).
    - Vanilla can only download releases, for alphas, betas and snapshots you have to use the manual install URL. 
    - Velocity always downloads the latest version(Warning!).
- Only supports Minecraft versions 1.8.8 and higher

## Manual Download
- There is a custom script that aids with the download and managment of MCserver content.
- Your are prompted with: Name of entry, URL, location to place content, Name of file.
- Name of file preloads a reccomended name, but is not limited to just .jar files.
  - Keep the server .jar file the same as the server name (ie dir name) to keep autostart features. 
- All manual download entries are stored the file manual-downloads.json located in the MCserver dir.
- Allows downloads from diferent sources based on URL. 
- Some URLs are however only for one version, thus you need to either update the URL, or get the latest:
  - Github: https://github.com/MCXboxBroadcast/Broadcaster/releases/latest/download/MCXboxBroadcastExtension.jar
  - Floodgate: https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/velocity

## Supported Loaders Overview
|                  | MCjarfiles API | Modrinth Colection Downloader |
|:----------------:|:--------------:|:-----------------------------:|
|      Vanilla     |        ✅       |               ✅               |
|       Paper      |        ✅       |               ✅               |
|      Purpur      |        ✅       |               ✅               |
|      Fabric      |        ✅       |               ✅               |
|       Forge      |        ✅       |               ✅               |
|     Neoforge     |        ✅       |               ✅               |
| Velocity (Proxy) |        ✅       |               ✅               |
|    Lightloader   |        ❌       |               ✅               |
|       Rift       |        ❌       |               ✅               |
|       Quilt      |        ❌       |               ✅               |
|      Spigot      |        ❌       |               ✅               |
|       Folia      |        ❌       |               ✅               |
|      Bukkit      |        ❌       |               ✅               |
|      Sponge      |        ❌       |               ✅               |

---

# Backup Servers
- Literally just this: https://codeberg.org/squidnose-code/Backups-RSYNC-TUI
- Manges MCserver backups.
- More Info in that section.

## Periodic Backups
- There 2 Types of periodic backups:
  - Mirror (Will overwrite the previous backup)
  - Timestamp (Will make another backup using timestamps)
- Allows for periodic backups on a: Daily, Weekly, Monthly bases. 

## Manual Backups
- You can also make a manual backup.
- You will be prompted to choose where to run the backup:
  - In the console you are running MCserverTUI in. (Simple)
  - Or in a Tmux window (Useful for big servers and long backups)

## Restore from backup
- You can also restore from a previous backup
  - The steps are very similar to the Manual setup
  - You just have to select what backups to restore from
  - It is advised to make a backups of the existing server before restoring from a previous backup. 

---

# Settings
- Settings and Logs 

## Logs
- Offers these log files to open:

|            Name            |                           Log Location                          |
|:--------------------------:|:---------------------------------------------------------------:|
|        MC-server-TUI       |          $HOME/.local/state/MCserverTUI/mcservertui.log         |
|   Periodic Rsync Backups   | $HOME/.local/state/Backups-RSYNC-TUI/rsync-periodic-backups.log |
| Manual Backups and Restore | $HOME/.local/state/Backups-RSYNC-TUI/rsync-manual-backups.log   |

## watch_java
- Lists all processes with the word "java" referenced.
- Literally just this command: 
 - watch -n 1 "ps -ef | grep java"

## crontab
- Crontab is used to start MCservers and Tunneling serivices.
- This script opens the crontab configuration file for manual intervention
- It asks for you to select a text editor
- opens user crontab using: crontab -e

## term_utils
- External terminal utilities that may be usefull
- Currently:

| ncdu |   Disk usage analisys  |
|:----:|:----------------------:|
|  nnn | Terminal file explorer |

- The utils open in ~/mcservers directory
- Or in a specific MCserver Directory when opened in Manage-Servers.sh


## Colors
- set-colors.sh
  - sets a color theme from presets
  - Uses newt colors as standard for whiptail
  - saves choice in colors.conf

---

# More Scripts
- modrinth-autodownloader.py 
  - Modrinth collection downloader in python. 
  - This is not my code, i used: https://github.com/aayushdutt/modrinth-collection-downloader
- modrinth-downloader.sh
  - modrith-downloader.sh is a TUI front for modrinth-autodownloader.py 
  - can recive --name or -n paramter
- server_properties_editor.sh
  - Edits server.properties of a MCserver
  - Does not make a new server.properties. This must be generated by the server jar. 
  - can recive --name or -n paramter


