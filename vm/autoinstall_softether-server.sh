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

#unanswered
yes it shows the lists but the scan of link kinda meh look at the results. oh ya i changed the head to 10
SoftEther VPN Server Installation Manager
===========================================

SoftEther VPN Server is not installed.

Select an option:
1) Install SoftEther VPN Server
2) Exit
Enter choice [1-2]: 1

Fetching latest RTM versions...

Select a version:
1) v4.44-9807-rtm-2025.04.16-tree<
2) v4.44-9807-rtm-2025.04.16-tree
3) v4.43-9799-beta-2023.08.31-tree<
4) v4.43-9799-beta-2023.08.31-tree
5) v4.42-9798-rtm-2023.06.30-tree<
6) v4.42-9798-rtm-2023.06.30-tree
7) v4.41-9787-rtm-2023.03.14-tree<
8) v4.41-9787-rtm-2023.03.14-tree
9) v4.41-9782-beta-2022.11.17-tree<
10) v4.41-9782-beta-2022.11.17-tree
4) Enter custom version
Enter choice [1-4]: 1
(why there is "<" in the filename and beta are included?)
Selected version: 4.44-9807-rtm-2025.04.16-tree<

Select architecture:
1) 32-bit (x86)
2) 64-bit (x64)
3) ARM 32-bit
4) ARM 64-bit
Enter choice [1-4]: 2

Selected architecture: x64-64bit
Filename pattern: softether-vpnserver-v4.41-9782-beta-2022.11.17-tree-linux-x64-64bit.tar.gz

i'm starting to getting lost, why 2022? the above result are from this line of code
    
# Build filename pattern
    filename_pattern="softether-vpnserver-${clean_version}-linux-${arch}.tar.gz"
    echo -e "\nSelected architecture: \033[1;33m$arch\033[0m"
    echo -e "Filename pattern: \033[1;33m$filename_pattern\033[0m"

which is i pick from this Select a version:
1) v4.44-9807-rtm-2025.04.16-tree<
when i inspect element on https://www.softether-download.com/files/softether/ the results should grab this line <A HREF="/files/softether/v4.44-9807-rtm-2025.04.16-tree/">v4.44-9807-rtm-2025.04.16-tree</A><br>2013/02/14    23:53          208 <A HREF="/files/softether/web.config">web.config</A><br></pre><hr></body></html>
so it should pick v4.44-9807-rtm-2025.04.16-tree not softether-vpnserver-v4.41-9782-beta-2022.11.17-tree-linux-x64-64bit.tar.gz
the 2022 version is grabbed from <A HREF="/files/softether/v4.41-9782-beta-2022.11.17-tree/">v4.41-9782-beta-2022.11.17-tree</A><br>2023/03/14 which is is not make sense.

before answering the code i wanted to ask you, can you read the html like humans do? because the problem is the line order from the web view and inspect element is different.

