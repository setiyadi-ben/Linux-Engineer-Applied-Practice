#!/bin/bash

# Generate SSL certificate if missing
if [ ! -f /etc/ssl/certs/apache-selfsigned.crt ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/private/apache-selfsigned.key \
        -out /etc/ssl/certs/apache-selfsigned.crt \
        -subj "/C=ID/ST=JAWA TENGAH/L=KOTA SEMARANG/O=SECURE-NET SEMARANG/OU=TELECOM ISP/CN=ubuntux64server-master/emailAddress=support@secure-net.id"
fi

# Validate Apache config
apachectl configtest

exec "$@"