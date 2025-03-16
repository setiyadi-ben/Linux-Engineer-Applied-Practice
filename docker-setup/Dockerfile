# Use Ubuntu as base image
FROM ubuntu:latest

# Set non-interactive mode to bypass prompts
ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y \
    net-tools \
    mysql-server \
    default-jdk \
    apache2 \
    wget \
    unzip \
    openssl \
    phpmyadmin \
    && rm -rf /var/lib/apt/lists/*

# Enable Apache2 SSL | PORT 443
RUN mkdir -p /etc/ssl/private && \
    openssl req -x509 -newkey rsa:2048 -nodes -days 365 \
    -keyout /etc/ssl/private/apache-selfsigned.key \
    -out /etc/ssl/certs/apache-selfsigned.crt \
    -subj "/C=ID/ST=JAWA TENGAH/L=KOTA SEMARANG/O=SECURE-NET SEMARANG/OU=TELECOM ISP/CN=ubuntux64server-master/emailAddress=support@secure-net.id"
COPY website_ssl.conf /etc/apache2/sites-available/website_ssl.conf
RUN a2enmod proxy proxy_http ssl
RUN a2ensite website_ssl.conf && a2enmod ssl
RUN service apache2 restart

# Copy html shortcut to check the performance status of deployed services
COPY index.html /var/www/html/index.html
COPY deployedWebapps.html /var/www/html/deployedWebapps.html

# Copy and execute custom setup script (mysql database startup creattion)
RUN chown -R mysql:mysql /etc/mysql/ && chmod 644 /etc/mysql/
COPY mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# Preconfigure phpMyAdmin to avoid interactive prompts
RUN echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections && \
    echo "phpmyadmin phpmyadmin/app-password-confirm password root" | debconf-set-selections && \
    echo "phpmyadmin phpmyadmin/mysql/admin-pass password root" | debconf-set-selections && \
    echo "phpmyadmin phpmyadmin/mysql/app-pass password root" | debconf-set-selections && \
    echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections

# Install Apache Tomcat manually in /opt/tomcat
RUN wget https://raw.githubusercontent.com/setiyadi-ben/Linux-Engineer-Applied-Practice/main/installer/apache-tomcat-10.1.34.tar.gz -O /tmp/tomcat.tar.gz \
    && mkdir -p /opt/tomcat \
    && tar -xvzf /tmp/tomcat.tar.gz -C /opt/tomcat --strip-components=1 \
    && rm -rf /tmp/tomcat.tar.gz

# Disable login as Tomcat
RUN useradd -m -d /opt/tomcat -U -s /bin/false tomcat

# Set permissions for Tomcat
RUN chown -R root:root /opt/tomcat \
    && chmod +x /opt/tomcat/bin/*.sh

# Generate SSL Certificate for Tomcat
RUN keytool -genkey -alias tomcat -keyalg RSA \
    -keystore /opt/tomcat/conf/localhost-rsa.jks \
    -storepass tomcatpassword -validity 365 \
    -dname "CN=ubuntux64server-master, OU=TELECOM ISP, O=SECURE-NET SEMARANG, L=KOTA SEMARANG, ST=JAWA TENGAH, C=ID"

# Replace Tomcat configuration files | SSL PORT 8443
COPY tomcat-users.xml /opt/tomcat/conf/tomcat-users.xml
COPY context.xml /opt/tomcat/webapps/manager/META-INF/context.xml
COPY context.xml /opt/tomcat/webapps/host-manager/META-INF/context.xml
COPY server.xml /opt/tomcat/conf/server.xml

# Expose necessary ports (443 for Apache, 8443 for Tomcat SSL)
EXPOSE 443 8443

# Default command
CMD ["/bin/bash"]