this is the line from web view
2013/05/04     8:43        <dir> v1.00-9022-rc2-2013.03.07-tree
2013/05/04     8:44        <dir> v1.00-9023-rc2-2013.03.08-tree
2013/05/04     8:44        <dir> v1.00-9024-rc2-2013.03.09-tree
2013/05/04     8:45        <dir> v1.00-9026-rc2-2013.03.10-tree
2013/05/04     8:45        <dir> v1.00-9027-rc2-2013.03.12-tree
2013/05/04     8:45        <dir> v1.00-9029-rc2-2013.03.16-tree
2013/05/04     8:46        <dir> v1.00-9030-rc2-2013.03.21-tree
2013/05/04     8:46        <dir> v1.00-9031-rc2-2013.03.22-tree
2013/05/04     8:47        <dir> v1.00-9033-rc2-2013.03.22-tree
2013/05/04     8:47        <dir> v1.00-9035-rc2-2013.03.25-tree
2013/05/04     8:48        <dir> v1.00-9037-rc2-2013.03.28-tree
2013/05/04     8:48        <dir> v1.00-9038-rc2-2013.03.28-tree
2013/05/04     8:48        <dir> v1.00-9043-rc2-2013.04.01-tree
2013/05/04     8:49        <dir> v1.00-9045-rc2-2013.04.02-tree
2013/05/04     8:49        <dir> v1.00-9051-rc2-2013.04.05-tree
2013/05/04     8:50        <dir> v1.00-9053-rc2-2013.04.08-tree
2013/05/04     8:50        <dir> v1.00-9069-rc2-2013.04.17-tree
2013/05/04     8:51        <dir> v1.00-9070-rc2-2013.04.18-tree
2013/05/04     8:51        <dir> v1.00-9071-rc2-2013.04.20-tree
2013/05/04     8:51        <dir> v1.00-9072-rc2-2013.04.20-tree
2013/05/04     8:52        <dir> v1.00-9074-rc2-2013.04.24-tree
2013/05/04     8:52        <dir> v1.00-9078-rc2-2013.04.28-tree
2013/05/05    22:07        <dir> v1.00-9079-rc2-2013.05.05-tree
2013/05/19    14:48        <dir> v1.00-9091-rc3-2013.05.19-tree
2013/07/21     3:02        <dir> v1.00-9367-rc4-2013.07.20-tree
2013/07/25     2:46        <dir> v1.00-9371-rtm-2013.07.25-tree
2013/08/03     3:39        <dir> v1.00-9376-rtm-2013.08.02-tree
2013/08/03    18:51        <dir> v1.00-9377-rtm-2013.08.03-tree
2013/08/18    19:20        <dir> v1.01-9379-rtm-2013.08.18-tree
2013/09/16    15:00        <dir> v2.00-9387-rtm-2013.09.16-tree
2014/01/04    21:57        <dir> v4.03-9408-rtm-2014.01.04-tree
2014/01/07     5:40        <dir> v4.03-9411-rtm-2014.01.07-tree
2014/01/15    18:54        <dir> v4.04-9412-rtm-2014.01.15-tree
2014/02/06     1:28        <dir> v4.05-9416-beta-2014.02.06-tree
2014/02/06    13:18        <dir> v4.05-9418-beta-2014.02.06-tree
2014/02/17     3:04        <dir> v4.05-9422-beta-2014.02.17-tree
2014/02/18    20:06        <dir> v4.05-9423-beta-2014.02.18-tree
2014/03/21    14:07        <dir> v4.06-9433-beta-2014.03.21-tree
2014/03/26    12:36        <dir> v4.06-9435-beta-2014.03.26-tree
2014/04/09     9:36        <dir> v4.06-9436-beta-2014.04.09-tree
2014/04/09    11:30        <dir> v4.06-9437-beta-2014.04.09-tree
2014/06/06     6:51        <dir> v4.07-9448-rtm-2014.06.06-tree
2014/06/08    16:28        <dir> v4.08-9449-rtm-2014.06.08-tree
2014/06/09    11:58        <dir> v4.09-9451-beta-2014.06.09-tree
2014/07/12     2:59        <dir> v4.10-9473-beta-2014.07.12-tree
2014/10/04     0:06        <dir> v4.10-9505-beta-2014.10.03-tree
2014/10/23     0:59        <dir> v4.11-9506-beta-2014.10.22-tree
2014/11/18    12:06        <dir> v4.12-9514-beta-2014.11.17-tree
2015/01/30    22:30        <dir> v4.13-9522-beta-2015.01.30-tree
2015/01/31     3:25        <dir> v4.13-9524-beta-2015.01.31-tree
2015/02/02    12:31        <dir> v4.13-9525-beta-2015.02.02-tree
2015/02/02    18:52        <dir> v4.14-9529-beta-2015.02.02-tree
2015/03/26    17:59        <dir> v4.15-9537-beta-2015.03.26-tree
2015/03/27    20:51        <dir> v4.15-9538-beta-2015.03.27-tree
2015/04/04     5:58        <dir> v4.15-9539-beta-2015.04.04-tree
2015/04/05     3:39        <dir> v4.15-9546-beta-2015.04.05-tree
2015/05/31    19:02        <dir> v4.17-9562-beta-2015.05.30-tree
2015/07/17     0:31        <dir> v4.17-9566-beta-2015.07.16-tree
2015/07/26    19:39        <dir> v4.18-9570-rtm-2015.07.26-tree
2015/09/15    14:22        <dir> v4.19-9577-beta-2015.09.15-tree
2015/09/15    16:20        <dir> v4.19-9578-beta-2015.09.15-tree
2015/10/06    20:18        <dir> v4.19-9582-beta-2015.10.06-tree
2015/10/19    21:31        <dir> v4.19-9599-beta-2015.10.19-tree
2016/03/06    22:27        <dir> v4.19-9605-beta-2016.03.06-tree
2016/04/18     1:52        <dir> v4.20-9608-rtm-2016.04.17-tree
2016/04/24    23:49        <dir> v4.21-9613-beta-2016.04.24-tree
2016/11/27    17:19        <dir> v4.22-9634-beta-2016.11.27-tree
2017/10/18    18:18        <dir> v4.23-9647-beta-2017.10.18-tree
2017/10/23     2:45        <dir> v4.24-9651-beta-2017.10.23-tree
2017/12/21    22:38        <dir> v4.24-9652-beta-2017.12.21-tree
2018/01/15    11:07        <dir> v4.25-9656-rtm-2018.01.15-tree
2018/04/20    22:20        <dir> v4.27-9664-beta-2018.04.20-tree
2018/04/21    11:23        <dir> v4.27-9665-beta-2018.04.21-tree
2018/04/21    16:22        <dir> v4.27-9666-beta-2018.04.21-tree
2018/05/26    12:04        <dir> v4.27-9667-beta-2018.05.26-tree
2018/05/30     0:49        <dir> v4.27-9668-beta-2018.05.29-tree
2018/09/11    16:31        <dir> v4.28-9669-beta-2018.09.11-tree
2019/02/28    14:33        <dir> v4.29-9678-rtm-2019.02.28-tree
2019/02/28    20:12        <dir> v4.29-9680-rtm-2019.02.28-tree
2019/07/07    21:21        <dir> v4.30-9695-beta-2019.07.07-tree
2019/07/08    15:18        <dir> v4.30-9696-beta-2019.07.08-tree
2019/07/14    11:14        <dir> v4.30-9700-beta-2019.07.13-tree
2019/11/18    12:26        <dir> v4.31-9727-beta-2019.11.18-tree
2020/01/01    20:15        <dir> v4.32-9731-beta-2020.01.01-tree
2020/03/21    10:35        <dir> v4.34-9744-beta-2020.03.20-tree
2020/06/24    23:48        <dir> v4.34-9745-beta-2020.04.05-tree
2020/06/24    23:47        <dir> v4.34-9745-rtm-2020.04.05-tree
2021/06/07    22:17        <dir> v4.36-9754-beta-2021.06.07-tree
2021/08/16     1:12        <dir> v4.37-9758-beta-2021.08.16-tree
2021/08/17    22:54        <dir> v4.38-9760-rtm-2021.08.17-tree
2022/04/26    19:40        <dir> v4.39-9772-beta-2022.04.26-trees
2022/11/17    17:46        <dir> v4.41-9782-beta-2022.11.17-tree
2023/03/14    20:52        <dir> v4.41-9787-rtm-2023.03.14-tree
2023/06/30    12:14        <dir> v4.42-9798-rtm-2023.06.30-tree
2023/08/31    12:13        <dir> v4.43-9799-beta-2023.08.31-tree
2025/04/16    15:09        <dir> v4.44-9807-rtm-2025.04.16-tree
2013/02/14    23:53          208 web.config

