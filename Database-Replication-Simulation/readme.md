# Database Replication Simulation
## [**back to Linux-Engineer-Applied-Practice**](../README.md)

## Use cases knowledge
(Hover the mouse to read below)

<p><span style="display: inline-block; cursor: pointer;">
  <span style="visibility: hidden;" onmouseover="this.style.visibility='visible';" onmouseout="this.style.visibility='hidden'">
    Hover to reveal this text!
  </span>
</span></p>

<justify>
Database replication is a crucial technique in the IT world that enables data duplication from one database (master) to another (slave). This brings many benefits to various applications and businesses, especially in improving data performance and availability. Here are some common use cases for database replication:

**1. Scalability and High Performance:**

High-traffic e-commerce websites: Database replication can distribute product, price, and inventory data to multiple servers, allowing the website to serve many users simultaneously without experiencing bottlenecks on a single central server.
Mobile apps with a global user base: **Database replication allows data to be stored on servers in different regions, so users worldwide can access data with low latency.**

**2. Disaster Recovery and Data Availability:**

Financial and banking applications: Database replication ensures transaction data and customer balances remain available even if the central server fails. Replicated data on other servers can be used to continue operations without downtime. News websites or social media platforms: **Database replication ensures the website remains online and accessible to users even in the event of natural disasters or infrastructure disruptions in one location.**

**3. Disaster Recovery and Backup Solutions:**

Point-in-Time (PIT) Replication: Allows restoring the database to a specific point in time in the past, useful for recovering data after cyberattacks or human errors.
Disaster recovery solutions: **Database replication in different locations enables rapid system recovery after natural disasters or infrastructure failures in one location.**

**4. Data Analytics and Reporting:**

Distributed data warehouses: Database replication allows data from various sources to be centralized in one location for easier analysis and reporting.
Real-time analytics: **Database replication enables data to be transmitted and analyzed in real-time across multiple locations for faster decision-making.**
</justify>

## Tools & materials

- VMware for virtualization or other software that matches your preferences.
- 2 or more Linux OS that have been installed database in it.
- Any syntax/script or software to initialize **MySQL query** for sending the dummy data.
- Linux commands for configuring master slave simulations.
- SSH Client for simulating a remote connection from outside local network.

## Simulation steps:

<b>A. Installation and database setup </b>

<left>
I have make freedom from selecting those tools and materials I have provided above. So, I'm will straight to the things that are important below and I'm assuming you have understand the basics setup like installation process.
</left>

<left>
1. Make sure you have installed the Linux OS with database inside the virtualization software.

<a href="https://github.com/setiyadi-ben/Linux-Engineer-Applied-Practice/blob/main/Database-Replication-Simulation/terminal-command.md#01"><b>Commands are putting up here. If not loaded please refresh the browser.</b></a>
</left>
<center>

![Image when installation is successful](/image-files/installation-done.png)
![Image when mysql installation is successful](/image-files/installation-mysql-done.png)
</center>

<left>
2. Create new user and also grant the permissions.
</left>

<a href="https://github.com/setiyadi-ben/Linux-Engineer-Applied-Practice/blob/main/Database-Replication-Simulation/terminal-command.md#02"><b>Commands are putting up here. If not loaded please refresh the browser.</b></a>
<center>

![Image when mysql installation is successful](/image-files/creating-auth-user-pass.png)
</center>

<left>
3. Install phpMyAdmin <b>(Optional if you want to skip point B)</b> to get easy access creating a database table for a use of master database that you can use phpmyadmin for GUI based or you just write syntax below inside myql terminal.
</left>

<a href="https://github.com/setiyadi-ben/Linux-Engineer-Applied-Practice/blob/main/Database-Replication-Simulation/terminal-command.md#03"><b>Commands are putting up here. If not loaded please refresh the browser.</b></a>
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
</center><left>
In preview button on the bottom left, you can use that syntax output if you want to speed up your process creating a database table when using a terminal.

