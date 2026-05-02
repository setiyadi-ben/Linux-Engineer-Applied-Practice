# FROM tomcat:9.0-jre25 | Base image Tomcat 9 (compability) dengan JRE 25
# FROM tomcat:jre25 | Base image Tomcat 11 Latest dengan JRE 25

FROM tomcat:9.0-jre25
WORKDIR /usr/local/tomcat

# Install openssl jika dibutuhkan; keytool sudah tersedia dari JRE
# RUN apt-get update && apt-get install -y openssl \
#     && rm -rf /var/lib/apt/lists/*

# Copy konfigurasi Tomcat
COPY tomcat-users.xml /usr/local/tomcat/conf/tomcat-users.xml
COPY server.xml       /usr/local/tomcat/conf/server.xml

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/local/tomcat/bin/catalina.sh", "run"]

