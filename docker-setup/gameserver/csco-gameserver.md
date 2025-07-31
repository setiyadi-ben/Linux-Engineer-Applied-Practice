https://developer.valvesoftware.com/wiki/Counter-Strike_2/Dedicated_Servers
https://developer.valvesoftware.com/wiki/SteamCMD
<!-- # place the additional files to enable standard 5v5 competitive mode
# Soon -->
<!-- sudo cp /mnt/server.cfg /home/steam/.local/share/Steam/steamapps/Classic\ Offensive/csco/csgo/cfg
sudo cp /mnt/autoexec.cfg /home/steam/.local/share/Steam/steamapps/Classic\ Offensive/csco/csgo/cfg
sudo cp /mnt/motd.txt /home/steam/.local/share/Steam/steamapps/Classic\ Offensive/csco/csgo/cfg -->

### Tested on Debian 12 Bookworm Contabo VPS Server

<p>1. Create user steam with password and then install all required libraries.</p>

```
sudo useradd -m steam
sudo passwd steam
sudo apt update; sudo apt install software-properties-common; sudo apt-add-repository non-free; sudo dpkg --add-architecture i386; sudo apt update
sudo apt-get install lib32gcc-s1 -y
```
<p>2. Install steamcmd</p>

```
cd /home/steam
sudo apt-get install wget -y
sudo apt install screen -y
su - steam
mkdir ~/Steam && cd ~/Steam
wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz && tar -xvzf steamcmd_linux.tar.gz
./steamcmd.sh
steamcmd +login anonymous
```
<p>3. Copy your <b>"Classic Offensive.zip"</b> to /home/steam. If you don't have it download it from <a href="https://archive.org/download/classic-offensive">here.</a></p>

```
sudo apt update && sudo apt install unzip
sudo mv /home/steam/Classic\ Offensive.zip /home/steam/.local/share/Steam/steamapps
cd /home/steam/.local/share/Steam/steamapps
sudo unzip Classic\ Offensive.zip
sudo chmod -R 755 "/home/steam/.local/share/Steam/steamapps/Classic Offensive"
```
<p>4. Create script to host CSCO dedicated server.</p>

```
cd Classic\ Offensive
nano csco_dedicated-server_start.sh
```
```
./srcds_run -game cscomod\csgo -console -dedicated -tickrate 128 -usercon +game_type 0 +game_mode 1 +map de_mirage_csco +exec server.cfg -port 27015 +sv_setsteamaccount ADXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX +sv_pure 0
```
```
chmod +x csco_dedicated-server_start.sh
mkdir '/home/steam/.steam/sdk32/'
ln -s /home/steam/.local/share/Steam/steamcmd/linux32/steamclient.so /home/steam/.steam/sdk32/
```
<p>5. Run the server and make it keep running after shell closed.</p>

```
screen -S csco_server
./csco_dedicated-server_start.sh
```

```
screen -r csco_server
```