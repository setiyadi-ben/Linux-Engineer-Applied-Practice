#!/bin/bash
# ==============================================================
# lxc_nas-provisioning.sh
# ==============================================================

set -e

CONTAINER_NAME="nas"
PUB_IFACE="eth0"
VPN_IFACE="tap_softether"
TEMPLATE_DIR="/root/lxc-templates"

VMBR_NAME="vmbr0"
VMBR_ADDR="10.20.0.2"
VMBR_PREFIX="20"
VMBR_NETMASK="255.255.240.0"
VMBR_SUBNET="10.20.0.0/20"

CONTAINER_IP="10.20.1.1"
DNS_SERVERS="8.8.8.8 1.1.1.1"

CONFIG="/var/lib/lxc/$CONTAINER_NAME/config"
ROOTFS_IF="/var/lib/lxc/$CONTAINER_NAME/rootfs/etc/network/interfaces"

PORT_MAP=(
    "8080:tcp:80:WebGUI/WebDAV HTTP"
)

# Ambil IP Public secara dinamis dari interface eth0
PUB_IP=$(ip -4 addr show dev "$PUB_IFACE" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n 1)
if [ -z "$PUB_IP" ]; then
    PUB_IP=$(curl -s ifconfig.me)
fi

echo "================================"
echo " Setup network + port forward: $CONTAINER_NAME"
echo "================================"

