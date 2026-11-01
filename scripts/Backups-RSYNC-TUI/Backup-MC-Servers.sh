#!/usr/bin/env bash
# Backups-Rsync-TUI / MCserverTUI
# https://codeberg.org/squidnose-code/Backups-RSYNC-TUI
# https://github.com/squidnose/MCserverTUI
## Backup-MC-Servers.sh
set -euo pipefail
# A modified version of rsyncTUI.sh

#============================ Info ============================
# Features:
## Just selects a MC server to:
### Manually Backup
### Setup Periodic Backups
### Restore from Backups
### Manage existing Backups
### Change TUI settings and read logs

#============================ Initialization ============================
SCRIPT_DIR="$(dirname "$(realpath "$0")")" #neccery
source "$SCRIPT_DIR"/tui-lib.sh # Load Library of functions
load_vars # Load variables: Title, Config files and Log files
term_size # set TUI size to console size
color_tui # Set color schemes for newt/whiptail
conf_file # Load config file or make new one. For enableing/diableing logs.
checks_deps # Check for dependencies: whiptail, rsync and crontab
checks_dirs # Check if the OS has folder parameters set + finds script location
TITLE="MCserver Backup - $SCRIPT_TITLE"

#============================ MCserverTUI config ============================
MCSERVERTUI_CONF="$HOME/.local/state/MCserverTUI/MCserverTUI.conf"
# Load MCserverTUI config
if [ -f "$MCSERVERTUI_CONF" ]; then
    source "$MCSERVERTUI_CONF"
else
    echo "No MCserverTUI config file, please run MC-server-TUI.sh first!"
    exit 1
fi
# Parameters sourced from file:
MC_ROOT="$mcdir"
## Bakcups
MC_BACKUPS="$backups"
## $loggs for logs

