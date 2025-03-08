# Commands that used in simulation process

## Formatting

### What it is used --> Commands

### Install net tools

~~~bash
sudo apt-get install net-tools
~~~
<a id="01"></a>
### (1.) Install and configure MySQL server

[**back to Database Replication Simulation**](/Database-Replication-Simulation/readme.md#1)

[**click here for details**](https://ubuntu.com/server/docs/install-and-configure-a-mysql-server)

**Install**

~~~bash
sudo apt install mysql-server
~~~

**Check status**

~~~bash
sudo service mysql status
~~~
### (2.) Create a new user and grant permissions in MySQL
<a id="02"></a>

[**back to Database Replication Simulation**](/Database-Replication-Simulation/readme.md#2)

[**click here for details**](https://www.digitalocean.com/community/tutorials/how-to-create-a-new-user-and-grant-permissions-in-mysql)

**Login using user root, password are the same with your linux login password**
~~~bash
sudo mysql -u root -p
~~~

**Create user with password also with enabling permissions**

For this configuration, I'm using user: staff1-engineer | pwd: password | % = can be accesesed on all network
~~~sql
CREATE USER 'staff1-engineer'@'%' IDENTIFIED BY 'password';
~~~
~~~sql
GRANT ALL PRIVILEGES ON*.*TO 'staff1-engineer'@'%' WITH GRANT OPTION;
~~~
### (3.) Installing phpMyAdmin
<a id="03"></a>

[**back to Database Replication Simulation**](/Database-Replication-Simulation/readme.md#3)

[**click here for details**](https://www.hostinger.com/tutorials/how-to-install-and-setup-phpmyadmin-on-ubuntu)
~~~
sudo apt-get install phpmyadmin
~~~

### (7.) Creating Database and Database Table using MySQL Query Syntax
<a id="07"></a>

[**back to Database Replication Simulation**](/Database-Replication-Simulation/readme.md#7)

**Creating database using MySQL Query**
~~~sql
CREATE DATABASE `id-lcm-prd1`;
~~~
**Creating database table using MySQL Query**
~~~sql
CREATE TABLE `id-lcm-prd1`.`penjualan_ikan`
 (`id` INT NOT NULL AUTO_INCREMENT ,
  `name` VARCHAR(45) NOT NULL ,
   `timestamp` TIMESTAMP NOT NULL ,
    `price` FLOAT NOT NULL ,
     `stock` INT NOT NULL ,
      PRIMARY KEY (`id`)) ENGINE = InnoDB;
~~~

### (9 to 10) Simulate sending MySQL query data using Python
<a id="09"></a>

**Installing MySQL Connector Driver for Python**
~~~python
pip install mysql-connector-python
~~~
**Configure MySQL to Listen on All Interfaces**

[**back to Database Replication Simulation**](/Database-Replication-Simulation/readme.md#9)
~~~bash
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
~~~
Locate the bind-address Directive: Find the line that starts with bind-address. By default, it's set to 127.0.0.1, limiting MySQL to localhost connections only
~~~
bind-address = 0.0.0.0
~~~

**Check hosts binding addresses**

~~~bash
netstat -tan
~~~

**Test database connections from remote address**


**mysql-test-connections.py** - [Click here to view code](/Database-Replication-Simulation/mysql-test-connections.py)

~~~python
python mysql-test-connections.py
~~~

**Send dummy data into MySQL Database using the modified python code to make it as if simulating the consecutive data flow through the database (mysql-insert_data.py)** - [Click here to view code](/Database-Replication-Simulation/mysql-insert_data.py)

~~~python
python mysql-insert_data.py
~~~

### (12.) Database dump using SQL query syntax
<a id="12"></a>

[**back to Database Replication Simulation**](/Database-Replication-Simulation/readme.md#12)

~~~bash
sudo mysqldump -u staff1-engineer -p id-lcm-prd1 > sql_dump-db_id-lcm-prd1.sql
~~~
~~~bash
ls
pwd
~~~

### (13.) DROP Database table using SQL query syntax
<a id="12"></a>

~~~bash
sudo mysql -u staff1-engineer -p
~~~
~~~sql
show databases;
use id-lcm-prd1;
drop table `penjualan_ikan`;
~~~

### (15 to 24.) Access mysqld.cnf to enable multiple parameters on master server
<a id="15"></a>

[**back to Database Replication Simulation**](/Database-Replication-Simulation/readme.md#15)
~~~
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
~~~

## - Master server configuration

**Scroll to the bottom and un-tick the following in Master Server:**
~~~nano
server-id   = 1
log-bin     = /var/log/mysql/mysql-bin.log
~~~
**Restart the MySQL service**
~~~
sudo systemctl restart mysql
~~~

**Create user and password for replica also with enabling permission**

~~~sql
CREATE USER 'replica-bot'@'%' IDENTIFIED WITH mysql_native_password BY 'password';
~~~
~~~sql
GRANT REPLICATION SLAVE ON *.* TO 'replica-bot'@'%' WITH GRANT OPTION;
~~~
**Check if the user was already created**
~~~
SELECT HOST, USER FROM mysql.user;
~~~

**Test login authentication using user replica-bot**
~~~
sudo mysql -h 192.168.129.129 -u replica-bot -p
~~~

**Pinpoint the value of MySQL master status**
~~~
SHOW MASTER STATUS \G
~~~

**Access mysqld.cnf to enable multiple parameters on slave server**
~~~
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
~~~

**Restart the MySQL service**
~~~
sudo systemctl restart mysql
~~~

## - Slave server configuration
<a id="18"></a>

[**back to Database Replication Simulation**](/Database-Replication-Simulation/readme.md#18)

**Scroll to the bottom and un-tick the following on Slave Server:**
~~~nano
server-id   = 2
log-bin     = /var/log/mysql/mysql-bin.log
~~~

**Restart the MySQL service**
~~~
sudo systemctl restart mysql
~~~

**Login with user root**
~~~
sudo mysql -u root -p
~~~

**Slave Server configuration in order to replicate data from master server**
~~~sql
STOP SLAVE;
~~~
~~~sql
CHANGE REPLICATION SOURCE TO
SOURCE_HOST='192.168.129.129',
SOURCE_USER='replica-bot',
SOURCE_PASSWORD='password',
SOURCE_LOG_FILE='mysql-bin.000002',
SOURCE_LOG_POS=5140;
~~~
~~~sql
START SLAVE;
SHOW SLAVE STATUS\G
~~~

## - Restoring data from master server
<a id="21"></a>

[**back to Database Replication Simulation**](/Database-Replication-Simulation/readme.md#21)

**Restore Master Server Database Data**
~~~bash
mysql -u staff1-engineer -p id-lcm-prd1 < sql_dump-db_id-lcm-prd1.sql
~~~

**Check the database table data in Master Server**
~~~sql
USE `id-lcm-prd1`;
~~~
~~~sql
SHOW TABLES;
~~~

## - Check the replication data delivery into the slave server
~~~sql
SHOW REPLICA STATUS \G
~~~
~~~sql
SHOW DATABASES;
~~~
~~~sql
USE `id-lcm-prd1`;
~~~
~~~sql
SHOW TABLES;
~~~