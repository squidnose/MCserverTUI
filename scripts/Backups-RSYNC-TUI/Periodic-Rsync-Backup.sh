#!/usr/bin/env bash
# Backups-Rsync-TUI
# https://codeberg.org/squidnose-code/Backups-RSYNC-TUI
## Periodic-Rsync-Backup.sh
set -euo pipefail
#============================ Info ============================
# Features:
## Change Settings of a Peridic Cron backup
### Input/Output folder, Time Period, Pruning, Files to exclude and wheter to Log(Reccomended)
## Enable/Disable backup in cron
## Test if created backup script works (Dry run or Manual run outside period)

#============================ Initialization ============================
SCRIPT_DIR="$(dirname "$(realpath "$0")")" # Find script location
source "$SCRIPT_DIR"/lib-rsync-tui.sh # Load Library of functions
load_vars # Load variables: Title, Config files and Log files
term_size # set TUI size to console size
color_tui # Set color schemes for newt/whiptail
conf_file # Load config file or make new one. For enableing/diableing logs.
checks_deps # Check for dependencies: whiptail, rsync and crontab
checks_dirs # Check if the OS has folder parameters set
TITLE="Main Menu - $SCRIPT_TITLE"

#============================ Config ============================
## Backup variables
name="" # Name of backup script file located in $BACKUP_SCRIPTS_DIR
input="" # Input file or direcotry parsed from -i flag
output_dir="" # Output directory parsed from -o flag
mode="" # Operation mode (mirror, timestamp_link, timestamp)
period="" # Period of operation (hourly, daily, weekly, monthly)
minutes="" # Minutes of the Hour to backup (0-60 integers)
hour="" # Hour of backup (00-23 integers)
week_day="" # Day of the Week (0-6 integers)
week_day_name="" # Day of the week (English)
month_day="" # Day of the month (1-28 integers)
logs="" # Make logs (true or false)
time_display="" # Time displayed in plain english (String)
prune="0" # Backup pruning - How many backups to keep - 0 means no pruning (Integers)

#============================ Parsed CLI flags ================================
while getopts ":n:i:o:t:s:h:m:w:p:r:l:" opt; do
    case "$opt" in
        n) name="$OPTARG" ;;
        i) input="$OPTARG" ;;
        o) output_dir="$OPTARG" ;;
        t) mode="$OPTARG" ;;
        s) minutes="$OPTARG" ;;
        h) hour="$OPTARG" ;;
        w) week_day="$OPTARG" ;;
        m) month_day="$OPTARG" ;;
        p) period="$OPTARG" ;;
        r) prune="$OPTARG" ;;
        l) logs="$OPTARG" ;;
        *) echo "Invalid option" ;;
    esac
done

#============================ Excludes Files ================================
excludes=()
exclude_file="${BACKUP_SCRIPTS_DIR}/$name.exclude"
read_exclude_file()
{
# Read lines from file into the array
while IFS= read -r line; do
    excludes+=("$line")
done < "$exclude_file"
} #read_exclude_file()
# initial read
if [ -f "$exclude_file" ]; then
   read_exclude_file
fi

#============================ Helper Functions ============================
# Create cronline
create_cronline()
{
    # Default cron parameters
    cron_min="${minutes:-0}"
    cron_hour="${hour:-0}"
    cron_dom="*"
    cron_mon="*"
    cron_dow="*"

    case "$period" in
        hourly) cron_min="$minutes"; cron_hour="*" ;;
        daily)  cron_min="$minutes"; cron_hour="$hour" ;;
        weekly) cron_min="$minutes"; cron_hour="$hour"; cron_dow="$week_day" ;;
        monthly) cron_min="$minutes"; cron_hour="$hour"; cron_dom="$month_day" ;;
    esac

    script_target_path="$BACKUP_SCRIPTS_DIR/$name"
    mkdir -p "$BACKUP_SCRIPTS_DIR"
    mkdir -p "$(dirname "$LOGFILE_CRON")"

    CRONLINE="$cron_min $cron_hour $cron_dom $cron_mon $cron_dow /bin/bash $script_target_path"

} #create_cronline()

