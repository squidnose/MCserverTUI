# MC Server TUI:
## A Simple TUI for Minecraft(Java) servers on linux.
## Features:
- Setup and manage multiple MCservers with very low resource usage. (Runs in terminal)
- Setup Wizard with all important settings (Version, Loader, Mods, Ram, config and Autostart)
- Server Manager to reconfigure settings
- Update server jar files and mods 
- Setup periodic backups of your MCserver
## Knowlage
- Not reccomended for tech noobies!
- Requires knowlage about
  - The architecture of [MCservers](https://minecraft.fandom.com/wiki/Tutorials/Setting_up_a_server).
  - Keybinds or nano or vim or less (You can choose). 
  - Keybinds of tmux
- The Goal of this TUI is Simplicity and robustness. It works on any linux distro if the depencencies are met. 
- You dont need MCserverTUI to run your MC server. 
  - MCserverTUI is only needed for Setting up and manageing your MC server.
## Dependencies
- [whiptail (newt package)](https://man.archlinux.org/man/whiptail.1.en) - For the menu system
- ncurses - includes tput that finds the terminal size
- Crontab support, Tested with cronie and crond - For automation and server startup
- tmux - for MC server console
- python - for [Modrinth Colection Downloader](https://github.com/aayushdutt/modrinth-collection-downloader)
- curl and wget - to download minecraft server jar files 
- Text editor/viewer - nano, vim, less, kate, mousepad - for editing text files
## Java for Minecraft
- Diferent Minecraft versoins uses diferent java versions.
  - Java 8  | MC 1.16.5 and older
  - Java 17 | MC 1.17 - 1.20.4
  - Java 21 | MC 1.20.5 - 1.21.11
  - Java 25 | MC 26.1 and Newer
- openjdk is mostly used on Linux for Java, you will thus need to install:
  - openjdk8-jdk, openjdk17-jdk, openjdk21-jdk, openjdk25-jdk
  - You can also use JRE, but JDK is more comatible with mods.

### Not required
- Does not require SystemD
- Can work on Glibc or Musl (Not dependant on any libc) 
- Does not need a specific CPU architecture 

(Limitations are with Openjdk and Tunneling services)
## File-Structure:
- ~/mcservers/<server_name> = MC server locations
  - run.sh | Run shortcut with the Ram ammout with the nogui option
  - autostart.sh | Autostart script with tmux commands
  - server-version.conf | MC version, Loader and Modrith colection ID

## How to use:
### Setup Dependencies:
- I higly reccomended to install all your depencencies manually
- However you can also run **setup.sh**
```
./setup.sh
```
- This works great for Voidlinux and Archlinux
- With other distros you may need to manually install:
  - Older or Newever openjdk versions
  - Nerd fonts symbols ttf
### Download and run the Git version:
```
git clone https://github.com/squidnose/MCserverTUI.git
cd MCserverTUI
./MCserverTUI.sh
```
- MCserverTUI doest require a specific directory, but do not place it in ~/mcservers!

(If you have placed MCserverTUI in ~ )
## What scripts to run?
### setup.sh
- Will setup Dependecnies and services for some linux distros.
- If your distro doesnt have a preset, you will have to manually instal depencencies.

### MCserverTUI.sh
- uses My [[Linux-Script-Runner]](https://codeberg.org/squidnose-code/Linux-Script-Runner)
- runs all script located in the scripts dirctory.

### MCserver scripts
[[Scripts and their functions]](https://github.com/squidnose/MCserverTUI/blob/main/scripts/0.info.md)

## Todo
- Manage All Reverse proxys (Playig.gg, ngrok)
  - Make crontabs for them with Tmux 
- Auto Update-System
- remove server
  - Should i add it???

# Disclaimer
- I used an LLM to help with the programing. 
- I understand the generated code.
- It is not a "Copy and Paste" slop script. 
