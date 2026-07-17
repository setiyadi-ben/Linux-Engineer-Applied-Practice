-- Create users
CREATE USER IF NOT EXISTS 'staff1-engineer'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON *.* TO 'staff1-engineer'@'%' WITH GRANT OPTION;

CREATE USER IF NOT EXISTS 'replica-bot'@'%' IDENTIFIED BY 'password';
GRANT REPLICATION SLAVE ON *.* TO 'replica-bot'@'%' WITH GRANT OPTION;

-- Create database and table
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