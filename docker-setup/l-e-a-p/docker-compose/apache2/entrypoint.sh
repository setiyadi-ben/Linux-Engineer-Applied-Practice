#!/bin/bash
# file ini "entrypoint.sh" wajib menggunakan LF
# di vscode cek kanan bawah dan ganti atau menggunakan dos2unix entrypoint.sh
set -e

# Generate SSL certificate if missing
if [ ! -f /etc/ssl/certs/apache-selfsigned.crt ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/apache2/ssl/apache-selfsigned.key \
        -out /etc/apache2/ssl/apache-selfsigned.crt \
        -subj "/C=ID/ST=JAWA TENGAH/L=KOTA SEMARANG/O=SECURE-NET SEMARANG/OU=TELECOM ISP/CN=apache-ubuntux64server-master/emailAddress=support@secure-net.id"
fi

# Validate Apache config
apachectl configtest

# Start Apache in foreground properly
exec "$@"