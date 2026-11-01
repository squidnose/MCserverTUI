#============================ Functions List ============================
# load_vars # Load variables: Title, Config files and Log files
# term_size # set TUI size to console size
# color_tui # Set color schemes for newt/whiptail
# error "Das Kaput!" # Error Mesage Handler
# echlog "Alles Gute" # Echo and/or Log into file
# conf_file # Load config file or make new one. For enableing/diableing logs.
# checks_deps # Check for dependencies: whiptail, rsync and crontab
# checks_dirs # Check if the OS has folder parameters set + finds script location
# "$(choose_editor)" README.MD # Choose editor for viewing/editing the docs
# input=+$(select_directory "/$HOME/Pictures/") # NNN file selection
# input_output=$(normalize_dir "$input_output") # Ensure directory path ends with a trailing slash for rsync
# SRC=$(normalize_dir "$SRC") # Ensure directory path ends with a trailing slash for rsync
# exited # Exit 0 with debug notice

#============================ Variables ============================
load_vars()
{
    SCRIPT_TITLE="RsyncTUI-26.11"
    TITLE="$SCRIPT_TITLE"
    LOGDIR="$HOME/.local/state/Backups-RSYNC-TUI" # Folder for logs and configs
    #Logs
    LOGFILE_TUI="$LOGDIR/rsync-tui.log" # Logs for the TUI menus
    LOGFILE_CRON="$LOGDIR/rsync-periodic-backups.log" # Logs from periodic backups
    LOGFILE_MANUAL="$LOGDIR/rsync-manual-backups.log" # Logs from Manual and Restore backups
    LOGFILE_CRON_TMP="/tmp/Backups-RSYNC-TUI/rsync-periodic-backups.log" # Logs from dry-runs
    # Config
    RSYNC_TUI_CONF="$LOGDIR/rsync-tui.conf" # log or not
    NEWT_COLORS_FILE="$LOGDIR/colors.conf" # TUI colors
    BACKUP_SCRIPTS_DIR="$HOME/.local/share/Backups-RSYNC-TUI/backup-scripts" # periodic backup sciprts
    mkdir -p "$LOGDIR" ## Directory for Logs and Config files
    mkdir -p "$BACKUP_SCRIPTS_DIR" ## Direcotory for periodic backup sciprts
} #load_vars()

#============================ Term Size ============================
term_size()
{
    ## Detect terminal size
    ### Incase tput is not found, sets to fixed value (edge case)
    TERM_HEIGHT=$(tput lines 2>/dev/null || echo 24)
    TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
    ## Set TUI size based on terminal size
    HEIGHT=$(( TERM_HEIGHT  ))
    WIDTH=$(( TERM_WIDTH  ))
    MENU_HEIGHT=$(( HEIGHT - 10 ))
    ## Example implementations
    ### use "$HEIGHT" "$WIDTH" for --inputbox --msgbox --yesno --infobox --passwordbox
    ### or "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" for --menu --checklist --radiolist --gauge
} #term_size()

#============================ Term Color ============================
color_tui()
{

    if [ -f "$NEWT_COLORS_FILE" ]; then
        export NEWT_COLORS_FILE
    else
    ## Set default color scheme
cat > "$NEWT_COLORS_FILE" <<EOF
# Matrix
root=,black
window=,black
title=brightgreen,black
border=green,black
textbox=brightgreen,black
button=black,green
compactbutton=green,black
listbox=green,black
actlistbox=black,brightgreen
helpline=green,black
roottext=brightgreen,black
EOF
    export NEWT_COLORS_FILE
    whiptail --title "$TITLE" --msgbox "Colors set to Matrix Green, you can later change this in settings" "$HEIGHT" "$WIDTH"
    fi
} #color_tui()

#============================ Error handle ============================
error()
{
    whiptail --title "⚠️!ERROR!⚠️ - $TITLE" --msgbox "$1" $HEIGHT $WIDTH
    echlog "⚠️!ERROR!⚠️ message: $1"
} #error()

