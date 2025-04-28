#!/bin/bash

# Docker Installation Script for Ubuntu (with Desktop option)
echo "Starting Docker installation..."

# Install prerequisites
echo "Installing prerequisites..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl

# Add Docker's official GPG key
echo "Adding Docker's GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository
echo "Adding Docker repository..."
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index
sudo apt-get update

# Install Docker components
echo "Installing Docker packages..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Configure user permissions
echo "Configuring user permissions..."
sudo usermod -aG docker $USER

# Enable and start Docker
echo "Starting Docker service..."
sudo systemctl enable docker
sudo systemctl start docker

# Verify CLI installation
echo "Verifying CLI installation..."
docker --version
docker compose version
docker run --rm hello-world

# Docker Desktop installation prompt
read -p "Would you like to install Docker Desktop? (y/n) " choice
if [[ "$choice" =~ [yY] ]]; then
    echo "Installing Docker Desktop..."
    
    # Download Docker Desktop package
    curl -LO https://desktop.docker.com/linux/main/amd64/docker-desktop-4.40.0-amd64.deb
    
    # Install dependencies
    sudo apt-get install -y ./docker-desktop-4.40.0-amd64.deb
    
    # Clean up package
    rm docker-desktop-4.40.0-amd64.deb
    
    # Start Docker Desktop
    systemctl --user enable docker-desktop
    systemctl --user start docker-desktop
    
    echo "Docker Desktop has been installed."
    echo "You can start it from your application menu or by running:"
    echo "systemctl --user start docker-desktop"
fi

echo "Installation complete!"
echo "Please log out and back in for group permissions to take effect."
echo "Or run 'newgrp docker' to activate the group changes immediately."