# Linux Engineer Applied Practice (L-E-A-P)

This project automates the setup of Ubuntu with pre-installed packages, including Apache HTTPD, Apache Tomcat 10, MySQL, and phpMyAdmin, using Docker. The container is assigned a fixed IP address (`192.168.129.129`) within a custom Docker network.

## 1. Build the Docker Image
Run the following command to build the Docker image:
```bash
docker build -t l-e-a-p_github_docker_image .
```
Verify that the image was built successfully:
```bash
docker images | grep l-e-a-p_github_docker_image
```
If the image is missing, rebuild it without cache:
```bash
docker build -t l-e-a-p_github_docker_image . --no-cache
```

## 2. Create the Docker Network
Ensure the custom network exists:
```bash
docker network ls | grep l-e-a-p_github_network
```
If not, create it manually:
```bash
docker network create --subnet=192.168.129.0/24 l-e-a-p_github_network
```

## 3. Run the Container
Execute the following script to run the container:
```bash
docker run -d \
  --name l-e-a-p_github_container \
  --net l-e-a-p_github_network \
  --ip 192.168.129.129 \
  l-e-a-p_github_docker_image
```
Verify the container is running:
```bash
docker ps | grep l-e-a-p_github_container
```
If the container is not running, check the logs:
```bash
docker logs l-e-a-p_github_container
```

## 4. Debugging Issues
### Check Logs
```bash
docker logs l-e-a-p_github_container
```

### Check Assigned IP Address
```bash
docker inspect l-e-a-p_github_container | grep "IPAddress"
```

### Enter the Container
```bash
docker exec -it l-e-a-p_github_container /bin/bash
```

### Verify Services Are Running
```bash
ip a | grep 192.168.129.129  # Ensure IP is assigned
netstat -tulnp               # Check listening ports
systemctl status apache2     # Check Apache
systemctl status tomcat      # Check Tomcat
systemctl status mysql       # Check MySQL
systemctl status phpmyadmin  # Check phpMyAdmin
```

## 5. Testing the Setup
### Apache HTTPD (Port 443)
```bash
curl -k https://192.168.129.129
```

### Apache Tomcat 10 (Port 8443)
```bash
curl -k https://192.168.129.129:8443
```

### MySQL Connection (Inside Container)
```bash
mysql -u root -p -e "SHOW DATABASES;"
```

### phpMyAdmin Web Interface
Open in a browser:
```
https://192.168.129.129/phpmyadmin
```

## 6. Stopping & Removing the Container (If Needed)
```bash
docker stop l-e-a-p_github_container
docker rm l-e-a-p_github_container
```
Then rerun the setup script if needed.

---
This setup ensures quick deployment of a complete Linux-based development environment for practical exercises. 🚀

