# MC Server TUI:
## A Simple TUI for Minecraft(Java) servers for Unix like OS
## Features:
- Runs best on Linux and BSD (Or any other OS that meats the dependencies)
- Setup and manage multiple MC(Minecraft) servers with very low resource usage. (Runs in terminal)
- Setup Wizard with all important settings (Version, Loader, Mods, Ram, Config and Autostart)
- Server Manager to reconfigure settings and import your existing MCservers
- Update server jar files and its mods/plugins
- Setup periodic backups of your MCserver
- Setup Reverse Proxies for Home server 
- The TUI resizes to the size of you console (For Mobile ssh client)
- Your MCservers will still run even if your remove MCserverTUI from your system. 
- MCserverTUI is only needed for Setting up and managing your MC server.
  
## Use Case
- Use on a VPS instead of "Minecraft Server Hosting" at a way lower cost (2.2x - 4.8x cheaper)
- Turn a old PC into a Minecraft server
- Use parts of the code to make something else (Modular Desighn)

## Knowledge
**Not recommended for tech newbies!**
- Requires knowlage about:
  - The architecture of [MCservers](https://minecraft.fandom.com/wiki/Tutorials/Setting_up_a_server).
  - Keybinds of nano or vim or less (You can choose). 
  - Keybinds of tmux (server console)
  - Firewalls and Ports

# Setup 
## Recommended distros
- The main deciding factor in recomending a good distro is the Java compatibility
- Not all distros have Older and Newer java version
- Minecraft uses Java: 8, 17, 21, 25
- Distros that have all of them are:
  - Ubuntu LTS (Tested)
  - Voidlinux (Tested)
  - Archlinux (Un-Tested)
  - FreeBSD (Tested)
- Hence they are recommended.
- If you need a diferent version of Java then the one provided by your distro, then install java manually. 

## setup.sh
- I highly recommended to install all your dependencies manually: 
- However you can also run **setup.sh**
- It will setup Dependencies and services for some linux distros.

```
./setup.sh
```

## Download and run the latest Git version:
```
git clone https://github.com/squidnose/MCserverTUI.git
cd MCserverTUI
./MC-Server-TUI.sh
```
- MCserverTUI doesn’t require a specific directory.

## MCserver scripts
- MC-Server-TUI.sh is the main menu for all functions in the form of scripts.
- Please read the: [[Docs]](https://github.com/squidnose/MCserverTUI/blob/main/scripts/Docs/)
  
# Details
## Color Themes
- MCserverTUI offers a range of color themes for the TUI 
- The default is "Matrix" black and green theme
- You can later change presets in settings

## File-Structure:
- When you first run MC-server-TUI.sh you will be prompted with 3 questions:

### Logging
- Optional logs
- Logs are time stamped 

|              File location ($HOME is your home dir)             |             Usage            |
|:---------------------------------------------------------------:|:----------------------------:|
|          $HOME/.local/state/MCserverTUI/mcservertui.log         |     From the TUI menu's      |
|  $HOME/.local/state/Backups-RSYNC-TUI/rsync-manual-backups.log  | Only from Manual backup jobs |
| $HOME/.local/state/Backups-RSYNC-TUI/rsync-periodic-backups.log | Only from periodic backups * |

*Logs from periodic backups are not effected by your initial choice. Logs can be either logged or not on a per backup bassses. 

### MCserver Dir
- Location of your MCservers
- Default location is:
```
$HOME/mcservers/(MCserver-name)
```
- can be changed in settings (Be carefull!)

### Backups Dir
- Location of MCserver Backups
- Default location is:
```
$HOME/Backups/mcservers/(MCserver-name)
```
- can be changed (Be carefull!)

### TUI Config file 
- To store your choices, there is a config file
- Stores variables for: loggs, mcdir, backups
- Fixed Location:
```
$HOME/.local/state/MCserverTUI/MCserverTUI.conf 
```
- can not be changed

### MC server config files
- There are files per MCserver that this script adds

| $HOME/mcservers/(MCserver-name)* |                       MCserver location                      |
|:--------------------------------:|:------------------------------------------------------------:|
|              run.sh              |    Run shortcut with the Ram amount with the nogui option    |
|           autostart.sh           |   Autostart script that runs run.sh in tmux window on boot.  |
|        server-version.conf       | Info about: MC version, MC Loader and Modrinth collection ID |
|       manual-downloads.json      |              List of all manual Download Entries             |

*The default path is shown as example

# Todo
- Custom FRP TUI for self hosted Tunneling
- Duplicate MCserver - Unsure if i want to implement (Because it seems like to much bloat)
- Showcase Videos:
  - 1. Motivation ("Selling it")
  - 2. Turn Old PC into MCserver (Vanilla and Tunneling)
  - 3. Java + Bedrock Crossplay MCserver (Fabric, Geyser, Flodgate)
  - 4. Modded MCserver (Forge+Create+Terrain Mods)
  - 5. MCserver Hub (Velocity+ Geyser+Floodgate+Via Version)
- Consistent Title - Title=Script name
- A memory selection script or document
- Be able to enter URL for colection ID and deduce the ID from the link
- Term utils for either mcdir or backups
- FIX rsyincTUI bug: Make the config file aswell for code maintanece.

# Disclaimer
- I used an LLM to help with the programming. 
- I understand the generated parts of the code.
- It is not a "Copy and Paste" slop script. 
