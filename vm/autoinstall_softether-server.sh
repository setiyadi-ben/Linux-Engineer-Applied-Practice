#!/bin/bash
# SoftEther VPN Server Installation Manager
# Please refer to: https://www.softether.org/4-docs/1-manual/7/7.3
# Or you can read more on: https://www.softether.org/4-docs/1-manual/7
# Supports install, reinstall, and uninstall with version selection
# Fetches packages directly from SoftEther's official file server

# Supported architectures: x86-32bit, x64-64bit, ARM-32bit, ARM-64bit
# Usage: 
# sudo chmod +x ./autoinstall_softether-server.sh
# sudo ./autoinstall_softether-server.sh

# Check root privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: Run this script as root (sudo $0)" >&2
    exit 1
fi

# Function to check installation status
check_installation() {
    if [ -d "/usr/local/vpnserver" ]; then
        echo -e "\033[1;32mSoftEther VPN Server is currently installed.\033[0m"
        return 0
    else
        echo -e "\033[1;33mSoftEther VPN Server is not installed.\033[0m"
        return 1
    fi
}

# Function to uninstall
uninstall_softether() {
    echo -e "\n\033[1;31mUninstalling SoftEther VPN Server...\033[0m"
    
    # Stop and disable service
    systemctl stop vpnserver 2>/dev/null
    systemctl disable vpnserver 2>/dev/null
    rm -f /etc/systemd/system/vpnserver.service 2>/dev/null
    
    # Remove files
    rm -f /opt/vpnserver.sh 2>/dev/null
    rm -rf /usr/local/vpnserver 2>/dev/null
    
    # Remove extracted files in /opt
    find /opt -maxdepth 1 -type d -name 'vpnserver' -exec rm -rf {} + 2>/dev/null
    find /opt -maxdepth 1 -type f -name 'softether-vpnserver-*.tar.gz' -exec rm -f {} + 2>/dev/null
    rm -f /opt/softether-vpnserver.tar.gz 2>/dev/null

    # Reload the service after uninstall
    systemctl daemon-reload
    
    echo -e "\033[1;32mUninstallation completed successfully!\033[0m"
}

# Function to install dependencies
install_dependencies() {
    echo -e "\n\033[1;33mInstalling required dependencies...\033[0m"
    apt update && apt install -y \
        build-essential \
        libssl-dev \
        zlib1g-dev \
        libncurses5-dev \
        libedit-dev \
        libreadline-dev
}

