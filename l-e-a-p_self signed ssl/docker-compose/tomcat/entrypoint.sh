#!/bin/bash
# file ini "entrypoint.sh" wajib menggunakan LF
# jika di windows masih error: docker compose down, delete image, docker compose up lagi

KEYSTORE_PATH="/usr/local/tomcat/conf/ssl/tomcat-selfsigned-rsa.jks"

# Buat direktori ssl jika belum ada
mkdir -p /usr/local/tomcat/conf/ssl

# Generate keystore hanya jika belum ada
if [ ! -f "$KEYSTORE_PATH" ]; then
    keytool -genkeypair -alias tomcat -keyalg RSA \
        -keysize 2048 \
        -keystore "$KEYSTORE_PATH" \
        -storepass tomcatpassword \
        -validity 365 \
        -dname "CN=tomcat-ubuntux64server-master, OU=TELECOM ISP, O=SECURE-NET SEMARANG, L=KOTA SEMARANG, ST=JAWA TENGAH, C=ID" \
        -ext "SAN=DNS:localhost,IP:127.0.0.1" \
        -noprompt
fi

# Verifikasi konfigurasi sebelum start
/usr/local/tomcat/bin/catalina.sh configtest || exit 1

exec "$@"