# Database Replication - Tools and materials that need to be prepared

## [**back to Linux-Engineer-Applied-Practice**](../README.md)

## Use cases knowledge

<justify>
Database replication is a crucial technique in the IT world that enables data duplication from one database (master) to another (slave). This brings many benefits to various applications and businesses, especially in improving data performance and availability. Here are some common use cases for database replication:

1. Scalability and High Performance:

High-traffic e-commerce websites: Database replication can distribute product, price, and inventory data to multiple servers, allowing the website to serve many users simultaneously without experiencing bottlenecks on a single central server.
Mobile apps with a global user base: Database replication allows data to be stored on servers in different regions, so users worldwide can access data with low latency.

2. Disaster Recovery and Data Availability:

Financial and banking applications: Database replication ensures transaction data and customer balances remain available even if the central server fails. Replicated data on other servers can be used to continue operations without downtime.
News websites or social media platforms: Database replication ensures the website remains online and accessible to users even in the event of natural disasters or infrastructure disruptions in one location.

3. Disaster Recovery and Backup Solutions:

Point-in-Time (PIT) Replication: Allows restoring the database to a specific point in time in the past, useful for recovering data after cyberattacks or human errors.
Disaster recovery solutions: Database replication in different locations enables rapid system recovery after natural disasters or infrastructure failures in one location.

4. Data Analytics and Reporting:

Distributed data warehouses: Database replication allows data from various sources to be centralized in one location for easier analysis and reporting.
Real-time analytics: Database replication enables data to be transmitted and analyzed in real-time across multiple locations for faster decision-making.
</justify>

## Tools & materials

- VMware for virtualization or other software that matches your preferences.
- 2 or more Linux OS that have been installed database in it
- Any syntax/script or software to initialize **MySQL query** for sending the dummy data
- Linux commands for configuring master slave simulations

## Simulation steps

[**Commands are putting up here**](../Database-Replication-Simulation/terminal-command.md)


<b>A. Installation and database setup </b>

<justify>
I have make freedom from selecting those tools and materials I have provided above. So, I'm will straight to the things that are important below and I'm assuming you have understand the basics setup like installation process.
</justify>
</br>

<left>
1. Make sure you have installed the Linux OS with database inside the virtualization software.
</left>
<center>

![Image when installation is successful](/image-files/installation-done.png)

![Image when mysql installation is successful](/image-files/installation-mysql-done.png)
</center>

<left>
2. Create new user and also grant the permissions.
</left>

([**Commands are putting up here**](../Database-Replication-Simulation/terminal-command.md))
<center>

![Image when mysql installation is successful](/image-files/creating-auth-user-pass.png)
</center>

<left>
3. Install phpMyAdmin to get easy access creating a database table for a use of master database that you can use phpmyadmin for GUI based or you just write syntax below inside myql terminal.
</left>

([**Commands are putting up here**](../Database-Replication-Simulation/terminal-command.md))
<center>

![Image when phpMyAdmin installation is successful](/image-files/installation-phpmyadmin-done.png)

![image creating new mysqldb](/image-files/creating-mysqldb-phpmyadmin-1.png)

![Image creating mysqltable](/image-files/creating-mysqltable-phpmyadmin-1.png)

</center>

<left>
4. For an example in step 3 I'm creating the database with a name <b>"id-lcm-prd1"</b> and also database table named <b>"penjualan_ikan"</b>. Why am I choosing that idea? I was thinking that it was the easiest example for anyone to understand. To give more context, you can see where is it comes from.
</left>
<center>

![Image of reference table for mysql table](/image-files/table-references-spreadsheet.png)
</center>

<left>
5. When you have successfully creating database table, you will be able to fill those columns inside phpMyAdmin web. This is my configuration for my table below.
</left>

