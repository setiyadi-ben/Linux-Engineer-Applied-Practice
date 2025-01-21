## JDK Installation
### [back to Installation of Apache Tomcat and Apache HTTP Service](./1/Installing-ApacheTomcat_and_ApacheHTTP.md)
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
### [back to Installation of Apache Tomcat and Apache HTTP Service](./1/Installing-ApacheTomcat_and_ApacheHTTP.md)
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
### [back to Installation of Apache Tomcat and Apache HTTP Service](./1/Installing-ApacheTomcat_and_ApacheHTTP.md)
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
<user username="staff1-engineer" password="password" roles="manager-gui,manager-script,manager-jmx,manager-status" />

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
### [back to Installation of Apache Tomcat and Apache HTTP Service](./1/Installing-ApacheTomcat_and_ApacheHTTP.md)
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
**8. Reload the systemd daemon so that it becomes aware of the new service:**
~~~
sudo systemctl daemon-reload
~~~
**9. Enable Tomcat starting up with the system, run the following command:**
~~~
sudo systemctl start tomcat
sudo systemctl enable tomcat
~~~
**10. Then, look at its status to confirm that it started successfully:**
~~~
sudo systemctl status tomcat
~~~

## Apache HTTP HTTPS Certificate Installation
### [back to Installation of Apache Tomcat and Apace HTTP Service](./1/Installing-ApacheTomcat_and_ApacheHTTP.md)
<a id="05"></a>

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