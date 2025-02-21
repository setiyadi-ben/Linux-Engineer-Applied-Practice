# Installation of Apache Tomcat Server and Apace HTTP Server on Master Server
## [**back to Linux-Engineer-Applied-Practice**](/README.md)
### [**back to Java Procedure**](/Java-Webapps-Simulation/Java-Procedure.md)

## Tools & materials
- Previous requirements that is used in [**Database Replication Simulation.**](/Database-Replication-Simulation/readme.md)
- JDK or OpenJDK, I'm using version 21.
- Apache Tomcat
- Apache HTTP

## Simulation steps:

Adapted from [**Digital Ocean Community Tutorials**](https://www.digitalocean.com/community/tutorials/how-to-install-apache-tomcat-10-on-ubuntu-20-04)

<b>A. Installation of JDK or OpenJDK (Java Development Kit) </b>
<a id="01"></a>

<a href="https://github.com/setiyadi-ben/Linux-Engineer-Applied-Practice/blob/main/Java-Webapps-Simulation/terminal-commands.md#01"><b>Commands are putting up here. If not loaded please refresh the browser.</b></a>

<p align="justify">
1. If you using the same previous requirements, you can simply install the JDK by simply writing this command below.
<!-- ![Install JDK](/image-files/jdk-install-1.png) -->
<p align="center"><img src="/image-files/jdk-install-1.png"></p>
</p>

<p align="justify">
2. Check the version to verify the installation, is it successs or not.
<!-- ![Very JDK](/image-files/jdk-install-2.png) -->
<p align="center"><img src="/image-files/jdk-install-1.png"></p>
</p>

<b>B. Installation of Apache Tomcat Webserver </b>
<a id="02"></a>

<a href="https://github.com/setiyadi-ben/Linux-Engineer-Applied-Practice/blob/main/Java-Webapps-Simulation/terminal-commands.md#02"><b>Commands are putting up here. If not loaded please refresh the browser.</b></a>

<p align="justify">
3. Let's begin to download the files from the official site by using wget and don't forget to place the downloaded tomcat in directory /opt.
<!-- ![Download Tomcat](/image-files/apache-install-1.png) -->
<p align="center"><img src="/image-files/apache-install-1.png"></p>
If in the future the downloadable file error you, can visit this main website to get the official available apache tomcat on <b><a href="https://tomcat.apache.org/">https://tomcat.apache.org/</a> or <a href="https://dlcdn.apache.org/tomcat/">https://dlcdn.apache.org/tomcat/</a></b>
<!-- ![download apache from source](/image-files/apache-download-1.png) -->
<p align="center"><img src="/image-files/apache-download-1.png"></p>
<!-- ![download apache from source2](/image-files/apache-download-2.png) -->
<p align="center"><img src="/image-files/apache-download-2.png"></p>
</p>


<p align="justify">
4. Install the .tar.gz file with this following command.
<!-- ![Install Tomcat](/image-files/apache-install-2.png) -->
<p align="center"><img src="/image-files/apache-install-2.png"></p>
</p>

<p align="justify">
5. By supplying /bin/false as the user’s default shell, you ensure that it’s not possible to log in as tomcat
<!-- ![Create Tomcat user](/image-files/apache-install-3.png) -->
<p align="center"><img src="/image-files/apache-install-3.png"></p>
</p>

<p align="justify">
6. Since you have already created a user, you can now grant tomcat ownership over the extracted installation by running:
<p align="center"><img src="/image-files/apache-tomcat-ownership.png"></p>
</p>

<b>C. Configuring Admin Users</b>
<a id="03"></a>

<a href="https://github.com/setiyadi-ben/Linux-Engineer-Applied-Practice/blob/main/Java-Webapps-Simulation/terminal-commands.md#03"><b>Commands are putting up here. If not loaded please refresh the browser.</b></a>


<p align="justify">
7. Tomcat users are defined in /opt/tomcat/conf/tomcat-users.xml. Open the file for editing with the following command:

<p align="center"><img src="/image-files/apache-config-1.png"></p>

<p align="center"><img src="/image-files/apache-config-2.png"></p>
<p align="center">Don't forget to type <b>ctrl + x then y and enter to save</b></p>
</p>

<p align="justify">
By default, Tomcat is configured to restrict access to the admin pages, unless the connection comes from the server itself. To access those pages with the users you just defined, you will need to edit config files for those pages.

<p align="center"><img src="/image-files/tomcat-directory-locking.png"></p>
</p>

<p align="justify">
8. To remove the restriction for the Manager page, open its config file for editing:

<p align="center"><img src="/image-files/apache-config-3.png"></p>

Comment out the Valve definition, as shown:

<p align="center"><img src="/image-files/apache-config-4.png"></p>
<p align="center">Don't forget to type <b>ctrl + x then y and enter to save</b></p>

Save and close the file, then repeat for Host Manager:
<p align="center"><img src="/image-files/apache-config-5.png"></p>

<p align="center"><img src="/image-files/apache-config-6.png"></p>
<p align="center">Don't forget to type <b>ctrl + x then y and enter to save</b></p>
</p>

<b>D. Creating a systemd service </b>
<a id="04"></a>

<a href="https://github.com/setiyadi-ben/Linux-Engineer-Applied-Practice/blob/main/Java-Webapps-Simulation/terminal-commands.md#04"><b>Commands are putting up here. If not loaded please refresh the browser.</b></a>

<p align="justify">
9. Check the java version to write it in the next configuration.

<p align="center"><img src="/image-files/apache-install-4.png"></p>

You’ll store the tomcat service in a file named tomcat.service, under /etc/systemd/system. Create the file for editing by running:
<!-- ![Create Tomcat user](/image-files/apache-install-5.png) -->
<p align="center"><img src="/image-files/apache-install-5.png"></p>
<!-- ![Create Tomcat user](/image-files/apache-install-6.png) -->
<p align="center"><img src="/image-files/apache-install-6.png"></p>
Modify the highlighted value of JAVA_HOME if it differs from the one you noted previously. You also set a few environment variables to define its home directory (which is /opt/tomcat as before) and limit the amount of memory that the Java VM can allocate (in CATALINA_OPTS). Upon failure, the Tomcat service will restart automatically.
<p align="center">Don't forget to type <b>ctrl + x then y and enter to save</b></p>
</p>

<p align="justify">
10. Reload the systemd daemon so that it becomes aware of the new service:
</p>

~~~
sudo systemctl daemon-reload
~~~

<p align="justify">
11. Enable Tomcat starting up with the system, run the following command:
</p>

```
sudo systemctl start tomcat
```
```
sudo systemctl enable tomcat
```

<p align="justify">
12. Then, look at its status to confirm that it started successfully:
</p>

~~~
sudo systemctl status tomcat
~~~
<p align="center"><img src="/image-files/apache-install-7.png"></p>

<p align="center"><img src="/image-files/apache-tomcat-install-success.png"></p>


<p align="justify">
13. If find any warning or errors you can also check the logs by simply typing.
<!-- ![Create Tomcat user](/image-files/apache-debug.png) -->
<p align="center"><img src="/image-files/apache-debug.png"></p>
</p>

<b>E. Installing Apache Tomcat HTTPS Certificate and Disable port 8080</b>
<a id="05"></a>

<a href="https://github.com/setiyadi-ben/Linux-Engineer-Applied-Practice/blob/main/Java-Webapps-Simulation/terminal-commands.md#05"><b>Commands are putting up here. If not loaded please refresh the browser.</b></a>

<p align="justify">
In this step what I'm gonna doing is to generate  ssl certificate and then installing that certificate into apache tomcat since https protocol only works with that certificate. After that, I change the current http port 8080 to https port on 8443. With that, port 8080 is being disabled and being redirected to port 8443. Why you might ask? The aim is to follow the current security standards which is use an encryption between server and client. 
</p>

<p align="justify">
14. Start by generating certificate by put this following syntax below and don't forget to change the <b>"tomcatpassword"</b> or you can leave it.

<p align="center"><img src="/image-files/tomcat-cert-install-1.png"></p>
</p>

<p align="justify">
15. Update server.xml file with linking the new keystore file that have just generated. I'm also added the following settings to block access on port 8080 and make a reference to redirecting port 8080 to port 8443.

<p align="center"><img src="/image-files/tomcat-cert-install-2sh.png"></p>

<p align="center"><img src="/image-files/tomcat-cert-install-2.png"></p>
</p>
<p align="center">Don't forget to type <b>ctrl + x then y and enter to save</b></p>

<p align="justify">
16. Then force HTTPS Redirection via web.xml

<p align="center"><img src="/image-files/tomcat-cert-install-3sh.png"></p>

In nano, find the ```"</web-app>"```, to find that press <b>```ctrl+w```</b> and then type that ```"</web-app>"``` and paste the following config below at the end of the file, just before the closing ```</web-app>``` tag.

<p align="center"><img src="/image-files/tomcat-cert-install-3.png"></p>
</p>
<p align="center">Don't forget to type <b>ctrl + x then y and enter to save</b></p>

<p align="justify">
17. Let's try to accesss <a href="http://192.168.129.129:8080"><b>http://192.168.129.129:8080</b></a> through your browser it will be automatically redirected to port 8443 like the following figure below. If it is says not secure don't worry about it because I'm using self-signed certificate.
</p>

<p align="justify">
18. Restart the Tomcat service in order to make the changes applied.
</p>

```sh
systemctl restart tomcat
```

<p align="center"><img src="/image-files/tomcat-cert-install-succes.png"></p>
19. You can check the detailed certificate by typing <b>openssl s_client -connect 192.168.129.129:8443 -showcerts</b>
</p>

```
openssl s_client -connect 192.168.129.129:8443 -showcerts
```

<b>F. Installation of Apache HTTP HTTPS Certificate and Disable port 80 </b>
<a id="06"></a>

<a href="https://github.com/setiyadi-ben/Linux-Engineer-Applied-Practice/blob/main/Java-Webapps-Simulation/terminal-commands.md#06"><b>Commands are putting up here. If not loaded please refresh the browser.</b></a>

<p align="justify">
20. If you already practicing the <a href="/Database-Replication-Simulation/readme.md"><b>Database Replication Simulation</b></a> you should have installed that when installing phpmyadmin. If you just started from this simulation you can follow step by step below.
</p>
<!-- ![apache2 http](/image-files/install-apache2-1.png) -->
<p align="center"><img src="/image-files/install-apache2-1.png"></p>

<p align="justify">
21. To enable ssl/tls mode we need to generate certificate using openssl library. in this simulation I'm going to start by preparing the <a href="https://www.hostinger.com/tutorials/fqdn" >fqdn</a> and self-signed certificate generate command. Why using self signed? Because I don't have any domain ready to use.
</p>
<!-- ![apache http cert1](/image-files/install-apache2-cert-1.png) -->
<p align="center"><img src="/image-files/install-apache2-cert-1.png"></p>

<p align="justify">
22.  This is the example of how to fill the certificate value.
</p>
<!-- ![apache http cert2](/image-files/install-apache2-cert-2.png) -->
<p align="center"><img src="/image-files/install-apache2-cert-2.png"></p>

<p align="justify">
23.  After that navigate into <b>/etc/apache2/sites-available/website_ssl.conf</b> to configure virtual host for port 443.
</p>
<!-- ![apache http cert3](/image-files/install-apache2-cert-3.png) -->
<p align="center"><img src="/image-files/install-apache2-cert-3.png"></p>
<!-- ![apache http cert3.1](/image-files/install-apache2-cert-3.1.png) -->
<p align="center"><img src="/image-files/install-apache2-cert-3.1.png"></p>
<p align="center">Don't forget to type <b>ctrl + x then y and enter to save</b></p>

<p align="justify">
24. Restart the Apache HTTPD service in order to make the changes applied.
</p>

```sh
systemctl restart apache2
```

<p align="justify">
25. To make sure configuration changes are running, I'm typing several commands listed below. Then I check the certificate by typing <b>openssl s_client -connect 192.168.129.129:443 -showcerts</b>
</p>

```
openssl s_client -connect 192.168.129.129:443 -showcerts
```
<!-- ![](/image-files/install-apache2-cert-4.png) -->
<p align="center"><img src="/image-files/install-apache2-cert-4.png"></p>

<p align="justify">
25.  Another way to identify the certificate was installed successfully is to access it directly from the web. 
</p>
<!-- ![](/image-files/install-apache2-cert-5.png) -->
<p align="center"><img src="/image-files/install-apache2-cert-5.png"></p>

<p align="justify">
26. In the end, to redirect port 80 to 443 you can edit this configuration by accessing directory
<b>/etc/apache2/sites-available/000_default.conf</b> 
</p>

<p align="center"><img src="/image-files/install-apache2-cert-6.png"></p>

<p align="center"><img src="/image-files/install-apache2-cert-7.png"></p>

<p align="center">Don't forget to type <b>ctrl + x then y and enter to save</b></p>

<p align="justify">
27. Restart the Apache HTTPD service in order to make the changes applied.
</p>

```sh
systemctl restart apache2
```