# Check if crontab entry is installed
crontab_possible_action()
{
    # Check if the crontab currently contains this script's path
    if crontab -l 2>/dev/null | grep -q "$script_target_path"; then
        echo "DISABLE"
    else
        echo "ENABLE"
    fi
} #crontab_possible_action()

#============================ Menu Functions ============================
# Input or Output directory Selection menu
input_output_select()
{
    # Select input method
    input_selection_mode=$(whiptail --title "$1 Selection - $TITLE" --menu "Select an $1 file/directory using:" $HEIGHT $WIDTH $MENU_HEIGHT \
        nnn     "NNN File manager" \
        manual  "Manualy type $1 path" \
        3>&1 1>&2 2>&3)
    # If cancel, return previous value
    if [ ! $input_selection_mode ]; then
        echo "$2"
        return 0
    fi
    # NNN select
    text="Enter" # For the user to know if it is an enter or a confirmation
    local input_output="$2"
    if [ $input_selection_mode == nnn ]; then
        input_output=$(select_directory "$HOME")
        text="Confirm"
    fi
    # Manual select, runs even after nnn select (Confirmation logic)
    input_output=$(whiptail --title "$1 Selection - $TITLE" --inputbox "$text $1 Folder:" $HEIGHT $WIDTH "$input_output" \
        3>&1 1>&2 2>&3) || { echo "$2"; return 0; } # If cancel, return previos value
    input_output=$(normalize_dir "$input_output")
    echo "$input_output" # Return value from function
} #input_output_select()

# Backup mode Selection menu
mode_select()
{
whiptail --title "Backup Mode - $TITLE" --menu "Backup style:" $HEIGHT $WIDTH $MENU_HEIGHT \
    mirror          "Overwrite previos backup" \
    timestamp_link  "Keep timestamped backups with Hardlinks (saves space)" \
    timestamp       "Keep timestamped backups (For FAT32 and exFAT partitions)" \
    3>&1 1>&2 2>&3
} #mode_select()

# Backup period Selection menu
period_select()
{
whiptail --title "Schedule - $TITLE" --menu "Backup period:" $HEIGHT $WIDTH $MENU_HEIGHT \
    hourly  "Every hour" \
    daily   "Every day" \
    weekly  "Once a week" \
    monthly "Once a month" \
    3>&1 1>&2 2>&3
} #period_select()

# Universal Number Selector
## call: number_select min max "Text description"
number_select() {
    local min="$1"
    local max="$2"
    local text="$3"
    local menu_options=()
    local i formatted
    for ((i=min; i<=max; i++)); do
        # Automatically pad numbers with a leading zero if max >= 10 and the number is a single digit
        if (( max >= 10 && i < 10 )); then
            formatted=$(printf "%02d" "$i")
        else
            formatted="$i"
        fi
        menu_options+=("$formatted" "")
    done
    whiptail --title "Selection - $TITLE" --menu "$text" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
    "${menu_options[@]}" 3>&1 1>&2 2>&3
}

# Day selection menu
day_select()
{
whiptail --title "Day Selection - $TITLE" --menu "Select day of week:" \
    "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
    0 "Sunday" \
    1 "Monday" \
    2 "Tuesday" \
    3 "Wednesday" \
    4 "Thursday" \
    5 "Friday" \
    6 "Saturday" \
    3>&1 1>&2 2>&3
} #day_select()

# View files that will be excluded
view_file_exceptions()
{
    local current_display="No exclusions added yet."
    if [ "${#excludes[@]}" -gt 0 ]; then
        current_display="Current exclusions:"
        for item in "${excludes[@]}"; do
            current_display+=$'\n'" - $item"
        done
    fi
    whiptail --title "List of Backup Exclusions - $TITLE" --msgbox "$current_display" "$HEIGHT" "$WIDTH"
} #view_file_exceptions()

