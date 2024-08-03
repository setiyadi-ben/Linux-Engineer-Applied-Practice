**Installation of JDK or OpenJDK (Java Development Kit)**
~~~bash
sudo apt install default-jdk -y
~~~

~~~bash
java -version
~~~

~~~bash
cd /opt
sudo wget https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.26/bin/apache-tomcat-10.1.26.tar.gz
~~~

~~~bash
sudo tar xzvf apache-tomcat-10.1.26.tar.gz
~~~

~~~bash
sudo useradd -m -U -d /opt/tomcat -s /bin/false tomcat
~~~

~~~bash
grep '^tomcat:' /etc/passwd
~~~

~~~bash
sudo update-alternatives --config java
~~~

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

~~~bash
sudo su
sudo chmod +x /opt/tomcat/bin/*.sh
sudo systemctl daemon-reload
sudo systemctl start tomcat.service
sudo systemctl status tomcat.service
~~~

~~~bash

~~~