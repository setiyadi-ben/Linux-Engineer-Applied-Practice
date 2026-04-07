## JDK Installation
### [back to Installation of Apache Tomcat and Apache HTTP Service](./1/Installing-ApacheTomcat_and_ApacheHTTP.md#01)
<a id="01"></a>

**1. Installation of JDK or OpenJDK (Java Development Kit)**
~~~bash
sudo apt install default-jdk -y
~~~
**2. Check version of Java**
~~~bash
java -version
~~~

## Apache Tomcat Installation
### [back to Installation of Apache Tomcat and Apache HTTP Service](./1/Installing-ApacheTomcat_and_ApacheHTTP.md#02)
<a id="02"></a>

**3. Downloading Tomcat from official website**
~~~bash
cd /opt
sudo wget https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.34/bin/apache-tomcat-10.1.34.tar.gz
~~~
**4. Install the tomcat package**
~~~bash
ls
sudo mkdir /opt/tomcat
sudo tar xzvf apache-tomcat-10.1.34.tar.gz -C /opt/tomcat --strip-components=1
~~~

**5. By supplying /bin/false as the user’s default shell, you ensure that it’s not possible to log in as tomcat.**
~~~bash
sudo useradd -m -d /opt/tomcat -U -s /bin/false tomcat
~~~

## Apache Tomcat Admin Configuration
### [back to Installation of Apache Tomcat and Apache HTTP Service](./1/Installing-ApacheTomcat_and_ApacheHTTP.md#03)
<a id="03"></a>

**6. Tomcat users are defined in /opt/tomcat/conf/tomcat-users.xml. Open the file for editing with the following command:**
~~~bash
sudo nano /opt/tomcat/conf/tomcat-users.xml
~~~
Add the following lines before the ending tag:
~~~xml
 <!-- Define roles | to be used later -->
<role rolename="manager-script"/>
<role rolename="manager-jmx"/>
<role rolename="manager-status"/>
<!-- Standard roles-->
<role rolename="manager-gui" />

<user username="manager" password="manager_password" roles="manager-gui" />
<user username="staff1-engineer" password="password" roles="manager-gui,admin-gui,manager-script,manager-jmx,manager-status" />

<role rolename="admin-gui" />
<user username="admin" password="admin_password" roles="manager-gui,admin-gui" />
<user username=""/>
~~~

**7. To remove the restriction for the Manager page, open its config file for editing:**
~~~xml
sudo nano /opt/tomcat/webapps/manager/META-INF/context.xml
~~~
Save and close the file, then repeat for Host Manager:
~~~bash
sudo nano /opt/tomcat/webapps/host-manager/META-INF/context.xml
~~~

## Apache Tomcat Systemd Configuration
### [back to Installation of Apache Tomcat and Apache HTTP Service](./1/Installing-ApacheTomcat_and_ApacheHTTP.md#04)
<a id="04"></a>

**6. Verify the newly installed java version to put inside tomcat.service**
~~~bash
sudo update-alternatives --config java
~~~
**7. Writing the configuration inside tomcat.service**
~~~bash
sudo nano /etc/systemd/system/tomcat.service
~~~

~~~
[Unit]
Description=Tomcat
After=network.target

[Service]
Type=forking

User=tomcat
Group=tomcat

Environment="JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64"
Environment="JAVA_OPTS=-Djava.security.egd=file:///dev/urandom"
Environment="CATALINA_BASE=/opt/tomcat"
Environment="CATALINA_HOME=/opt/tomcat"
Environment="CATALINA_PID=/opt/tomcat/temp/tomcat.pid"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"

ExecStart=/opt/tomcat/bin/catalina.sh start
ExecStop=/opt/tomcat/bin/catalina.sh stop

RestartSec=10
Restart=always

StandardOutput=journal
StandardError=inherit

