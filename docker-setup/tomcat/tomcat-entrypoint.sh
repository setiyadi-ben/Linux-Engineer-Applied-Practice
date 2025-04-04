#!/bin/bash

# Generate keystore if missing
if [ ! -f /opt/tomcat/conf/localhost-rsa.jks ]; then
    keytool -genkeypair -alias tomcat -keyalg RSA \
        -keysize 2048 -keystore /opt/tomcat/conf/localhost-rsa.jks \
        -storepass tomcatpassword -validity 365 \
        -dname "CN=ubuntux64server-master, OU=TELECOM ISP, O=SECURE-NET SEMARANG, L=KOTA SEMARANG, ST=JAWA TENGAH, C=ID" \
        -ext "SAN=DNS:localhost,IP:127.0.0.1" -noprompt
fi

# Verify Tomcat configuration
/opt/tomcat/bin/configtest.sh || exit 1

exec "$@"