#!/bin/bash
# Auto-install SoftEther VPN Server with dynamic version detection
# Supported platforms: Linux, FreeBSD, Solaris, macOS
# Supported architectures: x86-32bit, x64-64bit, ARM-32bit, ARM-64bit
# sudo chmod +x autoinstall_softether-server.sh
# Usage: sudo ./autoinstall_softether-server.sh

set -e  # Exit on error

# Verify root privileges
if [ "$(id -u)" -ne 0 ]; then
  echo "Error: Run this script as root (sudo $0)" >&2
  exit 1
fi

# Install dependencies
apt update && apt install -y \
  build-essential \
  libssl-dev \
  zlib1g-dev \
  libncurses5-dev \
  libedit-dev \
  libreadline-dev \
  curl \
  jq

# Get latest release metadata from GitHub API
echo -e "\n\033[1;34mFetching latest release information...\033[0m"
RELEASE_JSON=$(curl -s "https://api.github.com/repos/SoftEtherVPN/SoftEtherVPN_Stable/releases/latest")
TAG_NAME=$(jq -r '.tag_name' <<< "$RELEASE_JSON")
ASSETS_URL=$(jq -r '.assets_url' <<< "$RELEASE_JSON")
ASSETS_JSON=$(curl -s "$ASSETS_URL")

# Platform selection menu
echo -e "\n\033[1;36mSelect platform:\033[0m"
platforms=("Linux" "FreeBSD" "Solaris" "macOS")
for i in "${!platforms[@]}"; do
  echo "$((i+1))) ${platforms[$i]}"
done

read -rp "Enter choice [1-${#platforms[@]}]: " platform_choice
case $platform_choice in
  1) platform="linux" ;;
  2) platform="freebsd" ;;
  3) platform="solaris" ;;
  4) platform="macos" ;;
  *) echo "Invalid platform selection"; exit 1 ;;
esac

# Architecture selection menu
echo -e "\n\033[1;36mSelect architecture:\033[0m"
architectures=("32-bit (x86)" "64-bit (x64)" "ARM 32-bit" "ARM 64-bit")
for i in "${!architectures[@]}"; do
  echo "$((i+1))) ${architectures[$i]}"
done

read -rp "Enter choice [1-${#architectures[@]}]: " arch_choice
case $arch_choice in
  1) arch="x86-32bit" ;;
  2) arch="x64-64bit" ;;
  3) arch="arm_eabi-32bit" ;;
  4) arch="arm64-64bit" ;;
  *) echo "Invalid architecture selection"; exit 1 ;;
esac

# Find matching asset
FILE_PATTERN="${platform}-${arch}"
ASSET_URL=$(jq -r ".[] | select(.name | contains(\"$FILE_PATTERN\")) | .browser_download_url" <<< "$ASSETS_JSON")
if [ -z "$ASSET_URL" ]; then
  echo -e "\033[1;31mError: No download found for ${platform} ${arch}\033[0m" >&2
  exit 1
fi

# Download and extract
echo -e "\n\033[1;34mDownloading: $(basename "$ASSET_URL")\033[0m"
cd /opt
curl -L -O "$ASSET_URL"
tar xzvf "$(basename "$ASSET_URL")"

# Compile and install
echo -e "\n\033[1;34mCompiling VPN Server...\033[0m"
cd vpnserver
make > /dev/null

echo -e "\n\033[1;34mInstalling to /usr/local/vpnserver...\033[0m"
cd ..
mv vpnserver /usr/local
cd /usr/local/vpnserver
chmod 600 *
chmod 700 vpncmd vpnserver

# Verify installation
echo -e "\n\033[1;34mRunning configuration check...\033[0m"
./vpncmd <<CMD
3
check
exit
CMD

# Create service script
echo -e "\n\033[1;34mCreating system service...\033[0m"
cat > /opt/vpnserver.sh <<'EOF'
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
cat > /etc/systemd/system/vpnserver.service <<'EOF'
[Unit]
Description = SoftEther VPN Server
After=network.target

[Service]
ExecStart = /opt/vpnserver.sh start
ExecStop = /opt/vpnserver.sh stop
ExecReload = /opt/vpnserver.sh restart
Restart = always
Type = forking

[Install]
WantedBy = multi-user.target
EOF

# Start service
systemctl daemon-reload
systemctl enable vpnserver
systemctl start vpnserver

# Verify status
echo -e "\n\033[1;32mInstallation completed!\033[0m"
echo -e "\033[1;33mService Status:\033[0m"
systemctl status vpnserver --no-pager
echo -e "\n\033[1;33mManagement Command:\033[0m /usr/local/vpnserver/vpncmd"



#!/bin/bash
# Auto-install SoftEther VPN Server with dynamic version detection
# Supported platforms: Linux, FreeBSD, Solaris, macOS
# Supported architectures: x86-32bit, x64-64bit, ARM-32bit, ARM-64bit
# sudo chmod +x autoinstall_softether-server.sh
# Usage: sudo ./autoinstall_softether-server.sh

set -e  # Exit on error

# Verify root privileges
if [ "$(id -u)" -ne 0 ]; then
  echo "Error: Run this script as root (sudo $0)" >&2
  exit 1
fi

# Install dependencies
apt update && apt install -y \
  build-essential \
  libssl-dev \
  zlib1g-dev \
  libncurses5-dev \
  libedit-dev \
  libreadline-dev \
  curl \
  jq \
  wget

# Get latest release metadata from GitHub API
echo -e "\n\033[1;34mFetching latest release information...\033[0m"
RELEASE_JSON=$(curl -s "https://api.github.com/repos/SoftEtherVPN/SoftEtherVPN_Stable/releases/latest")
TAG_NAME=$(jq -r '.tag_name' <<< "$RELEASE_JSON")
ASSETS_URL=$(jq -r '.assets_url' <<< "$RELEASE_JSON")
ASSETS_JSON=$(curl -s "$ASSETS_URL")

# Platform selection menu
echo -e "\n\033[1;36mSelect platform:\033[0m"
platforms=("Linux" "FreeBSD" "Solaris" "macOS")
for i in "${!platforms[@]}"; do
  echo "$((i+1))) ${platforms[$i]}"
done

read -rp "Enter choice [1-${#platforms[@]}]: " platform_choice
case $platform_choice in
  1) platform="linux" ;;
  2) platform="freebsd" ;;
  3) platform="solaris" ;;
  4) platform="macos" ;;
  *) echo "Invalid platform selection"; exit 1 ;;
esac

# Architecture selection menu
echo -e "\n\033[1;36mSelect architecture:\033[0m"
architectures=("32-bit (x86)" "64-bit (x64)" "ARM 32-bit" "ARM 64-bit")
for i in "${!architectures[@]}"; do
  echo "$((i+1))) ${architectures[$i]}"
done

read -rp "Enter choice [1-${#architectures[@]}]: " arch_choice
case $arch_choice in
  1) arch="x86-32bit" ;;
  2) arch="x64-64bit" ;;
  3) arch="arm_eabi" ;;      # Fixed ARM pattern
  4) arch="arm64-64bit" ;;
  *) echo "Invalid architecture selection"; exit 1 ;;
esac

# Find matching server asset
FILE_PATTERN="vpnserver.*${platform}.*${arch}"
ASSET_URL=$(jq -r ".[] | select(.name | test(\"$FILE_PATTERN\"; \"i\")) | .browser_download_url" <<< "$ASSETS_JSON")
if [ -z "$ASSET_URL" ]; then
  echo -e "\033[1;31mError: No download found for ${platform} ${arch}\033[0m" >&2
  exit 1
fi

# Extract filename from URL
FILENAME=$(basename "$ASSET_URL")
if [[ "$FILENAME" != *.tar.gz ]]; then
  echo -e "\033[1;31mError: Invalid filename format: $FILENAME\033[0m" >&2
  exit 1
fi

# Download and extract
echo -e "\n\033[1;34mDownloading: $FILENAME\033[0m"
cd /opt
curl -L -o "$FILENAME" "$ASSET_URL"
tar xzvf "$FILENAME"

# Compile and install
echo -e "\n\033[1;34mCompiling VPN Server...\033[0m"
cd vpnserver
make > /dev/null

echo -e "\n\033[1;34mInstalling to /usr/local/vpnserver...\033[0m"
cd ..
mv vpnserver /usr/local
cd /usr/local/vpnserver
chmod 600 *
chmod 700 vpncmd vpnserver

# Verify installation
echo -e "\n\033[1;34mRunning configuration check...\033[0m"
./vpncmd <<CMD
3
check
exit
CMD

# Create service script
echo -e "\n\033[1;34mCreating system service...\033[0m"
cat > /opt/vpnserver.sh <<'EOF'
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
cat > /etc/systemd/system/vpnserver.service <<'EOF'
[Unit]
Description = SoftEther VPN Server
After=network.target

[Service]
ExecStart = /opt/vpnserver.sh start
ExecStop = /opt/vpnserver.sh stop
ExecReload = /opt/vpnserver.sh restart
Restart = always
Type = forking

[Install]
WantedBy = multi-user.target
EOF

# Start service
systemctl daemon-reload
systemctl enable vpnserver
systemctl start vpnserver

# Verify status
echo -e "\n\033[1;32mInstallation completed!\033[0m"
echo -e "\033[1;33mService Status:\033[0m"
systemctl status vpnserver --no-pager
echo -e "\n\033[1;33mManagement Command:\033[0m /usr/local/vpnserver/vpncmd"




#!/bin/bash
# Auto-install SoftEther VPN Server with dynamic version detection
# Supported platforms: Linux, FreeBSD, Solaris, macOS
# Supported architectures: x86-32bit, x64-64bit, ARM-32bit, ARM-64bit
# sudo chmod +x autoinstall_softether-server.sh
# Usage: sudo ./autoinstall_softether-server.sh

set -e  # Exit on error

# Verify root privileges
if [ "$(id -u)" -ne 0 ]; then
  echo "Error: Run this script as root (sudo $0)" >&2
  exit 1
fi

# Install dependencies
apt update && apt install -y \
  build-essential \
  libssl-dev \
  zlib1g-dev \
  libncurses5-dev \
  libedit-dev \
  libreadline-dev \
  curl \
  jq

# Get latest release metadata from GitHub API
echo -e "\n\033[1;34mFetching latest release information...\033[0m"
RELEASE_JSON=$(curl -s "https://api.github.com/repos/SoftEtherVPN/SoftEtherVPN_Stable/releases/latest")
TAG_NAME=$(jq -r '.tag_name' <<< "$RELEASE_JSON")
ASSETS_URL=$(jq -r '.assets_url' <<< "$RELEASE_JSON")
ASSETS_JSON=$(curl -s "$ASSETS_URL")

# Platform selection menu
echo -e "\n\033[1;36mSelect platform:\033[0m"
platforms=("Linux" "FreeBSD" "Solaris" "macOS")
for i in "${!platforms[@]}"; do
  echo "$((i+1))) ${platforms[$i]}"
done

read -rp "Enter choice [1-${#platforms[@]}]: " platform_choice
case $platform_choice in
  1) platform="linux" ;;
  2) platform="freebsd" ;;
  3) platform="solaris" ;;
  4) platform="macos" ;;
  *) echo "Invalid platform selection"; exit 1 ;;
esac

# Architecture selection menu
echo -e "\n\033[1;36mSelect architecture:\033[0m"
architectures=("32-bit (x86)" "64-bit (x64)" "ARM 32-bit" "ARM 64-bit")
for i in "${!architectures[@]}"; do
  echo "$((i+1))) ${architectures[$i]}"
done

read -rp "Enter choice [1-${#architectures[@]}]: " arch_choice
case $arch_choice in
  1) arch="x86-32bit" ;;
  2) arch="x64-64bit" ;;
  3) arch="arm-32bit" ;;
  4) arch="arm64-64bit" ;;
  *) echo "Invalid architecture selection"; exit 1 ;;
esac

# Create filename pattern based on actual GitHub release names
if [ "$platform" = "linux" ]; then
    if [ "$arch" = "x86-32bit" ]; then
        FILE_PATTERN="linux-x86-32bit"
    elif [ "$arch" = "x64-64bit" ]; then
        FILE_PATTERN="linux-x64-64bit"
    elif [ "$arch" = "arm-32bit" ]; then
        FILE_PATTERN="linux-arm_eabi-32bit"
    elif [ "$arch" = "arm64-64bit" ]; then
        FILE_PATTERN="linux-arm64-64bit"
    fi
elif [ "$platform" = "freebsd" ]; then
    # FreeBSD patterns
    FILE_PATTERN="freebsd-${arch}"
elif [ "$platform" = "solaris" ]; then
    # Solaris patterns
    FILE_PATTERN="solaris-${arch}"
elif [ "$platform" = "macos" ]; then
    # macOS patterns
    FILE_PATTERN="macos-${arch}"
fi

# Find matching server asset
ASSET_URL=$(jq -r ".[] | select(.name | contains(\"vpnserver\") | select(.name | contains(\"$FILE_PATTERN\")) | .browser_download_url" <<< "$ASSETS_JSON")
if [ -z "$ASSET_URL" ]; then
  # Try alternative pattern matching if first attempt fails
  ALTERNATE_PATTERN="${platform}-${arch}"
  ASSET_URL=$(jq -r ".[] | select(.name | contains(\"vpnserver\")) | select(.name | contains(\"$ALTERNATE_PATTERN\")) | .browser_download_url" <<< "$ASSETS_JSON")
  
  if [ -z "$ASSET_URL" ]; then
    echo -e "\033[1;31mError: No download found for ${platform} ${arch}\033[0m" >&2
    echo "Available assets:"
    jq -r '.[].name' <<< "$ASSETS_JSON" | grep vpnserver
    exit 1
  fi