[Install]
WantedBy=multi-user.target
~~~
**8. Using chown and chmod to make tomcat service are able to run**
~~~sh
sudo chown -R tomcat:tomcat /opt/tomcat
sudo chmod -R  u+x  /opt/tomcat/bin
~~~
**9. Enable Tomcat starting up with the system, run the following command**
~~~sh
sudo systemctl daemon-reload
sudo systemctl start tomcat
sudo systemctl enable tomcat
~~~
**10. Then, look at its status to confirm that it started successfully:**
~~~
sudo systemctl status tomcat
~~~

## Apache Tomcat HTTPS Certificate Installation
### [back to Installation of Apache Tomcat and Apace HTTP Service](./1/Installing-ApacheTomcat_and_ApacheHTTP.md#05)
<a id="05"></a>

**11. Navigate to this directory /opt/tomcat/conf to generate SSL certificate**

~~~sh
sudo su
~~~
~~~sh
cd /opt/tomcat/conf
ls
~~~
**12. Update server.xml file with linking the keystore file that have just generated**
~~~sh
keytool -genkey -alias tomcat -keyalg RSA -keystore localhost-rsa.jks -storepass tomcatpassword -validity 365
~~~

~~~
nano server.xml
~~~

~~~xml
<!-- Disable HTTP by commenting out the HTTP connector or redirecting it -->
<!--    <Connector port="8080" protocol="HTTP/1.1"
               connectionTimeout="20000"
               redirectPort="8443"
               maxParameterCount="1000"
               />
-->

<Connector port="8443" protocol="org.apache.coyote.http11.Http11NioProtocol"
            maxThreads="150" SSLEnabled="true"
            maxParameterCount="1000"
               >
    <UpgradeProtocol className="org.apache.coyote.http2.Http2Protocol" />
    <SSLHostConfig>
        <Certificate certificateKeystoreFile="conf/localhost-rsa.jks"
                         certificateKeystorePassword="tomcatpassword" type="RSA" />
    </SSLHostConfig>
</Connector>
~~~
<!-- **13. Update web.xml file to Redirect HTTP Traffic to HTTPS**

~~~
nano web.xml
~~~

Add the following configuration at the end of the file, just before the closing ```"</web-app>"``` tag:

~~~xml
<security-constraint>
    <web-resource-collection>
        <web-resource-name>Protected Context</web-resource-name>
        <url-pattern>/*</url-pattern>
    </web-resource-collection>
    <user-data-constraint>
        <transport-guarantee>CONFIDENTIAL</transport-guarantee>
    </user-data-constraint>
</security-constraint>
~~~ -->


## Apache HTTP HTTPS Certificate Installation
### [back to Installation of Apache Tomcat and Apace HTTP Service](./1/Installing-ApacheTomcat_and_ApacheHTTP.md#06)
<a id="06"></a>

**13. Installing Apache HTTP Server**
~~~bash
sudo apt install apache2 -y
sudo systemctl status apache2
~~~

**14. Make a directory for cert, preparing fqdn and generating cert**
~~~bash
sudo mkdir -p /etc/ssl/private
hostname --fqdn
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/apache-selfsigned.key -out /etc/ssl/certs/apache-selfsigned.crt
~~~

**15. Configure virtual host for port 443**
~~~bash
sudo nano /etc/apache2/sites-available/website_ssl.conf
~~~
~~~sh
<VirtualHost *:443>
    ServerAdmin support@secure-net.id
    ServerName 192.168.129.129
    DocumentRoot /var/www/

    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/apache-selfsigned.crt
    SSLCertificateKeyFile /etc/ssl/private/apache-selfsigned.key

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
~~~

**16.  Apply configuration changes**
~~~bash
sudo a2ensite website_ssl.conf
sudo a2enmod ssl
~~~

**17. Configure virtual host for port 80**
```sh
nano /etc/apache2/sites-available/000-default.conf
```

```xml
#ServerAdmin webmaster@localhost
#DocumentRoot /var/www/html
ServerAdmin support@secure-net.id
Redirect permanent / https://192.168.129.129/
```

```
sudo a2ensite 000-default.conf
```