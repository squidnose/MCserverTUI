# MC Server TUI:
## A Simple TUI for Minecraft(Java) servers on linux.
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
- opejnjdk8, 17 and 21 - for Minecraft (My script doesnt use it)
- Text editor/viewer - nano, vim, less, kate, mousepad - for editing text files
- nerd-fonts-otf - For symbols in main menu (Not mandatory)
### Not required
- Does not require SystemD
- Can work on Glibc or Musl 
- Does not need a specific CPU architecture 

(Limitations are with Openjdk and Tunneling services)
## File-Structure:
- ~/mcservers/<server_name> = MC server locations
  - run.sh | Run shortcut with the Ram ammout with the nogui option
  - autostart.sh | Autostart script with tmux commands
  - server-version.conf | MC version, Loader and Modrith colection ID

## How to use:
### Setup Dependencies:
- Either install all the depencencies or run setup.sh
```
./setup.sh
```
### Download and run the Git version:
```
git clone https://github.com/squidnose/MCserverTUI.git
cd MCserverTUI
./MCserverTUI.sh
```
- MCserverTUI doest require a specific directory, but do not place it in ~/mcservers!
### Run on SSH login
- You can add MCserverTUI.sh to your .bashrc
- This makes it automaticly open on login. (Easier, but less secure)
- DO THIS AT YOUR OWN RISK!:
```
cd MCserverTUI
./MC-Server-TUI.sh
```
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
- Manage Backups for all servvers located in ~/mcservers
  - One time manula backup
  - Setup Auto backup with crontab 
- Manage All Reverse proxys (Playig.gg, ngrok)
  - Make crontabs for them with Tmux 
- Auto Update-System
- remove server
  - Should i add it???

# Disclaimer
- I used an LLM to help with the programing. 
- I understand the generated code.
- It is not a "Copy and Paste" slop script. 
