# Deployment of Apache Tomcat Webapps Reverse Proxied using mod_proxy to Apache HTTPD
## [**back to Linux-Engineer-Applied-Practice**](/README.md)
### [**back to Java Procedure**](/Java-Webapps-Simulation/Java-Procedure.md)

## Tools & materials
- Previous requirements that is used in [**Installing-ApacheTomcat_and_ApacheHTTP.**](/Java-Webapps-Simulation/1/Installing-ApacheTomcat_and_ApacheHTTP.md)
- Complete the tasks above, you can't jump here without finishing that.

## Source of theory
It is availabe in medium where someone shared the information about ```mod_proxy``` and any other, <a href="https://medium.com/swlh/apache-reverse-proxy-content-from-different-websites-3e82df87a34a"><b>here.</b></a>

<p align="center"><img src="/image-files/anotherSource/1_vPgcWpdshV6ut3Nz3izmzg.png"></p>
<p align="center">This is the implementation in general.</p>

**The mod_proxy** is the Apache module helps us to configure the Reverse Proxy to the different backend servers, mod_proxy is not an individual module but a collection of them (Summary)

## My own requirements:
Despite all of the explanation above, my requirements are focusing on the things that is shown below:

<p align="center"><img src="/image-files/mod_proxy-explanation.png"></p>
<p align="center">This is my implementation for this simulation in a form of simulation.</p>






<!-- <VirtualHost *:443>
    ServerAdmin support@secure-net.id
    ServerName 192.168.129.129
    DocumentRoot /var/www/

    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/apache-selfsigned.crt
    SSLCertificateKeyFile /etc/ssl/private/apache-selfsigned.key

    # Enable SSL Proxy
    SSLProxyEngine On
    SSLProxyVerify none
    SSLProxyCheckPeerCN off
    SSLProxyCheckPeerName off

    ProxyPreserveHost On

    ProxyPass "/probe" "https://192.168.129.129:8443/probe"
    ProxyPassReverse "/probe" "https://192.168.129.129:8443/probe"

    ProxyPass "/examples" "https://192.168.129.129:8443/examples"
    ProxyPassReverse "/examples" "https://192.168.129.129:8443/examples"

    ProxyPass "/sample" "https://192.168.129.129:8443/sample"
    ProxyPassReverse "/sample" "https://192.168.129.129:8443/sample"

    <Proxy *>
        Require all granted
    </Proxy>

    <Directory "/opt/tomcat/webapps/probe">
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
 -->