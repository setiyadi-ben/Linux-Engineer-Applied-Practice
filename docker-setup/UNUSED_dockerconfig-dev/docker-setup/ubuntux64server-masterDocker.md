# 🚀 Ubuntu Docker Setup with Apache, MySQL, and Tomcat

## 📌 Overview
This project sets up a **Docker container** that includes:
- **Apache2 (SSL Enabled)**
- **MySQL Server with Pre-configured Database**
- **Tomcat 10.1.34 (Manual Install)**
- **phpMyAdmin**
- **Self-Signed SSL Certificates for Apache & Tomcat**

---

## 📂 Required Files
Your project should have the following files:

```
/my-docker-project
│── Dockerfile
│── docker-compose.yml
│── entrypoint.sh
│── server.xml
│── tomcat-users.xml
│── context.xml
│── mysqld.cnf
│── website_ssl.conf
│── index.html
│── deployedWebapps.html
│── README.md
```

---

## 🛠 1. Install Docker & Docker Compose

### 🔹 Install Docker (Ubuntu)
```sh
sudo apt update
sudo apt install -y docker.io
sudo systemctl enable --now docker
```

### 🔹 Install Docker Compose
```sh
sudo apt install -y docker-compose
```

---

## 📜 2. `Dockerfile`

```dockerfile
FROM ubuntu:latest
ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y \
    net-tools mysql-server default-jdk apache2 wget unzip openssl phpmyadmin \
    && rm -rf /var/lib/apt/lists/*

# Enable Apache2 SSL
RUN mkdir -p /etc/ssl/private \
    && openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/apache-selfsigned.key \
    -out /etc/ssl/certs/apache-selfsigned.crt \
    -subj "/C=ID/ST=JAWA TENGAH/L=KOTA SEMARANG/O=SECURE-NET SEMARANG/OU=TELECOM ISP/CN=ubuntux64server-master"

COPY website_ssl.conf /etc/apache2/sites-available/website_ssl.conf
RUN a2ensite website_ssl.conf && a2enmod ssl

# Copy custom startup script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# Install Tomcat
RUN wget https://raw.githubusercontent.com/setiyadi-ben/Linux-Engineer-Applied-Practice/main/installer/apache-tomcat-10.1.34.tar.gz -O /tmp/tomcat.tar.gz \
    && mkdir -p /opt/tomcat \
    && tar -xvzf /tmp/tomcat.tar.gz -C /opt/tomcat --strip-components=1 \
    && rm -rf /tmp/tomcat.tar.gz

# Generate SSL Certificate for Tomcat
RUN keytool -genkey -alias tomcat -keyalg RSA \
    -keystore /opt/tomcat/conf/localhost-rsa.jks \
    -storepass tomcatpassword -validity 365 \
    -dname "CN=ubuntux64server-master, OU=TELECOM ISP, O=SECURE-NET SEMARANG, L=KOTA SEMARANG, ST=JAWA TENGAH, C=ID"

# Expose necessary ports
EXPOSE 443 8443
CMD ["/bin/bash"]
```

---

## 📜 3. `docker-compose.yml`

```yaml
version: '3.8'

services:
  webserver:
    build: .
    container_name: my-container
    ports:
      - "443:443"
      - "8443:8443"
    restart: always
    volumes:
      - ./website_ssl.conf:/etc/apache2/sites-available/website_ssl.conf
      - ./index.html:/var/www/html/index.html
      - ./deployedWebapps.html:/var/www/html/deployedWebapps.html
    environment:
      - MYSQL_ROOT_PASSWORD=root
    command: ["/entrypoint.sh"]
```

---

## 📜 4. `entrypoint.sh`

```bash
#!/bin/bash

# Start MySQL
service mysql start
until mysqladmin ping --silent; do
    echo "Waiting for MySQL..."
    sleep 2
done

# Setup Database
mysql -u root <<EOF
CREATE USER 'staff1-engineer'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON *.* TO 'staff1-engineer'@'%' WITH GRANT OPTION;

CREATE DATABASE IF NOT EXISTS `id-lcm-prd1`;
USE `id-lcm-prd1`;
CREATE TABLE IF NOT EXISTS `penjualan_ikan` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(45) NOT NULL,
  `timestamp` TIMESTAMP NOT NULL,
  `price` FLOAT NOT NULL,
  `stock` INT NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE = InnoDB;

FLUSH PRIVILEGES;
EOF

# Start Apache & Tomcat
service apache2 start
/opt/tomcat/bin/startup.sh
exec "$@"
```

---

## 🚀 5. Build & Run the Container

### 🔹 Build the Image
```sh
docker-compose build
```

### 🔹 Run the Container
```sh
docker-compose up -d
```

### 🔹 Check Running Containers
```sh
docker ps
```

---

## 🛠 6. Debugging & Logs

### 🔹 View Logs
```sh
docker logs -f my-container
```

### 🔹 Enter the Container
```sh
docker exec -it my-container bash
```

### 🔹 Check if `entrypoint.sh` is Executable
```sh
ls -l /entrypoint.sh
chmod +x /entrypoint.sh
```

### 🔹 Fix Windows Line Endings (If Needed)
```sh
apt update && apt install -y dos2unix
dos2unix /entrypoint.sh
```

---

## 🧹 7. Stop & Remove Containers & Images

### 🔹 Stop & Remove the Container
```sh
docker-compose down
```

### 🔹 Remove Everything (Caution!)
```sh
docker system prune -a
```

---

## ✅ That's It!
This guide covers **installation, setup, building, running, and debugging** your containerized Apache-MySQL-Tomcat stack! 🚀🔥 Let me know if you need any refinements.

