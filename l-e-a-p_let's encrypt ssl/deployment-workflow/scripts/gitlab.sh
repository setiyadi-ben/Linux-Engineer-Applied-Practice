#!/usr/bin/env bash
# =============================================================================
#  gitlab.sh — GitLab CE + Runner on Debian 13 (Trixie)
#  Converted from Contabo cloud-init template.
#
#  Usage:
#    sudo bash gitlab.sh [--password <root_password>] [--email <admin_email>]
#
#  Defaults:
#    --password  Randomly generated (printed at end)
#    --email     admin@<FQDN>
# =============================================================================
set -euo pipefail

# ── Colour helpers ────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ── Root check ────────────────────────────────────────────────────────────────
[[ $EUID -eq 0 ]] || error "Script harus dijalankan sebagai root: sudo bash $0"

# ── Argument parsing ──────────────────────────────────────────────────────────
OWNER_PASSWORD=""
OWNER_EMAIL_ARG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --password) OWNER_PASSWORD="$2"; shift 2 ;;
    --email)    OWNER_EMAIL_ARG="$2"; shift 2 ;;
    *) warn "Argumen tidak dikenal: $1"; shift ;;
  esac
done

# ── FQDN detection ────────────────────────────────────────────────────────────
HOSTNAME_SHORT="$(hostname -s)"
# Coba deteksi FQDN dari hostname; fallback ke contaboserver.net seperti original
if hostname -f 2>/dev/null | grep -q '\.'; then
  FQDN="$(hostname -f)"
else
  FQDN="${HOSTNAME_SHORT}.contaboserver.net"
fi

info "FQDN terdeteksi: ${FQDN}"

# ── Defaults ──────────────────────────────────────────────────────────────────
OWNER_EMAIL="${OWNER_EMAIL_ARG:-admin@${FQDN}}"
if [[ -z "$OWNER_PASSWORD" ]]; then
  OWNER_PASSWORD="$(openssl rand -base64 18 | tr -dc 'A-Za-z0-9!@#$%' | head -c 20)"
  warn "Password tidak diberikan — password acak akan digunakan (lihat ringkasan di akhir)."
fi

GITLAB_DIR="/opt/gitlab"

# =============================================================================
# 1. System update & base dependencies
# =============================================================================
info "Update sistem dan install dependensi dasar..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y
apt-get install -y \
  ca-certificates curl gnupg openssl apache2-utils \
  lsb-release apt-transport-https software-properties-common \
  ufw postfix

# =============================================================================
# 2. Install Docker (official repo — Debian 13 / Trixie)
# =============================================================================
info "Menambahkan Docker apt repository untuk Debian 13..."

install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

ARCH="$(dpkg --print-architecture)"
# Debian 13 codename = trixie
CODENAME="$(lsb_release -cs 2>/dev/null || echo trixie)"
# Docker belum tentu punya repo trixie; fallback ke bookworm jika tidak ada
SUPPORTED_CODENAMES="bookworm bullseye buster trixie"
if ! echo "$SUPPORTED_CODENAMES" | grep -qw "$CODENAME"; then
  warn "Codename '${CODENAME}' mungkin belum ada di Docker repo, fallback ke 'bookworm'."
  CODENAME="bookworm"
fi

echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/debian ${CODENAME} stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y \
  docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

systemctl enable --now docker
info "Docker berhasil diinstall: $(docker --version)"

# =============================================================================
# 3. Buat direktori & file konfigurasi GitLab
# =============================================================================
info "Menyiapkan direktori GitLab di ${GITLAB_DIR}..."
mkdir -p "${GITLAB_DIR}"/{config,logs,data,runner-config}
cd "${GITLAB_DIR}"

# ── .env ──────────────────────────────────────────────────────────────────────
cat > "${GITLAB_DIR}/.env" <<EOF
DOMAIN=${FQDN}
OWNER_EMAIL=${OWNER_EMAIL}
OWNER_PASSWORD=${OWNER_PASSWORD}
EOF
chmod 0600 "${GITLAB_DIR}/.env"

