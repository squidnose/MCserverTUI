# Dependencies
- realpath (coreutils package) - to find out script location
- [whiptail (newt package)](https://man.archlinux.org/man/whiptail.1.en) - For the menu system
- ncurses - includes tput that finds the terminal size (Not mandatory)
- Crontab support, Tested with cronie and crond - For automation and server startup
- tmux - for MC server console
- python - for [Modrinth Colection Downloader](https://github.com/aayushdutt/modrinth-collection-downloader)
- curl and wget - to download minecraft server jar files 
- jq - for Manual Entry Downloader 
- Text editor/viewer - mdr, nano, vim, less, kate, mousepad - for editing text files (You can Choose)
- nnn - File browser 
- ncdu - Disk Usage Analyzer 

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
