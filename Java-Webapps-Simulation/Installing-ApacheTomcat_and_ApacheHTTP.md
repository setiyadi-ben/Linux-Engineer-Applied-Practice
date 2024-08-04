# Installation of Apache Tomcat and Apace HTTP Service
### [**back to Table-of-Contents**](./Table-of-Contents.md)

## Tools & materials
- Previous requirements that is used in [**Database Replication Simulation.**](/Database-Replication-Simulation/readme.md)
- JDK or OpenJDK, I'm using version 21.
- Apache Tomcat
- Apache HTTP

## Simulation steps:
<b>A. Installation of JDK or OpenJDK (Java Development Kit) </b>

<a href="https://github.com/setiyadi-ben/Linux-Engineer-Applied-Practice/blob/main/Java-Webapps-Simulation/terminal-command.md#01"><b>Commands are putting up here. If not loaded please refresh the browser.</b></a>

<left>
1. If you using the same previous requirements, you can simply install the JDK by simply writing this command below.
<center>

![Install JDK](/image-files/jdk-install-1.png)
</center>
<left>

<left>
2. Check the version to verify the installation, is it successs or not.
<center>

![Very JDK](/image-files/jdk-install-2.png)
</center>
</left>

<b>B. Installation of Apache Tomcat Webserver </b>

<a href="https://github.com/setiyadi-ben/Linux-Engineer-Applied-Practice/blob/main/Java-Webapps-Simulation/terminal-command.md#02"><b>Commands are putting up here. If not loaded please refresh the browser.</b></a>

<left>
3. Let's begin to download the files from the official site by using wget and don't forget to place the downloaded tomcat in directory /opt.
<center>

![Download Tomcat](/image-files/apache-install-1.png)
</center>
</left>

<left>
4. Install the .tar.gz file with this following command.
<center>

![Install Tomcat](/image-files/apache-install-2.png)
</center>
</left>

<left>
5. Create the user "tomcat" and check which is created or not.
<center>

![Create Tomcat user](/image-files/apache-install-3.png)
</center>
</left>

<left>
6. Check the java version to write it in the next configuration.
<center>

![Create Tomcat user](/image-files/apache-install-4.png)
</center>
</left>

<left>
7. Check the java version to write it in the next configuration.
<center>

![Create Tomcat user](/image-files/apache-install-5.png)
![Create Tomcat user](/image-files/apache-install-6.png)
<br>Don't forget to type <b>ctrl + x then y and enter to save</b></br>
</center>
</left>

<left>
8. To be able to access /opt/tomcat/bin/*.sh I'm switching to root user then restarting the service like the image shown below.
<center>

![Create Tomcat user](/image-files/apache-install-7.png)
</center>
</left>

<left>
9. If find any warning or errors you can also check the logs by simply typing.
<center>

![Create Tomcat user](/image-files/apache-debug.png)
</center>
</left>

<b>C. Installation of Apache HTTP </b>

<left>
10. If you already practicing the Database Replication Simulation you should have installed that when installing phpmyadmin. If you just started from this simulation you can follow step by step below.
<center>

![apache2 http](/image-files/install-apache2-1.png)
</center></left>

<left>
11. Know that installing the apache httpd itself not always make the services running. You can see that port 443 for ssl are not listening yet. the term "ufw" are for firewall config, verify the status first. If it is says "inactive" then you do not need to allow the prompt after.
<center>

![apache http-2](/image-files/install-apache2-2.png)
</center></left>

<left>
12.
<center>

![]()
</center></left>

<left>
4.
<center>

![]()
</center></left>

<left>
5.
<center>

![]()
</center></left>

<left>
6.
<center>

![]()
</center></left>

<left>
7.
<center>

![]()
</center></left>

<left>
8.
<center>

![]()
</center></left>

<left>
9.
<center>

![]()
</center></left>

<left>
10.
<center>

![]()
</center></left>