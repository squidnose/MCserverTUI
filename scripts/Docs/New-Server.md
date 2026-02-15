# New-Server.sh
- Walks you through the processes of setting up a new server

## MCserver Name
- Name you MC server
- You can later change the name without loosing features
    - However it will temporarily turn the MCserver off
    
## MC version
- MC version number
- Only supports releases
- eg: 1.16.5, 1.21.11

## Loader Type
- Currently best supported MC loader types are:
  - Vanilla
  - Fabric
  - Forge
  - Neoforge
  - Paper
  - Purpur
  - Velocity (Proxy)
  
## Modrinth Colection ID
- Modrinth ID (For mods, Not Manditory)
- If using a modded server, you will be offered to run the modrinth-collection-downloader

## Manual Downloader
- Manual Downloader allows for downloading files to a specific place in your MCserver directory
- Ment for .jar files, but is not limited by the .jar suffix

## Jarfile install method
- MCjarfiles only supports a certain amount of server.jar files
    - Vanilla, Paper, Purpur, Fabric, Forge, Neoforge, Velocity
- Manual allows you to download a specific version
    - for: Snapshots, MC older than 1.8.8, New or Experimental loaders

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
- changes the parameter eula=false to eula=true
- by doing this you are agreeing to: https://www.minecraft.net/en-us/eula

## Automatic Start
- Automatic start on Reboot
  - Creates run.sh and autostart.sh (Located in the directory of your MCserver)
  - run.sh has stores the Memory amount and the Jarfile name.
  - Autostart runs run.sh in a tmux window on boot.
  - Adds crontab entry that automatically runs autostart.sh on boot.

## Backups
- Setup automated backups for your MCserver
- More info in that section

## Run and Connect
- Run the MCserver console in a tmux window
- CTR+B, D to disconnect