# Exclude Selection Menu
exclude_select() {
    while true; do
        action=$(whiptail --title "Exclusions - $TITLE" --menu "Current exclusions: ${#excludes[@]} added\n\nChoose an action:" \
        "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
        "add_nnn"       "➕ Add directory/file(s) using NNN" \
        "add_manual"    "⌨️ Type path manually" \
        "view"          "👁️ View what has been selected so far" \
        "clear"         "🔄 Clear all exclusions" \
        "save"          "💾 Save Exclusions to File" \
        "discard"       "❌ Discard changes to Exclusions" \
        3>&1 1>&2 2>&3) || break
        case "$action" in
            add_nnn)
                selected=$(select_directory "$input")
                # Save the select in a format for rsync
                if [ -n "$selected" ]; then
                    while IFS= read -r path; do
                        if [ -n "$path" ]; then
                            # Removes the $/home/... path for rsync
                            relative_path="${path#$input}"
                            relative_path="${relative_path#/}"
                            excludes+=("$relative_path")
                        fi
                    done <<< "$selected"
                fi
            ;;
            add_manual)
                manual_path=$(whiptail --title "Manual Exclusion - $TITLE" --inputbox "Enter a relative path to exclude:\n\neg: logs/" \
                "$HEIGHT" "$WIDTH" "" 3>&1 1>&2 2>&3)
                if [ -n "$manual_path" ]; then
                    excludes+=("$manual_path")
                fi
            ;;
            view)
                view_file_exceptions
            ;;
            clear)
                excludes=()
                whiptail --title "Exclusions - $TITLE" --msgbox "All exclusions cleared." "$HEIGHT" "$WIDTH"
            ;;
            save)
                # Save the Exclude File
                > "$exclude_file" # Clear/Initialize file
                for item in "${excludes[@]}"; do
                    echo "$item" >> "$exclude_file"
                done
                break
            ;;
            *)
                # Treat any other input as discard changes and reload exlusions from file
                if [ -f "exclude_file" ]; then
                    read_exclude_file
                fi
                break
            ;;
        esac
    done
} #exclude_select

#============================ Checks ================================
if [ -z "$name" ]; then
    # Name
    name=$(whiptail --title "$TITLE" --inputbox "Backup Script to make:\n\n!If you wish to change the settings, run rsyncTUI.sh instead!" $HEIGHT $WIDTH \
    3>&1 1>&2 2>&3) || exit 0
fi

script_target_path="$BACKUP_SCRIPTS_DIR/$name" # For crontab cheking

