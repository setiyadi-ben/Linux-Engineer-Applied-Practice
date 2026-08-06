#!/bin/bash
# SoftEther TAP Adapter Setup & Systemd Bootstrap
# -----------------------------------------------
# This script:
#   1. Creates the tap_softether adapter via vpncmd (programmatic, no GUI needed)
#   2. Creates a persistent IP binding script for the tap adapter
#   3. Installs a systemd service so the binding survives reboots
#
# The tap adapter gets IP 10.20.0.2/20 — the Virtual Hub holds 10.20.0.1
# Only the VPN subnet (10.20.0.0/20) is routed through the adapter,
# NOT a default gateway override (which would break SSH/public traffic).
#
# Usage:
#   sudo chmod +x ./autoinstall_setup-tap_softether.sh
#   sudo ./autoinstall_setup-tap_softether.sh

# --- Configuration ---
TAP_IF="tap_softether"
TAP_NAME="softether"          # Name used inside SoftEther (tap_<name> = tap_softether)
HUB_NAME="VPN"                # SoftEther Virtual Hub name (adjust if different)
IP_ADDR="10.20.0.2"
SUBNET_CIDR="10.20.0.0/20"
BROADCAST="10.20.15.255"
PREFIX="20"
VPNCMD="/usr/local/vpnserver/vpncmd"
BIND_SCRIPT="/opt/tap_softether_bind.sh"
SERVICE_FILE="/etc/systemd/system/tap-softether-bind.service"

# --- Root check ---
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: Run this script as root (sudo $0)" >&2
    exit 1
fi

# --- Check vpncmd is available ---
if [ ! -x "$VPNCMD" ]; then
    echo -e "\033[1;31mError: vpncmd not found at $VPNCMD\033[0m" >&2
    echo "Please ensure SoftEther VPN Server is installed first." >&2
    exit 1
fi

# --- Check vpnserver service is running ---
if ! systemctl is-active --quiet vpnserver; then
    echo -e "\033[1;31mError: vpnserver service is not running.\033[0m" >&2
    echo "Start it first: systemctl start vpnserver" >&2
    exit 1
fi

echo -e "\n\033[1;34mSoftEther TAP Adapter Bootstrap\033[0m"
echo "========================================"

# --- Show server network info before asking for credentials ---
echo ""
echo -e "\033[1;33mDetected network interfaces on this server:\033[0m"
ip -o addr show | awk '{printf "  %-12s %s\n", $2, $4}' | grep -v "^  lo "
echo ""

# --- Port selection ---
echo -e "\033[1;33mWhich port is SoftEther listening on?\033[0m"
echo "  1) 443"
echo "  2) 992"
echo "  3) 1194"
echo "  4) 5555"
echo "  5) Enter custom port"
echo ""
read -p "Select an option (1-5): " port_choice
case $port_choice in
    1) SE_PORT="443" ;;
    2) SE_PORT="992" ;;
    3) SE_PORT="1194" ;;
    4) SE_PORT="5555" ;;
    5)
        read -p "Enter port number: " SE_PORT
        if [[ ! $SE_PORT =~ ^[0-9]+$ ]] || ((SE_PORT < 1 || SE_PORT > 65535)); then
            echo -e "\033[1;31mError: Invalid port number.\033[0m" >&2
            exit 1
        fi
        ;;
    *)
        echo -e "\033[1;31mInvalid selection. Exiting.\033[0m" >&2
        exit 1
        ;;
esac
echo -e "\033[1;32mUsing port: $SE_PORT\033[0m"

# --- Prompt for SoftEther admin password (not hardcoded) ---
echo ""
read -s -p "Enter SoftEther Server Manager admin password: " SE_PASSWORD
echo ""

# --- Verify credentials and show server info ---
echo -e "\n\033[1;33mConnecting to SoftEther on localhost:$SE_PORT ...\033[0m"
CHECK_OUTPUT=$("$VPNCMD" /SERVER localhost:"$SE_PORT" /PASSWORD:"$SE_PASSWORD" /CMD ServerInfoGet 2>&1)

