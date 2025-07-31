https://developer.valvesoftware.com/wiki/Counter-Strike_2/Dedicated_Servers
https://developer.valvesoftware.com/wiki/SteamCMD

### Tested on Debian 12 Bookworm Contabo VPS Server

<p>1. Create user steam with password and then install all required libraries.</p>

```
sudo useradd -m steam
sudo passwd steam
sudo apt update; sudo apt install software-properties-common; sudo apt-add-repository non-free; sudo dpkg --add-architecture i386; sudo apt update -y
sudo apt-get install lib32gcc-s1 -y
```

<p>2. Install steamcmd.</p>

```
cd /home/steam
sudo apt-get install wget -y
sudo apt install screen -y
sudo apt install unzip
su - steam
mkdir ~/Steam && cd ~/Steam
wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz && tar -xvzf steamcmd_linux.tar.gz
./steamcmd.sh
steamcmd +login anonymous
app_update 740 +validate +quit
```

<p>3. Download CSGO Skinmods plugin and install.</p>

```
cd "/home/steam/.local/share/Steam/steamapps/common/Counter-Strike Global Offensive Beta - Dedicated Server/csgo"
ls -al
wget https://raw.githubusercontent.com/setiyadi-ben/cstrike-assets/main/csgo/csgo-skinmod.zip
unzip csgo-skinmod.zip
```

<p>4. Create script to host CSGO dedicated server.</p>

```
cd ..
nano csgo_dedicated-server_start.sh
```
```
./srcds_run -game csgo -dedicated -tickrate 128 +map de_mirage +game_type 0 +game_mode 0 -console -usercon -debug +sv_setsteamaccount ADXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```
<!-- ./srcds_run -game csgo -dedicated -tickrate 128 +map de_mirage +game_type 0 +game_mode 1 -console -usercon +exec server.cfg -port 27016 +sv_setsteamaccount 60533DAB98B23DC2E8CDE8725130DBFB -->
```
chmod +x csgo_dedicated-server_start.sh
mkdir '/home/steam/.steam/sdk32/'
ln -s /home/steam/.local/share/Steam/steamcmd/linux32/steamclient.so /home/steam/.steam/sdk32/
mv bin/libgcc_s.so.1 bin/old.libgcc_s.so.1
exit
```
<!-- sudo dpkg --add-architecture i386 && sudo apt update
sudo apt-get update && apt install -y gdb libcurl4:i386 lib32ncurses6 libtinfo6:i386 lib32stdc++6 lib32gcc-s1
cd /home/steam/.local/share/Steam/steamapps/common/Counter-Strike\ Global\ Offensive\ Beta\ -\ Dedicated\ Server
ls -al bin/libgcc_s.so.1
mv bin/libgcc_s.so.1 bin/old.libgcc_s.so.1

copy "mods" from local repository to vm/docker repository at
cd /home/steam/.local/share/Steam/steamapps/common/Counter-Strike\ Global\ Offensive\ Beta\ -\ Dedicated\ Server/csgo -->

<p>5. Modify the files to change the ownership.</p>

```
cd "/home/steam/.local/share/Steam/steamapps/common/Counter-Strike Global Offensive Beta - Dedicated Server/csgo"
sudo chown -R steam:steam "/home/steam/.local/share/Steam/steamapps/common/Counter-Strike Global Offensive Beta - Dedicated Server/csgo/addons"
sudo chown -R steam:steam "/home/steam/.local/share/Steam/steamapps/common/Counter-Strike Global Offensive Beta - Dedicated Server/csgo/cfg"
```

<!-- sudo usermod -aG sudo bennyjrx
cp /mnt/f/CSGO\ Backup/csgo-skinmods/mods /home/steam/.local/share/Steam/steamapps/common/Counter-Strike\ Global\ Offensive\ Beta\ -\ Dedicated\ Server/csgo

sudo cp -rv "/mnt/f/CSGO Backup/csgo-skinmods/mods/"* "/home/steam/.local/share/Steam/steamapps/common/Counter-Strike Global Offensive Beta - Dedicated Server/csgo" -->

<!-- cd /home/steam/.local/share/Steam/steamapps/common/Counter-Strike\ Global\ Offensive\ Beta\ -\ Dedicated\ Server/csgo/addons/sourcemod/configs
nano core.cfg
"FollowCSGOServerGuidelines"	"no"
"BlockBadPlugins"	"no" -->

<!-- mkdir /home/steam/.steam/sdk64/
ln -s /home/steam/.local/share/Steam/steamcmd/linux64/steamclient.so /home/steam/.steam/sdk64/ -->
<p>6. Run the server and make it keep running after shell closed.</p>

```
su - steam
cd "/home/steam/.local/share/Steam/steamapps/common/Counter-Strike Global Offensive Beta - Dedicated Server"
screen -S csgo_server
./csgo_dedicated-server_start.sh
```
```
screen -r csgo_server
```
<!-- edit in csgo
dir driveLettter:\SteamLibrary\steamapps\common\Counter-Strike Global Offensive\csgo
find steam.inf and edit
ClientVersion=2000258
ServerVersion=1575
PatchVersion=1.38.8.1
ProductName=csgo
appID=730
SourceRevision=8413246
VersionDate=Oct 12 2023
VersionTime=09:57:39


fixing
sudo apt update && sudo apt install libcurl4
sudo chown -R steam:steam "/home/steam/.local/share/Steam/steamapps/common/Counter-Strike Global Offensive Beta - Dedicated Server/csgo/addons"
sudo chmod -R 755 "/home/steam/.local/share/Steam/steamapps/common/Counter-Strike Global Offensive Beta - Dedicated Server/csgo/addons"

./srcds_run -game csgo -console -usercon +map de_mirage +sv_setsteamaccount ADB345D8F3C8D8018EFCB07BCF43A277

# cek installed plugin
sm plugins list -->