#============================ Menu Functions ============================
# Specific backup selection, used by Restore and Manage backups
choose_backup_snapshot()
{
    # $BACKUP_DIR = $output_dir
    ## Build list of available backups
    BACKUP_ITEMS=()
    for d in "$BACKUP_DIR"/*; do
        [ -e "$d" ] || return 0
        NAME=$(basename "$d")
        BACKUP_ITEMS+=("$NAME" "Backup snapshot")
    done
    #$1 is "Restore from" or "Manage"
    SNAPSHOT=$(whiptail --title "Select Backup Snapshot - $TITLE" --menu "Choose a backup snapshot to $1:" \
    "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" "${BACKUP_ITEMS[@]}" 3>&1 1>&2 2>&3) || return 1
    echo "$SNAPSHOT"
} #choose_backup_snapshot()

# Select a backup script
select_backup_script()
{
    menu_options=() # Clear to prevent menu duplication:)
    # Locate backup scripts (Inspired by LSR)
    items=$(find "$BACKUP_SCRIPTS_DIR" -maxdepth 1 -mindepth 1 -name "${SERVER_NAME}*" | sort)
    while read -r item; do
        item_name=$(basename "$item")
        case "$item_name" in
            *.sh)
                menu_options+=("$item_name" "Backup Script")
                ;;
            *) ;;
        esac
    done <<< "$items"
    backup_name=$(whiptail --title "$TITLE" --menu "Choose what Backup script to modify" \
    "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" "${menu_options[@]}" 3>&1 1>&2 2>&3) || return 1

    # Read backup script
    script_path="$BACKUP_SCRIPTS_DIR/$backup_name"
    if [ -f "$script_path" ]; then
        # set default values
        excludes="" # Im unsure if this is neccery
        # Extract variables from the script file
        input=$(grep -E '^input=' "$script_path" | cut -d'"' -f2)
        output_dir=$(grep -E '^output_dir=' "$script_path" | cut -d'"' -f2)
        mode=$(grep -E '^mode=' "$script_path" | cut -d'"' -f2)
        period=$(grep -E '^period=' "$script_path" | cut -d'"' -f2)
        prune=$(grep -E '^prune=' "$script_path" | cut -d'"' -f2)
        logs=$(grep -E '^logs=' "$script_path" | cut -d'"' -f2)

        # Extract and parse the cronline string (22 12 25 * * sh -c etc...)
        cron_line_val=$(grep -E '^cronline=' "$script_path" | cut -d'"' -f2)

        # Split cron fields into positional variables: MIN HOUR DOM MON DOW CMD
        read -r minutes hour month_day cron_mon week_day cron_cmd <<< "$cron_line_val"

        # for compatibility sake
        BACKUP_DIR="$output_dir"
    else
        error "Selected script file does not exist."
        return 1
    fi
} #select_backup_script()

run_periodic_backups()
{
    "$SCRIPT_DIR/Periodic-Rsync-Backup.sh" \
        -n "$backup_name" \
        -i "$input" \
        -o "$output_dir" \
        -t "$mode" \
        -p "$period" \
        -r "$prune" \
        -l "$logs" \
        -s "$minutes" \
        -h "$hour" \
        -m "$month_day" \
        -w "$week_day"
} #run_periodic_backups()

#============================ 1. Menu ============================
MENU_ITEMS=()
for d in "$MC_ROOT"/*; do
    [ -d "$d" ] || continue
    NAME=$(basename "$d")
    MENU_ITEMS+=("$NAME" "Minecraft server")
done

SERVER_NAME=$(whiptail --title "Choose Server - $TITLE" --menu "Select a server to Configure backups of" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
    "${MENU_ITEMS[@]}" 3>&1 1>&2 2>&3) || exit 0

SERVER_DIR="$MC_ROOT/$SERVER_NAME"
BACKUP_DIR="$MC_BACKUPS/$SERVER_NAME"
echo "$MC_BACKUPS"
echo "$BACKUP_DIR"
#============================ Main Menu ================================
while true; do
    CHOICE=$(whiptail --title "Choose Backup Options - $TITLE" --menu "Select an action for $SERVER_NAME:" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
        info        "ℹ️ Help - How does this work?" \
        new_backup  "➕ Setup a new Periodic Backup for $SERVER_NAME" \
        change      "✏️ Change Periodic Backup settings for $SERVER_NAME" \
        manual      "🛠️ Run a manual backup of $SERVER_NAME" \
        restore     "🔄 Restore from previous backup of $SERVER_NAME" \
        manage      "⚙️ Backup Retention and Compression of $SERVER_NAME" \
        go_back     "X Go back .." \
        3>&1 1>&2 2>&3) || break

case "$CHOICE" in
    info) #ℹ️
        EDITOR=$(choose_editor) || continue
        echlog "Opening info.md Documentation using $EDITOR"
        "$EDITOR" "$SCRIPT_DIR/How-To-Backup.md"
    ;;
    change) #✏️
        select_backup_script || continue
        # In case user hits cancel
        if [ ! $backup_name ]; then
            continue
        else
            run_periodic_backups
        fi
    ;;
    new_backup) #➕
        while true; do
            backup_name=$(whiptail --title "Backup Name - $TITLE" --inputbox \
            "What will be the name of the new backup?\n\nThe Final name will be $SERVER_NAME-<what you type here>.sh" \
            "$HEIGHT" "$WIDTH" 3>&1 1>&2 2>&3) || break
            # Check if no name inputed
            if [ "$backup_name" == "" ]; then
                    error "You cant have and empty name!"
            fi
            # Check if or allready exists
            if [ -f  "$BACKUP_SCRIPTS_DIR/$SERVER_NAME-$backup_name" ] || [ -f  "$BACKUP_SCRIPTS_DIR/$SERVER_NAME-$backup_name.sh" ]; then
                error "Name allready exists, type in a new one!"
            else
                [[ "$backup_name" != *.sh ]] && backup_name="${SERVER_NAME-$backup_name}.sh" # Add .sh to make it a script
                "$SCRIPT_DIR/Periodic-Rsync-Backup.sh" -n "$backup_name" -i "$SERVER_DIR" -o "$BACKUP_DIR"
                break
            fi
        done
    ;;
    manual) "$SCRIPT_DIR/Manual-Rsync-Backup.sh" -i "$SERVER_DIR" -o "$BACKUP_DIR" ;; #📂
    restore)
        #Ask to do a manual backup before restoration
        if whiptail --title "Manual Backup before restoration  - $TITLE" --yesno \
        "Restoring from backup will delete the existing contens of $SERVER_DIR

        Do you wish to run a manual backup before you restore from backup?" \
        "$HEIGHT" "$WIDTH"; then
            "$SCRIPT_DIR/Manual-Rsync-Backup.sh" -i "$SERVER_DIR" -o "$BACKUP_DIR"
        whiptail --title "$TITLE" --msgbox \
        "You have now made a Manual backup of the existing contents of $SERVER_DIR
        You will now setup a Restoration from a backup snapshot" $HEIGHT $WIDTH
        fi

        # Choose backup snapshot
        SRC=$BACKUP_DIR/$(choose_backup_snapshot "Restore From") || continue
        # If the functions returns nothing, presume no backups found
        if [ -z "$SRC" ]; then
            whiptail --title "$TITLE" --msgbox "You did not choose a Backup!\n(Or no backup snapshots found)" \
            "$HEIGHT" "$WIDTH"
            continue
        fi
        # Run backup retore
        "$SCRIPT_DIR/Restore-Rsync-Backup.sh" -i "$SRC" -o "$SERVER_DIR"
    ;;
    manage)
        SRC=$BACKUP_DIR/$(choose_backup_snapshot "Manage") || continue
        ## If the functions returns nothing, presume no backups found
        if [ -z "$SRC" ]; then
            whiptail --title "$TITLE" --msgbox "You did not choose a Backup!\n(Or no backup snapshots found)" \
            "$HEIGHT" "$WIDTH"
            continue
        fi
        "$SCRIPT_DIR/Backup-Manager.sh" -i "$SRC"
    ;;
    *) break ;;
esac
done
exit 0
