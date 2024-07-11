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

**Creating database table using MySQL Query**
~~~sql
CREATE TABLE `id-lcm-prd2`.`penjualan_ikan` (`id` INT NOT NULL AUTO_INCREMENT , `name` VARCHAR(45) NOT NULL , `timestamp` TIMESTAMP NOT NULL , `price` FLOAT NOT NULL , `stock` INT NOT NULL , PRIMARY KEY (`id`)) ENGINE = CSV;
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
  user="your.user",
  password="password",
)

print(mydb)
~~~

**Test database connections from remote address**

[**back to Database Replication - Tools and materials that need to be prepared**](/Database-Replication-Simulation/readme.md)
~~~python
python mysql-test-connections.py
~~~

**Send dummy data into MySQL Database using the modified python code to make it as if simulating the consecutive data flow through the database**

[**back to Database Replication - Tools and materials that need to be prepared**](/Database-Replication-Simulation/readme.md)
~~~python
import mysql.connector
import datetime
import random
import time

mydb = mysql.connector.connect(
  host="your.ip-address",
  port=3306,
  user="your.user",
  password="password",
  database="your.database"
)

# Define the lists of edible fish names
list_ikan = ["Ikan Gurame", "Ikan Lele", "Ikan Nila", "Ikan Patin", "Ikan Tuna"]
list_ikan.sort()

# Define price changes
list_price_changes_1 = [88550, 33000, 57200, 35200, 115610]
list_price_changes_2 = [88000, 32000, 58000, 33200, 110320]
list_price_changes_3 = [89250, 32500, 54000, 34450, 116000]
list_price_changes_4 = [87500, 33500, 56250, 35000, 114600]
list_price_changes_5 = [88500, 32300, 55700, 35800, 113500]
# Merge all price changes
all_price_changes = [list_price_changes_1, list_price_changes_2, list_price_changes_3, list_price_changes_4, list_price_changes_5]
# Function to simulate random pick selection
def random_pick_price_changes(lists):
    selected_price_list = random.choice(lists)  # Pick a random list
    return selected_price_list  # Return the selected list

# Simulate random pick selection
price_changes = random_pick_price_changes(all_price_changes)

#return select_list_ikan
stock_changes = [2099, 3548, 2545, 2200, 1800]

if __name__ == "__main__":
    mycursor = mydb.cursor()
    while True:
        # Define formatted_date as timestamp values
        now = datetime.datetime.now()
        formatted_date = now.strftime('%Y-%m-%d %H:%M:%S')

        for i in range(len(list_ikan)):
          sql = "INSERT INTO penjualan_ikan (name, timestamp, price, stock) VALUES (%s, %s, %s, %s)"
          val = ((list_ikan[i]), (formatted_date), (price_changes[i]), (stock_changes[i]))
          mycursor.execute(sql, val)
        
        mydb.commit()
        print(mycursor.rowcount, "was inserted.")
        # Looping
        time.sleep(60)
~~~

