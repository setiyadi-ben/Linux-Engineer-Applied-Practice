#!/bin/bash
set -e

# ==============================
# CONFIG (sesuai desain Anda)
# ==============================
TAP_IF="tap_softether"
IP_ADDR="10.20.0.2"
PREFIX="20"              # /21 = 255.255.240.0
GATEWAY="10.20.0.1"

SOFTETHER_DIR="/usr/local/vpnserver"
SCRIPT_DIR="$SOFTETHER_DIR/scripts"
TAP_SCRIPT="$SCRIPT_DIR/tap_softether_up.sh"
SYSTEMD_UNIT="/etc/systemd/system/tap-softether.service"

# ==============================
# PRECHECK
# ==============================
if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: Run as root"
    exit 1
fi

if [ ! -d "$SOFTETHER_DIR" ]; then
    echo "ERROR: SoftEther directory not found at $SOFTETHER_DIR"
    exit 1
fi

# ==============================
# CREATE TAP SCRIPT
# ==============================
mkdir -p "$SCRIPT_DIR"

cat > "$TAP_SCRIPT" << EOF
#!/bin/bash
set -e

TAP_IF="$TAP_IF"
IP_ADDR="$IP_ADDR"
PREFIX="$PREFIX"
GATEWAY="$GATEWAY"

# Wait for TAP interface (SoftEther server)
for i in {1..15}; do
    if ip link show "\$TAP_IF" >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

# Exit if TAP not present
ip link show "\$TAP_IF" >/dev/null 2>&1 || exit 1

# Idempotent configuration
ip addr flush dev "\$TAP_IF"
ip addr add "\$IP_ADDR/\$PREFIX" dev "\$TAP_IF"
ip link set "\$TAP_IF" up

# Add default route only if not exists
if ! ip route show default | grep -q "\$GATEWAY"; then
    ip route add default via "\$GATEWAY" dev "\$TAP_IF"
fi
EOF

chmod +x "$TAP_SCRIPT"

# ==============================
# CREATE SYSTEMD UNIT
# ==============================
cat > "$SYSTEMD_UNIT" << EOF
[Unit]
Description=Configure tap_softether interface for SoftEther VPN
After=vpnserver.service network.target
Requires=vpnserver.service

[Service]
Type=oneshot
ExecStart=$TAP_SCRIPT
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# ==============================
# ENABLE & START SERVICE
# ==============================
systemctl daemon-reload
systemctl enable tap-softether.service
systemctl restart tap-softether.service

# ==============================
# FINAL CHECK
# ==============================
echo "=== TAP STATUS ==="
ip a show "$TAP_IF" || true

echo "=== ROUTING TABLE ==="
ip route || true

echo "Setup completed successfully."