fi

# Download and extract
echo -e "\n\033[1;34mDownloading: $(basename "$ASSET_URL")\033[0m"
cd /opt
curl -L -O "$ASSET_URL"
FILENAME=$(basename "$ASSET_URL")
tar xzvf "$FILENAME"

# Compile and install
echo -e "\n\033[1;34mCompiling VPN Server...\033[0m"
cd vpnserver
make > /dev/null

echo -e "\n\033[1;34mInstalling to /usr/local/vpnserver...\033[0m"
cd ..
mv vpnserver /usr/local
cd /usr/local/vpnserver
chmod 600 *
chmod 700 vpncmd vpnserver

# Verify installation
echo -e "\n\033[1;34mRunning configuration check...\033[0m"
./vpncmd <<CMD
3
check
exit
CMD

# Create service script
echo -e "\n\033[1;34mCreating system service...\033[0m"
cat > /opt/vpnserver.sh <<'EOF'
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
cat > /etc/systemd/system/vpnserver.service <<'EOF'
[Unit]
Description = SoftEther VPN Server
After=network.target

[Service]
ExecStart = /opt/vpnserver.sh start
ExecStop = /opt/vpnserver.sh stop
ExecReload = /opt/vpnserver.sh restart
Restart = always
Type = forking

[Install]
WantedBy = multi-user.target
EOF

# Start service
systemctl daemon-reload
systemctl enable vpnserver
systemctl start vpnserver

# Verify status
echo -e "\n\033[1;32mInstallation completed!\033[0m"
echo -e "\033[1;33mService Status:\033[0m"
systemctl status vpnserver --no-pager
echo -e "\n\033[1;33mManagement Command:\033[0m /usr/local/vpnserver/vpncmd"



#!/bin/bash
# Auto-install SoftEther VPN Server with direct download from softether-download.com
# Supported platforms: Linux, FreeBSD, Solaris, macOS
# Supported architectures: x86-32bit, x64-64bit, ARM-32bit, ARM-64bit
# Usage: sudo ./autoinstall_softether-server.sh

set -e  # Exit on error

# Verify root privileges
if [ "$(id -u)" -ne 0 ]; then
  echo "Error: Run this script as root (sudo $0)" >&2
  exit 1
fi

# Install dependencies
apt update && apt install -y \
  build-essential \
  libssl-dev \
  zlib1g-dev \
  libncurses5-dev \
  libedit-dev \
  libreadline-dev \
  curl \
  jq

# Get download page
echo -e "\n\033[1;34mFetching download information from softether-download.com...\033[0m"
DOWNLOAD_PAGE=$(curl -s "https://www.softether-download.com/en.aspx?product=softether")

# Platform selection menu
echo -e "\n\033[1;36mSelect platform:\033[0m"
platforms=("Linux" "FreeBSD" "Solaris" "macOS")
for i in "${!platforms[@]}"; do
  echo "$((i+1))) ${platforms[$i]}"
done

read -rp "Enter choice [1-${#platforms[@]}]: " platform_choice
case $platform_choice in
  1) platform="linux" ;;
  2) platform="freebsd" ;;
  3) platform="solaris" ;;
  4) platform="macos" ;;
  *) echo "Invalid platform selection"; exit 1 ;;
esac

# Architecture selection menu
echo -e "\n\033[1;36mSelect architecture:\033[0m"
architectures=("32-bit (x86)" "64-bit (x64)" "ARM 32-bit" "ARM 64-bit")
for i in "${!architectures[@]}"; do
  echo "$((i+1))) ${architectures[$i]}"
done

read -rp "Enter choice [1-${#architectures[@]}]: " arch_choice
case $arch_choice in
  1) arch="x86-32bit" ;;
  2) arch="x64-64bit" ;;
  3) arch="arm_eabi-32bit" ;;
  4) arch="arm64-64bit" ;;
  *) echo "Invalid architecture selection"; exit 1 ;;
esac

# Map to SoftEther's naming convention
case "$platform-$arch" in
  "linux-x86-32bit") FILE_PATTERN="linux-x86-32bit" ;;
  "linux-x64-64bit") FILE_PATTERN="linux-x64-64bit" ;;
  "linux-arm_eabi-32bit") FILE_PATTERN="linux-arm_eabi-32bit" ;;
  "linux-arm64-64bit") FILE_PATTERN="linux-arm64-64bit" ;;
  "freebsd-x86-32bit") FILE_PATTERN="freebsd-x86-32bit" ;;
  "freebsd-x64-64bit") FILE_PATTERN="freebsd-x64-64bit" ;;
  "solaris-x64-64bit") FILE_PATTERN="solaris-x64-64bit" ;;
  "macos-x64-64bit") FILE_PATTERN="macos-x64-64bit" ;;
  "macos-arm64-64bit") FILE_PATTERN="macos-arm64-64bit" ;;
  *) echo "Unsupported platform-arch combination: $platform-$arch"; exit 1 ;;
esac

# Extract download URL from SoftEther download page
DOWNLOAD_URL=$(echo "$DOWNLOAD_PAGE" | 
  grep -oP "https://[^\"]*softether-vpnserver[^\"]*${FILE_PATTERN}[^\"]*\.tar\.gz" |
  head -1)

if [ -z "$DOWNLOAD_URL" ]; then
  echo -e "\033[1;31mError: Failed to find download URL for ${platform} ${arch}\033[0m" >&2
  echo "Please check available downloads at: https://www.softether-download.com/en.aspx?product=softether"
  exit 1
fi

FILENAME=$(basename "$DOWNLOAD_URL")
echo -e "\n\033[1;34mDownloading: $FILENAME\033[0m"
echo -e "\033[1;33mSource: $DOWNLOAD_URL\033[0m"

# Download and extract
cd /opt
curl -L -O "$DOWNLOAD_URL"
tar xzvf "$FILENAME"

# Compile and install
echo -e "\n\033[1;34mCompiling VPN Server...\033[0m"
cd vpnserver
make > /dev/null

echo -e "\n\033[1;34mInstalling to /usr/local/vpnserver...\033[0m"
cd ..
mv vpnserver /usr/local
cd /usr/local/vpnserver
chmod 600 *
chmod 700 vpncmd vpnserver

# Verify installation
echo -e "\n\033[1;34mRunning configuration check...\033[0m"
./vpncmd <<CMD
3
check
exit
CMD

# Create service script
echo -e "\n\033[1;34mCreating system service...\033[0m"
cat > /opt/vpnserver.sh <<'EOF'
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
cat > /etc/systemd/system/vpnserver.service <<'EOF'
[Unit]
Description = SoftEther VPN Server
After=network.target

[Service]
ExecStart = /opt/vpnserver.sh start
ExecStop = /opt/vpnserver.sh stop
ExecReload = /opt/vpnserver.sh restart
Restart = always
Type = forking

[Install]
WantedBy = multi-user.target
EOF

# Start service
systemctl daemon-reload
systemctl enable vpnserver
systemctl start vpnserver

# Verify status
echo -e "\n\033[1;32mInstallation completed!\033[0m"
echo -e "\033[1;33mService Status:\033[0m"
systemctl status vpnserver --no-pager
echo -e "\n\033[1;33mManagement Command:\033[0m /usr/local/vpnserver/vpncmd"



#!/bin/bash
# SoftEther VPN Server Installation Manager
# Supports install, reinstall, and uninstall with version selection
# Fetches packages directly from SoftEther's official file server

# Supported architectures: x86-32bit, x64-64bit, ARM-32bit, ARM-64bit
# Usage: sudo ./autoinstall_softether-server.sh

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
    rm -f /etc/systemd/system/vpnserver.service
    
    # Remove files
    rm -f /opt/vpnserver.sh
    rm -rf /usr/local/vpnserver
    
    # Remove extracted files in /opt
    find /opt -maxdepth 1 -type d -name 'vpnserver' -exec rm -rf {} +
    find /opt -maxdepth 1 -type f -name 'softether-vpnserver-*.tar.gz' -exec rm -f {} +
    
    echo -e "\033[1;32mUninstallation completed successfully!\033[0m"
}

# Function to get latest versions
get_latest_versions() {
    echo -e "\n\033[1;34mFetching latest versions...\033[0m"
    versions=$(curl -s https://www.softether-download.com/files/softether/ | 
               grep -oP 'href="\Kv[^"]+' | 
               grep -E '^v[0-9]+\.[0-9]+-[0-9]+-(rtm|beta)-[0-9]{4}\.[0-9]{2}\.[0-9]{2}-tree$' |
               grep -E 'v[0-9]+\.[0-9]+-[0-9]+-(rtm|beta)-[0-9]{4}\.[0-9]{2}\.[0-9]{2}-tree' |
               sort -r | head -3)
    
    if [ -z "$versions" ]; then
        echo -e "\033[1;31mFailed to fetch versions. Please check your internet connection.\033[0m"
        exit 1
    fi
    
    # Convert to array
    version_array=()
    while IFS= read -r line; do
        version_array+=("$line")
    done <<< "$versions"
    
    # Display version menu
    echo -e "\n\033[1;36mSelect a version:\033[0m"
    for i in "${!version_array[@]}"; do
        clean_version=$(echo "${version_array[$i]}" | sed 's/^v//; s/-tree$//')
        echo "$((i+1))) $clean_version"
    done
    echo "4) Enter custom version"
    
    # Get user selection
    while true; do
        read -rp "Enter choice [1-4]: " version_choice
        case $version_choice in
            1|2|3)
                selected_version="${version_array[$((version_choice-1))]}"
                clean_version=$(echo "$selected_version" | sed 's/^v//; s/-tree$//')
                break
                ;;
            4)
                read -rp "Enter version (e.g., v4.44-9807-rtm-2025.04.16-tree): " selected_version
                clean_version=$(echo "$selected_version" | sed 's/^v//; s/-tree$//')
                break
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
    
    # Build download URL
    download_dir="https://www.softether-download.com/files/softether/$selected_version/Linux/"
    echo -e "\nSelected version: \033[1;33m$clean_version\033[0m"
}

# Function to select architecture
select_architecture() {
    echo -e "\n\033[1;36mSelect architecture:\033[0m"
    echo "1) 32-bit (x86)"
    echo "2) 64-bit (x64)"
    echo "3) ARM 32-bit"
    echo "4) ARM 64-bit"
    
    while true; do
        read -rp "Enter choice [1-4]: " arch_choice
        case $arch_choice in
            1) 
                arch="x86-32bit"
                break
                ;;
            2) 
                arch="x64-64bit"
                break
                ;;
            3) 
                arch="arm_eabi-32bit"
                break
                ;;
            4) 
                arch="arm64-64bit"
                break
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
    
    # Build filename pattern
    filename_pattern="softether-vpnserver-${clean_version}-linux-${arch}.tar.gz"
    echo -e "\nSelected architecture: \033[1;33m$arch\033[0m"
    echo -e "Filename pattern: \033[1;33m$filename_pattern\033[0m"
}

# Function to install dependencies
install_dependencies() {
    echo -e "\n\033[1;34mInstalling dependencies...\033[0m"
    apt update
    apt install -y \
        build-essential \
        libssl-dev \
        zlib1g-dev \
        libncurses5-dev \
        libedit-dev \
        libreadline-dev
}

# Function to install SoftEther
install_softether() {
    # Download the file
    download_url="${download_dir}${filename_pattern}"
    echo -e "\n\033[1;34mDownloading package...\033[0m"
    echo -e "URL: \033[1;33m$download_url\033[0m"
    
    cd /opt
    wget "$download_url"
    
    if [ ! -f "$filename_pattern" ]; then
        echo -e "\033[1;31mDownload failed. Please check the URL and try again.\033[0m"
        exit 1
    fi
    
    # Extract and install
    echo -e "\n\033[1;34mExtracting package...\033[0m"
    tar xzvf "$filename_pattern"
    
    echo -e "\n\033[1;34mCompiling VPN Server...\033[0m"
    cd ./vpnserver
    make >/dev/null
    
    echo -e "\n\033[1;34mInstalling to /usr/local/vpnserver...\033[0m"
    cd ..
    mv vpnserver /usr/local
    cd /usr/local/vpnserver
    chmod 600 *
    chmod 700 vpncmd vpnserver
    
    # Verify installation
    echo -e "\n\033[1;34mRunning configuration check...\033[0m"
    ./vpncmd <<CMD
3
check
exit
CMD
    
    # Create service script
    echo -e "\n\033[1;34mCreating system service...\033[0m"
    cat > /opt/vpnserver.sh <<'EOF'
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
    cat > /etc/systemd/system/vpnserver.service <<EOF
[Unit]
Description = SoftEther VPN Server
After = network.target

[Service]
ExecStart = /opt/vpnserver.sh start
ExecStop = /opt/vpnserver.sh stop
ExecReload = /opt/vpnserver.sh restart
Restart = always
Type = forking

[Install]
WantedBy = multi-user.target
EOF
    
    # Start service
    systemctl daemon-reload
    systemctl enable vpnserver
    systemctl start vpnserver
    
    # Verify status
    echo -e "\n\033[1;32mInstallation completed successfully!\033[0m"
    echo -e "\033[1;33mService Status:\033[0m"
    systemctl status vpnserver --no-pager
    echo -e "\n\033[1;33mManagement Command:\033[0m /usr/local/vpnserver/vpncmd"
    echo -e "\033[1;33mServer Admin Port:\033[0m 5555"
}

