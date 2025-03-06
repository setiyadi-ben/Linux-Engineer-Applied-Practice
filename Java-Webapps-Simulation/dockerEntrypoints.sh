#!/bin/bash

# Customizing Apache2
echo "Configuring Apache2..."
a2enmod ssl
service apache2 restart

# Customizing Tomcat 10
echo "Configuring Tomcat..."
sed -i 's/8080/8443/g' /opt/tomcat/conf/server.xml

# Execute default command
exec "$@"