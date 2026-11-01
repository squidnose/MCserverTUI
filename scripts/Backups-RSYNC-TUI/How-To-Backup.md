# How to use Backup Rsync TUI

---

## rsyncTUI.sh
- Main Menu for the scripts:
  - info (Opens How-To-Backup.md)
  - change (runs Periodic-Rsync-Backup.sh)
  - new_backup (Runs Periodic-Rsync-Backup.sh)
  - manual (Runs Manual-Rsync-Backup.sh)
  - restore (Runs Restore-Rsync-Backup.sh)
  - manage (Runs Backup-Manager.sh)
  - settings (Runs Settings.sh)

### Backup-MC-Servers.sh
- Modified rsyncTUI used in my MCserverTUI script:
  - (https://github.com/squidnose/MCserverTUI)

---

## Periodic-Rsync-Backup.sh
- New Backup - Create a backup script that runs automatically.
- Change - Change backup settings of existing backup scripts.

### Explanations
- Mode - Type of backup:
  - mirror - Mirror, overwrites previous backup
  - timestamp_link - Adds a backup with a timestamp, Hard links previous backup data to save space (Does not work on FAT32 or exFAT!)
  - timestamp - Adds a backup with a timestamp (Works on any File System)
- Period, backup at:
  - hourly - Every Hour
  - daily - Every Day
  - weekly - Every Week
  - monthly - Every Month
- Logs:
  - Log output from backups or not
  - rsync-periodic-backups.log - Log output of periodic backups located in Cron 
  - rsync-manual-backups.log - Log outputs of Manual and Resotre scripts
- Pruning:
  - Backup retention - How many previos backups will be kept
  - Always the oldest backups get deleted. 
  - Setting this to 0 will disable pruning.
- Exclusion:
  - You can exclude files from being backed up
  - Saves in a separate file (name.sh.exclude)
- Backup execution:
  - Enable or Disable the execution of the created backup script
  - Adds or removes the cronline 

### Recommendations 
- For a Minecraft server I would recommend setting up theese backups:
  - Daily Mirrored 
  - Weekly Mirrored 
  - Monthly Timestamped (Ideally with link) 
- You should weight whether or not to prune, based on how big your server is.
- You should add a automatic stop job, that will turn off the server when the backup is performed

---

## Manual-Rsync-Backup.sh
Run a **one-off backup** without creating any cron jobs.

### Features
- Uses the same source/destination logic as scheduled backups
- Backups the folder as /(backed up folder)/manual(date and time)

### Flow
- Select source directory
- Select destination directory
- Before running, offer a dry run to see what will be coppied over
- A dry run to see what files will be copied over
- Choose run mode:
  - **Normal** – runs in the current terminal
  - **tmux** – runs in a tmux session (recommended for large backups)

---

## Restore-Rsync-Backup.sh
- Very similar code to manual backup.
- Copies over and restores the original name and location (Unlike Manual).
- Restore replaces the destination directory so that it exactly matches the selected backup snapshot.
  - That is why you are prompted to make a backup before restoring. 

---

## Backup-Manager.sh
- Size usage analysis (folder only)
- Rename backup
- Move backup
- Copy backup
- Remove backup
- Compress Backup (Archives only: .zip, .tar.xz, 7z)
- De-compress backup 

---

## Settings.sh (RsyncTUI Only)
- logs (Open logs located in: ~/.local/state/Backups-RSYNC-TUI/)
- watch_rsync (literally just this cmd: watch -n 1 "ps -ef | grep rsync")
- crontab_line (Runs crontab-line-by-line-editor.sh)
- crontab (Choose a editor to open crontab -e)
- logging (Saves loggs= true or false to rsync-tui.conf )
- colors (runs set-colors.sh)

(I made a typo, loggs instead of logs. But because I have it saved everywhere in my config files, I will call this a feature.... LOGGS as in the Log of a Great Script...)

---

## crontab-line-by-line-editor.sh  (RsyncTUI Only)
- Simply put, a checklist that allows to remove any lines in your crontab.
- Usefull for disabling backups globally.

---

# Info
- The code is from https://codeberg.org/squidnose-code/Backups-RSYNC-TUI

[Go back](https://codeberg.org/squidnose-code/Backups-RSYNC-TUI/src/branch/main/)
