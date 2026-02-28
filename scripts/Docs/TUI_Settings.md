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
- This will list any java -jar -Xms... Minecraft servers running. 
    - But will also list it self as it also references java:)

## crontab
- Crontab is used to start MCservers and Tunneling serivices.
- It runs a custom crontab editor that allows you to remove selected lines. 
- If you wish to edit crontab using a text editor, use the command: crontab -e

## term_utils
- External terminal utilities that may be usefull
- Currently:

| ncdu |   Disk usage analisys  |
|:----:|:----------------------:|
|  nnn | Terminal file explorer |

- The utils open in ~/mcservers directory (or your chosen direcotory).

## Colors
- set-colors.sh
  - sets a color theme from presets
  - Uses newt colors as standard for whiptail
  - saves choice in ~/.local/state/MCserverTUI/colors.conf 