# Main menu
echo -e "\n\033[1;35mSoftEther VPN Server Installation Manager\033[0m"
echo -e "===========================================\n"

# Check installation status
if check_installation; then
    echo -e "\n\033[1;36mSelect an option:\033[0m"
    echo "1) Reinstall SoftEther VPN Server"
    echo "2) Uninstall SoftEther VPN Server"
    echo "3) Exit"
    
    while true; do
        read -rp "Enter choice [1-3]: " main_choice
        case $main_choice in
            1)
                echo -e "\n\033[1;33mReinstalling SoftEther VPN Server...\033[0m"
                uninstall_softether
                get_latest_versions
                select_architecture
                install_dependencies
                install_softether
                break
                ;;
            2)
                uninstall_softether
                exit 0
                ;;
            3)
                exit 0
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
else
    echo -e "\n\033[1;36mSelect an option:\033[0m"
    echo "1) Install SoftEther VPN Server"
    echo "2) Exit"
    
    while true; do
        read -rp "Enter choice [1-2]: " main_choice
        case $main_choice in
            1)
                get_latest_versions
                select_architecture
                install_dependencies
                install_softether
                break
                ;;
            2)
                exit 0
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
fi


#!/bin/bash
# SoftEther VPN Server Installation Manager
# Supports install, reinstall, and uninstall with version selection
# Fetches packages directly from SoftEther's official file server

# Supported architectures: x86-32bit, x64-64bit, ARM-32bit, ARM-64bit
# Usage: sudo ./autoinstall_softether-server.sh

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
    rm -f /etc/systemd/system/vpnserver.service
    
    # Remove files
    rm -f /opt/vpnserver.sh
    rm -rf /usr/local/vpnserver
    
    # Remove extracted files in /opt
    find /opt -maxdepth 1 -type d -name 'vpnserver' -exec rm -rf {} +
    find /opt -maxdepth 1 -type f -name 'softether-vpnserver-*.tar.gz' -exec rm -f {} +
    
    echo -e "\033[1;32mUninstallation completed successfully!\033[0m"
}

# Function to get latest versions
get_latest_versions() {
    echo -e "\n\033[1;34mFetching latest RTM versions...\033[0m"
    
    # Get directory listing and process versions
    versions=$(curl -s https://www.softether-download.com/files/softether/ | 
               grep -oP 'href="\K[^"]+' | 
               awk -F'/' '{print $NF}' | 
               grep -E '^v[0-9]+\.[0-9]+-[0-9]+-rtm-[0-9]{4}\.[0-9]{2}\.[0-9]{2}-tree$' | 
               sort -r | 
               head -3)
    
    # Verify we found RTM versions
    if [ -z "$versions" ]; then
        echo -e "\033[1;31mError: No RTM versions found. Possible causes:\033[0m"
        echo "1. Website structure changed"
        echo "2. No RTM releases available"
        echo "3. Temporary network issue"
        echo -e "\nPlease check manually: https://www.softether-download.com/files/softether/"
        exit 1
    fi
    
    # Convert to array
    version_array=()
    while IFS= read -r line; do
        version_array+=("$line")
    done <<< "$versions"
    
    # Display version menu
    echo -e "\n\033[1;36mSelect a version:\033[0m"
    for i in "${!version_array[@]}"; do
        clean_version=$(echo "${version_array[$i]}" | sed 's/^v//; s/-tree$//')
        echo "$((i+1))) $clean_version"
    done
    echo "4) Enter custom version"
    
    # Get user selection
    while true; do
        read -rp "Enter choice [1-4]: " version_choice
        case $version_choice in
            1|2|3)
                selected_version="${version_array[$((version_choice-1))]}"
                clean_version=$(echo "$selected_version" | sed 's/^v//; s/-tree$//')
                break
                ;;
            4)
                read -rp "Enter version (e.g., v4.44-9807-rtm-2025.04.16-tree): " selected_version
                # Validate custom version format
                if [[ ! "$selected_version" =~ ^v[0-9]+\.[0-9]+-[0-9]+-rtm-[0-9]{4}\.[0-9]{2}\.[0-9]{2}-tree$ ]]; then
                    echo -e "\033[1;31mInvalid version format. Please use the format: vX.XX-XXXX-rtm-YYYY.MM.DD-tree\033[0m"
                    continue
                fi
                clean_version=$(echo "$selected_version" | sed 's/^v//; s/-tree$//')
                break
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
    
    # Build download URL
    download_dir="https://www.softether-download.com/files/softether/$selected_version/Linux/"
    echo -e "\nSelected version: \033[1;33m$clean_version\033[0m"
}

# Function to select architecture
select_architecture() {
    echo -e "\n\033[1;36mSelect architecture:\033[0m"
    echo "1) 32-bit (x86)"
    echo "2) 64-bit (x64)"
    echo "3) ARM 32-bit"
    echo "4) ARM 64-bit"
    
    while true; do
        read -rp "Enter choice [1-4]: " arch_choice
        case $arch_choice in
            1) 
                arch="x86-32bit"
                break
                ;;
            2) 
                arch="x64-64bit"
                break
                ;;
            3) 
                arch="arm_eabi-32bit"
                break
                ;;
            4) 
                arch="arm64-64bit"
                break
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
    
    # Build filename pattern
    filename_pattern="softether-vpnserver-${clean_version}-linux-${arch}.tar.gz"
    echo -e "\nSelected architecture: \033[1;33m$arch\033[0m"
    echo -e "Filename pattern: \033[1;33m$filename_pattern\033[0m"
}

# Function to install dependencies
install_dependencies() {
    echo -e "\n\033[1;34mInstalling dependencies...\033[0m"
    apt update
    apt install -y \
        build-essential \
        libssl-dev \
        zlib1g-dev \
        libncurses5-dev \
        libedit-dev \
        libreadline-dev
}

# Function to install SoftEther
install_softether() {
    # Download the file
    download_url="${download_dir}${filename_pattern}"
    echo -e "\n\033[1;34mDownloading package...\033[0m"
    echo -e "URL: \033[1;33m$download_url\033[0m"
    
    cd /opt
    wget "$download_url"
    
    if [ ! -f "$filename_pattern" ]; then
        echo -e "\033[1;31mDownload failed. Please check the URL and try again.\033[0m"
        exit 1
    fi
    
    # Extract and install
    echo -e "\n\033[1;34mExtracting package...\033[0m"
    tar xzvf "$filename_pattern"
    
    echo -e "\n\033[1;34mCompiling VPN Server...\033[0m"
    cd ./vpnserver
    make >/dev/null
    
    echo -e "\n\033[1;34mInstalling to /usr/local/vpnserver...\033[0m"
    cd ..
    mv vpnserver /usr/local
    cd /usr/local/vpnserver
    chmod 600 *
    chmod 700 vpncmd vpnserver
    
    # Verify installation
    echo -e "\n\033[1;34mRunning configuration check...\033[0m"
    ./vpncmd <<CMD
3
check
exit
CMD
    
    # Create service script
    echo -e "\n\033[1;34mCreating system service...\033[0m"
    cat > /opt/vpnserver.sh <<'EOF'
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
    cat > /etc/systemd/system/vpnserver.service <<EOF
[Unit]
Description = SoftEther VPN Server
After = network.target

[Service]
ExecStart = /opt/vpnserver.sh start
ExecStop = /opt/vpnserver.sh stop
ExecReload = /opt/vpnserver.sh restart
Restart = always
Type = forking

[Install]
WantedBy = multi-user.target
EOF
    
    # Start service
    systemctl daemon-reload
    systemctl enable vpnserver
    systemctl start vpnserver
    
    # Verify status
    echo -e "\n\033[1;32mInstallation completed successfully!\033[0m"
    echo -e "\033[1;33mService Status:\033[0m"
    systemctl status vpnserver --no-pager
    echo -e "\n\033[1;33mManagement Command:\033[0m /usr/local/vpnserver/vpncmd"
    echo -e "\033[1;33mServer Admin Port:\033[0m 5555"
}

# Main menu
echo -e "\n\033[1;35mSoftEther VPN Server Installation Manager\033[0m"
echo -e "===========================================\n"

# Check installation status
if check_installation; then
    echo -e "\n\033[1;36mSelect an option:\033[0m"
    echo "1) Reinstall SoftEther VPN Server"
    echo "2) Uninstall SoftEther VPN Server"
    echo "3) Exit"
    
    while true; do
        read -rp "Enter choice [1-3]: " main_choice
        case $main_choice in
            1)
                echo -e "\n\033[1;33mReinstalling SoftEther VPN Server...\033[0m"
                uninstall_softether
                get_latest_versions
                select_architecture
                install_dependencies
                install_softether
                break
                ;;
            2)
                uninstall_softether
                exit 0
                ;;
            3)
                exit 0
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
else
    echo -e "\n\033[1;36mSelect an option:\033[0m"
    echo "1) Install SoftEther VPN Server"
    echo "2) Exit"
    
    while true; do
        read -rp "Enter choice [1-2]: " main_choice
        case $main_choice in
            1)
                get_latest_versions
                select_architecture
                install_dependencies
                install_softether
                break
                ;;
            2)
                exit 0
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
fi


#!/bin/bash
# SoftEther VPN Server Installation Manager
# Supports install, reinstall, and uninstall with version selection
# Fetches packages directly from SoftEther's official file server

# Supported architectures: x86-32bit, x64-64bit, ARM-32bit, ARM-64bit
# Usage: sudo ./autoinstall_softether-server.sh

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
    rm -f /etc/systemd/system/vpnserver.service
    
    # Remove files
    rm -f /opt/vpnserver.sh
    rm -rf /usr/local/vpnserver
    
    # Remove extracted files in /opt
    find /opt -maxdepth 1 -type d -name 'vpnserver' -exec rm -rf {} +
    find /opt -maxdepth 1 -type f -name 'softether-vpnserver-*.tar.gz' -exec rm -f {} +
    
    echo -e "\033[1;32mUninstallation completed successfully!\033[0m"
}

# Function to get latest versions
get_latest_versions() {
    echo -e "\n\033[1;34mFetching latest RTM versions...\033[0m"
    # Fetch directory listing and parse version strings
    versions=$(curl -s https://www.softether-download.com/files/softether/ |
               grep -oP 'href="\Kv[^"]+' |
               grep -E 'v[0-9]+\.[0-9]+-[0-9]+-rtm-[0-9]{4}\.[0-9]{2}\.[0-9]{2}-tree' |
               sort -r | head -3)
    
    # Verify we found RTM versions
    if [ -z "$versions" ]; then
        echo -e "\033[1;31mError: No RTM versions found. Possible causes:\033[0m"
        echo "1. Website structure changed"
        echo "2. No RTM releases available"
        echo "3. Temporary network issue"
        echo -e "\nPlease check manually: https://www.softether-download.com/files/softether/"
        exit 1
    fi
    
    # Convert to array
    version_array=()
    while IFS= read -r line; do
        version_array+=("$line")
    done <<< "$versions"
    
    # Display version menu
    echo -e "\n\033[1;36mSelect a version:\033[0m"
    for i in "${!version_array[@]}"; do
        clean_version=$(echo "${version_array[$i]}" | sed 's/^v//; s/-tree$//')
        echo "$((i+1))) $clean_version"
    done
    echo "4) Enter custom version"
    
    # Get user selection
    while true; do
        read -rp "Enter choice [1-4]: " version_choice
        case $version_choice in
            1|2|3)
                selected_version="${version_array[$((version_choice-1))]}"
                clean_version=$(echo "$selected_version" | sed 's/^v//; s/-tree$//')
                break
                ;;
            4)
                read -rp "Enter version (e.g., v4.44-9807-rtm-2025.04.16-tree): " selected_version
                # Validate custom version format
                if [[ ! "$selected_version" =~ ^v[0-9]+\.[0-9]+-[0-9]+-rtm-[0-9]{4}\.[0-9]{2}\.[0-9]{2}-tree$ ]]; then
                    echo -e "\033[1;31mInvalid version format. Please use the format: vX.XX-XXXX-rtm-YYYY.MM.DD-tree\033[0m"
                    continue
                fi
                clean_version=$(echo "$selected_version" | sed 's/^v//; s/-tree$//')
                break
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
    
    # Build download URL
    download_dir="https://www.softether-download.com/files/softether/$selected_version/Linux/"
    echo -e "\nSelected version: \033[1;33m$clean_version\033[0m"
}

# Function to select architecture
select_architecture() {
    echo -e "\n\033[1;36mSelect architecture:\033[0m"
    echo "1) 32-bit (x86)"
    echo "2) 64-bit (x64)"
    echo "3) ARM 32-bit"
    echo "4) ARM 64-bit"
    
    while true; do
        read -rp "Enter choice [1-4]: " arch_choice
        case $arch_choice in
            1) 
                arch="x86-32bit"
                break
                ;;
            2) 
                arch="x64-64bit"
                break
                ;;
            3) 
                arch="arm_eabi-32bit"
                break
                ;;
            4) 
                arch="arm64-64bit"
                break
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
    
    # Build filename pattern
    filename_pattern="softether-vpnserver-${clean_version}-linux-${arch}.tar.gz"
    echo -e "\nSelected architecture: \033[1;33m$arch\033[0m"
    echo -e "Filename pattern: \033[1;33m$filename_pattern\033[0m"
}

