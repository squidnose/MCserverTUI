# How to use Backup Rsync TUP
- The code is from https://codeberg.org/squidnose-code/Backups-RSYNC-TUI
- Backup-MC-Servers.sh is a custom script to use Backup-RSYNC-TUI

---

# New Backup
A wizard for creating **automatic rsync backups** that runs as cron jobs.

This script assumes you already know:
- what directories you want to back up
- where backups should be stored
- how cron scheduling works at a basic level
## Explanations
- Mirror backup - deletes previos backups in the destinatoin folder
- Time stamp - does not delete previos backups, instead it adds the date and time to the end of the name. 
- Mothly allows to enter what ever. But i would reccomend to set it to any whole number between 1 and 28.
    - Non-numeric values are technically allowed by cron, but dont do it:(
- Minutes are currently fixed to `00` (Do you really care???)
## Recomendations
- For a MC server i would reccomend setting up:
    - Daily Mirror backup
    - Weekly Mirror backup
    - Mothly Time stamped backup

---

# Manual
Run a **one-off backup** without creating any cron jobs.

## Features
- Uses the same source/destination logic as scheduled backups
- Backups the folder as /(backed up folder)/manual(date and time)

## Flow
- Select source directory
- Select destination directory
- Before running, offer a dry run to see what will be coppied over
- A dry run to see what files will be copied over
- Choose run mode:
  - **Normal** – runs in the current terminal
  - **tmux** – runs in a tmux session (recommended for large backups)

---

# Restore
- very similar code to manual backup
- copies over and restores the original name nad location (Unlike Manual)

---

# Logs
- Logs are stored in ~/.local/state/Backups-RSYNC-TUI/
- There are 2 diferent logs:
  - rsync-periodic-backups.log - Log output of periodic backups located in Cron 
  - rsync-manual-backups.log - Log outputs of Manual and Resotre scripts
