#!/bin/bash
#before executing don't forget to type chmod +x entrypoint.sh

# Ensure MySQL service is running
service mysql start

# Wait for MySQL to be fully ready
until mysqladmin ping --silent; do
    echo "Waiting for MySQL to be available..."
    sleep 2
done

# Execute MySQL commands
mysql -u root <<EOF
-- Create the 'staff1-engineer' user if it doesn't exist
CREATE USER IF NOT EXISTS 'staff1-engineer'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON *.* TO 'staff1-engineer'@'%' WITH GRANT OPTION;

-- Create database and table
CREATE DATABASE IF NOT EXISTS \`id-lcm-prd1\`;
USE \`id-lcm-prd1\`;

CREATE TABLE IF NOT EXISTS \`penjualan_ikan\` (
  \`id\` INT NOT NULL AUTO_INCREMENT,
  \`name\` VARCHAR(45) NOT NULL,
  \`timestamp\` TIMESTAMP NOT NULL,
  \`price\` FLOAT NOT NULL,
  \`stock\` INT NOT NULL,
  PRIMARY KEY (\`id\`)
) ENGINE = InnoDB;

-- Create the 'replica-bot' user for replication
CREATE USER IF NOT EXISTS 'replica-bot'@'%' IDENTIFIED WITH mysql_native_password BY 'password';
GRANT REPLICATION SLAVE ON *.* TO 'replica-bot'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

echo "MySQL setup complete!"

# Start Apache and Tomcat
#!/bin/bash
service mysql start
service apache2 start
exec /opt/tomcat/bin/startup.sh run

# Keep the container running
tail -f /dev/null


# Keep the container running
exec "$@"