if echo "$CHECK_OUTPUT" | grep -qi "password is incorrect\|cannot connect\|error"; then
    echo -e "\033[1;31mError: Could not authenticate with SoftEther.\033[0m" >&2
    echo "vpncmd output: $CHECK_OUTPUT" >&2
    exit 1
fi

# Extract and display key server info fields
echo -e "\n\033[1;32mConnected. Server info:\033[0m"
echo "$CHECK_OUTPUT" | grep -E "Server Name|Server Type|OS Name|Product Version|Build Info" | \
    sed 's/^/  /'
echo ""

# --- Safety check: Virtual Hub must exist and be configured before proceeding ---
echo -e "\033[1;33mChecking Virtual Hub '$HUB_NAME'...\033[0m"
HUB_OUTPUT=$("$VPNCMD" /SERVER localhost:"$SE_PORT" /PASSWORD:"$SE_PASSWORD" /CMD HubList 2>&1)

if ! echo "$HUB_OUTPUT" | grep -q "$HUB_NAME"; then
    echo -e "\033[1;31m"
    echo "========================================================"
    echo " STOP: Virtual Hub '$HUB_NAME' does not exist."
    echo "========================================================"
    echo -e "\033[0mThis script cannot proceed on a fresh SoftEther install."
    echo ""
    echo "Before running this script, you must complete the following"
    echo "steps in SoftEther VPN Server Manager (from your Windows PC):"
    echo ""
    echo "  1. Connect to this server using SoftEther VPN Server Manager"
    echo "  2. Create a Virtual Hub (default name used here: '$HUB_NAME')"
    echo "  3. Set the Virtual Hub admin password"
    echo "  4. Create at least one user with an IP assignment policy"
    echo "  5. Enable SecureNAT or configure the hub's IP (10.20.0.1)"
    echo "  6. Import or apply your saved server config if you have one"
    echo "     (Server Manager → Edit Config, or via .vpn config file)"
    echo ""
    echo "Once the hub is configured, re-run this script."
    echo -e "\033[1;31mExiting.\033[0m" >&2
    exit 1
fi

# Verify hub is enabled (not disabled)
HUB_DETAIL=$("$VPNCMD" /SERVER localhost:"$SE_PORT" /PASSWORD:"$SE_PASSWORD" /CMD HubStatusGet "$HUB_NAME" 2>&1)
if echo "$HUB_DETAIL" | grep -qi "online.*no\|status.*offline"; then
    echo -e "\033[1;31mWarning: Virtual Hub '$HUB_NAME' exists but appears to be offline.\033[0m"
    echo "Enable it in SoftEther VPN Server Manager before continuing."
    read -p "Continue anyway? (y/N): " cont_anyway
    [[ ! $cont_anyway =~ ^[Yy]$ ]] && { echo "Exiting."; exit 1; }
fi

echo -e "\033[1;32mVirtual Hub '$HUB_NAME' found and online.\033[0m"
echo ""

# --- Show current configuration and allow editing before proceeding ---
echo -e "\033[1;34m========================================\033[0m"
echo -e "\033[1;34m  Current TAP Adapter Configuration\033[0m"
echo -e "\033[1;34m========================================\033[0m"
echo ""
printf "  %-20s %s\n" "TAP interface name:"  "$TAP_IF"
printf "  %-20s %s\n" "TAP device name:"     "$TAP_NAME  (creates $TAP_IF in kernel)"
printf "  %-20s %s\n" "Virtual Hub:"         "$HUB_NAME"
printf "  %-20s %s\n" "TAP adapter IP:"      "$IP_ADDR  (this VPS on the VPN subnet)"
printf "  %-20s %s\n" "VPN Gateway IP:"      "10.20.0.1  (Virtual Hub — assigned in SoftEther)"
printf "  %-20s %s\n" "Subnet CIDR:"         "$SUBNET_CIDR"
printf "  %-20s %s\n" "Prefix length:"       "/$PREFIX"
printf "  %-20s %s\n" "Broadcast:"           "$BROADCAST"
echo ""
echo -e "\033[1;33mNote: The gateway IP (10.20.0.1) is managed by SoftEther's Virtual Hub"
echo -e "and must be configured there — not in this script.\033[0m"
echo ""

