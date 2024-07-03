# Commands that used in simulation process

## Formatting

### What app --> What it is used --> Commands

## Bash

### Installing ifconfig

~~~
sudo apt-install net-tools
~~~

### Installing and configure and configuring MySQL Server

[**back to Database Replication - Tools and materials that need to be prepared**](/Database-Replication-Simulation/readme.md)

[**click here for details**](https://ubuntu.com/server/docs/install-and-configure-a-mysql-server)

**Install**

~~~
sudo apt install mysql-server
~~~

**Check status**

~~~
sudo service mysql status
~~~
### Create a New User and Grant Permissions in MySQL
[**back to Database Replication - Tools and materials that need to be prepared**](/Database-Replication-Simulation/readme.md)

[**click here for details**](https://www.digitalocean.com/community/tutorials/how-to-create-a-new-user-and-grant-permissions-in-mysql)

**Login using user root, password are the same with your linux login password**
~~~
sudo mysql -u root -p
~~~

**Create user with password also with enabling permissions**

For this configuration, I'm using user: staff1-engineer | pwd: password
~~~
CREATE USER 'staff1-engineer'@'localhost' IDENTIFIED BY 'password';
~~~
~~~
GRANT ALL PRIVILEGES ON*.*TO 'staff1-engineer'@'localhost' WITH GRANT OPTION;
~~~

**Installing phpMyAdmin**

[**back to Database Replication - Tools and materials that need to be prepared**](/Database-Replication-Simulation/readme.md)

[**click here for details**](https://www.hostinger.com/tutorials/how-to-install-and-setup-phpmyadmin-on-ubuntu)
~~~
sudo apt-get install phpmyadmin
~~~