#!/bin/sh
# =============================================================================
# L-E-A-P Local DNS Installer - Alpine LXC (10.20.0.3) - IDEMPOTENT
# Aman dijalankan berkali-kali: hanya melakukan perubahan jika memang perlu.
# =============================================================================
set -eu

DNSMASQ_CONF="/etc/dnsmasq.conf"
HOSTS_FILE="/etc/hosts"
BACKUP_DIR="/etc/dnsmasq.conf.bak"
LISTEN_IP="10.20.0.3"
UPSTREAM_SERVERS="1.1.1.1 1.0.0.1 8.8.8.8 8.8.4.4"
LOCAL_SUFFIX="local"

log()  { printf '[*] %s\n' "$1"; }
ok()   { printf '[+] %s\n' "$1"; }
warn() { printf '[!] %s\n' "$1" >&2; }

# ---- Step 0: harus root -----------------------------------------------
if [ "$(id -u)" -ne 0 ]; then
    warn "Skrip ini wajib dijalankan sebagai root di Alpine Linux."
    exit 1
fi

# ---- Step 1: install paket hanya jika belum ada ------------------------
if apk info -e dnsmasq >/dev/null 2>&1; then
    ok "Paket dnsmasq sudah terpasang, lewati instalasi."
else
    log "Menginstal dnsmasq via apk..."
    apk update
    apk add dnsmasq
fi

# ---- Step 2: susun konfigurasi baru ke file sementara -------------------
TMP_CONF="$(mktemp)"
trap 'rm -f "$TMP_CONF"' EXIT

{
    printf '# ============================================================\n'
    printf '# L-E-A-P Standalone Local DNS Server - Alpine LXC (%s)\n' "$LISTEN_IP"
    printf '# Digenerate otomatis oleh dnsmasq_install.sh - jangan edit manual\n'
    printf '# ============================================================\n\n'
    printf 'listen-address=%s,127.0.0.1\n' "$LISTEN_IP"
    printf 'bind-interfaces\n\n'
    printf '# Upstream didefinisikan manual, bukan dari resolv.conf container\n'
    printf 'no-resolv\n\n'
    for srv in $UPSTREAM_SERVERS; do
        printf 'server=%s\n' "$srv"
    done
    printf '\n# %s TIDAK PERNAH di-forward ke publik\n' ".$LOCAL_SUFFIX"
    printf 'local=/%s/\n\n' "$LOCAL_SUFFIX"
    printf 'domain-needed\n'
    printf 'bogus-priv\n\n'
    printf 'addn-hosts=%s\n' "$HOSTS_FILE"
    printf 'cache-size=1000\n'
} > "$TMP_CONF"

# ---- Step 3: validasi config BARU sebelum menyentuh yang live ----------
log "Memvalidasi konfigurasi baru (belum diterapkan)..."
dnsmasq --test --conf-file="$TMP_CONF"

# ---- Step 4: terapkan hanya jika benar-benar berbeda --------------------
CONF_CHANGED=0
if [ -f "$DNSMASQ_CONF" ] && cmp -s "$TMP_CONF" "$DNSMASQ_CONF"; then
    ok "Konfigurasi tidak berubah, tidak perlu menulis ulang."
else
    CONF_CHANGED=1
    if [ -f "$DNSMASQ_CONF" ]; then
        mkdir -p "$BACKUP_DIR"
        STAMP="$(date +%Y%m%d%H%M%S)"
        cp "$DNSMASQ_CONF" "$BACKUP_DIR/dnsmasq.conf.$STAMP"
        log "Backup konfigurasi lama -> $BACKUP_DIR/dnsmasq.conf.$STAMP"
    fi
    cp "$TMP_CONF" "$DNSMASQ_CONF"
    ok "Konfigurasi baru ditulis ke $DNSMASQ_CONF"
fi

# ---- Step 5: daftarkan ke OpenRC hanya jika belum terdaftar -------------
if rc-update show default 2>/dev/null | grep -qw dnsmasq; then
    ok "Service dnsmasq sudah terdaftar di runlevel default."
else
    log "Mendaftarkan dnsmasq ke OpenRC (runlevel default)..."
    rc-update add dnsmasq default
fi

# ---- Step 6: start/restart hanya jika perlu ------------------------------
if rc-service dnsmasq status >/dev/null 2>&1; then
    if [ "$CONF_CHANGED" -eq 1 ]; then
        log "Konfigurasi berubah, restart service dnsmasq..."
        rc-service dnsmasq restart
    else
        ok "Service sudah berjalan, konfigurasi sama -> tidak ada restart."
    fi
else
    log "Service belum berjalan, menjalankan dnsmasq..."
    rc-service dnsmasq start
fi

ok "Selesai. Jalankan ulang skrip ini kapan pun tanpa efek samping (idempotent)."