read -p "Edit configuration before continuing? (y/N): " edit_config
if [[ $edit_config =~ ^[Yy]$ ]]; then
    echo ""
    echo "Press ENTER to keep the current value shown in brackets."
    echo ""

    read -p "  TAP interface name [$TAP_IF]: " input
    TAP_IF="${input:-$TAP_IF}"

    read -p "  TAP device name (part after tap_) [$TAP_NAME]: " input
    TAP_NAME="${input:-$TAP_NAME}"

    read -p "  Virtual Hub name [$HUB_NAME]: " input
    HUB_NAME="${input:-$HUB_NAME}"

    read -p "  TAP adapter IP [$IP_ADDR]: " input
    IP_ADDR="${input:-$IP_ADDR}"

    read -p "  Subnet CIDR [$SUBNET_CIDR]: " input
    SUBNET_CIDR="${input:-$SUBNET_CIDR}"

    read -p "  Prefix length [$PREFIX]: " input
    PREFIX="${input:-$PREFIX}"

    read -p "  Broadcast [$BROADCAST]: " input
    BROADCAST="${input:-$BROADCAST}"

    echo ""
    echo -e "\033[1;33mUpdated configuration:\033[0m"
    printf "  %-20s %s\n" "TAP interface name:"  "$TAP_IF"
    printf "  %-20s %s\n" "TAP device name:"     "$TAP_NAME"
    printf "  %-20s %s\n" "Virtual Hub:"         "$HUB_NAME"
    printf "  %-20s %s\n" "TAP adapter IP:"      "$IP_ADDR"
    printf "  %-20s %s\n" "Subnet CIDR:"         "$SUBNET_CIDR"
    printf "  %-20s %s\n" "Prefix:"              "/$PREFIX"
    printf "  %-20s %s\n" "Broadcast:"           "$BROADCAST"
    echo ""
fi

read -p "Proceed with this configuration? (y/N): " confirm_proceed
if [[ ! $confirm_proceed =~ ^[Yy]$ ]]; then
    echo "Exiting without changes."
    exit 0
fi
echo ""

# --- Create tap adapter via vpncmd if not already present ---
echo -e "\n\033[1;33mChecking tap adapter...\033[0m"

if ip link show "$TAP_IF" &>/dev/null; then
    echo -e "\033[1;32mTap adapter '$TAP_IF' already exists, skipping creation.\033[0m"
else
    echo "Creating tap adapter '$TAP_IF' in SoftEther hub '$HUB_NAME'..."
    CREATE_OUTPUT=$("$VPNCMD" /SERVER localhost:"$SE_PORT" /PASSWORD:"$SE_PASSWORD" /CMD BridgeCreate "$HUB_NAME" /DEVICE:"$TAP_NAME" /TAP:yes 2>&1)

    # Give the kernel a moment to register the new tap interface
    sleep 2

    if ip link show "$TAP_IF" &>/dev/null; then
        echo -e "\033[1;32mTap adapter '$TAP_IF' created successfully.\033[0m"
    else
        echo -e "\033[1;31mError: Tap adapter '$TAP_IF' was not created.\033[0m" >&2
        echo "vpncmd output: $CREATE_OUTPUT" >&2
        echo "Try manually: BridgeCreate $HUB_NAME /DEVICE:$TAP_NAME /TAP:yes" >&2
        exit 1
    fi
fi

# --- Create the persistent IP binding script ---
echo -e "\n\033[1;33mCreating IP binding script at $BIND_SCRIPT...\033[0m"
cat > "$BIND_SCRIPT" << EOF
#!/bin/bash
# Persistent IP binding for SoftEther tap adapter
# Managed by: tap-softether-bind.service
# Do not edit manually — regenerate via autoinstall_setup-tap_softether.sh

TAP_IF="$TAP_IF"
IP_ADDR="$IP_ADDR"
PREFIX="$PREFIX"
BROADCAST="$BROADCAST"
SUBNET_CIDR="$SUBNET_CIDR"

