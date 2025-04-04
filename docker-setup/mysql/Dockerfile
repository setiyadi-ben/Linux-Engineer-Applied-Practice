# 1. Select base image
FROM ubuntu/mysql:latest

# 2. NO NEED, USE PRECONF USER PWD AT NO. 3  |Set environment variables for the root user credentials
#ENV MYSQL_ROOT_USER=root
#- SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ENV "MYSQL_ROOT_PASSWORD") (line 7)
#ENV MYSQL_ROOT_PASSWORD=root

# 3. Copy the initialization SQL file into the container so that it runs during startup
COPY init.sql /docker-entrypoint-initdb.d/

# 4. Declare volumes to persist both the database data and the init.sql file
VOLUME [ "/var/lib/mysql", "/docker-entrypoint-initdb.d" ]

# 5. Expose MySQL port
EXPOSE 3306

# The official MySQL image already defines an entrypoint and CMD to run mysqld, so no need to add anything further.