[**Also, here if you not understand about those column parameters.**](https://world.siteground.com/tutorials/phpmyadmin/create-populate-tables/)
</left>

<left>
6. If you manage to have into this steps. Congratulation! Your database was successfully created and would look like something like below.
</left>
<center>

![Image When Creating mysql table is done](/image-files/creating-mysqltable-phpmyadmin-3.png)

</center>

<left>
7. Some of you might be wanted to try creating database and database table using MySQL query language. So, here it is I'm also provided below the second database inside terminal commands.

<a href="https://github.com/setiyadi-ben/Linux-Engineer-Applied-Practice/blob/main/Database-Replication-Simulation/terminal-command.md#07"><b>Commands are putting up here. If not loaded please refresh the browser.</b></a>
<br><center>
![Image of creating database table using MySQL query](/image-files/creating-mysqldb-and_table-1.png)
</br></center>
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

<a href="https://github.com/setiyadi-ben/Linux-Engineer-Applied-Practice/blob/main/Database-Replication-Simulation/terminal-command.md#09"><b>Commands are putting up here. If not loaded please refresh the browser.</b></a>
<center>

![Image When installing Python](/image-files/installation-python.png)
![Image When MySQL Connector](/image-files/installation-python-2.png)
![Image When MySQL Connector](/image-files/mysql-setup-firewall-3.png)
![Image When Configure MySQL Firewall](/image-files/mysql-setup-firewall.png)
<br>Don't forget to type <b>ctrl + x then y and enter to save</b></br>

![Image When Configure MySQL Firewall](/image-files/mysql-setup-firewall-2.png)
![Image of MySQL Connection Test](/image-files/mysql-test-connections-py.png)
![Image of MySQL Connection Test](/image-files/mysql-test-connections-py-2.png)
</center>

<left>
10. Once you have passed the connection check by outputting similar to the image above. Now, I'm going to send the dummy data into MySQL Database using the modified python code to make it <b>as if simulating the consecutive data flow through the database id-lcm-prd1 from another network.</b>
</left>

<a href="https://github.com/setiyadi-ben/Linux-Engineer-Applied-Practice/blob/main/Database-Replication-Simulation/terminal-command.md#09"><b>Commands are putting up here. If not loaded please refresh the browser.</b></a>

<center>

![Image of Python Code for MySQL Inser Query](/image-files/mysql-insert-py-0.png)
![Image of Python compile prompt](/image-files/mysql-insert-py-1.png)
![Image of MySQL Insert Query success inserting data](/image-files/mysql-insert-py-2.png)
</center>

<br>

<b>C. Setup Database Replication (mysqldump) - For the use case of Scaling-up the current databases infrastructure </b></br>

<left>
11. Before get in into replication tasks, when the condition of the current databases has the data in it what you should do is to <b>dump the current data in your databases outside (export the data)</b> with supportable format such as: SQL, CSV, JSON, XML & etc.
</left><br></br>

<left>
12. To simulate SQL dump or you can say export database, I have provided 2 methods using phpMyAdmin via web GUI and using SQL query syntax using in bash shell.
</left>

<center>

<b>Using phpMyAdmin</b>
![Image of database dump using phpMyAdmin-1](/image-files/mysql-dump-data-1_phpmyadmin.png)
![Image of database dump using phpMyAdmin-1](/image-files/mysql-dump-data-2_phpmyadmin.png)
</center>

<center>

<b>Using Linux bash on Ubuntu Server</b>
<a href="https://github.com/setiyadi-ben/Linux-Engineer-Applied-Practice/blob/main/Database-Replication-Simulation/terminal-command.md#12"><b>(Commands are putting up here).</b></a>

![Image of database dump using SQL query syntax](/image-files/mysql-dump-data-3.png)
</center>

<left>
From 2 example methods that I have provided above, <b>method 1 the sql dump file is stored in your personal computer and method 2 the sql file is stored inside the linux server you have configured into.</b>
</left>

<br>
<left>
13. Next, perform database data cleansing by clearing the table inside the database using 2 methods phpMyAdmin via web GUI and using SQL query syntax in bash shell.
</left></br>

<center>

<b>Using phpMyAdmin</b>
![Image of Drop Database via phpmyadmin](/image-files/mysql-dump-data-4.png)
![Image of Drop Database via phpmyadminn Success](/image-files/mysql-dump-data-5.png)

<b>Using Linux bash on Ubuntu Server</b>
<a href="https://github.com/setiyadi-ben/Linux-Engineer-Applied-Practice/blob/main/Database-Replication-Simulation/terminal-command.md#13"><b>(Commands are putting up here).</b></a>

![Image of Drop Database Table via SQL query](/image-files/mysql-dump-data-6.png)
</center>
<left>
Avoid dropping the database because the mysql dump that just backed-up only work when the database are still availabe in the server. I'm also providing the error first in order to you understand the situation.
</left>

<center>

![Image of False Drop Database via phpmyadmin](/image-files/mysql-dump-data-8.png)
![Image of False Drop Database via SQL query](/image-files/mysql-dump-data-9.png)
</center>

<left>
14. From here I'm going to set-up the replicas first. After that, continue to push the database data back into the master server and then checking the slave server to verify the database data is already inside.
</left>

[**MySQL :How to Configure Mysql master slave replication in MYSQL database**](https://www.youtube.com/watch?v=6VfE3XKXpTs)

<b>D. Setup Database Replication for a Master Server </b>

<left>
15.  I'm going to start with typing ifconfig to print the master server host ip and changing some parameters in mysqld.cnf. In this step I'm keeping the bind-address to 0.0.0.0 because this is a simulation, when you are in real work you might be binding the address to a private ip in order to limit networks that has access into database.

<a href="https://github.com/setiyadi-ben/Linux-Engineer-Applied-Practice/blob/main/Database-Replication-Simulation/terminal-command.md#15"><b>Commands are putting up here. If not loaded please refresh the browser.</b></a>
<center>

![Image of ifconfig & mysqld.cnf](/image-files/mysql-replica_set-up-1.png)
![Image of mysqld.cnf config](/image-files/mysqld.cnf_master-1.png)
<br>Don't forget to type <b>ctrl + x then y and enter to save</b></br>
</center>
</left>

<left>
16. The next step is to create replica user for a way slave server gain access to the master server to able to perform the replica. You can also check if the user you have created is exist or not. Also check that users in slave server is it can be connected or not.
<center>

![image of creating user for slave server replica's](/image-files/mysql-replica_set-up-3.png)
![Image of granting access to slave server replica's](/image-files/mysql-replica_set-up-4.png)
![image of checking slave server connection](/image-files/mysql-replica_set-up-5.png)
</center>
</left>

<left>
17. After the replica user has been successfully created, the next step is pinpoint the value of mysql master status to be used later.
<center>

![Image of mysql master status](/image-files/mysql-replica_set-up-2.png)
</center>
</left>

<b>E. Setup Database Replication for a Slave Server </b>

<left>
18. This step is similar to number 15, only change the server-id from 1 to 2.
<center>

![Image of ifconfig & mysqld.cnf](/image-files/mysql-replica_set-up-6.png)
![Image of mysqld.cnf config](/image-files/mysqld.cnf_slave-2.png)
<br>Don't forget to type <b>ctrl + x then y and enter to save</b></br>
</center>
</left>

<left>
19. From step number 18, after succesfully login as root user I'm going to configure the slave server for listening to master server in order to replicate every database data from there. Those value below are from previous steps that I have done already.
<center>

![Image of ](/image-files/mysql-replica_set-up-7.png)
</center>
</left>

<left>
20. To check if your configuration is rightly applied, type this prompt below to verify your configuration by checking the mysql slave status.
<center>

![Image of check slave status](/image-files/mysql-replica_set-up-8.png)
</center>
</left>

<b>F. Restore Master Server Database Data to Test Replication on Slave Server</b>

<left>
21. In step 12, I have stored the database data inside /home/admintelecom. Now I'm gonna restore the database data back by importing this file using SQL syntax below.
<center>

![Image of restoring database data](/image-files/mysql-replica_restore-data-1.png)
</center>
</left>

<left>
22. To check if the data was inserted or not, simply login and navigate to check the database table data on master server.
<center>

![Image of Checking database table data](/image-files/mysql-replica_restore-data-2.png)
</center>
</left>

<left>
23. Technically, the database replication would sync the data asynchronously from the master source. To verify if the replication process is running correctly, you need to check the status on both master and slave server like this below. You can see that a match connection between master and slave server by just seeing Source_log_File and Read_Source_Log_Pos values.
<center>

![Image of replication check on master server](/image-files/mysql-replica_restore-data-3.png)
![Image of replication check on slave server](/image-files/mysql-replica_restore-data-4.png)
</center>
</left>

<left>
24. If those value are the same, now you are already know the implementation of the database replication. You can set it up on beginning, or whenever you need to scaling-up your current infrastructure you can do with similar method like this.
<center>

![Image of restoring data](/image-files/mysql-replica_restore-data-5.png)
</center>
</left>