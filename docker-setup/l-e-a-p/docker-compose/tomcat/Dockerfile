# 1. Select base image
FROM ubuntu/apache2:latest
WORKDIR /opt/tomcat

# 2. Install nano to CRUD the necessary configs
RUN apt-get update && apt-get install -y nano
# 3. Install openssl to perform free unsecure HTTPS SSL certificate
RUN apt-get update && apt-get install -y openssl 

# 4. Install standard OpenJDK version 21
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    wget \
    openjdk-21-jre-headless \
    && rm -rf /var/lib/apt/lists/

# 5. Install tomcat via l-e-a-p repository
# https://github.com/setiyadi-ben/Linux-Engineer-Applied-Practice/tree/main/installer
RUN wget https://raw.githubusercontent.com/setiyadi-ben/Linux-Engineer-Applied-Practice/main/installer/apache-tomcat-9.0.102.tar.gz -O /tmp/tomcat.tar.gz \
    && mkdir -p /opt/tomcat \
    && tar -xvzf /tmp/tomcat.tar.gz -C /opt/tomcat --strip-components=1 \
    && rm -rf /tmp/tomcat.tar.gz

# 6. Replace Tomcat configuration files | To SSL PORT 8443 running
COPY tomcat.service /etc/systemd/system/tomcat.service
COPY tomcat-users.xml /opt/tomcat/conf/tomcat-users.xml
COPY server.xml /opt/tomcat/conf/server.xml
COPY context.xml /opt/tomcat/webapps/manager/META-INF/context.xml
COPY context.xml /opt/tomcat/webapps/host-manager/META-INF/context.xml
COPY context.xml /opt/tomcat/webapps/examples/META-INF/context.xml

# 7.Import, change ownership and run autogenerated unsecure HTTPS SSL certificate
COPY entrypoint.sh /entrypoint.sh
RUN chown -R root:root /opt/tomcat && \
    chmod +x /opt/tomcat/bin/*.sh && \
    chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/opt/tomcat/bin/catalina.sh", "run"]

