FROM ubuntu:22.04

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    wget \
    default-jdk \
    && rm -rf /var/lib/apt/lists/*

RUN wget https://raw.githubusercontent.com/setiyadi-ben/Linux-Engineer-Applied-Practice/main/installer/apache-tomcat-10.1.34.tar.gz -O /tmp/tomcat.tar.gz \
    && mkdir -p /opt/tomcat \
    && tar -xvzf /tmp/tomcat.tar.gz -C /opt/tomcat --strip-components=1 \
    && rm -rf /tmp/tomcat.tar.gz

COPY tomcat-entrypoint.sh /entrypoint.sh

RUN chown -R root:root /opt/tomcat && \
    chmod +x /opt/tomcat/bin/*.sh && \
    chmod +x /entrypoint.sh

# Replace Tomcat configuration files | SSL PORT 8443
COPY tomcat.service /etc/systemd/system/tomcat.service
COPY tomcat-users.xml /opt/tomcat/conf/tomcat-users.xml
COPY server.xml /opt/tomcat/conf/server.xml
COPY context.xml /opt/tomcat/webapps/manager/META-INF/context.xml
COPY context.xml /opt/tomcat/webapps/host-manager/META-INF/context.xml
COPY context.xml /opt/tomcat/webapps/examples/META-INF/context.xml

VOLUME ["/opt/tomcat/conf"]
EXPOSE 8443

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/opt/tomcat/bin/catalina.sh", "run"]