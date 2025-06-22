# How to use these scripts:
A set of scripts for complete Docker management on Ubuntu systems, including installation, purge, and credential reset functionality.

## 📦 Files Included

1. `purge_docker.sh` - Complete Docker removal
2. `install_docker.sh` - Fresh Docker installation (with Desktop option)
3. `reset_pass_docker.sh` - Docker Desktop credential reset

## Procedures:

#### 1. First make them executable:
```sh
chmod +x purge_docker.sh
chmod +x install_docker.sh
chmod +x reset_pass_docker.sh
```
#### 2. Run the purge script:
```sh
./purge_docker.sh
```
#### 3. Reboot your system (recommended):
```sh
sudo reboot
```
#### 4. Before running the script below, download the latest distribution of [```DEB Package here```](https://docs.docker.com/desktop/setup/install/linux/ubuntu/) and run the installation script:

<p align="center"><img src="/image-files/docker-desktop-deb.png"></p>

Make sure the ```docker-desktop-amd64.deb``` in the same directory as ```install_docker.sh```.
```sh
./install_docker.sh
```
#### 5. When prompted "Would you like to install Docker Desktop?", press:
```y``` or ```Y``` to install Docker Desktop, any other key to skip Docker Desktop installation.

#### 6. Sign in to Docker requires pass initialization, so with that said you can execute this command after changing ```GPG_NAME``` and ```GPG_EMAIL``` inside ```reset_pass_docker.sh```.

<p align="center"><img src="/image-files/gpg-pass-init_docker.png"></p>

After that run the commands, below:
```
./reset_pass_docker.sh
```
