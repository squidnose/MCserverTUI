# MC Server TUI:
## A Simple TUI for Minecraft(Java) servers on Linux and BSD.
## Features:
- Setup and manage multiple MC(Minecraft) servers with very low resource usage. (Runs in terminal)
- Setup Wizard with all important settings (Version, Loader, Mods, Ram, config and Autostart)
- Server Manager to reconfigure settings
- Update server jar files and its mods/plugins
- Setup periodic backups of your MCserver
- Setup Reverse Proxies for home server
- The TUI resizes to the size of you console
## Use Case
- Use on a VPS instead of "Minecraft Server Hosting" at a way lower cost (2.2x - 4.8x cheeper)
- Turn a old PC into a Minecraft server
- Use parts of the code to make something else:)
## Knowlage
- Not reccomended for tech noobies!
- Requires knowlage about
  - The architecture of [MCservers](https://minecraft.fandom.com/wiki/Tutorials/Setting_up_a_server).
  - Keybinds or nano or vim or less (You can choose). 
  - Keybinds of tmux
- The Goal of this TUI is Simplicity and robustness.
- It should work on any Linux or BSD distro, if the depencencies are met. 
- You dont need MCserverTUI to run your MC server. 
  - MCserverTUI is only needed for Setting up and managing your MC server.
  
# Details
## Dependencies
- [whiptail (newt package)](https://man.archlinux.org/man/whiptail.1.en) - For the menu system
- ncurses - includes tput that finds the terminal size (Not manditory)
- Crontab support, Tested with cronie and crond - For automation and server startup
- tmux - for MC server console
- python - for [Modrinth Colection Downloader](https://github.com/aayushdutt/modrinth-collection-downloader)
- curl and wget - to download minecraft server jar files 
- Text editor/viewer - mdr, nano, vim, less, kate, mousepad - for editing text files (Not manditory)
- nnn - File browser (Not manditory)
- ncdu - Disk Usage Analyzer (Not manditory)

## Java for Minecraft
- Diferent Minecraft versions uses diferent java versions:

| Java V. |     Minecraft V.    |
|:-------:|:-------------------:|
|  Java 8 | MC 1.16.5 and older |
| Java 17 |   MC 1.17 - 1.20.4  |
| Java 21 | MC 1.20.5 - 1.21.11 |
| Java 25 |  MC 26.1 and Newer  |

- Some mods/plugins require an older version of Java to operate, despite the MCserver using a newer one!
  - It is reccomended to install all java versions for maximum compatibility. 
- openjdk is usually used on Linux and BSD. Thus you will need to install:
  - openjdk8-jdk, openjdk17-jdk, openjdk21-jdk, openjdk25-jdk
  - You can also use JRE, but JDK is more comatible with mods/plugins.
- If you can not find the desired Java version in your distros repo, id reccomended this:
  - https://sdkman.io/install/
  - It manually installs Java 
  - May not be as secure as distro package

## Not required
- Does not require SystemD
- Can work on Glibc, Musl and BSD etc. (Not dependant on a specific libc) 
- Does not need a specific CPU architecture. (Limitations may be with some depencencies)

(Limitations are mostly with Openjdk and Tunneling services)
## File-Structure:
- Fixed MCserver location.

| ~/mcservers/(MCserver-name) |                      MCserver location                     |
|:---------------------------:|:----------------------------------------------------------:|
|            run.sh           |   Run shortcut with the Ram ammout with the nogui option   |
|         autostart.sh        | Autostart script that runs run.sh in tmux window on boot.  |
|     server-version.conf     | Info about: MC version, MC Loader and Modrith colection ID |

# Setup 
## Reccomended distros
- The main deciding factor in reccomending a good distro is the Java compatibility
- Not all distros have Older and Newever java version
- Minecraft uses Java: 8, 17, 21, 25
- The only distros that have all of them are:
  - Ubuntu LTS (Tested)
  - Voidlinux (Tested)
  - Archlinux
  - FreeBSD (Not Linux)
- Hence they are reccomended.
- If you need a diferent version of Java then the one provided by your distro, then install java manually. 

## Download and run the latest Git version:
```
git clone https://github.com/squidnose/MCserverTUI.git
cd MCserverTUI
./MC-Server-TUI.sh
```
- MCserverTUI doest require a specific directory, but do not place it in ~/mcservers!

## setup.sh
- Will setup Dependecnies and services for some linux distros.
- I higly reccomended to install all your depencencies manually.
- However you can also run **setup.sh**

```
./setup.sh
```
- Works well with Ubuntu, Voidlinux and Archlinux
- Other distros may lack Older or Newever openjdk versions.
  - Either manually install a .deb, .rpm package
  - Or use https://sdkman.io/install/

## MCserver scripts
- MC-Server-TUI.sh is the main menu for all functions in the form of scripts.
- [[Scripts and their functions]](https://github.com/squidnose/MCserverTUI/blob/main/scripts/01.Info-Main-Menu.md)


# Todo
- Manage more Reverse proxys (Playig.gg, ngrok, FRP)
  - Make crontabs for them with Tmux 
- LSR: Add file from URL button
- Add official Piston Data API (Kinda Hard)
- Add more store fronts like CurseForge and HangarPapermc (Kinda Hard)
- Duplicate MCerver Button
- Remove MCserver (Should i add it???)
- Showcase Videos:
  - 1. Motivation ("Selling it")
  - 2. Turn Old PC into MCserver (Vanilla and Tunneling)
  - 3. Java + Bedrock Crossplay MCserver (Fabric, Geyser, Flodgate)
  - 4. Modded MCserver (Forge+Create+Terrain Mods)
  - 5. MCserver Hub (Velocity+ Geyser+Floodgate+Via Version)

# Disclaimer
- I used an LLM to help with the programing. 
- I understand the generated code.
- It is not a "Copy and Paste" slop script. 