#============================ Main Menu ================================
while true; do
    # Human readable time
    case $period in
        monthly) time_display="$period on the $month_day day at $hour:$minutes" ;;
        weekly) time_display="$period on $week_day_name's at $hour:$minutes" ;;
        daily) time_display="$period at $hour:$minutes" ;;
        hourly) time_display="Hourly every $minutes minutes" ;;
    esac
    # Detect possible action with crontab
    current_crontab_possible_action=$(crontab_possible_action)
    # Actual main menu
    menu=$(whiptail --title "$name - $TITLE" --menu "Backup settings" $HEIGHT $WIDTH $MENU_HEIGHT \
    1       "📁 Item to Backup - $input" \
    2       "🎯 Folder to Backup to - $output_dir" \
    3       "🔄 Type of Backup - $mode with $prune pruning" \
    4       "⏰ Period of Backup - $time_display" \
    5       "🚫 Exclude files from Backup (${#excludes[@]})" \
    6       "📜 Logs of Backup - $logs" \
    7       "✅ Save and Install Backup" \
    8       "🚗 Test run - Try out Backup" \
    9       "⏱️ $current_crontab_possible_action Backup execution" \
    back    "↩️ .. go back" \
    3>&1 1>&2 2>&3) || break
    case "$menu" in
    1) input=$(input_output_select Input "$input") ;;
    2) output_dir=$(input_output_select Output "$output_dir") ;;
    3)
        mode=$(mode_select) || continue
        # Pruning
        if [ $mode == "timestamp" ] || [ $mode == "timestamp_link" ]; then
            prune=$(whiptail --title "Pruning - $TITLE" --inputbox "How many backups do you want to keep?\n0 Means dont prune, ie keep all backups." "$HEIGHT" "$WIDTH" "$prune" \
            3>&1 1>&2 2>&3) || (prune="0" && continue)
        else
            prune=0
        fi
    ;;
    4)
        period=$(period_select) || continue
        case $period in
        monthly)
            while true; do
                month_day=$(number_select 1 31 "At what day of the month?") || continue
                if [ "$month_day" -gt "28" ]; then
                    # Ask if you really want a number higher than 28
                    if whiptail --title "Day of Month - $TITLE" --yesno --defaultno \
                        "Days higher than 28 may wont work every month\n\nContinue despite warning?" "$HEIGHT" "$WIDTH"; then
                        break
                    fi
                else
                    break
                fi
            done
            week_day="" # Reset value
            week_day_name=""
            hour=$(number_select 00 23 "Hour of backup (24h format)") || continue
            minutes=$(number_select 00 59 "Run at which minute of the hour?") || continue
        ;;
        weekly)
            week_day=$(day_select) || continue
            month_day="" # Reset value
            hour=$(number_select 00 23 "Hour of backup (24h format)") || continue
            minutes=$(number_select 00 59 "Run at which minute of the hour?") || continue
            case "$week_day" in
                0) week_day_name="Sunday" ;;
                1) week_day_name="Monday" ;;
                2) week_day_name="Tuesday" ;;
                3) week_day_name="Wednesday" ;;
                4) week_day_name="Thursday" ;;
                5) week_day_name="Friday" ;;
                6) week_day_name="Saturday" ;;
                *) week_day_name="" ;;
            esac
        ;;
        daily)
            week_day="" # Reset value
            week_day_name=""
            month_day="" # Reset value
            hour=$(number_select 00 23 "Hour of backup (24h format)") || continue
            minutes=$(number_select 00 59 "Run at which minute of the hour?") || continue
        ;;
        hourly)
            week_day="" # Reset value
            week_day_name=""
            month_day="" # Reset value
            hour=""
            minutes=$(number_select 00 59 "Run at which minute of the hour?") || continue
        ;;
        *) continue ;;
        esac
    ;;
    5)
        # Check for input dir, because the directory needs to be relative
        [ -z "$input" ] && error "Input directory is not set!" && continue
        exclude_select
    ;;
    6)
    logs_choice=$(whiptail --title "Logging - $TITLE" --menu "Enable logging?" "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
        true    "Log backup output (recommended)" \
        false   "No logging" \
        3>&1 1>&2 2>&3) || continue
    # Only apply if user did not hit cancel
    if [ "$logs_choice" == "true" ] || [ "$logs_choice" == "false" ]; then
        logs="$logs_choice"
    fi
    ;;
    7)
        # Safety messures
        [ -z "$input" ] && error "Input directory is not set!" && continue
        [ -z "$output_dir" ] && error "Output directory is not set!" && continue
        [ -z "$mode" ] && error "Backup mode is not set!" && continue
        [ -z "$period" ] && error "Backup period is not set!" && continue
        [ -z "$prune" ] && error "Pruning is not set! (0 for no pruning)" && continue
        [ -z "$logs" ] && error "You have not enabled or diabled logs!" && continue

        # Create cronline
        create_cronline

        # View files that will be excluded, only if there are any:
        if [ "${#excludes[@]}" -gt 0 ]; then
            view_file_exceptions
        fi

         # Pruneing Text
        prune_text="$prune pruning"
        if [ "$prune" -gt 0 ]; then
            prune_text="Will keep $prune older backup(s)"
        else
            prune_text="Will Keep All backup(s)"
        fi

        # Confirmation
        if (whiptail --title "Confirmation - $TITLE" --backtitle "Install this Backup?" --yesno \
"=== Install the following cron job? ===
Backing up: $input

Backing up to: $output_dir

Backup Mode: $mode

Backup Period: $time_display

$prune_text

Excluding ${#excludes[@]} files

Logs are set to $logs

=== Debug ===
Crontab line:
$CRONLINE" "$HEIGHT" "$WIDTH" 3>&1 1>&2 2>&3); then
#  Save the Runner Script:
        cat << EOF > "$script_target_path"
#!/usr/bin/env bash
#DO NOT MODIFY -> Use Periodic-Rsync-Backup.sh to modify.
#Dry-run
dry_run=""
rsync_opt="-aAX"
logdir="$LOGDIR"
logfile="$LOGFILE_CRON"
while getopts "d" opt; do
    case "\$opt" in
        d)
            dry_run="--dry-run"
            rsync_opt="-aAv"
            logdir="/tmp/Backups-RSYNC-TUI"
            logfile="\$logdir/rsync-periodic-backups.log"
        ;;
        *) ;;
    esac
