#!/usr/bin/env bash
set -euo pipefail

# Pastikan dieksekusi sebagai root
if [ "$(id -u)" -ne 0 ]; then
    echo "[!] Skrip ini wajib dijalankan sebagai root." >&2
    exit 1
fi

SERVICE_PATH="/etc/systemd/system/dns-scope-vmbr0.service"

echo "[*] Membuat berkas service systemd di $SERVICE_PATH..."
cat << 'EOF' > "$SERVICE_PATH"
[Unit]
Description=Assign 10.20.0.3 sebagai DNS untuk vmbr0 (.local routing domain)
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/resolvectl dns vmbr0 10.20.0.3
ExecStart=/usr/bin/resolvectl domain vmbr0 '~local'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

echo "[*] Memuat ulang daemon systemd..."
systemctl daemon-reload

echo "[*] Mengaktifkan dan menjalankan service (enable --now)..."
systemctl enable --now dns-scope-vmbr0.service

echo ""
echo "=== Verifikasi Konfigurasi Interface vmbr0 ==="
resolvectl status vmbr0