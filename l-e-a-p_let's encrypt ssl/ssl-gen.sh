#!/usr/bin/env bash
# =============================================================================
# ssl-gen.sh
# =============================================================================
# Manual, one-shot script untuk request/renew SSL certificate dari Let's Encrypt
# via certbot webroot mode (cocok untuk Apache yang jalan terus di Docker,
# tidak perlu stop container seperti mode standalone).
#
# Semua config dibaca dari .env — tidak ada value hardcoded di script ini:
#   SSL_DOMAIN      wajib diisi
#   SSL_EMAIL       opsional (boleh kosong)
#   SSL_OUTPUT_DIR  wajib diisi
#
# Cara pakai:
#   ./ssl-gen.sh
#
# Prasyarat:
#   1. .env sudah diisi (lihat section "SSL - LET'S ENCRYPT" di .env)
#   2. docker-compose.yml sudah punya volume mount di service apache2:
#        ${SSL_OUTPUT_DIR}/.well-known/acme-challenge:/usr/local/apache2/htdocs/.well-known/acme-challenge
#      dan container apache2 sudah `up` dengan volume ini aktif.
#   3. 000-default.conf sudah punya exception rule untuk /.well-known/acme-challenge/
#      di VirtualHost port 80 (supaya tidak ke-redirect ke HTTPS).
#   4. SSL_DOMAIN sudah resolve ke IP publik VPS ini, port 80 reachable dari
#      internet (cek dulu: dig +short $SSL_DOMAIN)
#
# Validity cert 90 hari — jalankan ulang manual tiap mendekati expiry,
# tidak perlu automasi/cron.
# =============================================================================

set -euo pipefail

ENV_FILE=".env"

if [ ! -f "$ENV_FILE" ]; then
    echo "❌ File $ENV_FILE tidak ditemukan di direktori ini (jalankan script dari root project)."
    exit 1
fi

# Load semua variabel dari .env ke environment
set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

: "${SSL_DOMAIN:?❌ SSL_DOMAIN belum diisi di .env}"
: "${SSL_OUTPUT_DIR:?❌ SSL_OUTPUT_DIR belum diisi di .env}"

CERTBOT_DATA_DIR="./https/apache2-cert/certbot-data"   # simpan akun & state certbot antar run — JANGAN dihapus, biar tidak kena rate limit re-register

echo "==> Domain target : $SSL_DOMAIN"
echo "==> Output dir     : $SSL_OUTPUT_DIR"
echo ""

mkdir -p "$SSL_OUTPUT_DIR" "$CERTBOT_DATA_DIR"

EMAIL_ARG=(--register-unsafely-without-email)
if [ -n "${SSL_EMAIL:-}" ]; then
    EMAIL_ARG=(--email "$SSL_EMAIL")
    echo "==> Notifikasi expiry ke : $SSL_EMAIL"
else
    echo "⚠️  SSL_EMAIL kosong — lanjut tanpa email (tidak dapat notifikasi expiry dari Let's Encrypt)"
fi
echo ""

echo "==> Menjalankan certbot (webroot mode, one-off container)..."
docker run --rm \
    -v "$(pwd)/${SSL_OUTPUT_DIR}:/var/www/certbot" \
    -v "$(pwd)/${CERTBOT_DATA_DIR}:/etc/letsencrypt" \
    certbot/certbot certonly \
    --webroot -w /var/www/certbot \
    -d "$SSL_DOMAIN" \
    "${EMAIL_ARG[@]}" \
    --agree-tos \
    --non-interactive

CERT_SRC="${CERTBOT_DATA_DIR}/live/${SSL_DOMAIN}"

if [ ! -d "$CERT_SRC" ]; then
    echo "❌ Gagal: direktori cert tidak ditemukan di $CERT_SRC"
    echo "   Cek output certbot di atas untuk detail error (biasanya masalah DNS/port 80 tidak reachable)."
    exit 1
fi

echo ""
echo "==> Menyalin & rename cert ke $SSL_OUTPUT_DIR (cocok dengan SSLCertificateFile/SSLCertificateKeyFile di 000-default.conf)"
cp -L "$CERT_SRC/fullchain.pem" "$SSL_OUTPUT_DIR/server.crt"
cp -L "$CERT_SRC/privkey.pem"   "$SSL_OUTPUT_DIR/server.key"

echo ""
echo "✅ Selesai. Cert baru ada di: $SSL_OUTPUT_DIR/server.crt & server.key"
echo "   Restart Apache supaya cert baru ke-load:"
echo "     docker compose restart apache2"