# Main installation function
install_softether() {
    # Fetch and prepare version list
    echo "Fetching available SoftEther versions..."
    versions=$(curl -s https://www.softether-download.com/files/softether/ | \
    grep -E -o 'v[0-9].[0-9][0-9]-[0-9][0-9][0-9][0-9]-rtm-20[0-9][0-9].[0-1][0-9].[0-3][0-9]-tree' | \
    sort -r | uniq | head -10)

    # Convert to array
    IFS=$'\n' read -r -d '' -a version_array <<< "$versions"

    # Display menu
    echo ""
    echo "Available SoftEther VPN Server versions:"
    for i in "${!version_array[@]}"; do
        printf "%2d) %s\n" $((i+1)) "${version_array[$i]}"
    done

    # Get user selection
    echo ""
    read -p "Select a version (1-${#version_array[@]}): " choice
    if [[ ! $choice =~ ^[0-9]+$ ]] || ((choice < 1 || choice > ${#version_array[@]})); then
        echo "Invalid selection. Exiting."
        exit 1
    fi

    # Set selected version
    selected_version="${version_array[$((choice-1))]}"
    echo -e "\n\033[1;32mSelected version: $selected_version\033[0m"

    # Fetch architecture list
    echo "Fetching available architectures..."
    base_url="https://www.softether-download.com/files/softether/$selected_version"
    arch_list=$(curl -s "$base_url/Linux/SoftEther_VPN_Server/" | grep -Eo 'Linux/SoftEther_VPN_Server/[^/<>]+/' | sort -u)

    # Convert to array
    IFS=$'\n' read -r -d '' -a arch_array <<< "$arch_list"

    # Display architecture menu
    echo ""
    echo "Available architectures:"
    for i in "${!arch_array[@]}"; do
        printf "%2d) %s\n" $((i+1)) "${arch_array[$i]}"
    done

    # Get architecture selection
    echo ""
    read -p "Select an architecture (1-${#arch_array[@]}): " arch_choice
    if [[ ! $arch_choice =~ ^[0-9]+$ ]] || ((arch_choice < 1 || arch_choice > ${#arch_array[@]})); then
        echo "Invalid selection. Exiting."
        exit 1
    fi

    # Set selected architecture
    selected_arch="${arch_array[$((arch_choice-1))]}"
    echo -e "\n\033[1;32mSelected architecture: $selected_arch\033[0m"

    # Extract filename
    filename=$(curl -s "$base_url/$selected_arch" | grep -Eo 'softether-vpnserver[^"]+\.tar\.gz' | head -1)

    # Download the package
    echo "Downloading from the server..."
    download_url="$base_url/$selected_arch$filename"
    echo "Download URL: $download_url"
    wget "$download_url" -O "/opt/softether-vpnserver.tar.gz"

    # Install dependencies
    install_dependencies

    # Prepare for installation
    echo -e "\n\033[1;33mPreparing for installation...\033[0m"
    cd /opt
    tar xzvf softether-vpnserver.tar.gz
    cd ./vpnserver
    make 1>/dev/null  # Suppress verbose make output

    # Install to system location
    echo -e "\n\033[1;33mInstalling to system location...\033[0m"
    ./.install.sh
    cd .. 
    mv vpnserver /usr/local
    cd /usr/local/vpnserver/
    chmod 600 *
    chmod 700 vpncmd vpnserver

    # Create service management script
    echo -e "\n\033[1;33mCreating service management script...\033[0m"
    cat > /opt/vpnserver.sh << 'EOF'
#!/bin/sh
# chkconfig: 2345 99 01
# description: SoftEther VPN Server
DAEMON=/usr/local/vpnserver/vpnserver
LOCK=/var/lock/subsys/vpnserver
test -x $DAEMON || exit 0
case "$1" in
start)
$DAEMON start
touch $LOCK
;;
stop)
$DAEMON stop
rm $LOCK
;;
restart)
$DAEMON stop
sleep 3
$DAEMON start
;;
*)
echo "Usage: $0 {start|stop|restart}"
exit 1
esac
exit 0
EOF

    chmod 755 /opt/vpnserver.sh

    # Create systemd service
    echo -e "\n\033[1;33mCreating systemd service...\033[0m"
    cat > /etc/systemd/system/vpnserver.service << 'EOF'
[Unit]
Description = vpnserver daemon

[Service]
ExecStart = /opt/vpnserver.sh start
ExecStop = /opt/vpnserver.sh stop
ExecReload = /opt/vpnserver.sh restart
Restart = always
Type = forking

[Install]
WantedBy = multi-user.target
EOF

    # Enable and start service
    echo -e "\n\033[1;33mStarting VPN service...\033[0m"
    systemctl daemon-reload
    systemctl enable vpnserver
    systemctl start vpnserver
    
    # Cleanup
    rm -f /opt/softether-vpnserver.tar.gz

    echo -e "\n\033[1;32mInstallation completed successfully!\033[0m"
    echo -e "\n\033[1;33mService Status:\033[0m"
    systemctl status vpnserver --no-pager
}

# Main script logic
echo -e "\n\033[1;34mSoftEther VPN Server Installation Manager\033[0m"
echo "=============================================="

# Check installation status
check_installation
installed=$?

if [ $installed -eq 0 ]; then
    echo -e "\n\033[1;36m1) Uninstall existing installation"
    echo "2) Reinstall (uninstall then install new version)"
    echo "3) Cancel and exit"
    read -p "Select an option (1-3): " option

    case $option in
        1)
            uninstall_softether
            echo -e "\n\033[1;32mUninstallation complete. Exiting.\033[0m"
            exit 0
            ;;
        2)
            uninstall_softether
            echo -e "\n\033[1;32mProceeding with reinstallation...\033[0m"
            install_softether
            ;;
        3)
            echo "Exiting without changes."
            exit 0
            ;;
        *)
            echo "Invalid option. Exiting."
            exit 1
            ;;
    esac
else
    echo -e "\n\033[1;36m1) Install SoftEther VPN Server"
    echo "2) Cancel and exit"
    read -p "Select an option (1-2): " option

    case $option in
        1)
            install_softether
            ;;
        2)
            echo "Exiting without installation."
            exit 0
            ;;
        *)
            echo "Invalid option. Exiting."
            exit 1
            ;;
    esac
fi

# Final check and service status
if check_installation; then
    echo -e "\n\033[1;33mFinal Service Status:\033[0m"
    systemctl status vpnserver --no-pager
    echo -e "\n\033[1;32mSetup complete! SoftEther VPN Server is running.\033[0m"
else
    echo -e "\n\033[1;31mInstallation may not have completed successfully. Please check logs.\033[0m"
fi