this is from the inspect element:

<html><head><title>www.softether-download.com - /files/softether/</title></head><body><H1>www.softether-download.com - /files/softether/</H1><hr>

<pre><A HREF="/files/">[To Parent Directory]</A><br><br>2013/05/04     8:43        &lt;dir&gt; <A HREF="/files/softether/v1.00-9022-rc2-2013.03.07-tree/">v1.00-9022-rc2-2013.03.07-tree</A><br>2013/05/04     8:44        &lt;dir&gt; <A HREF="/files/softether/v1.00-9023-rc2-2013.03.08-tree/">v1.00-9023-rc2-2013.03.08-tree</A><br>2013/05/04     8:44        &lt;dir&gt; <A HREF="/files/softether/v1.00-9024-rc2-2013.03.09-tree/">v1.00-9024-rc2-2013.03.09-tree</A><br>2013/05/04     8:45        &lt;dir&gt; <A HREF="/files/softether/v1.00-9026-rc2-2013.03.10-tree/">v1.00-9026-rc2-2013.03.10-tree</A><br>2013/05/04     8:45        &lt;dir&gt; <A HREF="/files/softether/v1.00-9027-rc2-2013.03.12-tree/">v1.00-9027-rc2-2013.03.12-tree</A><br>2013/05/04     8:45        &lt;dir&gt; <A HREF="/files/softether/v1.00-9029-rc2-2013.03.16-tree/">v1.00-9029-rc2-2013.03.16-tree</A><br>2013/05/04     8:46        &lt;dir&gt; <A HREF="/files/softether/v1.00-9030-rc2-2013.03.21-tree/">v1.00-9030-rc2-2013.03.21-tree</A><br>2013/05/04     8:46        &lt;dir&gt; <A HREF="/files/softether/v1.00-9031-rc2-2013.03.22-tree/">v1.00-9031-rc2-2013.03.22-tree</A><br>2013/05/04     8:47        &lt;dir&gt; <A HREF="/files/softether/v1.00-9033-rc2-2013.03.22-tree/">v1.00-9033-rc2-2013.03.22-tree</A><br>2013/05/04     8:47        &lt;dir&gt; <A HREF="/files/softether/v1.00-9035-rc2-2013.03.25-tree/">v1.00-9035-rc2-2013.03.25-tree</A><br>2013/05/04     8:48        &lt;dir&gt; <A HREF="/files/softether/v1.00-9037-rc2-2013.03.28-tree/">v1.00-9037-rc2-2013.03.28-tree</A><br>2013/05/04     8:48        &lt;dir&gt; <A HREF="/files/softether/v1.00-9038-rc2-2013.03.28-tree/">v1.00-9038-rc2-2013.03.28-tree</A><br>2013/05/04     8:48        &lt;dir&gt; <A HREF="/files/softether/v1.00-9043-rc2-2013.04.01-tree/">v1.00-9043-rc2-2013.04.01-tree</A><br>2013/05/04     8:49        &lt;dir&gt; <A HREF="/files/softether/v1.00-9045-rc2-2013.04.02-tree/">v1.00-9045-rc2-2013.04.02-tree</A><br>2013/05/04     8:49        &lt;dir&gt; <A HREF="/files/softether/v1.00-9051-rc2-2013.04.05-tree/">v1.00-9051-rc2-2013.04.05-tree</A><br>2013/05/04     8:50        &lt;dir&gt; <A HREF="/files/softether/v1.00-9053-rc2-2013.04.08-tree/">v1.00-9053-rc2-2013.04.08-tree</A><br>2013/05/04     8:50        &lt;dir&gt; <A HREF="/files/softether/v1.00-9069-rc2-2013.04.17-tree/">v1.00-9069-rc2-2013.04.17-tree</A><br>2013/05/04     8:51        &lt;dir&gt; <A HREF="/files/softether/v1.00-9070-rc2-2013.04.18-tree/">v1.00-9070-rc2-2013.04.18-tree</A><br>2013/05/04     8:51        &lt;dir&gt; <A HREF="/files/softether/v1.00-9071-rc2-2013.04.20-tree/">v1.00-9071-rc2-2013.04.20-tree</A><br>2013/05/04     8:51        &lt;dir&gt; <A HREF="/files/softether/v1.00-9072-rc2-2013.04.20-tree/">v1.00-9072-rc2-2013.04.20-tree</A><br>2013/05/04     8:52        &lt;dir&gt; <A HREF="/files/softether/v1.00-9074-rc2-2013.04.24-tree/">v1.00-9074-rc2-2013.04.24-tree</A><br>2013/05/04     8:52        &lt;dir&gt; <A HREF="/files/softether/v1.00-9078-rc2-2013.04.28-tree/">v1.00-9078-rc2-2013.04.28-tree</A><br>2013/05/05    22:07        &lt;dir&gt; <A HREF="/files/softether/v1.00-9079-rc2-2013.05.05-tree/">v1.00-9079-rc2-2013.05.05-tree</A><br>2013/05/19    14:48        &lt;dir&gt; <A HREF="/files/softether/v1.00-9091-rc3-2013.05.19-tree/">v1.00-9091-rc3-2013.05.19-tree</A><br>2013/07/21     3:02        &lt;dir&gt; <A HREF="/files/softether/v1.00-9367-rc4-2013.07.20-tree/">v1.00-9367-rc4-2013.07.20-tree</A><br>2013/07/25     2:46        &lt;dir&gt; <A HREF="/files/softether/v1.00-9371-rtm-2013.07.25-tree/">v1.00-9371-rtm-2013.07.25-tree</A><br>2013/08/03     3:39        &lt;dir&gt; <A HREF="/files/softether/v1.00-9376-rtm-2013.08.02-tree/">v1.00-9376-rtm-2013.08.02-tree</A><br>2013/08/03    18:51        &lt;dir&gt; <A HREF="/files/softether/v1.00-9377-rtm-2013.08.03-tree/">v1.00-9377-rtm-2013.08.03-tree</A><br>2013/08/18    19:20        &lt;dir&gt; <A HREF="/files/softether/v1.01-9379-rtm-2013.08.18-tree/">v1.01-9379-rtm-2013.08.18-tree</A><br>2013/09/16    15:00        &lt;dir&gt; <A HREF="/files/softether/v2.00-9387-rtm-2013.09.16-tree/">v2.00-9387-rtm-2013.09.16-tree</A><br>2014/01/04    21:57        &lt;dir&gt; <A HREF="/files/softether/v4.03-9408-rtm-2014.01.04-tree/">v4.03-9408-rtm-2014.01.04-tree</A><br>2014/01/07     5:40        &lt;dir&gt; <A HREF="/files/softether/v4.03-9411-rtm-2014.01.07-tree/">v4.03-9411-rtm-2014.01.07-tree</A><br>2014/01/15    18:54        &lt;dir&gt; <A HREF="/files/softether/v4.04-9412-rtm-2014.01.15-tree/">v4.04-9412-rtm-2014.01.15-tree</A><br>2014/02/06     1:28        &lt;dir&gt; <A HREF="/files/softether/v4.05-9416-beta-2014.02.06-tree/">v4.05-9416-beta-2014.02.06-tree</A><br>2014/02/06    13:18        &lt;dir&gt; <A HREF="/files/softether/v4.05-9418-beta-2014.02.06-tree/">v4.05-9418-beta-2014.02.06-tree</A><br>2014/02/17     3:04        &lt;dir&gt; <A HREF="/files/softether/v4.05-9422-beta-2014.02.17-tree/">v4.05-9422-beta-2014.02.17-tree</A><br>2014/02/18    20:06        &lt;dir&gt; <A HREF="/files/softether/v4.05-9423-beta-2014.02.18-tree/">v4.05-9423-beta-2014.02.18-tree</A><br>2014/03/21    14:07        &lt;dir&gt; <A HREF="/files/softether/v4.06-9433-beta-2014.03.21-tree/">v4.06-9433-beta-2014.03.21-tree</A><br>2014/03/26    12:36        &lt;dir&gt; <A HREF="/files/softether/v4.06-9435-beta-2014.03.26-tree/">v4.06-9435-beta-2014.03.26-tree</A><br>2014/04/09     9:36        &lt;dir&gt; <A HREF="/files/softether/v4.06-9436-beta-2014.04.09-tree/">v4.06-9436-beta-2014.04.09-tree</A><br>2014/04/09    11:30        &lt;dir&gt; <A HREF="/files/softether/v4.06-9437-beta-2014.04.09-tree/">v4.06-9437-beta-2014.04.09-tree</A><br>2014/06/06     6:51        &lt;dir&gt; <A HREF="/files/softether/v4.07-9448-rtm-2014.06.06-tree/">v4.07-9448-rtm-2014.06.06-tree</A><br>2014/06/08    16:28        &lt;dir&gt; <A HREF="/files/softether/v4.08-9449-rtm-2014.06.08-tree/">v4.08-9449-rtm-2014.06.08-tree</A><br>2014/06/09    11:58        &lt;dir&gt; <A HREF="/files/softether/v4.09-9451-beta-2014.06.09-tree/">v4.09-9451-beta-2014.06.09-tree</A><br>2014/07/12     2:59        &lt;dir&gt; <A HREF="/files/softether/v4.10-9473-beta-2014.07.12-tree/">v4.10-9473-beta-2014.07.12-tree</A><br>2014/10/04     0:06        &lt;dir&gt; <A HREF="/files/softether/v4.10-9505-beta-2014.10.03-tree/">v4.10-9505-beta-2014.10.03-tree</A><br>2014/10/23     0:59        &lt;dir&gt; <A HREF="/files/softether/v4.11-9506-beta-2014.10.22-tree/">v4.11-9506-beta-2014.10.22-tree</A><br>2014/11/18    12:06        &lt;dir&gt; <A HREF="/files/softether/v4.12-9514-beta-2014.11.17-tree/">v4.12-9514-beta-2014.11.17-tree</A><br>2015/01/30    22:30        &lt;dir&gt; <A HREF="/files/softether/v4.13-9522-beta-2015.01.30-tree/">v4.13-9522-beta-2015.01.30-tree</A><br>2015/01/31     3:25        &lt;dir&gt; <A HREF="/files/softether/v4.13-9524-beta-2015.01.31-tree/">v4.13-9524-beta-2015.01.31-tree</A><br>2015/02/02    12:31        &lt;dir&gt; <A HREF="/files/softether/v4.13-9525-beta-2015.02.02-tree/">v4.13-9525-beta-2015.02.02-tree</A><br>2015/02/02    18:52        &lt;dir&gt; <A HREF="/files/softether/v4.14-9529-beta-2015.02.02-tree/">v4.14-9529-beta-2015.02.02-tree</A><br>2015/03/26    17:59        &lt;dir&gt; <A HREF="/files/softether/v4.15-9537-beta-2015.03.26-tree/">v4.15-9537-beta-2015.03.26-tree</A><br>2015/03/27    20:51        &lt;dir&gt; <A HREF="/files/softether/v4.15-9538-beta-2015.03.27-tree/">v4.15-9538-beta-2015.03.27-tree</A><br>2015/04/04     5:58        &lt;dir&gt; <A HREF="/files/softether/v4.15-9539-beta-2015.04.04-tree/">v4.15-9539-beta-2015.04.04-tree</A><br>2015/04/05     3:39        &lt;dir&gt; <A HREF="/files/softether/v4.15-9546-beta-2015.04.05-tree/">v4.15-9546-beta-2015.04.05-tree</A><br>2015/05/31    19:02        &lt;dir&gt; <A HREF="/files/softether/v4.17-9562-beta-2015.05.30-tree/">v4.17-9562-beta-2015.05.30-tree</A><br>2015/07/17     0:31        &lt;dir&gt; <A HREF="/files/softether/v4.17-9566-beta-2015.07.16-tree/">v4.17-9566-beta-2015.07.16-tree</A><br>2015/07/26    19:39        &lt;dir&gt; <A HREF="/files/softether/v4.18-9570-rtm-2015.07.26-tree/">v4.18-9570-rtm-2015.07.26-tree</A><br>2015/09/15    14:22        &lt;dir&gt; <A HREF="/files/softether/v4.19-9577-beta-2015.09.15-tree/">v4.19-9577-beta-2015.09.15-tree</A><br>2015/09/15    16:20        &lt;dir&gt; <A HREF="/files/softether/v4.19-9578-beta-2015.09.15-tree/">v4.19-9578-beta-2015.09.15-tree</A><br>2015/10/06    20:18        &lt;dir&gt; <A HREF="/files/softether/v4.19-9582-beta-2015.10.06-tree/">v4.19-9582-beta-2015.10.06-tree</A><br>2015/10/19    21:31        &lt;dir&gt; <A HREF="/files/softether/v4.19-9599-beta-2015.10.19-tree/">v4.19-9599-beta-2015.10.19-tree</A><br>2016/03/06    22:27        &lt;dir&gt; <A HREF="/files/softether/v4.19-9605-beta-2016.03.06-tree/">v4.19-9605-beta-2016.03.06-tree</A><br>2016/04/18     1:52        &lt;dir&gt; <A HREF="/files/softether/v4.20-9608-rtm-2016.04.17-tree/">v4.20-9608-rtm-2016.04.17-tree</A><br>2016/04/24    23:49        &lt;dir&gt; <A HREF="/files/softether/v4.21-9613-beta-2016.04.24-tree/">v4.21-9613-beta-2016.04.24-tree</A><br>2016/11/27    17:19        &lt;dir&gt; <A HREF="/files/softether/v4.22-9634-beta-2016.11.27-tree/">v4.22-9634-beta-2016.11.27-tree</A><br>2017/10/18    18:18        &lt;dir&gt; <A HREF="/files/softether/v4.23-9647-beta-2017.10.18-tree/">v4.23-9647-beta-2017.10.18-tree</A><br>2017/10/23     2:45        &lt;dir&gt; <A HREF="/files/softether/v4.24-9651-beta-2017.10.23-tree/">v4.24-9651-beta-2017.10.23-tree</A><br>2017/12/21    22:38        &lt;dir&gt; <A HREF="/files/softether/v4.24-9652-beta-2017.12.21-tree/">v4.24-9652-beta-2017.12.21-tree</A><br>2018/01/15    11:07        &lt;dir&gt; <A HREF="/files/softether/v4.25-9656-rtm-2018.01.15-tree/">v4.25-9656-rtm-2018.01.15-tree</A><br>2018/04/20    22:20        &lt;dir&gt; <A HREF="/files/softether/v4.27-9664-beta-2018.04.20-tree/">v4.27-9664-beta-2018.04.20-tree</A><br>2018/04/21    11:23        &lt;dir&gt; <A HREF="/files/softether/v4.27-9665-beta-2018.04.21-tree/">v4.27-9665-beta-2018.04.21-tree</A><br>2018/04/21    16:22        &lt;dir&gt; <A HREF="/files/softether/v4.27-9666-beta-2018.04.21-tree/">v4.27-9666-beta-2018.04.21-tree</A><br>2018/05/26    12:04        &lt;dir&gt; <A HREF="/files/softether/v4.27-9667-beta-2018.05.26-tree/">v4.27-9667-beta-2018.05.26-tree</A><br>2018/05/30     0:49        &lt;dir&gt; <A HREF="/files/softether/v4.27-9668-beta-2018.05.29-tree/">v4.27-9668-beta-2018.05.29-tree</A><br>2018/09/11    16:31        &lt;dir&gt; <A HREF="/files/softether/v4.28-9669-beta-2018.09.11-tree/">v4.28-9669-beta-2018.09.11-tree</A><br>2019/02/28    14:33        &lt;dir&gt; <A HREF="/files/softether/v4.29-9678-rtm-2019.02.28-tree/">v4.29-9678-rtm-2019.02.28-tree</A><br>2019/02/28    20:12        &lt;dir&gt; <A HREF="/files/softether/v4.29-9680-rtm-2019.02.28-tree/">v4.29-9680-rtm-2019.02.28-tree</A><br>2019/07/07    21:21        &lt;dir&gt; <A HREF="/files/softether/v4.30-9695-beta-2019.07.07-tree/">v4.30-9695-beta-2019.07.07-tree</A><br>2019/07/08    15:18        &lt;dir&gt; <A HREF="/files/softether/v4.30-9696-beta-2019.07.08-tree/">v4.30-9696-beta-2019.07.08-tree</A><br>2019/07/14    11:14        &lt;dir&gt; <A HREF="/files/softether/v4.30-9700-beta-2019.07.13-tree/">v4.30-9700-beta-2019.07.13-tree</A><br>2019/11/18    12:26        &lt;dir&gt; <A HREF="/files/softether/v4.31-9727-beta-2019.11.18-tree/">v4.31-9727-beta-2019.11.18-tree</A><br>2020/01/01    20:15        &lt;dir&gt; <A HREF="/files/softether/v4.32-9731-beta-2020.01.01-tree/">v4.32-9731-beta-2020.01.01-tree</A><br>2020/03/21    10:35        &lt;dir&gt; <A HREF="/files/softether/v4.34-9744-beta-2020.03.20-tree/">v4.34-9744-beta-2020.03.20-tree</A><br>2020/06/24    23:48        &lt;dir&gt; <A HREF="/files/softether/v4.34-9745-beta-2020.04.05-tree/">v4.34-9745-beta-2020.04.05-tree</A><br>2020/06/24    23:47        &lt;dir&gt; <A HREF="/files/softether/v4.34-9745-rtm-2020.04.05-tree/">v4.34-9745-rtm-2020.04.05-tree</A><br>2021/06/07    22:17        &lt;dir&gt; <A HREF="/files/softether/v4.36-9754-beta-2021.06.07-tree/">v4.36-9754-beta-2021.06.07-tree</A><br>2021/08/16     1:12        &lt;dir&gt; <A HREF="/files/softether/v4.37-9758-beta-2021.08.16-tree/">v4.37-9758-beta-2021.08.16-tree</A><br>2021/08/17    22:54        &lt;dir&gt; <A HREF="/files/softether/v4.38-9760-rtm-2021.08.17-tree/">v4.38-9760-rtm-2021.08.17-tree</A><br>2022/04/26    19:40        &lt;dir&gt; <A HREF="/files/softether/v4.39-9772-beta-2022.04.26-tree/">v4.39-9772-beta-2022.04.26-tree</A><br>2022/11/17    17:46        &lt;dir&gt; <A HREF="/files/softether/v4.41-9782-beta-2022.11.17-tree/">v4.41-9782-beta-2022.11.17-tree</A><br>2023/03/14    20:52        &lt;dir&gt; <A HREF="/files/softether/v4.41-9787-rtm-2023.03.14-tree/">v4.41-9787-rtm-2023.03.14-tree</A><br>2023/06/30    12:14        &lt;dir&gt; <A HREF="/files/softether/v4.42-9798-rtm-2023.06.30-tree/">v4.42-9798-rtm-2023.06.30-tree</A><br>2023/08/31    12:13        &lt;dir&gt; <A HREF="/files/softether/v4.43-9799-beta-2023.08.31-tree/">v4.43-9799-beta-2023.08.31-tree</A><br>2025/04/16    15:09        &lt;dir&gt; <A HREF="/files/softether/v4.44-9807-rtm-2025.04.16-tree/">v4.44-9807-rtm-2025.04.16-tree</A><br>2013/02/14    23:53          208 <A HREF="/files/softether/web.config">web.config</A><br></pre><hr></body></html>