done
mkdir -p "\$logdir"
#Parameters
input="$input"
output_dir="$output_dir"
mode="$mode"
period="$period"
prune="$prune"
logs="$logs"
cronline="$CRONLINE"
# Exclusions
excludes_file="$BACKUP_SCRIPTS_DIR/$name.exclude"
excludes=""
[ -f "\$excludes_file" ] && excludes="--exclude-from=\$excludes_file"
# Helpers
if [ "\$mode" = "mirror" ]; then
    output="\${output_dir}\${period}"
elif [ "\$mode" = "timestamp" ]; then
    timestamp=\$(date +%Y-%m-%d_%H-%M)
    output="\${output_dir}\${period}-\${timestamp}/"
elif [ "\$mode" = "timestamp_link" ]; then
    timestamp=\$(date +%Y-%m-%d_%H-%M)
    output="\${output_dir}\${period}-\${timestamp}/"
fi
mkdir -p "\$output_dir"
# Backup Execution
if [ "\$logs" = "true" ]; then
    rsync_exit="0" #Set default exit code or rsync to 0
    echo "[\$(date)] Backup start | period=\$period | mode=\$mode | source=\$input | destination=\$output" >> "\$logfile"
    case \$mode in
        mirror)
            rsync \$rsync_opt \$dry_run \$excludes --delete "\$input" "\$output" >> "\$logfile" 2>&1 || rsync_exit=\$?
        ;;
        timestamp)
            rsync \$rsync_opt \$dry_run \$excludes "\$input" "\$output" >> "\$logfile" 2>&1 || rsync_exit=\$?
        ;;
        timestamp_link)
            output_previous=\$(find "\$output_dir" -maxdepth 1 -type d -name "\$period-*" | sort | tail -n 1)
            rsync \$rsync_opt \$dry_run \$excludes --link-dest "\$output_previous" "\$input" "\$output" >> "\$logfile" 2>&1 || rsync_exit=\$?
        ;;
    esac
    # Log explicit success or failure based on exit code
    if [ \$rsync_exit -eq 0 ]; then
        echo "[\$(date)] Backup SUCCESS | destination=\$output" >> "\$logfile"
    else
        echo "[\$(date)] Backup FAILED | Exit code: \$rsync_exit" >> "\$logfile"
    fi