# Function to install dependencies
install_dependencies() {
    echo -e "\n\033[1;34mInstalling dependencies...\033[0m"
    apt update
    apt install -y \
        build-essential \
        libssl-dev \
        zlib1g-dev \
        libncurses5-dev \
        libedit-dev \
        libreadline-dev
}

# Function to install SoftEther
install_softether() {
    # Download the file
    download_url="${download_dir}${filename_pattern}"
    echo -e "\n\033[1;34mDownloading package...\033[0m"
    echo -e "URL: \033[1;33m$download_url\033[0m"
    
    cd /opt
    wget "$download_url"
    
    if [ ! -f "$filename_pattern" ]; then
        echo -e "\033[1;31mDownload failed. Please check the URL and try again.\033[0m"
        exit 1
    fi
    
    # Extract and install
    echo -e "\n\033[1;34mExtracting package...\033[0m"
    tar xzvf "$filename_pattern"
    
    echo -e "\n\033[1;34mCompiling VPN Server...\033[0m"
    cd ./vpnserver
    make >/dev/null
    
    echo -e "\n\033[1;34mInstalling to /usr/local/vpnserver...\033[0m"
    cd ..
    mv vpnserver /usr/local
    cd /usr/local/vpnserver
    chmod 600 *
    chmod 700 vpncmd vpnserver
    
    # Verify installation
    echo -e "\n\033[1;34mRunning configuration check...\033[0m"
    ./vpncmd <<CMD
3
check
exit
CMD
    
    # Create service script
    echo -e "\n\033[1;34mCreating system service...\033[0m"
    cat > /opt/vpnserver.sh <<'EOF'
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
    cat > /etc/systemd/system/vpnserver.service <<EOF
[Unit]
Description = SoftEther VPN Server
After = network.target

[Service]
ExecStart = /opt/vpnserver.sh start
ExecStop = /opt/vpnserver.sh stop
ExecReload = /opt/vpnserver.sh restart
Restart = always
Type = forking

[Install]
WantedBy = multi-user.target
EOF
    
    # Start service
    systemctl daemon-reload
    systemctl enable vpnserver
    systemctl start vpnserver
    
    # Verify status
    echo -e "\n\033[1;32mInstallation completed successfully!\033[0m"
    echo -e "\033[1;33mService Status:\033[0m"
    systemctl status vpnserver --no-pager
    echo -e "\n\033[1;33mManagement Command:\033[0m /usr/local/vpnserver/vpncmd"
    echo -e "\033[1;33mServer Admin Port:\033[0m 5555"
}

# Main menu
echo -e "\n\033[1;35mSoftEther VPN Server Installation Manager\033[0m"
echo -e "===========================================\n"

# Check installation status
if check_installation; then
    echo -e "\n\033[1;36mSelect an option:\033[0m"
    echo "1) Reinstall SoftEther VPN Server"
    echo "2) Uninstall SoftEther VPN Server"
    echo "3) Exit"
    
    while true; do
        read -rp "Enter choice [1-3]: " main_choice
        case $main_choice in
            1)
                echo -e "\n\033[1;33mReinstalling SoftEther VPN Server...\033[0m"
                uninstall_softether
                get_latest_versions
                select_architecture
                install_dependencies
                install_softether
                break
                ;;
            2)
                uninstall_softether
                exit 0
                ;;
            3)
                exit 0
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
else
    echo -e "\n\033[1;36mSelect an option:\033[0m"
    echo "1) Install SoftEther VPN Server"
    echo "2) Exit"
    
    while true; do
        read -rp "Enter choice [1-2]: " main_choice
        case $main_choice in
            1)
                get_latest_versions
                select_architecture
                install_dependencies
                install_softether
                break
                ;;
            2)
                exit 0
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
fi


#!/bin/bash
# SoftEther VPN Server Installation Manager
# Supports install, reinstall, and uninstall with version selection
# Fetches packages directly from SoftEther's official file server

# Supported architectures: x86-32bit, x64-64bit, ARM-32bit, ARM-64bit
# Usage: sudo ./autoinstall_softether-server.sh

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
    rm -f /etc/systemd/system/vpnserver.service
    
    # Remove files
    rm -f /opt/vpnserver.sh
    rm -rf /usr/local/vpnserver
    
    # Remove extracted files in /opt
    find /opt -maxdepth 1 -type d -name 'vpnserver' -exec rm -rf {} +
    find /opt -maxdepth 1 -type f -name 'softether-vpnserver-*.tar.gz' -exec rm -f {} +
    
    echo -e "\033[1;32mUninstallation completed successfully!\033[0m"
}

# Function to get latest versions
get_latest_versions() {
    echo -e "\n\033[1;34mFetching latest RTM versions...\033[0m"
    
    # Get directory listing and process versions
    versions=$(curl -s https://www.softether-download.com/files/softether/ | 
               grep -oP 'href="\K[^"]+' | 
               awk -F'/' '{print $NF}' | 
               grep -E '^v[0-9]+\.[0-9]+-[0-9]+-rtm-[0-9]{4}\.[0-9]{2}\.[0-9]{2}-tree$' | 
               sort -r | 
               head -3)
    
    # Verify we found RTM versions
    if [ -z "$versions" ]; then
        echo -e "\033[1;31mError: No RTM versions found. Possible causes:\033[0m"
        echo "1. Website structure changed"
        echo "2. No RTM releases available"
        echo "3. Temporary network issue"
        echo -e "\nPlease check manually: https://www.softether-download.com/files/softether/"
        exit 1
    fi
    
    # Convert to array
    version_array=()
    while IFS= read -r line; do
        version_array+=("$line")
    done <<< "$versions"
    
    # Display version menu
    echo -e "\n\033[1;36mSelect a version:\033[0m"
    for i in "${!version_array[@]}"; do
        clean_version=$(echo "${version_array[$i]}" | sed 's/^v//; s/-tree$//')
        echo "$((i+1))) $clean_version"
    done
    echo "4) Enter custom version"
    
    # Get user selection
    while true; do
        read -rp "Enter choice [1-4]: " version_choice
        case $version_choice in
            1|2|3)
                selected_version="${version_array[$((version_choice-1))]}"
                clean_version=$(echo "$selected_version" | sed 's/^v//; s/-tree$//')
                break
                ;;
            4)
                read -rp "Enter version (e.g., v4.44-9807-rtm-2025.04.16-tree): " selected_version
                # Validate custom version format
                if [[ ! "$selected_version" =~ ^v[0-9]+\.[0-9]+-[0-9]+-rtm-[0-9]{4}\.[0-9]{2}\.[0-9]{2}-tree$ ]]; then
                    echo -e "\033[1;31mInvalid version format. Please use the format: vX.XX-XXXX-rtm-YYYY.MM.DD-tree\033[0m"
                    continue
                fi
                clean_version=$(echo "$selected_version" | sed 's/^v//; s/-tree$//')
                break
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
    
    # Build download URL
    download_dir="https://www.softether-download.com/files/softether/$selected_version/Linux/"
    echo -e "\nSelected version: \033[1;33m$clean_version\033[0m"
}

# Function to select architecture
select_architecture() {
    echo -e "\n\033[1;36mSelect architecture:\033[0m"
    echo "1) 32-bit (x86)"
    echo "2) 64-bit (x64)"
    echo "3) ARM 32-bit"
    echo "4) ARM 64-bit"
    
    while true; do
        read -rp "Enter choice [1-4]: " arch_choice
        case $arch_choice in
            1) 
                arch="x86-32bit"
                break
                ;;
            2) 
                arch="x64-64bit"
                break
                ;;
            3) 
                arch="arm_eabi-32bit"
                break
                ;;
            4) 
                arch="arm64-64bit"
                break
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
    
    # Build filename pattern
    filename_pattern="softether-vpnserver-${clean_version}-linux-${arch}.tar.gz"
    echo -e "\nSelected architecture: \033[1;33m$arch\033[0m"
    echo -e "Filename pattern: \033[1;33m$filename_pattern\033[0m"
}

# Function to install dependencies
install_dependencies() {
    echo -e "\n\033[1;34mInstalling dependencies...\033[0m"
    apt update
    apt install -y \
        build-essential \
        libssl-dev \
        zlib1g-dev \
        libncurses5-dev \
        libedit-dev \
        libreadline-dev
}

# Function to install SoftEther
install_softether() {
    # Download the file
    download_url="${download_dir}${filename_pattern}"
    echo -e "\n\033[1;34mDownloading package...\033[0m"
    echo -e "URL: \033[1;33m$download_url\033[0m"
    
    cd /opt
    wget "$download_url"
    
    if [ ! -f "$filename_pattern" ]; then
        echo -e "\033[1;31mDownload failed. Please check the URL and try again.\033[0m"
        exit 1
    fi
    
    # Extract and install
    echo -e "\n\033[1;34mExtracting package...\033[0m"
    tar xzvf "$filename_pattern"
    
    echo -e "\n\033[1;34mCompiling VPN Server...\033[0m"
    cd ./vpnserver
    make >/dev/null
    
    echo -e "\n\033[1;34mInstalling to /usr/local/vpnserver...\033[0m"
    cd ..
    mv vpnserver /usr/local
    cd /usr/local/vpnserver
    chmod 600 *
    chmod 700 vpncmd vpnserver
    
    # Verify installation
    echo -e "\n\033[1;34mRunning configuration check...\033[0m"
    ./vpncmd <<CMD
3
check
exit
CMD
    
    # Create service script
    echo -e "\n\033[1;34mCreating system service...\033[0m"
    cat > /opt/vpnserver.sh <<'EOF'
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
    cat > /etc/systemd/system/vpnserver.service <<EOF
[Unit]
Description = SoftEther VPN Server
After = network.target

[Service]
ExecStart = /opt/vpnserver.sh start
ExecStop = /opt/vpnserver.sh stop
ExecReload = /opt/vpnserver.sh restart
Restart = always
Type = forking

[Install]
WantedBy = multi-user.target
EOF
    
    # Start service
    systemctl daemon-reload
    systemctl enable vpnserver
    systemctl start vpnserver
    
    # Verify status
    echo -e "\n\033[1;32mInstallation completed successfully!\033[0m"
    echo -e "\033[1;33mService Status:\033[0m"
    systemctl status vpnserver --no-pager
    echo -e "\n\033[1;33mManagement Command:\033[0m /usr/local/vpnserver/vpncmd"
    echo -e "\033[1;33mServer Admin Port:\033[0m 5555"
}

# Main menu
echo -e "\n\033[1;35mSoftEther VPN Server Installation Manager\033[0m"
echo -e "===========================================\n"

# Check installation status
if check_installation; then
    echo -e "\n\033[1;36mSelect an option:\033[0m"
    echo "1) Reinstall SoftEther VPN Server"
    echo "2) Uninstall SoftEther VPN Server"
    echo "3) Exit"
    
    while true; do
        read -rp "Enter choice [1-3]: " main_choice
        case $main_choice in
            1)
                echo -e "\n\033[1;33mReinstalling SoftEther VPN Server...\033[0m"
                uninstall_softether
                get_latest_versions
                select_architecture
                install_dependencies
                install_softether
                break
                ;;
            2)
                uninstall_softether
                exit 0
                ;;
            3)
                exit 0
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
else
    echo -e "\n\033[1;36mSelect an option:\033[0m"
    echo "1) Install SoftEther VPN Server"
    echo "2) Exit"
    
    while true; do
        read -rp "Enter choice [1-2]: " main_choice
        case $main_choice in
            1)
                get_latest_versions
                select_architecture
                install_dependencies
                install_softether
                break
                ;;
            2)
                exit 0
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
fi

#!/bin/bash
# SoftEther VPN Server Installation Manager
# Supports install, reinstall, and uninstall with version selection
# Fetches packages directly from SoftEther's official file server

# Supported architectures: x86-32bit, x64-64bit, ARM-32bit, ARM-64bit
# Usage: sudo ./autoinstall_softether-server.sh

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
    rm -f /etc/systemd/system/vpnserver.service
    
    # Remove files
    rm -f /opt/vpnserver.sh
    rm -rf /usr/local/vpnserver
    
    # Remove extracted files in /opt
    find /opt -maxdepth 1 -type d -name 'vpnserver' -exec rm -rf {} +
    find /opt -maxdepth 1 -type f -name 'softether-vpnserver-*.tar.gz' -exec rm -f {} +
    
    echo -e "\033[1;32mUninstallation completed successfully!\033[0m"
}