#============================ Logs ============================
echlog()
{
    local msg="$*"
    echo "$msg"
    if [ "$loggs" == "true" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') $msg" >> "$LOGFILE_TUI"
    fi
} #echlog()

#============================ Config File ============================
conf_file()
{

    if [ -f "$RSYNC_TUI_CONF" ]; then
        source "$RSYNC_TUI_CONF"
    else

        if whiptail --title "$TITLE - Logging" --yesno "Do you wish to have loggs enabled?" $HEIGHT $WIDTH; then
            loggs="true"
        else
            loggs="false"
        fi

cat > "$RSYNC_TUI_CONF" <<EOF
loggs="$loggs"
EOF
    fi
} #conf_file()

#============================ Dependency Checks ============================
checks_deps()
{
    # whiptail
    if ! command -v whiptail >/dev/null 2>&1; then
        echo "Please install the Newt package for whiptail menu support!!!"
        exit 1
    # rsync
    elif ! command -v rsync >/dev/null 2>&1; then
        echo "Please install rsync..."
        exit 1
    fi
    # crontab
    if ! command -v crontab >/dev/null 2>&1; then
        error "Crontab not installed or enabled, this will limit functionality!!!"
    fi
} #checks_deps()

#============================ Direcotory checks ============================
checks_dirs()
{
    # Checking if $HOME parameter is set by OS
    if [ -z "$HOME" ]; then
        error "Your Operating System did not set the \$HOME parameter, please set it..."
        exit 1
    fi

    # Finds out where the script is located
    SCRIPT_DIR="$(dirname "$(realpath "$0")")"
    if [ -z "$SCRIPT_DIR" ]; then
        error "This script has no idea where it is.\n you will have to find a way to get dirname and realpath to work on your OS"
        exit 1
    fi
} #checks_dirs()

#============================ Text Editors/Viewers ============================
choose_editor()
{
    whiptail --title "Choose editor - $TITLE" --menu "Select editor:" $HEIGHT $WIDTH $MENU_HEIGHT \
        less        "Simple, read only (q to quit)" \
        nano        "Simple terminal editor (CTR+X to quit)" \
        mdr         "Simple Terminal Markdown Reader (q to quit)" \
        vim         "Advanced terminal editor (No one knows how to quit)" \
        kate        "KDEs graphical notepad" \
        mousepad    "XFCEs graphical notepad" \
        3>&1 1>&2 2>&3
} #choose_editor()

#============================ File Selector NNN ============================
select_directory()
{
    ## Take from input where to start or set to $HOME
    if [ -d "$1" ]; then
        local START_DIR="$1"
    else
        local START_DIR="$HOME"
    fi
    ## Inform the user on how to use it
    whiptail --title "Select File or Directory - $TITLE" --msgbox \
    "Directory selection controls:

    Enter       : open directory
    left arrow  : go back a directory
    right arrow : go forward a directory
    Space       : select directory
    q           : confirm selection

    You will now enter the directory browser." \
    "$HEIGHT" "$WIDTH" 3>&1 1>&2 2>&3 || return 0
    ## Create a temporary file to store the selected path
    local TMPFILE
    TMPFILE=$(mktemp)
    ## d - open directories only (no file selection)
    ## Q - quit automatically after selection
    ## -p "$TMPFILE" - tells nnn to write the selected path into this file when exiting
    NNN_OPTS="dQ" nnn -p "$TMPFILE" "$START_DIR"
    ## If content exists then output it:
    [ -s "$TMPFILE" ] && cat "$TMPFILE"
    ## Remove the tmp file
    rm -f "$TMPFILE"
} #select_directory()

#============================ Normalize Dir ============================
normalize_dir()
{
    local dir="$1"
    [[ "$dir" != */ ]] && dir="${dir}/"
    echo "$dir"
} #normalize_dir()

#============================ Exit 0 debug ============================
exited()
{
    echlog "exited out of $TITLE mid script"
    echlog "=========================================="
    exit 0
} #exited()
