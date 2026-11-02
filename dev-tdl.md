# To put into library function
- validate memory input (re-write)
- start/stop mcserver (For new-server, mange-server and backups)
- Choose a server menu
- Colors chooser - re-witen to also apply to BackupsRsyncTUI

# TOTAL RE-DESIGHN
- Make the base MCserverTUI aprat of the repo. 
- Make BackupsRsyncTUI and Runneling services a module. 
- File structure:
    - MCserverTUI.sh
    - setup.sh (switch to Use Lbac )
    - scripts (The base scripts)
    - docs
    - modules
        - Backups-RSYNC-TUI
        - Tunneling serveices (New Repo)
        - System manager/updater (New Repo)
        - Cronutils Add/remove cronjobs (New Repo)
    - settings.sh
        - Add updater for MCserverTUI
            - Manage modules update aswell
        - 