# Function to get latest versions
get_latest_versions() {
    echo -e "\n\033[1;34mFetching latest RTM versions...\033[0m"
    
    # Get directory listing and process versions
    versions=$(curl -s https://www.softether-download.com/files/softether/ | 
               grep -oP 'href="\K[^"]+' | 
               awk -F'/' '{print $NF}' | 
               grep -E '^v[0-9]+\.[0-9]+-[0-9]+-rtm-[0-9]{4}\.[0-9]{2}\.[0-9]{2}-tree$' | 
               sort -r | 
               head -3)
    
    # Verify we found RTM versions
    if [ -z "$versions" ]; then
        echo -e "\033[1;31mError: No RTM versions found. Possible causes:\033[0m"
        echo "1. Website structure changed"
        echo "2. No RTM releases available"
        echo "3. Temporary network issue"
        echo -e "\nPlease check manually: https://www.softether-download.com/files/softether/"
        exit 1
    fi
    
    # Convert to array
    version_array=()
    while IFS= read -r line; do
        version_array+=("$line")
    done <<< "$versions"
    
    # Display version menu
    echo -e "\n\033[1;36mSelect a version:\033[0m"
    for i in "${!version_array[@]}"; do
        clean_version=$(echo "${version_array[$i]}" | sed 's/^v//; s/-tree$//')
        echo "$((i+1))) $clean_version"
    done
    echo "4) Enter custom version"
    
    # Get user selection
    while true; do
        read -rp "Enter choice [1-4]: " version_choice
        case $version_choice in
            1|2|3)
                selected_version="${version_array[$((version_choice-1))]}"
                clean_version=$(echo "$selected_version" | sed 's/^v//; s/-tree$//')
                break
                ;;
            4)
                read -rp "Enter version (e.g., v4.44-9807-rtm-2025.04.16-tree): " selected_version
                # Validate custom version format
                if [[ ! "$selected_version" =~ ^v[0-9]+\.[0-9]+-[0-9]+-rtm-[0-9]{4}\.[0-9]{2}\.[0-9]{2}-tree$ ]]; then
                    echo -e "\033[1;31mInvalid version format. Please use the format: vX.XX-XXXX-rtm-YYYY.MM.DD-tree\033[0m"
                    continue
                fi
                clean_version=$(echo "$selected_version" | sed 's/^v//; s/-tree$//')
                break
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
    
    # Build download URL
    download_dir="https://www.softether-download.com/files/softether/$selected_version/Linux/"
    echo -e "\nSelected version: \033[1;33m$clean_version\033[0m"
}

# Function to select architecture
select_architecture() {
    echo -e "\n\033[1;36mSelect architecture:\033[0m"
    echo "1) 32-bit (x86)"
    echo "2) 64-bit (x64)"
    echo "3) ARM 32-bit"
    echo "4) ARM 64-bit"
    
    while true; do
        read -rp "Enter choice [1-4]: " arch_choice
        case $arch_choice in
            1) 
                arch="x86-32bit"
                break
                ;;
            2) 
                arch="x64-64bit"
                break
                ;;
            3) 
                arch="arm_eabi-32bit"
                break
                ;;
            4) 
                arch="arm64-64bit"
                break
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
    
    # Build filename pattern
    filename_pattern="softether-vpnserver-${clean_version}-linux-${arch}.tar.gz"
    echo -e "\nSelected architecture: \033[1;33m$arch\033[0m"
    echo -e "Filename pattern: \033[1;33m$filename_pattern\033[0m"
}

# Function to install dependencies
install_dependencies() {
    echo -e "\n\033[1;34mInstalling dependencies...\033[0m"
    apt update
    apt install -y \
        build-essential \
        libssl-dev \
        zlib1g-dev \
        libncurses5-dev \
        libedit-dev \
        libreadline-dev
}

# Function to install SoftEther
install_softether() {
    # Download the file
    download_url="${download_dir}${filename_pattern}"
    echo -e "\n\033[1;34mDownloading package...\033[0m"
    echo -e "URL: \033[1;33m$download_url\033[0m"
    
    cd /opt
    wget "$download_url"
    
    if [ ! -f "$filename_pattern" ]; then
        echo -e "\033[1;31mDownload failed. Please check the URL and try again.\033[0m"
        exit 1
    fi
    
    # Extract and install
    echo -e "\n\033[1;34mExtracting package...\033[0m"
    tar xzvf "$filename_pattern"
    
    echo -e "\n\033[1;34mCompiling VPN Server...\033[0m"
    cd ./vpnserver
    make >/dev/null
    
    echo -e "\n\033[1;34mInstalling to /usr/local/vpnserver...\033[0m"
    cd ..
    mv vpnserver /usr/local
    cd /usr/local/vpnserver
    chmod 600 *
    chmod 700 vpncmd vpnserver
    
    # Verify installation
    echo -e "\n\033[1;34mRunning configuration check...\033[0m"
    ./vpncmd <<CMD
3
check
exit
CMD
    
    # Create service script
    echo -e "\n\033[1;34mCreating system service...\033[0m"
    cat > /opt/vpnserver.sh <<'EOF'
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
    cat > /etc/systemd/system/vpnserver.service <<EOF
[Unit]
Description = SoftEther VPN Server
After = network.target

[Service]
ExecStart = /opt/vpnserver.sh start
ExecStop = /opt/vpnserver.sh stop
ExecReload = /opt/vpnserver.sh restart
Restart = always
Type = forking

[Install]
WantedBy = multi-user.target
EOF
    
    # Start service
    systemctl daemon-reload
    systemctl enable vpnserver
    systemctl start vpnserver
    
    # Verify status
    echo -e "\n\033[1;32mInstallation completed successfully!\033[0m"
    echo -e "\033[1;33mService Status:\033[0m"
    systemctl status vpnserver --no-pager
    echo -e "\n\033[1;33mManagement Command:\033[0m /usr/local/vpnserver/vpncmd"
    echo -e "\033[1;33mServer Admin Port:\033[0m 5555"
}

# Main menu
echo -e "\n\033[1;35mSoftEther VPN Server Installation Manager\033[0m"
echo -e "===========================================\n"

# Check installation status
if check_installation; then
    echo -e "\n\033[1;36mSelect an option:\033[0m"
    echo "1) Reinstall SoftEther VPN Server"
    echo "2) Uninstall SoftEther VPN Server"
    echo "3) Exit"
    
    while true; do
        read -rp "Enter choice [1-3]: " main_choice
        case $main_choice in
            1)
                echo -e "\n\033[1;33mReinstalling SoftEther VPN Server...\033[0m"
                uninstall_softether
                get_latest_versions
                select_architecture
                install_dependencies
                install_softether
                break
                ;;
            2)
                uninstall_softether
                exit 0
                ;;
            3)
                exit 0
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
else
    echo -e "\n\033[1;36mSelect an option:\033[0m"
    echo "1) Install SoftEther VPN Server"
    echo "2) Exit"
    
    while true; do
        read -rp "Enter choice [1-2]: " main_choice
        case $main_choice in
            1)
                get_latest_versions
                select_architecture
                install_dependencies
                install_softether
                break
                ;;
            2)
                exit 0
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
fi


#!/bin/bash
# SoftEther VPN Server Installation Manager
# Supports install, reinstall, and uninstall with version selection
# Fetches packages directly from SoftEther's official file server

# Supported architectures: x86-32bit, x64-64bit, ARM-32bit, ARM-64bit
# Usage: sudo ./autoinstall_softether-server.sh

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
    rm -f /etc/systemd/system/vpnserver.service
    
    # Remove files
    rm -f /opt/vpnserver.sh
    rm -rf /usr/local/vpnserver
    
    # Remove extracted files in /opt
    find /opt -maxdepth 1 -type d -name 'vpnserver' -exec rm -rf {} +
    find /opt -maxdepth 1 -type f -name 'softether-vpnserver-*.tar.gz' -exec rm -f {} +
    
    echo -e "\033[1;32mUninstallation completed successfully!\033[0m"
}

# Function to get latest versions
get_latest_versions() {
    echo -e "\n\033[1;34mFetching latest RTM versions...\033[0m"
    
    # Fetch directory listing and parse version strings
    versions=$(curl -s https://www.softether-download.com/files/softether/ |
               grep -oP 'href="\K[^"]+' |  # Extract all href values
               awk -F'/' '{print $NF}' |    # Get last path component
               grep -E '^v[0-9]+\.[0-9]+-[0-9]+-rtm-[0-9]{4}\.[0-9]{2}\.[0-9]{2}-tree$' |
               sort -t '-' -k4.1,4.4nr -k4.6,4.7Mr -k4.9,4.10nr |  # Sort by date descending
               head -3)
    
    # Verify we found RTM versions
    if [ -z "$versions" ]; then
        echo -e "\033[1;31mError: No RTM versions found. Possible causes:\033[0m"
        echo "1. Website structure changed"
        echo "2. No RTM releases available"
        echo "3. Temporary network issue"
        echo -e "\nPlease check manually: https://www.softether-download.com/files/softether/"
        exit 1
    fi
    
    # Convert to array
    version_array=()
    while IFS= read -r line; do
        version_array+=("$line")
    done <<< "$versions"
    
    # Display version menu
    echo -e "\n\033[1;36mSelect a version:\033[0m"
    for i in "${!version_array[@]}"; do
        clean_version=$(echo "${version_array[$i]}" | sed 's/^v//; s/-tree$//')
        echo "$((i+1))) $clean_version"
    done
    echo "4) Enter custom version"
    
    # Get user selection
    while true; do
        read -rp "Enter choice [1-4]: " version_choice
        case $version_choice in
            1|2|3)
                selected_version="${version_array[$((version_choice-1))]}"
                clean_version=$(echo "$selected_version" | sed 's/^v//; s/-tree$//')
                break
                ;;
            4)
                read -rp "Enter version (e.g., v4.44-9807-rtm-2025.04.16-tree): " selected_version
                # Validate custom version format
                if [[ ! "$selected_version" =~ ^v[0-9]+\.[0-9]+-[0-9]+-rtm-[0-9]{4}\.[0-9]{2}\.[0-9]{2}-tree$ ]]; then
                    echo -e "\033[1;31mInvalid version format. Please use the format: vX.XX-XXXX-rtm-YYYY.MM.DD-tree\033[0m"
                    continue
                fi
                clean_version=$(echo "$selected_version" | sed 's/^v//; s/-tree$//')
                break
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
    
    # Build download URL
    download_dir="https://www.softether-download.com/files/softether/$selected_version/Linux/"
    echo -e "\nSelected version: \033[1;33m$clean_version\033[0m"
}

# Function to select architecture
select_architecture() {
    echo -e "\n\033[1;36mSelect architecture:\033[0m"
    echo "1) 32-bit (x86)"
    echo "2) 64-bit (x64)"
    echo "3) ARM 32-bit"
    echo "4) ARM 64-bit"
    
    while true; do
        read -rp "Enter choice [1-4]: " arch_choice
        case $arch_choice in
            1) 
                arch="x86-32bit"
                break
                ;;
            2) 
                arch="x64-64bit"
                break
                ;;
            3) 
                arch="arm_eabi-32bit"
                break
                ;;
            4) 
                arch="arm64-64bit"
                break
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
    
    # Build filename pattern
    filename_pattern="softether-vpnserver-${clean_version}-linux-${arch}.tar.gz"
    echo -e "\nSelected architecture: \033[1;33m$arch\033[0m"
    echo -e "Filename pattern: \033[1;33m$filename_pattern\033[0m"
}

# Function to install dependencies
install_dependencies() {
    echo -e "\n\033[1;34mInstalling dependencies...\033[0m"
    apt update
    apt install -y \
        build-essential \
        libssl-dev \
        zlib1g-dev \
        libncurses5-dev \
        libedit-dev \
        libreadline-dev
}

# Function to install SoftEther
install_softether() {
    # Download the file
    download_url="${download_dir}${filename_pattern}"
    echo -e "\n\033[1;34mDownloading package...\033[0m"
    echo -e "URL: \033[1;33m$download_url\033[0m"
    
    cd /opt
    wget "$download_url"
    
    if [ ! -f "$filename_pattern" ]; then
        echo -e "\033[1;31mDownload failed. Please check the URL and try again.\033[0m"
        exit 1
    fi
    
    # Extract and install
    echo -e "\n\033[1;34mExtracting package...\033[0m"
    tar xzvf "$filename_pattern"
    
    echo -e "\n\033[1;34mCompiling VPN Server...\033[0m"
    cd ./vpnserver
    make >/dev/null
    
    echo -e "\n\033[1;34mInstalling to /usr/local/vpnserver...\033[0m"
    cd ..
    mv vpnserver /usr/local
    cd /usr/local/vpnserver
    chmod 600 *
    chmod 700 vpncmd vpnserver
    
    # Verify installation
    echo -e "\n\033[1;34mRunning configuration check...\033[0m"
    ./vpncmd <<CMD
3
check
exit
CMD
    
    # Create service script
    echo -e "\n\033[1;34mCreating system service...\033[0m"
    cat > /opt/vpnserver.sh <<'EOF'
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
    cat > /etc/systemd/system/vpnserver.service <<EOF
[Unit]
Description = SoftEther VPN Server
After = network.target

[Service]
ExecStart = /opt/vpnserver.sh start
ExecStop = /opt/vpnserver.sh stop
ExecReload = /opt/vpnserver.sh restart
Restart = always
Type = forking

[Install]
WantedBy = multi-user.target
EOF
    
    # Start service
    systemctl daemon-reload
    systemctl enable vpnserver
    systemctl start vpnserver
    
    # Verify status
    echo -e "\n\033[1;32mInstallation completed successfully!\033[0m"
    echo -e "\033[1;33mService Status:\033[0m"
    systemctl status vpnserver --no-pager
    echo -e "\n\033[1;33mManagement Command:\033[0m /usr/local/vpnserver/vpncmd"
    echo -e "\033[1;33mServer Admin Port:\033[0m 5555"
}

# Main menu
echo -e "\n\033[1;35mSoftEther VPN Server Installation Manager\033[0m"
echo -e "===========================================\n"

