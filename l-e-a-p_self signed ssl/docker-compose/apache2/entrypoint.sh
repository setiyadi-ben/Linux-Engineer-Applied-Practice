#!/bin/bash
set -e

# Generate cert di custom cert directory
if [ ! -f /usr/local/apache2/ssl/server.crt ]; then
    mkdir -p /usr/local/apache2/ssl
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /usr/local/apache2/certs/server.key \
        -out /usr/local/apache2/certs/server.crt \
        -subj "/C=ID/ST=JAWA TENGAH/L=KOTA SEMARANG/O=SECURE-NET SEMARANG/OU=TELECOM ISP/CN=leap_apache2-httpd/emailAddress=support@secure-net.id"
fi

httpd -t
exec "$@"