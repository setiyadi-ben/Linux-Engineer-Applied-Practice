#!/bin/bash

# Docker Purge Script for Ubuntu
echo "Starting complete Docker removal..."

# Stop all Docker services and containers
echo "Stopping Docker services and containers..."
sudo systemctl stop docker docker.socket containerd 2>/dev/null
sudo docker stop $(sudo docker ps -aq) 2>/dev/null

# Uninstall Docker packages
echo "Removing Docker packages..."
sudo apt-get purge -y docker-ce docker-ce-cli docker-ce-rootless-extras \
    docker-buildx-plugin docker-compose-plugin docker-desktop

# Remove residual files
echo "Cleaning up residual files..."
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
sudo rm -rf /etc/docker
sudo rm -rf ~/.docker
sudo rm -rf /usr/local/bin/docker-compose
sudo rm -f /etc/apt/sources.list.d/docker.list

# Clean up system
echo "Cleaning up system..."
sudo apt-get autoremove -y
sudo apt-get autoclean

echo "Docker has been completely removed from your system."
echo "Please reboot your system before proceeding with reinstallation."