# Check installation status
if check_installation; then
    echo -e "\n\033[1;36mSelect an option:\033[0m"
    echo "1) Reinstall SoftEther VPN Server"
    echo "2) Uninstall SoftEther VPN Server"
    echo "3) Exit"
    
    while true; do
        read -rp "Enter choice [1-3]: " main_choice
        case $main_choice in
            1)
                echo -e "\n\033[1;33mReinstalling SoftEther VPN Server...\033[0m"
                uninstall_softether
                get_latest_versions
                select_architecture
                install_dependencies
                install_softether
                break
                ;;
            2)
                uninstall_softether
                exit 0
                ;;
            3)
                exit 0
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
else
    echo -e "\n\033[1;36mSelect an option:\033[0m"
    echo "1) Install SoftEther VPN Server"
    echo "2) Exit"
    
    while true; do
        read -rp "Enter choice [1-2]: " main_choice
        case $main_choice in
            1)
                get_latest_versions
                select_architecture
                install_dependencies
                install_softether
                break
                ;;
            2)
                exit 0
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
fi


#!/bin/bash
# SoftEther VPN Server Installation Manager
# Supports install, reinstall, and uninstall with version selection
# Fetches packages directly from SoftEther's official file server

# Supported architectures: x86-32bit, x64-64bit, ARM-32bit, ARM-64bit
# Usage: sudo ./autoinstall_softether-server.sh

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
    rm -f /etc/systemd/system/vpnserver.service
    
    # Remove files
    rm -f /opt/vpnserver.sh
    rm -rf /usr/local/vpnserver
    
    # Remove extracted files in /opt
    find /opt -maxdepth 1 -type d -name 'vpnserver' -exec rm -rf {} +
    find /opt -maxdepth 1 -type f -name 'softether-vpnserver-*.tar.gz' -exec rm -f {} +
    
    echo -e "\033[1;32mUninstallation completed successfully!\033[0m"
}

# Function to get latest versions
get_latest_versions() {
    echo -e "\n\033[1;34mFetching latest RTM versions...\033[0m"
    
    # Fetch directory listing and process versions
    versions=$(curl -s https://www.softether-download.com/files/softether/ | 
               grep -oP 'href="\K[^"]+' | 
               grep 'rtm' | 
               grep -E '202[0-9]+\.[0-9]{2}\.[0-9]{2}' |
               sort -r | 
               head -3)
    
    # Verify we found RTM versions
    if [ -z "$versions" ]; then
        # Fallback to manual parsing if initial method fails
        versions=$(curl -s https://www.softether-download.com/files/softether/ | 
                   grep -oP 'href="\K[^"]+' | 
                   while read -r line; do
                       if [[ "$line" == *"rtm"* && "$line" =~ 202[0-9]+\.[0-9]{2}\.[0-9]{2} ]]; then
                           date_str="${BASH_REMATCH[0]}"
                           year="${date_str:0:4}"
                           month="${date_str:5:2}"
                           if (( year >= 2020 && month >= 1 && month <= 12 )); then
                               echo "$line"
                           fi
                       fi
                   done | sort -r | head -3)
    fi
    
    if [ -z "$versions" ]; then
        echo -e "\033[1;31mError: No RTM versions found. Possible causes:\033[0m"
        echo "1. Website structure changed"
        echo "2. No RTM releases available"
        echo "3. Temporary network issue"
        echo -e "\nPlease check manually: https://www.softether-download.com/files/softether/"
        exit 1
    fi
    
    # Convert to array
    version_array=()
    while IFS= read -r line; do
        version_array+=("$line")
    done <<< "$versions"
    
    # Display version menu
    echo -e "\n\033[1;36mSelect a version:\033[0m"
    for i in "${!version_array[@]}"; do
        clean_version=$(basename "${version_array[$i]}" | sed 's|/$||; s/^v//; s/-tree$//')
        echo "$((i+1))) $clean_version"
    done
    echo "4) Enter custom version"
    
    # Get user selection
    while true; do
        read -rp "Enter choice [1-4]: " version_choice
        case $version_choice in
            1|2|3)
                selected_version=$(basename "${version_array[$((version_choice-1))]}" | sed 's|/$||')
                clean_version=$(echo "$selected_version" | sed 's/^v//; s/-tree$//')
                break
                ;;
            4)
                read -rp "Enter version (e.g., v4.44-9807-rtm-2025.04.16-tree): " selected_version
                # Validate custom version format
                if [[ ! "$selected_version" =~ ^v[0-9]+\.[0-9]+-[0-9]+-rtm-[0-9]{4}\.[0-9]{2}\.[0-9]{2}-tree$ ]]; then
                    echo -e "\033[1;31mInvalid version format. Please use the format: vX.XX-XXXX-rtm-YYYY.MM.DD-tree\033[0m"
                    continue
                fi
                clean_version=$(echo "$selected_version" | sed 's/^v//; s/-tree$//')
                break
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
    
    # Build download URL
    download_dir="https://www.softether-download.com/files/softether/$selected_version/Linux/"
    echo -e "\nSelected version: \033[1;33m$clean_version\033[0m"
}

# Function to select architecture
select_architecture() {
    echo -e "\n\033[1;36mSelect architecture:\033[0m"
    echo "1) 32-bit (x86)"
    echo "2) 64-bit (x64)"
    echo "3) ARM 32-bit"
    echo "4) ARM 64-bit"
    
    while true; do
        read -rp "Enter choice [1-4]: " arch_choice
        case $arch_choice in
            1) 
                arch="x86-32bit"
                break
                ;;
            2) 
                arch="x64-64bit"
                break
                ;;
            3) 
                arch="arm_eabi-32bit"
                break
                ;;
            4) 
                arch="arm64-64bit"
                break
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
    
    # Build filename pattern
    filename_pattern="softether-vpnserver-${clean_version}-linux-${arch}.tar.gz"
    echo -e "\nSelected architecture: \033[1;33m$arch\033[0m"
    echo -e "Filename pattern: \033[1;33m$filename_pattern\033[0m"
}

# Function to install dependencies
install_dependencies() {
    echo -e "\n\033[1;34mInstalling dependencies...\033[0m"
    apt update
    apt install -y \
        build-essential \
        libssl-dev \
        zlib1g-dev \
        libncurses5-dev \
        libedit-dev \
        libreadline-dev
}

# Function to install SoftEther
install_softether() {
    # Download the file
    download_url="${download_dir}${filename_pattern}"
    echo -e "\n\033[1;34mDownloading package...\033[0m"
    echo -e "URL: \033[1;33m$download_url\033[0m"
    
    cd /opt
    wget "$download_url"
    
    if [ ! -f "$filename_pattern" ]; then
        echo -e "\033[1;31mDownload failed. Please check the URL and try again.\033[0m"
        exit 1
    fi
    
    # Extract and install
    echo -e "\n\033[1;34mExtracting package...\033[0m"
    tar xzvf "$filename_pattern"
    
    echo -e "\n\033[1;34mCompiling VPN Server...\033[0m"
    cd ./vpnserver
    make >/dev/null
    
    echo -e "\n\033[1;34mInstalling to /usr/local/vpnserver...\033[0m"
    cd ..
    mv vpnserver /usr/local
    cd /usr/local/vpnserver
    chmod 600 *
    chmod 700 vpncmd vpnserver
    
    # Verify installation
    echo -e "\n\033[1;34mRunning configuration check...\033[0m"
    ./vpncmd <<CMD
3
check
exit
CMD
    
    # Create service script
    echo -e "\n\033[1;34mCreating system service...\033[0m"
    cat > /opt/vpnserver.sh <<'EOF'
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
    cat > /etc/systemd/system/vpnserver.service <<EOF
[Unit]
Description = SoftEther VPN Server
After = network.target

[Service]
ExecStart = /opt/vpnserver.sh start
ExecStop = /opt/vpnserver.sh stop
ExecReload = /opt/vpnserver.sh restart
Restart = always
Type = forking

[Install]
WantedBy = multi-user.target
EOF
    
    # Start service
    systemctl daemon-reload
    systemctl enable vpnserver
    systemctl start vpnserver
    
    # Verify status
    echo -e "\n\033[1;32mInstallation completed successfully!\033[0m"
    echo -e "\033[1;33mService Status:\033[0m"
    systemctl status vpnserver --no-pager
    echo -e "\n\033[1;33mManagement Command:\033[0m /usr/local/vpnserver/vpncmd"
    echo -e "\033[1;33mServer Admin Port:\033[0m 5555"
}

# Main menu
echo -e "\n\033[1;35mSoftEther VPN Server Installation Manager\033[0m"
echo -e "===========================================\n"

# Check installation status
if check_installation; then
    echo -e "\n\033[1;36mSelect an option:\033[0m"
    echo "1) Reinstall SoftEther VPN Server"
    echo "2) Uninstall SoftEther VPN Server"
    echo "3) Exit"
    
    while true; do
        read -rp "Enter choice [1-3]: " main_choice
        case $main_choice in
            1)
                echo -e "\n\033[1;33mReinstalling SoftEther VPN Server...\033[0m"
                uninstall_softether
                get_latest_versions
                select_architecture
                install_dependencies
                install_softether
                break
                ;;
            2)
                uninstall_softether
                exit 0
                ;;
            3)
                exit 0
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
else
    echo -e "\n\033[1;36mSelect an option:\033[0m"
    echo "1) Install SoftEther VPN Server"
    echo "2) Exit"
    
    while true; do
        read -rp "Enter choice [1-2]: " main_choice
        case $main_choice in
            1)
                get_latest_versions
                select_architecture
                install_dependencies
                install_softether
                break
                ;;
            2)
                exit 0
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
fi


#!/bin/bash
# SoftEther VPN Server Installation Manager
# Supports install, reinstall, and uninstall with version selection
# Fetches packages directly from SoftEther's official file server

# Supported architectures: x86-32bit, x64-64bit, ARM-32bit, ARM-64bit
# Usage: sudo ./autoinstall_softether-server.sh

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
    rm -f /etc/systemd/system/vpnserver.service
    
    # Remove files
    rm -f /opt/vpnserver.sh
    rm -rf /usr/local/vpnserver
    
    # Remove extracted files in /opt
    find /opt -maxdepth 1 -type d -name 'vpnserver' -exec rm -rf {} +
    find /opt -maxdepth 1 -type f -name 'softether-vpnserver-*.tar.gz' -exec rm -f {} +
    
    echo -e "\033[1;32mUninstallation completed successfully!\033[0m"
}

# Function to get latest versions
get_latest_versions() {
    echo -e "\n\033[1;34mFetching latest RTM versions...\033[0m"
    
    # Get directory listing and process versions
    versions=$(curl -s https://www.softether-download.com/files/softether/ | 
               grep -oP 'href="\K[^"]+' | 
               awk -F'/' '{print $NF}' | 
               grep -E '^v[0-9]+\.[0-9]+-[0-9]+-rtm-[0-9]{4}\.[0-9]{2}\.[0-9]{2}-tree$' | 
               sort -r | 
               head -3)
    
    # Verify we found RTM versions
    if [ -z "$versions" ]; then
        echo -e "\033[1;31mError: No RTM versions found. Possible causes:\033[0m"
        echo "1. Website structure changed"
        echo "2. No RTM releases available"
        echo "3. Temporary network issue"
        echo -e "\nPlease check manually: https://www.softether-download.com/files/softether/"
        exit 1
    fi
    
    # Convert to array
    version_array=()
    while IFS= read -r line; do
        version_array+=("$line")
    done <<< "$versions"
    
    # Display version menu
    echo -e "\n\033[1;36mSelect a version:\033[0m"
    for i in "${!version_array[@]}"; do
        clean_version=$(echo "${version_array[$i]}" | sed 's/^v//; s/-tree$//')
        echo "$((i+1))) $clean_version"
    done
    echo "4) Enter custom version"
    
    # Get user selection
    while true; do
        read -rp "Enter choice [1-4]: " version_choice
        case $version_choice in
            1|2|3)
                selected_version="${version_array[$((version_choice-1))]}"
                clean_version=$(echo "$selected_version" | sed 's/^v//; s/-tree$//')
                break
                ;;
            4)
                read -rp "Enter version (e.g., v4.44-9807-rtm-2025.04.16-tree): " selected_version
                # Validate custom version format
                if [[ ! "$selected_version" =~ ^v[0-9]+\.[0-9]+-[0-9]+-rtm-[0-9]{4}\.[0-9]{2}\.[0-9]{2}-tree$ ]]; then
                    echo -e "\033[1;31mInvalid version format. Please use the format: vX.XX-XXXX-rtm-YYYY.MM.DD-tree\033[0m"
                    continue
                fi
                clean_version=$(echo "$selected_version" | sed 's/^v//; s/-tree$//')
                break
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
    
    # Build download URL
    download_dir="https://www.softether-download.com/files/softether/$selected_version/Linux/"
    echo -e "\nSelected version: \033[1;33m$clean_version\033[0m"
}

# Function to select architecture
select_architecture() {
    echo -e "\n\033[1;36mSelect architecture:\033[0m"
    echo "1) 32-bit (x86)"
    echo "2) 64-bit (x64)"
    echo "3) ARM 32-bit"
    echo "4) ARM 64-bit"
    
    while true; do
        read -rp "Enter choice [1-4]: " arch_choice
        case $arch_choice in
            1) 
                arch="x86-32bit"
                break
                ;;
            2) 
                arch="x64-64bit"
                break
                ;;
            3) 
                arch="arm_eabi-32bit"
                break
                ;;
            4) 
                arch="arm64-64bit"
                break
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
    
    # Build filename pattern
    filename_pattern="softether-vpnserver-${clean_version}-linux-${arch}.tar.gz"
    echo -e "\nSelected architecture: \033[1;33m$arch\033[0m"
    echo -e "Filename pattern: \033[1;33m$filename_pattern\033[0m"
}

