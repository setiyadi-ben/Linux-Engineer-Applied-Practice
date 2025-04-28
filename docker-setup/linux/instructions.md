# How to use these scripts:
#### 1. First make them executable:
```sh
chmod +x purge_docker.sh
chmod +x install_docker.sh
```
#### 2. Run the purge script:
```sh
./purge_docker.sh
```
#### 3. Reboot your system (recommended):
```sh
sudo reboot
```
#### 4. Run the installation script:
```sh
./install_docker.sh
```
#### 5. When prompted "Would you like to install Docker Desktop?", press:
```y``` or ```Y``` to install Docker Desktop, any other key to skip Docker Desktop installation. After installation completes, log out and back in or run:
```sh
newgrp docker
```
The updated installation script now:

1. Installs all the standard Docker CLI tools by default
2. Gives you the option to install Docker Desktop
3. Provides clear instructions for both scenarios
4. Automatically handles the Docker Desktop service setup