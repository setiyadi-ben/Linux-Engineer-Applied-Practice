#!/bin/bash
set -e
# Self-signed HANYA sebagai fallback/bootstrap - dipakai kalau belum ada cert
# sama sekali (first run / folder ./https/apache2-cert kosong). Begitu ssl-gen.sh
# berhasil, file ini otomatis ketimpa cert asli dari Let's Encrypt.
if [ ! -f /usr/local/apache2/ssl/server.crt ] || [ ! -f /usr/local/apache2/ssl/server.key ]; then
    mkdir -p /usr/local/apache2/ssl
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /usr/local/apache2/ssl/server.key \
        -out /usr/local/apache2/ssl/server.crt \
        -subj "/C=ID/ST=JAWA TENGAH/L=KOTA SEMARANG/O=SECURE-NET SEMARANG/OU=TELECOM ISP/CN=leap_apache2-httpd/emailAddress=support@secure-net.id"
fi
httpd -t
exec "$@"