# ---------------- STEP 0: AUTO-CREATE CONTAINER ----------------
if [ ! -d "/var/lib/lxc/$CONTAINER_NAME" ]; then
    echo "[!] Container $CONTAINER_NAME belum ada."
    
    # Kunci pencarian file murni ke kata "fileserver" 
    TEMPLATE_FILE=$(ls "$TEMPLATE_DIR"/*fileserver*.tar.gz 2>/dev/null | head -n 1)
    
    if [ -n "$TEMPLATE_FILE" ] && [ -f "$TEMPLATE_FILE" ]; then
        echo "    Template ditemukan: $TEMPLATE_FILE"
        echo "    Membuat wadah LXC kosong (downloading metadata)..."
        export DEBIAN_FRONTEND=noninteractive
        sudo lxc-create -n "$CONTAINER_NAME" -t download -- -d debian -r bookworm -a amd64
        
        echo "    Mengganti rootfs bawaan dengan template TurnKey Fileserver..."
        sudo rm -rf /var/lib/lxc/"$CONTAINER_NAME"/rootfs/*
        sudo tar -xf "$TEMPLATE_FILE" -C /var/lib/lxc/"$CONTAINER_NAME"/rootfs/
        echo "    [OK] Container $CONTAINER_NAME berhasil disiapkan secara instan!"
        echo ""
    else
        echo "[!] Template *fileserver*.tar.gz tidak ditemukan di $TEMPLATE_DIR." >&2
        echo "    Pastikan file template sudah didownload terlebih dahulu." >&2
        exit 1
    fi
fi

echo "Rencana eksekusi:"
echo "  - Container   : $CONTAINER_NAME"
echo "  - IP container: $CONTAINER_IP (subnet $VMBR_SUBNET via $VMBR_NAME)"
echo "  - Ke WAN cuma : tcp/8080 -> $CONTAINER_IP:80 (WebGUI/WebDAV)"
read -rp "Lanjutkan eksekusi? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Dibatalkan."
    exit 0
fi

# ---------------- STEP 1: INSTALL DEPENDENSI ----------------
echo "[*] Step 1: Memastikan paket dependensi terpasang..."
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -qq
sudo apt-get install -yq bridge-utils ifupdown iptables-persistent

# ---------------- STEP 2: NONAKTIFKAN lxcbr0 ----------------
echo "[*] Step 2: mematikan lxcbr0 default..."
if [ -f /etc/default/lxc-net ] && grep -q '^USE_LXC_BRIDGE="true"' /etc/default/lxc-net; then
    sudo sed -i 's/^USE_LXC_BRIDGE="true"/USE_LXC_BRIDGE="false"/' /etc/default/lxc-net
fi
sudo systemctl stop lxc-net 2>/dev/null || true
if ip link show lxcbr0 >/dev/null 2>&1; then
    sudo ip link delete lxcbr0 type bridge 2>/dev/null || true
fi

# ---------------- STEP 3: SETUP vmbr0 ----------------
echo "[*] Step 3: setup bridge $VMBR_NAME ($VMBR_ADDR/$VMBR_PREFIX)..."
if ip link show "$VMBR_NAME" >/dev/null 2>&1; then
    echo "    $VMBR_NAME sudah ada, skip pembuatan."
else
    sudo ip link add name "$VMBR_NAME" type bridge
    sudo ip link set "$VMBR_NAME" up

    if ip link show "$VPN_IFACE" >/dev/null 2>&1; then
        sudo ip addr flush dev "$VPN_IFACE" 2>/dev/null || true
        sudo ip link set "$VPN_IFACE" master "$VMBR_NAME"
        echo "    $VPN_IFACE dimasukkan ke $VMBR_NAME."
    else
        echo "    [!] Peringatan: $VPN_IFACE tidak ada, pastikan SoftEther berjalan." >&2
    fi

    sudo ip addr add "$VMBR_ADDR/$VMBR_PREFIX" dev "$VMBR_NAME" 2>/dev/null || true
fi

sudo sysctl -w net.ipv4.ip_forward=1 >/dev/null

if ! sudo iptables -t nat -C POSTROUTING -s "$VMBR_SUBNET" -o "$PUB_IFACE" -j MASQUERADE 2>/dev/null; then
    sudo iptables -t nat -A POSTROUTING -s "$VMBR_SUBNET" -o "$PUB_IFACE" -j MASQUERADE
fi

if ! grep -q "^auto $VMBR_NAME" /etc/network/interfaces 2>/dev/null; then
    {
        echo ""
        echo "auto $VMBR_NAME"
        echo "iface $VMBR_NAME inet static"
        echo "    address $VMBR_ADDR"
        echo "    netmask $VMBR_NETMASK"
        echo "    bridge_ports none"
        echo "    bridge_stp off"
        echo "    bridge_fd 0"
        echo "    post-up echo 1 > /proc/sys/net/ipv4/ip_forward"
        echo "    post-up iptables -t nat -A POSTROUTING -s '$VMBR_SUBNET' -o $PUB_IFACE -j MASQUERADE"
    } | sudo tee -a /etc/network/interfaces >/dev/null
fi

# ---------------- STEP 4: ARAHKAN NIC CONTAINER ----------------
echo "[*] Step 4: arahkan NIC $CONTAINER_NAME ke $VMBR_NAME..."
sudo sed -i '/^lxc\.net\.0\.\(type\|link\|flags\)/d' "$CONFIG"
{
    echo "lxc.net.0.type = veth"
    echo "lxc.net.0.link = $VMBR_NAME"
    echo "lxc.net.0.flags = up"
} | sudo tee -a "$CONFIG" >/dev/null

# ---------------- STEP 5: STATIC IP CONTAINER ----------------
echo "[*] Step 5: tulis static IP $CONTAINER_IP di rootfs container..."
sudo tee "$ROOTFS_IF" >/dev/null <<EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address $CONTAINER_IP
    netmask $VMBR_NETMASK
    gateway $VMBR_ADDR
    dns-nameservers $DNS_SERVERS
EOF

# ---------------- STEP 6: START CONTAINER ----------------
echo "[*] Step 6: start container $CONTAINER_NAME..."
STATE=$(sudo lxc-info -n "$CONTAINER_NAME" -s 2>/dev/null | awk '{print $2}')
if [ "$STATE" = "RUNNING" ]; then
    echo "    Sudah RUNNING, skip start."
else
    sudo lxc-start -n "$CONTAINER_NAME" -d
    sleep 3
    echo "    Container di-start."
fi

# ---------------- STEP 7: PORT FORWARDING ----------------
echo "[*] Step 7: pasang port forwarding..."
for ENTRY in "${PORT_MAP[@]}"; do
    IFS=':' read -r PUB_PORT PROTO DST_PORT LABEL <<< "$ENTRY"
    if ! sudo iptables -t nat -C PREROUTING -i "$PUB_IFACE" -p "$PROTO" --dport "$PUB_PORT" -j DNAT --to-destination "$CONTAINER_IP:$DST_PORT" 2>/dev/null; then
        sudo iptables -t nat -A PREROUTING -i "$PUB_IFACE" -p "$PROTO" --dport "$PUB_PORT" -j DNAT --to-destination "$CONTAINER_IP:$DST_PORT"
        echo "    + $PROTO/$PUB_PORT -> $CONTAINER_IP:$DST_PORT ($LABEL)"
    fi
done

if ! sudo iptables -C FORWARD -d "$CONTAINER_IP" -p tcp --dport 80 -j ACCEPT 2>/dev/null; then
    sudo iptables -A FORWARD -d "$CONTAINER_IP" -p tcp --dport 80 -j ACCEPT
fi

# ---------------- STEP 8: SIMPAN IPTABLES ----------------
echo "[*] Step 8: simpan aturan iptables..."
if command -v netfilter-persistent >/dev/null 2>&1; then
    sudo netfilter-persistent save
fi

# ---------------- STEP 9: TURNKEY INIT ----------------
echo ""
echo "[*] Step 9: jalankan turnkey-init..."
sudo lxc-attach -n "$CONTAINER_NAME" -- turnkey-init

echo ""
echo "================================"
echo " Akses Akhir"
echo "================================"
echo "WAN (publik)  : http://$PUB_IP:8080  (WebGUI/WebDAV)"
echo "VPN/lokal saja: https://$CONTAINER_IP:443, Samba \\\\$CONTAINER_IP\\, Webmin https://$CONTAINER_IP:12321"
echo "================================"
echo ""
echo "[!] TROUBLESHOOTING: Lupa Password & Terkena Banned Webmin"
echo "TurnKey File Server dilengkapi dengan perlindungan Fail2Ban."
echo "Jika Anda gagal login Webmin sebanyak 3x, IP VPN Anda akan diblokir."
echo ""
echo "Jika itu terjadi, jalankan perintah ini di terminal Host VPS:"
echo "  1. Masuk ke container : sudo lxc-attach -n $CONTAINER_NAME"
echo "  2. Reset password     : passwd root"
echo "  3. Hapus ban IP Anda  : fail2ban-client set webmin-auth unbanip <IP_VPN_ANDA>"
echo "                          (Ganti <IP_VPN_ANDA> dengan IP klien Anda, misal 10.20.0.10)"
echo "================================"