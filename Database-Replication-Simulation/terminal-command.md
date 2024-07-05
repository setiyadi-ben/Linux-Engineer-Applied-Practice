# Commands that used in simulation process

## Formatting

### What app --> What it is used --> Commands

## Bash

### Installing ifconfig

~~~bash
sudo apt-install net-tools
~~~

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

**mysql-test-connections.py**

[**back to Database Replication - Tools and materials that need to be prepared**](/Database-Replication-Simulation/readme.md)
~~~python
import mysql.connector

mydb = mysql.connector.connect(
  host="your.ip-address",
  port=3306,
  user="your.password",
  password="password",
)

print(mydb)
~~~

**Test database connections from remote address**

[**back to Database Replication - Tools and materials that need to be prepared**](/Database-Replication-Simulation/readme.md)
~~~python
python mysql-test-connections.py
~~~