# Function to install dependencies
install_dependencies() {
    echo -e "\n\033[1;34mInstalling dependencies...\033[0m"
    apt update
    apt install -y \
        build-essential \
        libssl-dev \
        zlib1g-dev \
        libncurses5-dev \
        libedit-dev \
        libreadline-dev
}

# Function to install SoftEther
install_softether() {
    # Download the file
    download_url="${download_dir}${filename_pattern}"
    echo -e "\n\033[1;34mDownloading package...\033[0m"
    echo -e "URL: \033[1;33m$download_url\033[0m"
    
    cd /opt
    wget "$download_url"
    
    if [ ! -f "$filename_pattern" ]; then
        echo -e "\033[1;31mDownload failed. Please check the URL and try again.\033[0m"
        exit 1
    fi
    
    # Extract and install
    echo -e "\n\033[1;34mExtracting package...\033[0m"
    tar xzvf "$filename_pattern"
    
    echo -e "\n\033[1;34mCompiling VPN Server...\033[0m"
    cd ./vpnserver
    make >/dev/null
    
    echo -e "\n\033[1;34mInstalling to /usr/local/vpnserver...\033[0m"
    cd ..
    mv vpnserver /usr/local
    cd /usr/local/vpnserver
    chmod 600 *
    chmod 700 vpncmd vpnserver
    
    # Verify installation
    echo -e "\n\033[1;34mRunning configuration check...\033[0m"
    ./vpncmd <<CMD
3
check
exit
CMD
    
    # Create service script
    echo -e "\n\033[1;34mCreating system service...\033[0m"
    cat > /opt/vpnserver.sh <<'EOF'
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
    cat > /etc/systemd/system/vpnserver.service <<EOF
[Unit]
Description = SoftEther VPN Server
After = network.target

[Service]
ExecStart = /opt/vpnserver.sh start
ExecStop = /opt/vpnserver.sh stop
ExecReload = /opt/vpnserver.sh restart
Restart = always
Type = forking

[Install]
WantedBy = multi-user.target
EOF
    
    # Start service
    systemctl daemon-reload
    systemctl enable vpnserver
    systemctl start vpnserver
    
    # Verify status
    echo -e "\n\033[1;32mInstallation completed successfully!\033[0m"
    echo -e "\033[1;33mService Status:\033[0m"
    systemctl status vpnserver --no-pager
    echo -e "\n\033[1;33mManagement Command:\033[0m /usr/local/vpnserver/vpncmd"
    echo -e "\033[1;33mServer Admin Port:\033[0m 5555"
}

# Main menu
echo -e "\n\033[1;35mSoftEther VPN Server Installation Manager\033[0m"
echo -e "===========================================\n"

# Check installation status
if check_installation; then
    echo -e "\n\033[1;36mSelect an option:\033[0m"
    echo "1) Reinstall SoftEther VPN Server"
    echo "2) Uninstall SoftEther VPN Server"
    echo "3) Exit"
    
    while true; do
        read -rp "Enter choice [1-3]: " main_choice
        case $main_choice in
            1)
                echo -e "\n\033[1;33mReinstalling SoftEther VPN Server...\033[0m"
                uninstall_softether
                get_latest_versions
                select_architecture
                install_dependencies
                install_softether
                break
                ;;
            2)
                uninstall_softether
                exit 0
                ;;
            3)
                exit 0
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
else
    echo -e "\n\033[1;36mSelect an option:\033[0m"
    echo "1) Install SoftEther VPN Server"
    echo "2) Exit"
    
    while true; do
        read -rp "Enter choice [1-2]: " main_choice
        case $main_choice in
            1)
                get_latest_versions
                select_architecture
                install_dependencies
                install_softether
                break
                ;;
            2)
                exit 0
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
fi


#!/bin/bash
# SoftEther VPN Server Installation Manager
# Supports install, reinstall, and uninstall with version selection
# Fetches packages directly from SoftEther's official file server

# Supported architectures: x86-32bit, x64-64bit, ARM-32bit, ARM-64bit
# Usage: sudo ./autoinstall_softether-server.sh

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
    rm -f /etc/systemd/system/vpnserver.service
    
    # Remove files
    rm -f /opt/vpnserver.sh
    rm -rf /usr/local/vpnserver
    
    # Remove extracted files in /opt
    find /opt -maxdepth 1 -type d -name 'vpnserver' -exec rm -rf {} +
    find /opt -maxdepth 1 -type f -name 'softether-vpnserver-*.tar.gz' -exec rm -f {} +
    
    echo -e "\033[1;32mUninstallation completed successfully!\033[0m"
}

# Function to get latest versions
get_latest_versions() {
    echo -e "\n\033[1;34mFetching latest RTM versions...\033[0m"
    
    # Fetch directory listing and parse version strings
    versions=$(curl -s https://www.softether-download.com/files/softether/ |
               grep -oP 'href="\K[^"]+' |  # Extract all href values
               awk -F'/' '{print $NF}' |    # Get last path component
               grep -E '^v[0-9]+\.[0-9]+-[0-9]+-rtm-[0-9]{4}\.[0-9]{2}\.[0-9]{2}-tree$' |
               sort -t '-' -k4.1,4.4nr -k4.6,4.7Mr -k4.9,4.10nr |  # Sort by date descending
               head -3)
    
    # Verify we found RTM versions
    if [ -z "$versions" ]; then
        echo -e "\033[1;31mError: No RTM versions found. Possible causes:\033[0m"
        echo "1. Website structure changed"
        echo "2. No RTM releases available"
        echo "3. Temporary network issue"
        echo -e "\nPlease check manually: https://www.softether-download.com/files/softether/"
        exit 1
    fi
    
    # Convert to array
    version_array=()
    while IFS= read -r line; do
        version_array+=("$line")
    done <<< "$versions"
    
    # Display version menu
    echo -e "\n\033[1;36mSelect a version:\033[0m"
    for i in "${!version_array[@]}"; do
        clean_version=$(echo "${version_array[$i]}" | sed 's/^v//; s/-tree$//')
        echo "$((i+1))) $clean_version"
    done
    echo "4) Enter custom version"
    
    # Get user selection
    while true; do
        read -rp "Enter choice [1-4]: " version_choice
        case $version_choice in
            1|2|3)
                selected_version="${version_array[$((version_choice-1))]}"
                clean_version=$(echo "$selected_version" | sed 's/^v//; s/-tree$//')
                break
                ;;
            4)
                read -rp "Enter version (e.g., v4.44-9807-rtm-2025.04.16-tree): " selected_version
                # Validate custom version format
                if [[ ! "$selected_version" =~ ^v[0-9]+\.[0-9]+-[0-9]+-rtm-[0-9]{4}\.[0-9]{2}\.[0-9]{2}-tree$ ]]; then
                    echo -e "\033[1;31mInvalid version format. Please use the format: vX.XX-XXXX-rtm-YYYY.MM.DD-tree\033[0m"
                    continue
                fi
                clean_version=$(echo "$selected_version" | sed 's/^v//; s/-tree$//')
                break
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
    
    # Build download URL
    download_dir="https://www.softether-download.com/files/softether/$selected_version/Linux/"
    echo -e "\nSelected version: \033[1;33m$clean_version\033[0m"
}

# Function to select architecture
select_architecture() {
    echo -e "\n\033[1;36mSelect architecture:\033[0m"
    echo "1) 32-bit (x86)"
    echo "2) 64-bit (x64)"
    echo "3) ARM 32-bit"
    echo "4) ARM 64-bit"
    
    while true; do
        read -rp "Enter choice [1-4]: " arch_choice
        case $arch_choice in
            1) 
                arch="x86-32bit"
                break
                ;;
            2) 
                arch="x64-64bit"
                break
                ;;
            3) 
                arch="arm_eabi-32bit"
                break
                ;;
            4) 
                arch="arm64-64bit"
                break
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
    
    # Build filename pattern
    filename_pattern="softether-vpnserver-${clean_version}-linux-${arch}.tar.gz"
    echo -e "\nSelected architecture: \033[1;33m$arch\033[0m"
    echo -e "Filename pattern: \033[1;33m$filename_pattern\033[0m"
}

# Function to install dependencies
install_dependencies() {
    echo -e "\n\033[1;34mInstalling dependencies...\033[0m"
    apt update
    apt install -y \
        build-essential \
        libssl-dev \
        zlib1g-dev \
        libncurses5-dev \
        libedit-dev \
        libreadline-dev
}

# Function to install SoftEther
install_softether() {
    # Download the file
    download_url="${download_dir}${filename_pattern}"
    echo -e "\n\033[1;34mDownloading package...\033[0m"
    echo -e "URL: \033[1;33m$download_url\033[0m"
    
    cd /opt
    wget "$download_url"
    
    if [ ! -f "$filename_pattern" ]; then
        echo -e "\033[1;31mDownload failed. Please check the URL and try again.\033[0m"
        exit 1
    fi
    
    # Extract and install
    echo -e "\n\033[1;34mExtracting package...\033[0m"
    tar xzvf "$filename_pattern"
    
    echo -e "\n\033[1;34mCompiling VPN Server...\033[0m"
    cd ./vpnserver
    make >/dev/null
    
    echo -e "\n\033[1;34mInstalling to /usr/local/vpnserver...\033[0m"
    cd ..
    mv vpnserver /usr/local
    cd /usr/local/vpnserver
    chmod 600 *
    chmod 700 vpncmd vpnserver
    
    # Verify installation
    echo -e "\n\033[1;34mRunning configuration check...\033[0m"
    ./vpncmd <<CMD
3
check
exit
CMD
    
    # Create service script
    echo -e "\n\033[1;34mCreating system service...\033[0m"
    cat > /opt/vpnserver.sh <<'EOF'
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
    cat > /etc/systemd/system/vpnserver.service <<EOF
[Unit]
Description = SoftEther VPN Server
After = network.target

[Service]
ExecStart = /opt/vpnserver.sh start
ExecStop = /opt/vpnserver.sh stop
ExecReload = /opt/vpnserver.sh restart
Restart = always
Type = forking

[Install]
WantedBy = multi-user.target
EOF
    
    # Start service
    systemctl daemon-reload
    systemctl enable vpnserver
    systemctl start vpnserver
    
    # Verify status
    echo -e "\n\033[1;32mInstallation completed successfully!\033[0m"
    echo -e "\033[1;33mService Status:\033[0m"
    systemctl status vpnserver --no-pager
    echo -e "\n\033[1;33mManagement Command:\033[0m /usr/local/vpnserver/vpncmd"
    echo -e "\033[1;33mServer Admin Port:\033[0m 5555"
}

# Main menu
echo -e "\n\033[1;35mSoftEther VPN Server Installation Manager\033[0m"
echo -e "===========================================\n"

# Check installation status
if check_installation; then
    echo -e "\n\033[1;36mSelect an option:\033[0m"
    echo "1) Reinstall SoftEther VPN Server"
    echo "2) Uninstall SoftEther VPN Server"
    echo "3) Exit"
    
    while true; do
        read -rp "Enter choice [1-3]: " main_choice
        case $main_choice in
            1)
                echo -e "\n\033[1;33mReinstalling SoftEther VPN Server...\033[0m"
                uninstall_softether
                get_latest_versions
                select_architecture
                install_dependencies
                install_softether
                break
                ;;
            2)
                uninstall_softether
                exit 0
                ;;
            3)
                exit 0
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
else
    echo -e "\n\033[1;36mSelect an option:\033[0m"
    echo "1) Install SoftEther VPN Server"
    echo "2) Exit"
    
    while true; do
        read -rp "Enter choice [1-2]: " main_choice
        case $main_choice in
            1)
                get_latest_versions
                select_architecture
                install_dependencies
                install_softether
                break
                ;;
            2)
                exit 0
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
fi


#!/bin/bash
# SoftEther VPN Server Installation Manager
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
    rm -f /etc/systemd/system/vpnserver.service
    
    # Remove files
    rm -f /opt/vpnserver.sh
    rm -rf /usr/local/vpnserver
    
    # Remove extracted files in /opt
    find /opt -maxdepth 1 -type d -name 'vpnserver' -exec rm -rf {} +
    find /opt -maxdepth 1 -type f -name 'softether-vpnserver-*.tar.gz' -exec rm -f {} +
    
    echo -e "\033[1;32mUninstallation completed successfully!\033[0m"
}

