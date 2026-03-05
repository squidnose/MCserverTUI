# Download Content
- MCserverTUI allows for Manual and Automatic MC jar file downloads.
- I use 2 APIs:
  - Mods and Plugins: Modrinth API (using the modrinth collection downloader)
  - Server jars: MCjarfiles API

## Modrinth Colection ID
- Modrinth collection ID is meant for moded servers and is not mandatory.
  - The ID comes from the URL address, example:
  - https://modrinth.com/collection/ziTsdV9j
  - where the ID is: ziTsdV9j
- Modrinth autodownloader automatically installs server mods or plugins.
  - You need to enter a collection ID for it to work

## MCjarfiles API
- MCjarfiles API - an automatic way to install server jar file 
    - Can be used for: Vanilla, Fabric, Forge, Neoforge, Paper, Purpur and Velocity(Proxy).
    - Vanilla can only download releases, for alphas, betas and snapshots you have to use the manual install URL. 
    - Velocity always downloads the latest version(Warning!).
- Only supports Minecraft versions 1.8.8 and higher

## Manual Download
- There is a custom script that aids with the download and managment of MCserver content.
- Your are prompted with: Name of entry, URL, location to place content, Name of file.
- You are not limited to just .jar files, but is preloaded(you can change it).
- Keep the server .jar file the same as the server name (ie dir name) to keep autostart features. 
- All manual download entries are stored the file manual-downloads.json located in the MCserver dir.
- Allows downloads from diferent sources based on URL. 
- Some URLs are however only for one version, thus you need to either update the URL, or get the latest:
  - Github: https://github.com/MCXboxBroadcast/Broadcaster/releases/latest/download/MCXboxBroadcastExtension.jar
  - Floodgate: https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/velocity

## Supported Loaders Overview
|                  | MCjarfiles API | Modrinth Colection Downloader |
|:----------------:|:--------------:|:-----------------------------:|
|      Vanilla     |        ✅       |               ✅               |
|       Paper      |        ✅       |               ✅               |
|      Purpur      |        ✅       |               ✅               |
|      Fabric      |        ✅       |               ✅               |
|       Forge      |        ✅       |               ✅               |
|     Neoforge     |        ✅       |               ✅               |
| Velocity (Proxy) |        ✅       |               ✅               |
|    Lightloader   |        ❌       |               ✅               |
|       Rift       |        ❌       |               ✅               |
|       Quilt      |        ❌       |               ✅               |
|      Spigot      |        ❌       |               ✅               |
|       Folia      |        ❌       |               ✅               |
|      Bukkit      |        ❌       |               ✅               |
|      Sponge      |        ❌       |               ✅               |

    (The manual downloader can download from enywhere)