# Wait for tap adapter to be available (it appears after vpnserver starts)
for i in \$(seq 1 15); do
    if ip link show "\$TAP_IF" &>/dev/null; then
        break
    fi
    echo "Waiting for \$TAP_IF to appear... (\$i/15)"
    sleep 2
done

if ! ip link show "\$TAP_IF" &>/dev/null; then
    echo "Error: \$TAP_IF not found after waiting. Is vpnserver running?" >&2
    exit 1
fi

# Flush any stale IPs on this adapter that don't match current config
# Handles the case where IP was changed on rerun — prevents leftover addresses
STALE_IPS=\$(ip addr show "\$TAP_IF" | awk '/inet / {print \$2}' | grep -v "^\$IP_ADDR/")
for stale in \$STALE_IPS; do
    ip addr del "\$stale" dev "\$TAP_IF" 2>/dev/null
    echo "Removed stale IP \$stale from \$TAP_IF"
done

# Bind IP if not already configured
if ! ip addr show "\$TAP_IF" | grep -q "\$IP_ADDR"; then
    ip addr add "\$IP_ADDR/\$PREFIX" brd "\$BROADCAST" dev "\$TAP_IF"
    echo "IP \$IP_ADDR/\$PREFIX bound to \$TAP_IF"
else
    echo "IP \$IP_ADDR already configured on \$TAP_IF"
fi

# Bring interface up
ip link set "\$TAP_IF" up

# Flush stale routes on this adapter that don't match current subnet
# Handles the case where SUBNET_CIDR was changed on rerun
STALE_ROUTES=\$(ip route | awk "\\\$3 == \"\$TAP_IF\" {print \\\$1}" | grep -v "^\$SUBNET_CIDR\$")
for stale_route in \$STALE_ROUTES; do
    ip route del "\$stale_route" dev "\$TAP_IF" 2>/dev/null
    echo "Removed stale route \$stale_route from \$TAP_IF"
done

# Add VPN subnet route only — do NOT touch the default gateway
if ! ip route | grep -q "\$SUBNET_CIDR"; then
    ip route add "\$SUBNET_CIDR" dev "\$TAP_IF"
    echo "Route \$SUBNET_CIDR via \$TAP_IF added"
else
    echo "Route \$SUBNET_CIDR already exists"
fi

echo "TAP adapter setup complete."
EOF

chmod 755 "$BIND_SCRIPT"
echo -e "\033[1;32mBinding script created.\033[0m"

# --- Create systemd service ---
echo -e "\n\033[1;33mInstalling systemd service...\033[0m"
cat > "$SERVICE_FILE" << EOF
[Unit]
Description=SoftEther TAP Adapter IP Binding
# Must start after vpnserver so tap_softether exists
After=network.target vpnserver.service
Requires=vpnserver.service

[Service]
Type=oneshot
ExecStart=$BIND_SCRIPT
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable tap-softether-bind.service

echo -e "\033[1;32mSystemd service installed and enabled.\033[0m"

# --- Run binding now immediately ---
# Use restart (not start) so rerun always re-executes with the latest config
echo -e "\n\033[1;33mApplying IP binding now...\033[0m"
systemctl restart tap-softether-bind.service
sleep 2

if systemctl is-active --quiet tap-softether-bind.service; then
    echo -e "\033[1;32mService is active.\033[0m"
else
    echo -e "\033[1;31mWarning: Service did not start cleanly. Check: journalctl -u tap-softether-bind\033[0m" >&2
fi

# --- Final status ---
echo -e "\n\033[1;33m--- Final Status ---\033[0m"
echo "[Interface]"
ip addr show "$TAP_IF" 2>/dev/null || echo "  $TAP_IF not visible yet"
echo ""
echo "[VPN Subnet Route]"
ip route | grep "$SUBNET_CIDR" || echo "  Route not found"
echo ""
echo "[Service]"
systemctl status tap-softether-bind.service --no-pager
echo ""
echo -e "\033[1;32mBootstrap complete!\033[0m"
echo "VPN clients connecting to the hub will be able to reach internal services"
echo "via port mappings on 10.20.0.1 (Virtual Hub) and this host at 10.20.0.2."