# ── docker-compose.yml ────────────────────────────────────────────────────────
info "Menulis docker-compose.yml..."
cat > "${GITLAB_DIR}/docker-compose.yml" <<'COMPOSE'
services:
  gitlab:
    image: gitlab/gitlab-ce:latest
    container_name: gitlab
    restart: unless-stopped
    hostname: ${DOMAIN}
    env_file: [ .env ]
    extra_hosts:
      - "host.docker.internal:host-gateway"
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url "https://#{ENV['DOMAIN']}"
        gitlab_rails['time_zone'] = 'UTC'
        gitlab_rails['initial_root_password'] = "#{ENV['OWNER_PASSWORD']}"
        gitlab_rails['gitlab_email_from'] = "#{ENV['OWNER_EMAIL']}"
        gitlab_rails['gitlab_email_display_name'] = "GitLab"
        gitlab_rails['gitlab_shell_ssh_port'] = 2222

        # harden sign-ups
        gitlab_rails['gitlab_signup_enabled'] = false
        gitlab_rails['gitlab_default_can_create_group'] = false

        # built-in NGINX + Let's Encrypt
        nginx['listen_https'] = true
        nginx['redirect_http_to_https'] = true
        letsencrypt['enable'] = true
        letsencrypt['contact_emails'] = ["#{ENV['OWNER_EMAIL']}"]

        # SMTP: relay via host (Postfix null-client)
        gitlab_rails['smtp_enable'] = true
        gitlab_rails['smtp_address'] = "host.docker.internal"
        gitlab_rails['smtp_port'] = 25
        gitlab_rails['smtp_domain'] = "#{ENV['DOMAIN']}"
        gitlab_rails['smtp_tls'] = false
        gitlab_rails['smtp_enable_starttls_auto'] = false
        gitlab_rails['smtp_openssl_verify_mode'] = 'none'
        gitlab_rails['gitlab_email_reply_to'] = "noreply@#{ENV['DOMAIN']}"

        # UNIX sockets only
        gitlab_workhorse['listen_network'] = 'unix'
        gitlab_workhorse['listen_addr']    = '/var/opt/gitlab/gitlab-workhorse/sockets/socket'
        puma['listen'] = nil
        puma['port']   = nil
        puma['socket'] = '/var/opt/gitlab/gitlab-rails/sockets/gitlab.socket'
    ports:
      - "80:80"
      - "443:443"
      - "2222:22"
    volumes:
      - ./config:/etc/gitlab
      - ./logs:/var/log/gitlab
      - ./data:/var/opt/gitlab

  gitlab-runner:
    image: gitlab/gitlab-runner:alpine
    container_name: gitlab-runner
    restart: unless-stopped
    depends_on: [ gitlab ]
    env_file: [ .env ]
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./runner-config:/etc/gitlab-runner
COMPOSE

# =============================================================================
# 4. Konfigurasi Postfix sebagai null-client relay
# =============================================================================
info "Mengkonfigurasi Postfix null-client relay..."

# Set debconf selections dulu sebelum install (sudah install di step 1, reconfigure)
echo "postfix postfix/mailname string ${FQDN}" | debconf-set-selections
echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
dpkg-reconfigure -f noninteractive postfix 2>/dev/null || true

# Deteksi IP bridge Docker
BRIDGE_IPS="$(ip -4 addr show 2>/dev/null \
  | awk '/inet / && ($NF=="docker0" || $NF ~ /^br-/){print $2}' \
  | cut -d/ -f1 || true)"

INET_IFS="127.0.0.1"
for ip in ${BRIDGE_IPS}; do
  INET_IFS="${INET_IFS}, ${ip}"
done