# Function to get latest versions
get_latest_versions() {
    echo -e "\n\033[1;34mFetching latest RTM versions...\033[0m"
    
    # Fetch and process versions using your successful method
    versions=$(curl -s https://www.softether-download.com/files/softether/ | 
               grep -E 'rtm-20[2-9][0-9]' | 
               grep -oP 'href="\K[^"]+' | 
               sort -r | 
               head -3)
    
    # Verify we found RTM versions
    if [ -z "$versions" ]; then
        echo -e "\033[1;31mError: No RTM versions found. Possible causes:\033[0m"
        echo "1. Website structure changed"
        echo "2. No RTM releases available"
        echo "3. Temporary network issue"
        echo -e "\nPlease check manually: https://www.softether-download.com/files/softether/"
        exit 1
    fi
    
    # Convert to array
    version_array=()
    while IFS= read -r line; do
        # Extract clean version name from path
        version_name=$(basename "$line" | sed 's|/$||')
        version_array+=("$version_name")
    done <<< "$versions"
    
    # Display version menu
    echo -e "\n\033[1;36mSelect a version:\033[0m"
    for i in "${!version_array[@]}"; do
        clean_version=$(echo "${version_array[$i]}" | sed 's/^v//; s/-tree$//')
        echo "$((i+1))) $clean_version"
    done
    echo "4) Enter custom version"
    
    # Get user selection
    while true; do
        read -rp "Enter choice [1-4]: " version_choice
        case $version_choice in
            1|2|3)
                selected_version="${version_array[$((version_choice-1))]}"
                clean_version=$(echo "$selected_version" | sed 's/^v//; s/-tree$//')
                break
                ;;
            4)
                read -rp "Enter version (e.g., v4.44-9807-rtm-2025.04.16-tree): " selected_version
                # Validate custom version format
                if [[ ! "$selected_version" =~ ^v[0-9]+\.[0-9]+-[0-9]+-rtm-[0-9]{4}\.[0-9]{2}\.[0-9]{2}-tree$ ]]; then
                    echo -e "\033[1;31mInvalid version format. Please use the format: vX.XX-XXXX-rtm-YYYY.MM.DD-tree\033[0m"
                    continue
                fi
                clean_version=$(echo "$selected_version" | sed 's/^v//; s/-tree$//')
                break
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
    
    # Build download URL
    download_dir="https://www.softether-download.com/files/softether/$selected_version/Linux/"
    echo -e "\nSelected version: \033[1;33m$clean_version\033[0m"
}

# Function to select architecture
select_architecture() {
    echo -e "\n\033[1;36mSelect architecture:\033[0m"
    echo "1) 32-bit (x86)"
    echo "2) 64-bit (x64)"
    echo "3) ARM 32-bit"
    echo "4) ARM 64-bit"
    
    while true; do
        read -rp "Enter choice [1-4]: " arch_choice
        case $arch_choice in
            1) 
                arch="x86-32bit"
                break
                ;;
            2) 
                arch="x64-64bit"
                break
                ;;
            3) 
                arch="arm_eabi-32bit"
                break
                ;;
            4) 
                arch="arm64-64bit"
                break
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
    
    # Build filename pattern
    filename_pattern="softether-vpnserver-${clean_version}-linux-${arch}.tar.gz"
    echo -e "\nSelected architecture: \033[1;33m$arch\033[0m"
    echo -e "Filename pattern: \033[1;33m$filename_pattern\033[0m"
}

# Function to install dependencies
install_dependencies() {
    echo -e "\n\033[1;34mInstalling dependencies...\033[0m"
    apt update
    apt install -y \
        build-essential \
        libssl-dev \
        zlib1g-dev \
        libncurses5-dev \
        libedit-dev \
        libreadline-dev
}

# Function to install SoftEther
install_softether() {
    # Download the file
    download_url="${download_dir}${filename_pattern}"
    echo -e "\n\033[1;34mDownloading package...\033[0m"
    echo -e "URL: \033[1;33m$download_url\033[0m"
    
    cd /opt
    wget "$download_url"
    
    if [ ! -f "$filename_pattern" ]; then
        echo -e "\033[1;31mDownload failed. Please check the URL and try again.\033[0m"
        exit 1
    fi
    
    # Extract and install
    echo -e "\n\033[1;34mExtracting package...\033[0m"
    tar xzvf "$filename_pattern"
    
    echo -e "\n\033[1;34mCompiling VPN Server...\033[0m"
    cd ./vpnserver
    make >/dev/null
    
    echo -e "\n\033[1;34mInstalling to /usr/local/vpnserver...\033[0m"
    cd ..
    mv vpnserver /usr/local
    cd /usr/local/vpnserver
    chmod 600 *
    chmod 700 vpncmd vpnserver
    
    # Verify installation
    echo -e "\n\033[1;34mRunning configuration check...\033[0m"
    ./vpncmd <<CMD
3
check
exit
CMD
    
    # Create service script
    echo -e "\n\033[1;34mCreating system service...\033[0m"
    cat > /opt/vpnserver.sh <<'EOF'
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
    cat > /etc/systemd/system/vpnserver.service <<EOF
[Unit]
Description = SoftEther VPN Server
After = network.target

[Service]
ExecStart = /opt/vpnserver.sh start
ExecStop = /opt/vpnserver.sh stop
ExecReload = /opt/vpnserver.sh restart
Restart = always
Type = forking

[Install]
WantedBy = multi-user.target
EOF
    
    # Start service
    systemctl daemon-reload
    systemctl enable vpnserver
    systemctl start vpnserver
    
    # Verify status
    echo -e "\n\033[1;32mInstallation completed successfully!\033[0m"
    echo -e "\033[1;33mService Status:\033[0m"
    systemctl status vpnserver --no-pager
    echo -e "\n\033[1;33mManagement Command:\033[0m /usr/local/vpnserver/vpncmd"
    echo -e "\033[1;33mServer Admin Port:\033[0m 5555"
}

# Main menu
echo -e "\n\033[1;35mSoftEther VPN Server Installation Manager\033[0m"
echo -e "===========================================\n"

# Check installation status
if check_installation; then
    echo -e "\n\033[1;36mSelect an option:\033[0m"
    echo "1) Reinstall SoftEther VPN Server"
    echo "2) Uninstall SoftEther VPN Server"
    echo "3) Exit"
    
    while true; do
        read -rp "Enter choice [1-3]: " main_choice
        case $main_choice in
            1)
                echo -e "\n\033[1;33mReinstalling SoftEther VPN Server...\033[0m"
                uninstall_softether
                get_latest_versions
                select_architecture
                install_dependencies
                install_softether
                break
                ;;
            2)
                uninstall_softether
                exit 0
                ;;
            3)
                exit 0
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
else
    echo -e "\n\033[1;36mSelect an option:\033[0m"
    echo "1) Install SoftEther VPN Server"
    echo "2) Exit"
    
    while true; do
        read -rp "Enter choice [1-2]: " main_choice
        case $main_choice in
            1)
                get_latest_versions
                select_architecture
                install_dependencies
                install_softether
                break
                ;;
            2)
                exit 0
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
fi


#!/bin/bash
# SoftEther VPN Server Installation Manager
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
    rm -f /etc/systemd/system/vpnserver.service
    
    # Remove files
    rm -f /opt/vpnserver.sh
    rm -rf /usr/local/vpnserver
    
    # Remove extracted files in /opt
    find /opt -maxdepth 1 -type d -name 'vpnserver' -exec rm -rf {} +
    find /opt -maxdepth 1 -type f -name 'softether-vpnserver-*.tar.gz' -exec rm -f {} +
    
    echo -e "\033[1;32mUninstallation completed successfully!\033[0m"
}

# Function to get latest versions
get_latest_versions() {
    echo -e "\n\033[1;34mFetching latest RTM versions...\033[0m"
    
    # Using your successful method directly
    versions=$(curl -s https://www.softether-download.com/files/softether/ | 
               grep -E 'rtm-20[2-9][0-9]' | 
               grep -oP 'v[^/]+' | 
               sort -r | 
               uniq | 
               head -10)
    
    # Verify we found RTM versions
    if [ -z "$versions" ]; then
        echo -e "\033[1;31mError: No RTM versions found. Possible causes:\033[0m"
        echo "1. Website structure changed"
        echo "2. No RTM releases available"
        echo "3. Temporary network issue"
        echo -e "\nPlease check manually: https://www.softether-download.com/files/softether/"
        exit 1
    fi
    
    # Convert to array
    version_array=()
    while IFS= read -r line; do
        version_array+=("$line")
    done <<< "$versions"
    
    # Display version menu
    echo -e "\n\033[1;36mSelect a version:\033[0m"
    for i in "${!version_array[@]}"; do
        # Display clean version without path components
        clean_version=$(echo "${version_array[$i]}" | sed 's|/$||')
        echo "$((i+1))) $clean_version"
    done
    echo "4) Enter custom version"
    
    # Get user selection
    while true; do
        read -rp "Enter choice [1-4]: " version_choice
        case $version_choice in
            1|2|3)
                selected_version="${version_array[$((version_choice-1))]}"
                # Remove any trailing slash
                selected_version=$(echo "$selected_version" | sed 's|/$||')
                break
                ;;
            4)
                read -rp "Enter version (e.g., v4.44-9807-rtm-2025.04.16-tree): " selected_version
                # Validate custom version format
                if [[ ! "$selected_version" =~ ^v[0-9]+\.[0-9]+-[0-9]+-rtm-[0-9]{4}\.[0-9]{2}\.[0-9]{2}-tree$ ]]; then
                    echo -e "\033[1;31mInvalid version format. Please use the format: vX.XX-XXXX-rtm-YYYY.MM.DD-tree\033[0m"
                    continue
                fi
                break
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
    
    # Build download URL
    download_dir="https://www.softether-download.com/files/softether/$selected_version/Linux/"
    clean_version_name=$(echo "$selected_version" | sed 's/^v//; s/-tree$//')
    echo -e "\nSelected version: \033[1;33m$clean_version_name\033[0m"
}

# Function to select architecture
select_architecture() {
    echo -e "\n\033[1;36mSelect architecture:\033[0m"
    echo "1) 32-bit (x86)"
    echo "2) 64-bit (x64)"
    echo "3) ARM 32-bit"
    echo "4) ARM 64-bit"
    
    while true; do
        read -rp "Enter choice [1-4]: " arch_choice
        case $arch_choice in
            1) 
                arch="x86-32bit"
                break
                ;;
            2) 
                arch="x64-64bit"
                break
                ;;
            3) 
                arch="arm_eabi-32bit"
                break
                ;;
            4) 
                arch="arm64-64bit"
                break
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
    
    # Build filename pattern
    filename_pattern="softether-vpnserver-${clean_version}-linux-${arch}.tar.gz"
    echo -e "\nSelected architecture: \033[1;33m$arch\033[0m"
    echo -e "Filename pattern: \033[1;33m$filename_pattern\033[0m"
}

# Function to install dependencies
install_dependencies() {
    echo -e "\n\033[1;34mInstalling dependencies...\033[0m"
    apt update
    apt install -y \
        build-essential \
        libssl-dev \
        zlib1g-dev \
        libncurses5-dev \
        libedit-dev \
        libreadline-dev
}

# Function to install SoftEther
install_softether() {
    # Download the file
    download_url="${download_dir}${filename_pattern}"
    echo -e "\n\033[1;34mDownloading package...\033[0m"
    echo -e "URL: \033[1;33m$download_url\033[0m"
    
    cd /opt
    wget "$download_url"
    
    if [ ! -f "$filename_pattern" ]; then
        echo -e "\033[1;31mDownload failed. Please check the URL and try again.\033[0m"
        exit 1
    fi
    
    # Extract and install
    echo -e "\n\033[1;34mExtracting package...\033[0m"
    tar xzvf "$filename_pattern"
    
    echo -e "\n\033[1;34mCompiling VPN Server...\033[0m"
    cd ./vpnserver
    make >/dev/null
    
    echo -e "\n\033[1;34mInstalling to /usr/local/vpnserver...\033[0m"
    cd ..
    mv vpnserver /usr/local
    cd /usr/local/vpnserver
    chmod 600 *
    chmod 700 vpncmd vpnserver
    
    # Verify installation
    echo -e "\n\033[1;34mRunning configuration check...\033[0m"
    ./vpncmd <<CMD
3
check
exit
CMD
    
    # Create service script
    echo -e "\n\033[1;34mCreating system service...\033[0m"
    cat > /opt/vpnserver.sh <<'EOF'
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
    cat > /etc/systemd/system/vpnserver.service <<EOF
[Unit]
Description = SoftEther VPN Server
After = network.target

[Service]
ExecStart = /opt/vpnserver.sh start
ExecStop = /opt/vpnserver.sh stop
ExecReload = /opt/vpnserver.sh restart
Restart = always
Type = forking

[Install]
WantedBy = multi-user.target
EOF
    
    # Start service
    systemctl daemon-reload
    systemctl enable vpnserver
    systemctl start vpnserver
    
    # Verify status
    echo -e "\n\033[1;32mInstallation completed successfully!\033[0m"
    echo -e "\033[1;33mService Status:\033[0m"
    systemctl status vpnserver --no-pager
    echo -e "\n\033[1;33mManagement Command:\033[0m /usr/local/vpnserver/vpncmd"
    echo -e "\033[1;33mServer Admin Port:\033[0m 5555"
}

# Main menu
echo -e "\n\033[1;35mSoftEther VPN Server Installation Manager\033[0m"
echo -e "===========================================\n"

# Check installation status
if check_installation; then
    echo -e "\n\033[1;36mSelect an option:\033[0m"
    echo "1) Reinstall SoftEther VPN Server"
    echo "2) Uninstall SoftEther VPN Server"
    echo "3) Exit"
    
    while true; do
        read -rp "Enter choice [1-3]: " main_choice
        case $main_choice in
            1)
                echo -e "\n\033[1;33mReinstalling SoftEther VPN Server...\033[0m"
                uninstall_softether
                get_latest_versions
                select_architecture
                install_dependencies
                install_softether
                break
                ;;
            2)
                uninstall_softether
                exit 0
                ;;
            3)
                exit 0
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
else
    echo -e "\n\033[1;36mSelect an option:\033[0m"
    echo "1) Install SoftEther VPN Server"
    echo "2) Exit"
    
    while true; do
        read -rp "Enter choice [1-2]: " main_choice
        case $main_choice in
            1)
                get_latest_versions
                select_architecture
                install_dependencies
                install_softether
                break
                ;;
            2)
                exit 0
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
fi