so what we think we sort the right order might be false all the time because the line order that we want are not in the suitable format



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
    echo -e "\n\033[1;34mFetching latest RTM versions sorted by actual release date...\033[0m"
    
    # Get directory listing with actual dates using curl -l
    versions=$(curl -s -l --list-only "https://www.softether-download.com/files/softether/" | 
               grep -E '^v.*-rtm-.*-tree$' | 
               while read -r dir; do
                   # Get last modified date using HEAD request
                   last_modified=$(curl -sI "https://www.softether-download.com/files/softether/$dir" | 
                                  grep -i '^last-modified:' | 
                                  cut -d' ' -f2- | 
                                  xargs -I {} date -d "{}" +%Y%m%d)
                   echo "$last_modified $dir"
               done | 
               sort -nr | 
               head -3 | 
               awk '{print $2}')
    
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
    
    # Get the HTML content
    html_content=$(curl -s https://www.softether-download.com/files/softether/)
    
    # Extract version directories with dates
    versions=$(echo "$html_content" | 
               grep -Eo '>[0-9]{4}/[0-9]{2}/[0-9]{2}.+v[0-9]+\.[0-9]+-[0-9]+-rtm-[0-9]{4}\.[0-9]{2}\.[0-9]{2}-tree' |
               sed 's/>//' |
               sort -r | 
               head -3 | 
               awk '{print $NF}')
    
    # If empty, try alternative pattern
    if [ -z "$versions" ]; then
        versions=$(echo "$html_content" | 
                   grep -Eo 'v[0-9]+\.[0-9]+-[0-9]+-rtm-[0-9]{4}\.[0-9]{2}\.[0-9]{2}-tree' | 
                   sort -r | 
                   uniq | 
                   head -3)
    fi
    
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
# Function to get latest versions
get_latest_versions() {
    echo -e "\n\033[1;34mFetching latest RTM versions...\033[0m"
    
    # Get valid version directories using precise pattern
    versions=$(curl -s -l --list-only "https://www.softether-download.com/files/softether/" | 
               grep -E '20[0-9]{2}/[0-1][0-9]' | 
               sed 's|/$||' | 
               sort -r | 
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
    
    # Create version array
    version_array=()
    while IFS= read -r line; do
        version_array+=("$line")
    done <<< "$versions"
    
    # Display version menu
    echo -e "\n\033[1;36mSelect a version:\033[0m"
    for i in "${!version_array[@]}"; do
        # Extract clean version name (last part of path)
        clean_name=$(basename "${version_array[$i]}")
        echo "$((i+1))) $clean_name"
    done
    echo "4) Enter custom version"
    
    # Get user selection
    while true; do
        read -rp "Enter choice [1-4]: " version_choice
        case $version_choice in
            1|2|3)
                selected_version="${version_array[$((version_choice-1))]}"
                break
                ;;
            4)
                read -rp "Enter version (e.g., v4.44-9807-rtm-2025.04.16-tree): " custom_version
                # Validate custom version format
                if [[ ! "$custom_version" =~ ^v[0-9]+\.[0-9]+-[0-9]+-rtm-[0-9]{4}\.[0-9]{2}\.[0-9]{2}-tree$ ]]; then
                    echo -e "\033[1;31mInvalid version format. Please use the format: vX.XX-XXXX-rtm-YYYY.MM.DD-tree\033[0m"
                    continue
                fi
                selected_version="$custom_version"
                break
                ;;
            *)
                echo "Invalid selection. Please try again."
                ;;
        esac
    done
    
    # Extract clean version name for display
    clean_version=$(basename "$selected_version")
    
    # Build download directory URL
    download_dir="https://www.softether-download.com/files/softether/$selected_version/Linux/SoftEther_VPN_Server/"
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