## JDK Installation
### [back to Installation of Apache Tomcat and Apace HTTP Service](./1/Installing-ApacheTomcat_and_ApacheHTTP.md)
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
### [back to Installation of Apache Tomcat and Apace HTTP Service](./1/Installing-ApacheTomcat_and_ApacheHTTP.md)
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
**6. Tomcat users are defined in /opt/tomcat/conf/tomcat-users.xml. Open the file for editing with the following command:**
~~~
sudo nano /opt/tomcat/conf/tomcat-users.xml
~~~
Add the following lines before the ending tag:
~~~xml
<role rolename="manager-gui" />
<user username="manager" password="manager_password" roles="manager-gui" />

<role rolename="admin-gui" />
<user username="admin" password="admin_password" roles="manager-gui,admin-gui" />
~~~
**6. Verify the newly installed java version to put inside tomcat.service**
~~~bash
sudo update-alternatives --config java
~~~
**7. Writing the configuration inside tomcat.service**
~~~bash
sudo nano /etc/systemd/system/tomcat.service
~~~

~~~nano
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking

Environment=JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_BASE=/opt/tomcat
Environment='CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC'
Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

User=tomcat
Group=tomcat
UMask=0007
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
~~~
**9. Gain root access to enable execute command in directory /opt/tomcat/bin/*.sh and turn on tomcat.service**
~~~bash
sudo su
sudo chmod +x /opt/tomcat/bin/*.sh
sudo systemctl daemon-reload
sudo systemctl start tomcat.service
sudo systemctl status tomcat.service
~~~

## Apache HTTP Installation
### [back to Installation of Apache Tomcat and Apace HTTP Service](./1/Installing-ApacheTomcat_and_ApacheHTTP.md)
<a id="03"></a>

**10. Installing Apache HTTP Server**
~~~bash
sudo apt install apache2 -y
sudo systemctl status apache2
~~~
**11. Check listening ports, firewall status and allow firewall**
~~~bash
netstat -tan
sudo ufw status
sudo ufw allow 'Apache Full'
~~~
**12. Make a directory for cert, preparing fqdn and generating cert**
~~~bash
sudo mkdir -p /etc/ssl/private
hostname --fqdn
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/apache-selfsigned.key -out /etc/ssl/certs/apache-selfsigned.crt
~~~

**14. Configure virtual host for port 443**
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
15. Apply configuration changes
~~~bash
sudo a2ensite website_ssl.conf
sudo a2enmod ssl
sudo systemctl restart apache2
openssl s_client -connect 192.168.129.129:443 -showcerts
~~~