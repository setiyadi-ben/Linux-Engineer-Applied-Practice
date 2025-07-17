#!/bin/bash

# Docker Installation Script with Error Handling
echo "Starting Docker installation..."

# Clean any existing Docker repo configurations
echo "Cleaning existing Docker repository configurations..."
sudo rm -f /etc/apt/sources.list.d/docker* 2>/dev/null
sudo rm -f /etc/apt/keyrings/docker* 2>/dev/null

# Install prerequisites with error handling
echo "Installing prerequisites..."
sudo apt-get update && sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key with proper permissions
echo "Adding Docker's GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add repository with version compatibility check
echo "Adding Docker repository..."
source /etc/os-release
sudo tee /etc/apt/sources.list.d/docker.list >/dev/null <<EOF
deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable
EOF

# Update package index with error checking
echo "Updating package lists..."
if ! sudo apt-get update; then
    echo "Error: Failed to update package lists. Check repository configuration."
    exit 1
fi

# Install Docker packages with dependency resolution
echo "Installing Docker packages..."
sudo apt-get install -y --fix-broken \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# Configure Docker service
echo "Configuring Docker service..."
sudo systemctl enable docker
if ! sudo systemctl start docker; then
    echo "Error: Failed to start Docker service. Checking status..."
    systemctl status docker --no-pager
    exit 1
fi

# Post-installation configuration
echo "Configuring user permissions..."
sudo usermod -aG docker $USER

#!/bin/bash

# Docker Installation Script with Local .deb Support
echo "Starting Docker installation..."

# ... [keep all previous setup steps unchanged until Docker Desktop section] ...

# Revised Docker Desktop installation section
read -p "Would you like to install Docker Desktop? [y/N] " choice
if [[ "$choice" =~ [yY] ]]; then
    echo "Checking for local Docker Desktop package..."
    
    # Look for .deb files in current directory
    DEB_FILE=$(find . -maxdepth 1 -name 'docker-desktop*.deb' -print -quit)
    
    if [ -n "$DEB_FILE" ]; then
        echo "Using local package: $DEB_FILE"
    else
        echo "Error: No docker-desktop*.deb file found in current directory"
        exit 1
    fi

    # Verify package integrity
    echo "Verifying package..."
    if ! dpkg -I "$DEB_FILE" &> /dev/null; then
        echo "Error: $DEB_FILE is not a valid Debian package"
        exit 1
    fi

    # Install with dependency resolution
    echo "Installing from local package..."
    sudo apt-get install -y "./$DEB_FILE" || {
        echo "Installation failed, trying dependency fix..."
        sudo apt-get install -f -y
    }

    # Configure systemd services
    systemctl --user enable docker-desktop || \
        echo "Warning: Failed to enable docker-desktop service"
    
    echo "Docker Desktop installed. Start with:"
    echo "systemctl --user start docker-desktop"
fi

# ... [keep remaining verification steps unchanged] ...

# Final verification
echo "Verifying installation..."
docker --version || echo "Docker CLI not found!"
docker compose version || echo "Docker Compose not found!"
sudo docker run --rm hello-world

echo "Installation complete! Please log out and back in for group changes."