postconf -e "myhostname = ${FQDN}"
postconf -e "myorigin = ${FQDN}"
postconf -e "inet_interfaces = ${INET_IFS}"
postconf -e "mydestination ="
postconf -e "local_transport = error: local delivery disabled"
postconf -e "smtpd_banner = ${FQDN} ESMTP"
postconf -e "smtp_tls_security_level = may"
postconf -e "inet_protocols = ipv4"
postconf -e "smtpd_relay_restrictions = permit_mynetworks,reject_unauth_destination"
postconf -e "mynetworks = 127.0.0.0/8, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16"

systemctl restart postfix
info "Postfix dikonfigurasi sebagai null-client relay."

# =============================================================================
# 5. Firewall (UFW)
# =============================================================================
info "Mengkonfigurasi UFW firewall..."
ufw allow 80/tcp   || true
ufw allow 443/tcp  || true
ufw allow 2222/tcp || true
ufw allow 22/tcp   || true   # SSH akses server sendiri
# Aktifkan UFW jika belum aktif (non-interactive)
echo "y" | ufw enable 2>/dev/null || true
ufw reload || true

# =============================================================================
# 6. Jalankan GitLab via Docker Compose
# =============================================================================
info "Menjalankan GitLab dengan Docker Compose..."
cd "${GITLAB_DIR}"
docker compose up -d

# =============================================================================
# 7. Buat UNIX socket directories di dalam volume GitLab
# =============================================================================
info "Mempersiapkan UNIX socket directories di dalam container..."

# Tunggu container healthy/running sebelum exec
WAIT_SECS=0
MAX_WAIT=120
until docker compose exec -T gitlab bash -c 'test -d /var/opt/gitlab' 2>/dev/null; do
  sleep 5
  WAIT_SECS=$((WAIT_SECS + 5))
  [[ $WAIT_SECS -ge $MAX_WAIT ]] && { warn "Container belum siap setelah ${MAX_WAIT}s, lanjutkan..."; break; }
  info "Menunggu container siap... (${WAIT_SECS}s)"
done

docker compose exec -T gitlab bash -lc '
  set -e
  install -d -m 2750 -o git -g gitlab-www /var/opt/gitlab/gitlab-workhorse/sockets
  install -d -m 2750 -o git -g gitlab-www /var/opt/gitlab/gitlab-rails/sockets
  update-permissions || true
  gitlab-ctl restart gitlab-workhorse puma nginx
' 2>/dev/null || warn "Socket setup gagal — GitLab mungkin masih dalam proses reconfigure, normal."

# =============================================================================
# 8. Tulis MOTD
# =============================================================================
info "Menulis MOTD..."
mkdir -p /etc/motd.d
cat > /etc/motd.d/90-gitlab <<MOTD
===============================================================================
 GitLab @ https://${FQDN}
 Password sudah di-seed (user: root). Harap ganti setelah login pertama.
 SSH Clone: port 2222 (User: git)
===============================================================================
MOTD

# =============================================================================
# 9. Tunggu GitLab reconfigure selesai
# =============================================================================
info "Menunggu GitLab reconfigure selesai (~5 menit)..."
info "Anda bisa pantau dengan: docker compose -f ${GITLAB_DIR}/docker-compose.yml logs -f gitlab"
sleep 300

# =============================================================================
# Ringkasan
# =============================================================================
echo ""
echo -e "${GREEN}=====================================================================${NC}"
echo -e "${GREEN}  INSTALASI GITLAB SELESAI${NC}"
echo -e "${GREEN}=====================================================================${NC}"
echo ""
echo "  URL        : https://${FQDN}"
echo "  Username   : root"
echo "  Password   : ${OWNER_PASSWORD}"
echo "  Email      : ${OWNER_EMAIL}"
echo "  SSH Clone  : git@${FQDN} -p 2222"
echo ""
echo "  Docker logs: docker compose -f ${GITLAB_DIR}/docker-compose.yml logs -f"
echo ""
echo -e "${YELLOW}  ⚠ Simpan password di atas! Ganti setelah login pertama.${NC}"
echo -e "${GREEN}=====================================================================${NC}"