[**For more info, you can learn more about mysql data types.**](https://www.w3schools.com/mysql/mysql_datatypes.asp)

<center>

![Image of filling the column parameters inside database table](/image-files/creating-mysqltable-phpmyadmin-2.png)
</center>
In preview button on the bottom left, you can use that syntax output if you want to speed up your process creating a database table when using a terminal.

[**Also, here if you not understand about those column parameters.**](https://world.siteground.com/tutorials/phpmyadmin/create-populate-tables/)

<left>
6. If you manage to have into this steps. Congratulation! Your database was successfully created and would look like something like below.
</left>
<center>

![Image When Creating mysql table is done](/image-files/creating-mysqltable-phpmyadmin-3.png)

</center>

<left>
7. Some of you might be wanted to try creating database using MySQL query language. So, here it is I'm also provided below the second database inside terminal commands.

<b>(TO BE WORKING ON SOON)</b>

</left>

<b>B. Simulate sending MySQL query data using Python </b>

<left>
8. In this particular simulation, I'm going to make scenario like this:
<br>- The database and the table we setup earlier is the server.
<br>- We will access the database from outside the server using the remote ip
that I have used already in ssh tunnel
<br>- Perform sending a random dummy data in every 5 minutes inside MySQL
database.</br>

</left>
<br>
<left>
9. To be able to perform the simulation, you need to have python installed in PATH, install mysql-connector, allowing the firewall inside the database server and having the syntax to be able to perform MySQL query. Below here you can pay attention to make sure you will not mess up with a bunch of errors.
</br></left>

([**Commands are putting up here**](../Database-Replication-Simulation/terminal-command.md))
<center>

![Image When installing Python](/image-files/installation-python.png)

![Image When MySQL Connector](/image-files/installation-python-2.png)

![Image When MySQL Connector](/image-files/mysql-setup-firewall-3.png)

![Image When Configure MySQL Firewall](/image-files/mysql-setup-firewall.png)

![Image When Configure MySQL Firewall](/image-files/mysql-setup-firewall-2.png)

![Image of MySQL Connection Test](/image-files/mysql-test-connections-py.png)

![Image of MySQL Connection Test](/image-files/mysql-test-connections-py-2.png)

</center>

<left>
10. Once you have passed the connection check by outputting similar to the image above. Now, I'm going to send the dummy data into MySQL Database using the modified python code to make it <b>as if simulating the consecutive data flow through the database id-lcm-prd1 from another network.</b>
</left>

([**Commands are putting up here**](../Database-Replication-Simulation/terminal-command.md))

<center>

![Image of Python Code for MySQL Inser Query](/image-files/mysql-insert-py-0.png)

![Image of Python compile prompt](/image-files/mysql-insert-py-1.png)

![Image of MySQL Insert Query success inserting data](/image-files/mysql-insert-py-2.png)
</center>

<br>

<b>C. Setup Database Replication - For the use case of Scaling-up the current databases infrastructure </b></br>

<left>
11. Before get in into replication tasks, when the condition of the current databases has the data in it what you should do is to <b>dump the current data in your databases outside (export the data)</b> with supportable format such as: SQL, CSV, JSON, XML & etc.
</left><br></br>

<left>
12. To simulate SQL dump or you can say export database, I have provided 2 methods using phpMyAdmin via web GUI and using SQL query syntax using bash.
</left>

<center>

<b>Using phpMyAdmin</b>
![Image of database dump using phpMyAdmin-1](/image-files/mysql-dump-data-1.png)

![Image of database dump using phpMyAdmin-1](/image-files/mysql-dump-data-2.png)
</center>

mysql -u [username] -p -e "SELECT * FROM penjualan_ikan" id-lcm-prd1 --json > sql_dump-penjualan_ikan.json

mysql -u staff1-engineer -p password -e "SELECT * FROM penjualan_ikan" id-lcm-prd1 --json > sql_dump-penjualan_ikan.json

mysql -u staff1-engineer -p password -e "SELECT JSON_ARRAYAGG(JSON_OBJECT(
    'id', id,
    'name', list_ikan,
    'timestamp', formatted_date,
    'price', price_changes,
    'stock', stock_changes
)) AS json_output FROM penjualan_ikan;" id-lcm-prd1 > sql_dump-penjualan_ikan.json

mysql -u staff1-engineer -p password -e "SELECT JSON_ARRAYAGG(JSON_OBJECT(
    'id', id,
    'list_ikan', name,
    'timestamp', timestamp,
    'formatted_date', price_changes,
    'stock_changes', stock_changes
)) AS json_output FROM penjualan_ikan;" id-lcm-prd1 > sql_dump-penjualan_ikan.json