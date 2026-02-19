# MC Server TUI:
## A Simple TUI for Minecraft(Java) servers for Linux and BSD OS
## Features:
- Setup and manage multiple MC(Minecraft) servers with very low resource usage. (Runs in terminal)
- Setup Wizard with all important settings (Version, Loader, Mods, Ram, config and Autostart)
- Server Manager to reconfigure settings and import your existing MCservers
- Update server jar files and its mods/plugins
- Setup periodic backups of your MCserver
- Setup Reverse Proxies for Home server 
- The TUI resizes to the size of you console (For Mobile ssh client)

## Use Case
- Use on a VPS instead of "Minecraft Server Hosting" at a way lower cost (2.2x - 4.8x cheaper)
- Turn a old PC into a Minecraft server
- Use parts of the code to make something else (Free and Open Source Software)

## Knowledge
- Not recommended for tech newbies!
- Requires knowlage about
  - The architecture of [MCservers](https://minecraft.fandom.com/wiki/Tutorials/Setting_up_a_server).
  - Keybinds of nano or vim or less (You can choose). 
  - Keybinds of tmux (server console)
- The Goal of this TUI is Simplicity and robustness.
- It should work on any Linux or BSD distro, if the dependencies are met. 
- Your MCservers will still run even if your remove MCserverTUI from your system. 
  - MCserverTUI is only needed for Setting up and managing your MC server.
  
# Details
## Dependencies
- [whiptail (newt package)](https://man.archlinux.org/man/whiptail.1.en) - For the menu system
- ncurses - includes tput that finds the terminal size (Not mandatory)
- Crontab support, Tested with cronie and crond - For automation and server startup
- tmux - for MC server console
- python - for [Modrinth Colection Downloader](https://github.com/aayushdutt/modrinth-collection-downloader)
- curl and wget - to download minecraft server jar files 
- jq - for Manual Downloader
- Text editor/viewer - mdr, nano, vim, less, kate, mousepad - for editing text files (Not mandatory)
- nnn - File browser (Not mandatory)
- ncdu - Disk Usage Analyzer (Not mandatory)

## Java for Minecraft
- Different Minecraft versions uses different java versions:

| Java V. |     Minecraft V.    |
|:-------:|:-------------------:|
|  Java 8 | MC 1.16.5 and older |
| Java 17 |   MC 1.17 - 1.20.4  |
| Java 21 | MC 1.20.5 - 1.21.11 |
| Java 25 |  MC 26.1 and Newer  |

- Some mods/plugins require an older version of Java to operate, despite the MCserver using a newer one!
  - It is recommended to install all java versions for maximum compatibility. 
- openjdk is usually used on Linux and BSD. Thus you will need to install:
  - openjdk8-jdk, openjdk17-jdk, openjdk21-jdk, openjdk25-jdk
  - You can also use JRE, but JDK is more compatible with mods/plugins.
- If you can not find the desired Java version in your distros repo, id recommend this:
  - https://sdkman.io/install/
  - It manually installs Java 
  - May not be as secure as distro package

## Not required
- Does not require SystemD
- Can work on Glibc, Musl and BSD etc. (Not dependent on a specific libc) 
- Does not need a specific CPU architecture. (Limitations may be with some dependencies)

(Limitations are mostly with Openjdk and Tunneling services)
## File-Structure:
- Fixed MCserver location.

| ~/mcservers/(MCserver-name) |                       MCserver location                      |
|:---------------------------:|:------------------------------------------------------------:|
|            run.sh           |    Run shortcut with the Ram amount with the nogui option    |
|         autostart.sh        |   Autostart script that runs run.sh in tmux window on boot.  |
|     server-version.conf     | Info about: MC version, MC Loader and Modrinth collection ID |
|    manual-downloads.json    |              List of all manual Download Entries             |

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

## Download and run the latest Git version:
```
git clone https://github.com/squidnose/MCserverTUI.git
cd MCserverTUI
./MC-Server-TUI.sh
```
- MCserverTUI doesn’t require a specific directory, but do NOT place it in ~/mcservers!

## setup.sh
- I highly recommended to install all your dependencies manually.
- However you can also run **setup.sh**
- It will setup Dependencies and services for some linux distros.

```
./setup.sh
```
- Works well with Ubuntu and Voidlinux 
- Other distros may lack Older or Newer openjdk versions.
  - Either manually install a .deb, .rpm package
  - Or use https://sdkman.io/install/

## MCserver scripts
- MC-Server-TUI.sh is the main menu for all functions in the form of scripts.
- [[Docs]](https://github.com/squidnose/MCserverTUI/blob/main/scripts/Docs/)

# Todo
- Custom FRP TUI for self hosted Tunneling
- Duplicate MCserver - Unsure if i want to implement (Because it seems like to much bloat)
- Find Better Emojis/Symbols for TUI
- Showcase Videos:
  - 1. Motivation ("Selling it")
  - 2. Turn Old PC into MCserver (Vanilla and Tunneling)
  - 3. Java + Bedrock Crossplay MCserver (Fabric, Geyser, Flodgate)
  - 4. Modded MCserver (Forge+Create+Terrain Mods)
  - 5. MCserver Hub (Velocity+ Geyser+Floodgate+Via Version)
- MCserverTUI settings config
  - Enable/DIable Logging
  - Change mcservers Location

# Disclaimer
- I used an LLM to help with the programming. 
- I understand the generated code.
- It is not a "Copy and Paste" slop script. 
