#============================ Functions List ============================
# load_vars # Load variables: Title, Config files and Log files
# change_conf_file # Menu to make new config file. For enableing/diableing logs and setting mcserver/backup locations.
# conf_file # Config file to read: Logging, mcservers and Backups Location. If not existing, run change_conf_file

#============================ Variables ============================
load_vars()
{
    SCRIPT_TITLE="MCserverTUI-26.11"
    TITLE="$SCRIPT_TITLE" # Set default value just in case

    # mcservertui
    LOGDIR_MCTUI="$HOME/.local/state/MCserverTUI" # Folder for logs and configs
    MCSERVERTUI_CONF="$LOGDIR_MCTUI/MCserverTUI.conf" # log or not, mcserver and backup locaitons
    NEWT_COLORS_FILE="$LOGDIR_MCTUI/colors.conf" # TUI colors
    LOGFILE_TUI="$LOGDIR_MCTUI/mcservertui.log" # Logs for the TUI menus

    # backups-rsync-tui
    LOGDIR="$HOME/.local/state/Backups-RSYNC-TUI" # Folder for logs and configs
    RSYNC_TUI_CONF="$LOGDIR/rsync-tui.conf" # log or not
    LOGFILE_CRON="$LOGDIR/rsync-periodic-backups.log" # Logs from periodic backups
    LOGFILE_MANUAL="$LOGDIR/rsync-manual-backups.log" # Logs from Manual and Restore backups
    LOGFILE_CRON_TMP="/tmp/Backups-RSYNC-TUI/rsync-periodic-backups.log" # Logs from dry-runs

    # Config
    BACKUP_SCRIPTS_DIR="$HOME/.local/share/Backups-RSYNC-TUI/backup-scripts" # periodic backup sciprts
    mkdir -p "$LOGDIR" ## Directory for Logs and Config files

} #load_vars()

#============================ Change Config File ============================
change_conf_file()
{
if whiptail --title "$TITLE - loggs" --yesno "Do you wish to have loggs enabled?" $HEIGHT $WIDTH; then
    loggs="true"
else
    loggs="false"
fi

mcdir=$(whiptail --title "$TITLE - mcdir" --inputbox \
    "Input the directory for your MCservers:" "$HEIGHT" "$WIDTH" "$HOME/mcservers" \
    3>&1 1>&2 2>&3) || exit 0

backups=$(whiptail --title "$TITLE - backups" --inputbox \
    "Input the directory for backups:" "$HEIGHT" "$WIDTH" "$HOME/Backups/mcservers" \
    3>&1 1>&2 2>&3) || exit 0

cat > "$MCSERVERTUI_CONF" <<EOF
loggs="$loggs"
mcdir="$mcdir"
backups="$backups"
EOF

## Make the direcotries
mkdir -p "$mcdir"
mkdir -p "$backups"
} #change_conf_file()

#============================ Config File ============================
conf_file()
{
    if [ -f "$MCSERVERTUI_CONF" ]; then
        source "$MCSERVERTUI_CONF"
    else
        change_conf_file
    fi

    ## Check if MCservers directory  exists
    if ! [ -d "$mcdir" ]; then
        whiptail --msgbox "$mcdir not found!\nWill re-run directory selection.\nThis could be a sign of coruption or Malice!!!" "$HEIGHT" "$WIDTH"
        change_conf_file
    fi
    ## Check if Backups directory exists
    if ! [ -d "$backups" ]; then
        whiptail --msgbox "$backups not found!\nWill re-run directory selection.\nThis could be a sign of coruption or Malice!!!" "$HEIGHT" "$WIDTH"
        change_conf_file
    fi
} #conf_file()

#============================ fold_tui ============================
fold_tui()
{
    local file="$1"
    local tmpfile
    tmpfile=$(mktemp)
    fold -s -w $((WIDTH-4)) "$file" > "$tmpfile"
    whiptail --title "$(basename "$file")" --textbox \
    "$tmpfile" "$HEIGHT" "$WIDTH" --scrolltext
    rm -f "$tmpfile"
}

#============================ pandoc_tui ============================
pandoc_tui()
{
    local file="$1"
    local tmpfile
    tmpfile=$(mktemp)
    pandoc -t plain "$file" | fold -s -w $((WIDTH-4)) > "$tmpfile"
    whiptail --title "$(basename "$file")" --textbox \
    "$tmpfile" "$HEIGHT" "$WIDTH" --scrolltext
    rm -f "$tmpfile"
}

