# New-Server.sh
- Explanations for new-server setup wizzard: 
  
## MC version
- MC version number
- Only supports releases
- eg: 1.16.5, 1.21.11

## Initialize MCserver
- Initialize server, runs the server without eula.txt being agreen apon
    - Generates conf files like server.properties, etc...
    - Doesnt generate the World

## Server.properties editor
-  Allows to change important server properties
    - Recommended reading: https://minecraft.fandom.com/wiki/Server.properties

## Memory
- Choose max and min memory that will be dedicated to the MCserver
  - you need to use either 1G or 1024M format (Example for 1 GB)
  - You dont need to enter any value, it works without it as well.(If you dont, it turns unstable)
- Min memory is good to ensure stability. 
    - Recommended making it 1/2 the max memory amount.
- Max memory needs to be high enough for a good experience, but low enough to not crash the server. 
    - If you are only running one minecraft server, leave at-least 1-2 GB free for the system. 

## Agree to Minecraft EULA
- Changes the parameter eula=false to eula=true
- By doing this you are agreeing to: https://www.minecraft.net/en-us/eula

## Automatic Start
- Automatic start on Reboot
  - Creates run.sh and autostart.sh (Located in the directory of your MCserver)
  - run.sh has stores the Memory amount and the Jarfile name.
  - Autostart runs run.sh in a tmux window on boot.
  - Adds crontab entry that automatically runs autostart.sh on boot.

## Run and Connect
- Run the MCserver console in a tmux window
- CTR+B, D to disconnect
