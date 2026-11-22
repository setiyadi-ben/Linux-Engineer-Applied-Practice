#!/bin/bash
# SoftEther TAP Adapter & Proxmox-style Bridge Setup
# -----------------------------------------------
# This script:
#   1. Creates the tap_softether adapter via vpncmd.
#   2. Idempotently flushes old configs and creates a Linux Bridge (vmbr0).
#   3. Attaches tap_softether to vmbr0 and assigns the Host IP (10.20.0.2) to vmbr0.
#   4. Enables IP forwarding and NAT so LXC containers can access the internet.
#   5. Installs a systemd service so this topology survives reboots.

# --- Configuration ---
TAP_IF="tap_softether"
TAP_NAME="softether"
HUB_NAME="VPN"
BRIDGE_IF="vmbr0"
WAN_IF="eth0"                 # Pastikan ini sesuai dengan interface public kamu
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

if [ ! -x "$VPNCMD" ]; then
    echo -e "\033[1;31mError: vpncmd not found at $VPNCMD\033[0m" >&2
    exit 1
fi

if ! systemctl is-active --quiet vpnserver; then
    echo -e "\033[1;31mError: vpnserver service is not running.\033[0m" >&2
    exit 1
fi

echo -e "\n\033[1;34mSoftEther TAP & LXC Bridge (vmbr0) Bootstrap\033[0m"
echo "================================================="

# --- Port selection & Auth ---
read -p "SoftEther port (default 443, press Enter for default): " input_port
SE_PORT="${input_port:-443}"

read -s -p "Enter SoftEther Server Manager admin password: " SE_PASSWORD
echo ""

CHECK_OUTPUT=$("$VPNCMD" /SERVER localhost:"$SE_PORT" /PASSWORD:"$SE_PASSWORD" /CMD ServerInfoGet 2>&1)
if echo "$CHECK_OUTPUT" | grep -qi "password is incorrect\|cannot connect\|error"; then
    echo -e "\033[1;31mError: Could not authenticate with SoftEther.\033[0m" >&2
    exit 1
fi
echo -e "\033[1;32mAuthenticated successfully.\033[0m"

# --- Create tap adapter via vpncmd if not already present ---
echo -e "\n\033[1;33mChecking tap adapter...\033[0m"
if ip link show "$TAP_IF" &>/dev/null; then
    echo -e "\033[1;32mTap adapter '$TAP_IF' already exists.\033[0m"
else
    echo "Creating tap adapter '$TAP_IF'..."
    "$VPNCMD" /SERVER localhost:"$SE_PORT" /PASSWORD:"$SE_PASSWORD" /CMD BridgeCreate "$HUB_NAME" /DEVICE:"$TAP_NAME" /TAP:yes >/dev/null
    sleep 2
fi

# --- Create the persistent IP binding & Bridging script ---
echo -e "\n\033[1;33mGenerating idempotent network bind script...\033[0m"
cat > "$BIND_SCRIPT" << EOF
#!/bin/bash
# Idempotent Bridge & TAP adapter configuration
# Managed by: tap-softether-bind.service

TAP_IF="$TAP_IF"
BRIDGE_IF="$BRIDGE_IF"
WAN_IF="$WAN_IF"
IP_ADDR="$IP_ADDR"
PREFIX="$PREFIX"
BROADCAST="$BROADCAST"
SUBNET_CIDR="$SUBNET_CIDR"

# 1. Wait for SoftEther to generate the TAP adapter
for i in \$(seq 1 15); do
    if ip link show "\$TAP_IF" &>/dev/null; then
        break
    fi
    sleep 2
done

if ! ip link show "\$TAP_IF" &>/dev/null; then
    echo "Error: \$TAP_IF not found." >&2
    exit 1
fi

# 2. FLUSH: Clean up old direct IP assignments on TAP to avoid conflicts
ip addr flush dev "\$TAP_IF" 2>/dev/null
ip route del "\$SUBNET_CIDR" dev "\$TAP_IF" 2>/dev/null

# 3. IDEMPOTENT: Create bridge vmbr0 if it doesn't exist
if ! ip link show "\$BRIDGE_IF" &>/dev/null; then
    ip link add name "\$BRIDGE_IF" type bridge
    echo "Created bridge \$BRIDGE_IF"
fi

# 4. Attach TAP adapter to vmbr0
ip link set "\$TAP_IF" master "\$BRIDGE_IF"
ip link set "\$TAP_IF" up
ip link set "\$BRIDGE_IF" up

# 5. IDEMPOTENT: Manage IPs on vmbr0 (Flush stale, add correct)
STALE_IPS=\$(ip addr show "\$BRIDGE_IF" | awk '/inet / {print \$2}' | grep -v "^\$IP_ADDR/")
for stale in \$STALE_IPS; do
    ip addr del "\$stale" dev "\$BRIDGE_IF" 2>/dev/null
done

if ! ip addr show "\$BRIDGE_IF" | grep -q "\$IP_ADDR"; then
    ip addr add "\$IP_ADDR/\$PREFIX" brd "\$BROADCAST" dev "\$BRIDGE_IF"
    echo "Assigned \$IP_ADDR/\$PREFIX to \$BRIDGE_IF"
fi

# 6. Enable IP Forwarding (Idempotent)
sysctl -w net.ipv4.ip_forward=1 >/dev/null

# 7. IDEMPOTENT: Setup NAT Masquerade so LXC can access Internet
if ! iptables -t nat -C POSTROUTING -s "\$SUBNET_CIDR" -o "\$WAN_IF" -j MASQUERADE 2>/dev/null; then
    iptables -t nat -A POSTROUTING -s "\$SUBNET_CIDR" -o "\$WAN_IF" -j MASQUERADE
    echo "Added NAT Masquerade for \$SUBNET_CIDR"
fi

echo "Network bridging setup complete."
EOF

chmod 755 "$BIND_SCRIPT"

# --- Create systemd service ---
cat > "$SERVICE_FILE" << EOF
[Unit]
Description=SoftEther TAP Bridge & LXC Networking
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
systemctl enable tap-softether-bind.service >/dev/null 2>&1

echo -e "\n\033[1;33mApplying Network Configuration...\033[0m"
systemctl restart tap-softether-bind.service
sleep 2

# --- Final Output ---
echo -e "\n\033[1;32m=== Setup Complete! ===\033[0m"
echo -e "\033[1;33mBridge Interface ($BRIDGE_IF):\033[0m"
ip -4 addr show "$BRIDGE_IF" | awk '/inet/ {print $2}'
echo -e "\n\033[1;33mAttached Ports:\033[0m"
bridge link show | grep "$BRIDGE_IF"
echo ""
echo "Host OS IP is now $IP_ADDR on $BRIDGE_IF."
echo "You can now bind LXC containers to $BRIDGE_IF (e.g., lxc.net.0.link = $BRIDGE_IF)"