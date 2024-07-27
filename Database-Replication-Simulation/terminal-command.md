# Commands that used in simulation process

## Formatting

### What it is used --> Commands

### Installing ifconfig

~~~bash
sudo apt-get install net-tools
~~~
<a id="drs-no-1"></a>
### Installing and configure and configuring MySQL Server

[**back to Database Replication - Tools and materials that need to be prepared**](/Database-Replication-Simulation/readme.md)

[**click here for details**](https://ubuntu.com/server/docs/install-and-configure-a-mysql-server)

**Install**

~~~bash
sudo apt install mysql-server
~~~

**Check status**

~~~bash
sudo service mysql status
~~~
### Create a New User and Grant Permissions in MySQL
[**back to Database Replication - Tools and materials that need to be prepared**](/Database-Replication-Simulation/readme.md)

[**click here for details**](https://www.digitalocean.com/community/tutorials/how-to-create-a-new-user-and-grant-permissions-in-mysql)
<a id="drs-no-2"></a>

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

**Installing phpMyAdmin**

[**back to Database Replication - Tools and materials that need to be prepared**](/Database-Replication-Simulation/readme.md)

[**click here for details**](https://www.hostinger.com/tutorials/how-to-install-and-setup-phpmyadmin-on-ubuntu)
~~~
sudo apt-get install phpmyadmin
~~~

**Installing MySQL Connector Driver for Python**
~~~python
pip install mysql-connector-python
~~~
**Configure MySQL to Listen on All Interfaces**

[**back to Database Replication - Tools and materials that need to be prepared**](/Database-Replication-Simulation/readme.md)
~~~bash
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
~~~
Locate the bind-address Directive: Find the line that starts with bind-address. By default, it's set to 127.0.0.1, limiting MySQL to localhost connections only
~~~
bind-address = 0.0.0.0
~~~

**Check hosts binding addresses**

[**back to Database Replication - Tools and materials that need to be prepared**](/Database-Replication-Simulation/readme.md)
~~~bash
netstat -tan
~~~

**Test database connections from remote address**

[**back to Database Replication - Tools and materials that need to be prepared**](/Database-Replication-Simulation/readme.md)

**mysql-test-connections.py** - [Click here to view code](/Database-Replication-Simulation/mysql-test-connections.py)

~~~python
python mysql-test-connections.py
~~~

**Send dummy data into MySQL Database using the modified python code to make it as if simulating the consecutive data flow through the database (mysql-insert_data.py)** - [Click here to view code](/Database-Replication-Simulation/mysql-insert_data.py)

~~~python
python mysql-insert_data.py
~~~

[**back to Database Replication - Tools and materials that need to be prepared**](/Database-Replication-Simulation/readme.md)

**Database dump using SQL query syntax**

~~~bash
sudo mysqldump -u staff1-engineer -p id-lcm-prd1 > sql_dump-db_id-lcm-prd1.sql
~~~
~~~bash
ls
pwd
~~~

**DROP Database table using SQL query syntax**

~~~bash
sudo mysql -u staff1-engineer -p
~~~
~~~sql
show databases;
use id-lcm-prd1;
drop table `penjualan_ikan`;
~~~

**Access mysqld.cnf to enable multiple parameters on master server**
~~~
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
~~~
Scroll to the bottom and un-tick the following:
~~~nano
server-id   = 1
log-bin     = /var/log/mysql/mysql-bin.log
~~~
Restart the MySQL service
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

**Try to connect replica-bot user from slave server**
~~~
sudo mysql -h 192.168.129.129 -u replica-bot -p
~~~

**Access mysqld.cnf to enable multiple parameters on slave server**
~~~
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
~~~
Scroll to the bottom and un-tick the following:
~~~nano
server-id   = 2
log-bin     = /var/log/mysql/mysql-bin.log
~~~
Restart the MySQL service
~~~
sudo systemctl restart mysql
~~~

<a="210"></a>
Slave Server configuration in order to connect to Master Server
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