else
    case \$mode in
        mirror)
            rsync \$rsync_opt \$dry_run \$excludes --delete "\$input" "\$output"
        ;;
        timestamp)
            rsync \$rsync_opt \$dry_run \$excludes "\$input" "\$output"
        ;;
        timestamp_link)
            output_previous=\$(find "\$output_dir" -maxdepth 1 -type d -name "\$period-*" | sort | tail -n 1)
            rsync \$rsync_opt \$dry_run \$excludes --link-dest "\$output_previous" "\$input" "\$output"
        ;;
    esac
fi
# Pruning
if [ -z "\$dry_run" ] && [ "\$mode" != "mirror" ] && [ "\$prune" -gt 0 ]; then
    backups=(\$(find "\$output_dir" -maxdepth 1 -type d -name "\$period-*" | sort))
    if [ "\${#backups[@]}" -gt "\$prune" ]; then
        oldest_backup="\${backups[0]}"
        if [ -n "\$oldest_backup" ] && [ "\$oldest_backup" != "\$output_dir" ] && [ -d "\$oldest_backup" ]; then
            if [ "\$logs" = "true" ]; then
                echo "[\$(date)] Automatic pruning removed: \$oldest_backup" >> "\$logfile"
            fi
            rm -rf "\$oldest_backup"
        fi
    fi
fi
EOF

        chmod +x "$script_target_path"

        ## Remove any existing cron entry for this specific script name to avoid duplicates
        (
            crontab -l 2>/dev/null | grep -v "$name" || true
            echo "$CRONLINE"
        ) | crontab -

        whiptail --title "Debug - $TITLE" --msgbox "Backup script saved and cron job installed\n\nBackup Script: $script_target_path\
        \n\nCronline: $CRONLINE" $HEIGHT $WIDTH
        fi
    ;;
    8)
    # Safety messures - Only run if the script exists
    if [ ! -f "$BACKUP_SCRIPTS_DIR/$name" ]; then
        error "Backup Script Does not Exist! You need to first Save and Intall it before you can test it!"
        continue
    fi

    test_run=$(whiptail --title "Test Run - $TITLE" --menu "How would you like to test the backup?" \
    "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
    "dry_run"       "Get a overview of what files could be coppied" \
    "manual"        "Run the backup out side the period" \
    3>&1 1>&2 2>&3) || break
    case $test_run in
        dry_run)
            LOGFILE_TMP="/tmp/Backups-RSYNC-TUI/rsync-periodic-backups.log"
            if [ -f "$LOGFILE_TMP" ]; then # Reset temporary logfile
                rm "$LOGFILE_TMP"
            fi
            # Run in drymode
            "$BACKUP_SCRIPTS_DIR/$name" -d
            cat "$LOGFILE_TMP" | less
            ;;
        manual) "$BACKUP_SCRIPTS_DIR/$name";;
    esac

    ;;
    9)
    # Safety messures - Only run if the script exists
    if [ ! -f "$BACKUP_SCRIPTS_DIR/$name" ]; then
        error "Backup Script Does not Exist! You need to first Save and Intall it before you can enable/disable it."
        continue
    fi

    create_cronline
    if [ "$current_crontab_possible_action" == "DISABLE" ]; then
        (
            crontab -l 2>/dev/null | grep -v "$script_target_path" || true
        ) | crontab -
    elif [ "$current_crontab_possible_action" == "ENABLE" ]; then
        (
            crontab -l 2>/dev/null || true
            echo "$CRONLINE"
        ) | grep -v '^$'| crontab - # | grep -v '^$' removes empty lines
    else
        error "Unknow Crontab Status"
    fi
    ;;
    *)
        break
    ;;
esac
done

# Exit handleing - If the user made a .exclude file, but no script, offer to remove it
if [ ! -f "$BACKUP_SCRIPTS_DIR/$name" ] && [ -f "$exclude_file" ]; then
    if whiptail --title "Remove .exclude file? - $TITLE" --yesno "You made a .exclude file, but no script file\n\nDo you wish to remove $exclude_file?" \
    "$HEIGHT" "$WIDTH"; then
        rm "$exclude_file"
    fi
fi

exit 0
