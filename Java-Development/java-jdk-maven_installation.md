# Installing Java SDK OpenJDK and Apache Maven.
## [**back to Linux-Engineer-Applied-Practice**](/README.md)
### [**back to Java-Development**](/Java-Development/index.md)

**Note:** If you have another OS besides Windows or Ubuntu Linux, search for an alternative that matches your system.

# On Windows

## Install OpenJDK

<left>
1. Open any search engine and put keyword "openjdk or java sdk". If you version has a newer version, then you can click on the red mark to proceed into download page. Or you can directly visit https://jdk.java.net
<center> 

![Download OpenJDK](/image-files/jdk-win-install-1.png)
</center><left>

<left>
2. Head over to the Windows download page and start downloading the file.
<center>

![Download Page JDK](/image-files/jdk-win-install-2.png)
</center></left>

<left>
3. After downloading the file, extract it into directory <b>C:\Program FIles</b>
<center>

![Extracting JDK](/image-files/jdk-win-install-3.png)
</center></left>

<left>
4. To able to operate, Java need to be placed inside <b>PATH</b> Starting from searching <b>environment variables> Click Environtment Variables> Select on PATH> Edit> New> C:\Program Files\jdk-22.0.2> OK> OK> OK</b>.
<center>

![Apply to Path](/image-files/jdk-win-install-4.png)
</center></left>

<left>
5. To verify the installation of Java, simply type <b>java --version</b> on your cmd. If it is show similar thing like this below it indicate that your installation was successful.
<center>

![Verify JDK](/image-files/jdk-win-install-5.png)
</center></left>

## Install Apache Maven

<left>
6. Open any search engine and put keyword "apache maven". Go to download package and select the file that has ".zip" extension.
<center>

![Download maven](/image-files/maven-install-1.png)
</center></left>

<left>
7. Same as Java, You need to put maven into <b>PATH</b> directory.
<center>

![Set-up env variable](/image-files/maven-install-2.png)
</center></left>

<left>
8. Also verify the installation of maven by typing <b>mvn --version</b> on cmd. If it is suceeded, then you can continue to the next step.
<center>

![maven verify](/image-files/maven-install-4.png)
</center></left>

# On Ubuntu Linux

1. Download the JDK with the same step as Windows does.

2. Download the tarball file for linux
<p align="center"><img src="/image-files/java-jdk-tarball.png"></p>

3. Place the ```openjdk-*_linux-x64_bin.tar.gz``` in the same directory as ```install_jdk_linux.sh```. And then give permission and execute this command below.
<p align="center"><img src="/image-files/java-jdk-ubuntulinux-install.png"></p>

```
sudo chmod +x install_jdk_linux.sh
./install_jdk_linux.sh
```