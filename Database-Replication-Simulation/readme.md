# Database Replication Simulation
## [**back to Linux-Engineer-Applied-Practice**](../README.md)

## Everything starts with "duplication" which is called "replica"

<p align="justify">
Everything begins with duplication, a concept commonly known as replication. This reflects my personal perspective on the evolution of human efforts to ensure that a piece or collection of information can be duplicated while preserving the quality of the original.
</p>

<p align="center"><img src="/image-files/anotherSource/rabah-al-shammary-UBLQ_TLy82U-unsplash.jpg"></p>

<p align="justify">
In prehistoric times, when humans were unable to write, they expressed their memories, experiences, and imaginative insights through cave paintings. These early artistic endeavors captured observations of the natural world and served as a primitive means of recording information.
</p>

<p align="center"><img src="/image-files/anotherSource/javaneseWriting.png"></p>

<p align="justify">
With the advent of writing systems and the invention of paper, duplicating information became significantly easier, as it could simply be reproduced by rewriting.
</p>

<p align="center"><img src="/image-files/anotherSource/databaseReplication.png"></p>

<p align="justify">
Today, as nearly every form of information is transformed into digital data, the technique of duplication is employed in computer technology  commonly referred to as replication. This process ensures that the replicated data maintains the same quality and integrity as the original.
<a href="https://www.geeksforgeeks.org/strategies-of-database-replication-system-design/">Read more here</a> </p>

## In-Summary, what will we do?

<p align="justify">
This repository provides a detailed, step-by-step guide for simulating database replication on Linux, with a particular focus on MySQL database. The guide explains how to configure both master and slave servers <b>starting with preparing the environment, establish connections, exporting the current database data and synchronize data as "replica" to ensure redundancy.</b> The key steps are as follows:
</p>

<p align="center"><img src="/image-files/databaseReplicationIntro.png"></p>

<p align="justify">
This project represents my initial work on the Linux-Engineer-Applied-Practice repository and serves as an introductory gateway to access other simulations within the repository. You may skip this guide if you have already set up the server independently.
</p>

## Database replication use cases

<p align="justify">
<Database replication is a critical technique in the field of information technology, enabling the duplication of data from one database (the master) to another (the slave). This process offers numerous advantages for various applications and businesses, particularly in enhancing data performance and availability. The following are common use cases for database replication:>
</p>
<b>1. Scalability and High Performance:</b>
<p align="justify">
<li>E-commerce sites distribute data to multiple servers to handle high traffic.</li>
<li>Global mobile apps store data regionally to reduce latency.</li>

</p>
<b>2. Disaster Recovery and Data Availability:</b>
<p align="justify">
<li>Financial services use replication to ensure continuous access to critical data despite server failures.</li>
<li>News and social media platforms maintain online presence during localized disruptions.</li>
</p>
<b>3. Disaster Recovery and Backup Solutions:</b>
<p align="justify">
<li>Point-in-Time Replication allows restoration to a specific past state, aiding recovery from errors or attacks.</li>
<li>Distributed replication enables rapid recovery after disasters.</li>

</p>
<b>4. Data Analytics and Reporting:</b>
<p align="justify">
<li>Centralizing data via replication improves analytical efficiency and reporting.</li>
<li>Real-time replication supports faster decision-making.</li>
</p>

## Tools & materials

- VMware for virtualization or other software that matches your preferences.
- 2 or more Linux OS that have been installed database in it.
- Any syntax/script or software to initialize **MySQL query** for sending the dummy data.
- Linux commands for configuring master slave simulations.
- SSH Client for simulating a remote connection from outside local network.

## Simulation steps:

## <b>A. Installation </b>
<a id="01"></a>
<p align="justify">
</p>
<p align="justify">
1. Make sure you have installed the Linux OS with database inside the virtualization software.
</p>
<!-- USING HTML TAG TO CENTER IMAGE, BECAUSE IN MID 2024 GITHUB DISABLE ALIGNMENT FOR IMAGE -->
<p align="center"><img src="/image-files/installation-done.png"></p>
<!-- ![Image when installation is successful](/image-files/installation-done.png) -->

<p align="justify">
<a id="02"></a>
2. Create new user and also grant the permissions.
<a href="https://github.com/setiyadi-ben/Linux-Engineer-Applied-Practice/blob/main/Database-Replication-Simulation/terminal-command.md#02"><b>Commands are putting up here. If not loaded please refresh the browser.</b></a>
</p>

<p align="center"><img src="/image-files/installation-mysql-done.png"></p>
<!-- ![Image when mysql installation is successful](/image-files/installation-mysql-done.png) -->
<p align="center"><img src="/image-files/creating-auth-user-pass.png"></p>
<!-- ![Image when mysql installation is successful](/image-files/creating-auth-user-pass.png) -->

<p align="justify">
<a id="03"></a>
3. Install phpMyAdmin, it is used to manage the database with the common functionality for CREATE, SHOW and DROP via interactive GUI.
<a href="https://github.com/setiyadi-ben/Linux-Engineer-Applied-Practice/blob/main/Database-Replication-Simulation/terminal-command.md#03"><b>Commands are putting up here. If not loaded please refresh the browser.</b></a>
</p>
<p align="center"><img src="/image-files/installation-phpmyadmin-done.png"></p>
<!-- ![Image when phpMyAdmin installation is successful](/image-files/installation-phpmyadmin-done.png) -->
<p align="center"><img src="/image-files/creating-mysqldb-phpmyadmin-1.png"></p>
<!-- ![image creating new mysqldb](/image-files/creating-mysqldb-phpmyadmin-1.png) -->
<p align="center"><img src="/image-files/creating-mysqltable-phpmyadmin-1.png"></p>
<!-- ![Image creating mysqltable](/image-files/creating-mysqltable-phpmyadmin-1.png) -->

## <b>B. Creating a sample database </b>

<p align="justify">
4. For an example in step 3 I'm creating the database with a name <b>"id-lcm-prd1"</b> and also database table named <b>"penjualan_ikan"</b>. Why am I choosing that idea? I was thinking that it was the easiest example for anyone to understand. To give more context, you can see where is it comes from.
</p>
<p align="center"><img src="/image-files/table-references-spreadsheet.png"></p>
<!-- ![Image of reference table for mysql table](/image-files/table-references-spreadsheet.png) -->

<p align="justify">
5. When you have successfully creating database table, you will be able to fill those columns inside phpMyAdmin web. This is my configuration for my table below.
</p>

[**For more info, you can learn more about mysql data types.**](https://www.w3schools.com/mysql/mysql_datatypes.asp)
<p align="center"><img src="/image-files/creating-mysqltable-phpmyadmin-2.png"></p>
<!-- ![Image of filling the column parameters inside database table](/image-files/creating-mysqltable-phpmyadmin-2.png) -->
<p align="justify">
In preview button on the bottom left, you can use that syntax output if you want to speed up your process creating a database table when using a terminal.

[**Also, here if you not understand about those column parameters.**](https://world.siteground.com/tutorials/phpmyadmin/create-populate-tables/)
</p>

<p align="justify">
6. If you manage to have into this steps. Congratulation! Your database was successfully created and would look like something like below.
</p>
<p align="center"><img src="/image-files/creating-mysqltable-phpmyadmin-3.png"></p>
<!-- ![Image When Creating mysql table is done](/image-files/creating-mysqltable-phpmyadmin-3.png) -->

<p align="justify">
<a id="07"></a>
7. Some of you might be wanted to try creating database and the table using MySQL query language. So, here it is I'm also provided below the second database inside terminal commands.
<a href="https://github.com/setiyadi-ben/Linux-Engineer-Applied-Practice/blob/main/Database-Replication-Simulation/terminal-command.md#07"><b>Commands are putting up here. If not loaded please refresh the browser.</b></a>
</p>
<p align="center"><img src="/image-files/creating-mysqldb-and_table-1.png"></p>
<!-- ![Image of creating database table using MySQL query](/image-files/creating-mysqldb-and_table-1.png) -->

## <b>C. Simulate sending MySQL query data using Python </b>

<p align="justify">
8. In this particular simulation, I'm going to make scenario like this:
<br>- The database and the table we setup earlier is the server.
<br>- We will access the database from outside the server using the remote ip
that I have used already in ssh tunnel
<br>- Perform sending a random dummy data in every 5 minutes inside MySQL
database.
</p>


<p align="justify">
<a id="09"></a>
9. To be able to perform the simulation, you need to have python installed in PATH, install mysql-connector, allowing the firewall inside the database server and having the syntax to be able to perform MySQL query. Below here you can pay attention to make sure you will not mess up with a bunch of errors.
<a href="https://github.com/setiyadi-ben/Linux-Engineer-Applied-Practice/blob/main/Database-Replication-Simulation/terminal-command.md#09"><b>Commands are putting up here. If not loaded please refresh the browser.</b></a>
</p>

<p align="center"><img src="/image-files/installation-python.png"></p>
<!-- ![Image When installing Python](/image-files/installation-python.png) -->
<p align="center"><img src="/image-files/installation-python-2.png"></p>
<!-- ![Image When MySQL Connector](/image-files/installation-python-2.png) -->
<p align="center"><img src="/image-files/mysql-setup-firewall-3.png"></p>
<!-- ![Image When MySQL Connector](/image-files/mysql-setup-firewall-3.png) -->
<p align="center"><img src="/image-files/mysql-setup-firewall.png"></p>
<!-- ![Image When Configure MySQL Firewall](/image-files/mysql-setup-firewall.png) -->
<p align="center">Don't forget to type <b>ctrl + x then y and enter to save</b></p>
<p align="center"><img src="/image-files/mysql-setup-firewall-2.png"></p>
<!-- ![Image When Configure MySQL Firewall](/image-files/mysql-setup-firewall-2.png) -->
<p align="center"><img src="/image-files/mysql-test-connections-py.png"></p>
<!-- ![Image of MySQL Connection Test](/image-files/mysql-test-connections-py.png) -->
<p align="center"><img src="/image-files/mysql-test-connections-py-2.png"></p>
<!-- ![Image of MySQL Connection Test](/image-files/mysql-test-connections-py-2.png) -->

<p align="justify">
10.   Once you have passed the connection check by outputting similar to the image above. Now, I'm going to send the dummy data into MySQL Database using the modified python code to make it <b>as if simulating the consecutive data flow through the database id-lcm-prd1 from another network.</b>
<a href="https://github.com/setiyadi-ben/Linux-Engineer-Applied-Practice/blob/main/Database-Replication-Simulation/terminal-command.md#09"><b>Commands are putting up here. If not loaded please refresh the browser.</b></a>
</p>
<p align="center"><img src="/image-files/mysql-insert-py-0.png"></p>
<!-- ![Image of Python Code for MySQL Inser Query](/image-files/mysql-insert-py-0.png) -->
<p align="center"><img src="/image-files/mysql-insert-py-1.png"></p>
<!-- ![Image of Python compile prompt](/image-files/mysql-insert-py-1.png) -->
<p align="center"><img src="/image-files/mysql-insert-py-2.png"></p>
<!-- ![Image of MySQL Insert Query success inserting data](/image-files/mysql-insert-py-2.png) -->

## <b>C. Setup database export (mysqldump) - For the use case of scaling-up the current database infrastructure </b>

<p align="justify">
11.   Before get in into replication tasks, when the condition of the current databases has the data in it what you should do is to <b>dump the current data in your databases outside (export the data)</b> with supportable format such as: SQL, CSV, JSON, XML & etc.
</p>

<p align="justify">
12.   To simulate SQL dump or you can say export database, I have provided 2 methods using phpMyAdmin via web GUI and using SQL query syntax using in bash shell.
</p>
<p align="center"><b>Using phpMyAdmin</b></p>
<a id="12"></a>
<p align="center"><img src="/image-files/mysql-dump-data-1_phpmyadmin.png"></p>
<!-- ![Image of database dump using phpMyAdmin-1](/image-files/mysql-dump-data-1_phpmyadmin.png) -->
<p align="center"><img src="/image-files/mysql-dump-data-2_phpmyadmin.png"></p>
<!-- ![Image of database dump using phpMyAdmin-1](/image-files/mysql-dump-data-2_phpmyadmin.png) -->

<p align="center"><b>Using Linux bash on Ubuntu Server</b>
<a href="https://github.com/setiyadi-ben/Linux-Engineer-Applied-Practice/blob/main/Database-Replication-Simulation/terminal-command.md#12"><b>(Commands are putting up here).</b></a>
</p>
<p align="center"><img src="/image-files/mysql-dump-data-3.png"></p>
<!-- ![Image of database dump using SQL query syntax](/image-files/mysql-dump-data-3.png) -->
<p align="justify">
From 2 example methods that I have provided above, <b>method 1 the sql dump file is stored in your personal computer and method 2 the sql file is stored inside the linux server you have configured into.</b>
</p>

<p align="justify">
13.  Next, perform database data cleansing by clearing the table inside the database using 2 methods phpMyAdmin via web GUI and using SQL query syntax in bash shell.
</p>
<p align="center"><b>Using phpMyAdmin</b></p>
<p align="center"><img src="/image-files/mysql-dump-data-4.png"></p>
<!-- ![Image of Drop Database via phpmyadmin](/image-files/mysql-dump-data-4.png) -->
<p align="center"><img src="/image-files/mysql-dump-data-5.png"></p>
<!-- ![Image of Drop Database via phpmyadminn Success](/image-files/mysql-dump-data-5.png) -->

<p align="center"><b>Using Linux bash on Ubuntu Server</b>
<a href="https://github.com/setiyadi-ben/Linux-Engineer-Applied-Practice/blob/main/Database-Replication-Simulation/terminal-command.md#13"><b>(Commands are putting up here).</b></a>
</p>
<p align="center"><img src="/image-files/mysql-dump-data-6.png"></p>
<!-- ![Image of Drop Database Table via SQL query](/image-files/mysql-dump-data-6.png) -->
<p align="justify">
Avoid dropping the database, because the mysql dump that just backed-up only work when the database are still availabe in the server. I'm also providing the error first in order to you understand the situation.
</p>
<p align="center"><img src="/image-files/mysql-dump-data-8.png"></p>
<!-- ![Image of False Drop Database via phpmyadmin](/image-files/mysql-dump-data-8.png) -->
<p align="center"><img src="/image-files/mysql-dump-data-9.png"></p>
<!-- ![Image of False Drop Database via SQL query](/image-files/mysql-dump-data-9.png) -->

<p align="justify">
14.  From here I'm going to set-up the replicas first. After that, continue to push the database data back into the master server and then checking the slave server to verify the database data is already inside.
</p>

[**MySQL: How to Configure MySQL Master Slave Replication in MySQL Database**](https://www.youtube.com/watch?v=6VfE3XKXpTs)

## <b>D. Setup database replication for a master server </b>

<p align="justify">
<a id="15"></a>
15.  I'm going to start with typing ifconfig to print the master server host ip and changing some parameters in mysqld.cnf. In this step I'm keeping the bind-address to 0.0.0.0 because this is a simulation, when you are in real work you might be binding the address to a private ip in order to limit networks that has access into database.
<a href="https://github.com/setiyadi-ben/Linux-Engineer-Applied-Practice/blob/main/Database-Replication-Simulation/terminal-command.md#15"><b>Commands are putting up here. If not loaded please refresh the browser.</b></a>
</p>
<p align="center"><img src="/image-files/mysql-replica_set-up-1.png"></p>
<!-- ![Image of ifconfig & mysqld.cnf](/image-files/mysql-replica_set-up-1.png) -->
<p align="center"><img src="/image-files/mysqld.cnf_master-1.png"></p>
<!-- ![Image of mysqld.cnf config](/image-files/mysqld.cnf_master-1.png) -->
<p align="center">Don't forget to type <b>ctrl + x then y and enter to save</b></p>

<p align="justify">
16.  The next step is to create replica user for a way slave server gain access to the master server to able to perform the replica. You can also check if the user you have created is exist or not. Also check that users in slave server is it can be connected or not.
</p>
<p align="center"><img src="/image-files/mysql-replica_set-up-3.png"></p>
<!-- ![image of creating user for slave server replica's](/image-files/mysql-replica_set-up-3.png) -->
<p align="center"><img src="/image-files/mysql-replica_set-up-4.png"></p>
<!-- ![Image of granting access to slave server replica's](/image-files/mysql-replica_set-up-4.png) -->
<p align="center"><img src="/image-files/mysql-replica_set-up-5.png"></p>
<!-- ![image of checking slave server connection](/image-files/mysql-replica_set-up-5.png) -->

<p align="justify">
17.  After the replica user has been successfully created, the next step is pinpoint the value of mysql master status to be used later.
</p>
<p align="center"><img src="/image-files/mysql-replica_set-up-2.png"></p>
<!-- ![Image of mysql master status](/image-files/mysql-replica_set-up-2.png) -->

## <b>E. Setup database replication for a slave server </b>

<p align="justify">
<a id="18"></a>
18.  This step is similar to number 15, only change the server-id from 1 to 2.
</p>
<p align="center"><img src="/image-files/mysql-replica_set-up-6.png"></p>
<!-- ![Image of ifconfig & mysqld.cnf](/image-files/mysql-replica_set-up-6.png) -->
<p align="center"><img src="/image-files/mysqld.cnf_slave-2.png"></p>
<!-- ![Image of mysqld.cnf config](/image-files/mysqld.cnf_slave-2.png) -->
<p align="center">Don't forget to type <b>ctrl + x then y and enter to save</b></p>

<p align="justify">
19.  From step number 18, after succesfully login as root user I'm going to configure the slave server for listening to master server in order to replicate every database data from there. Those value below are from previous steps that I have done already.
</p>
<p align="center"><img src="/image-files/mysql-replica_set-up-7.png"></p>
<!-- ![Image of ](/image-files/mysql-replica_set-up-7.png) -->

<p align="justify">
20.  To check if your configuration is rightly applied, type this prompt below to verify your configuration by checking the mysql slave status.
</p>
<p align="center"><img src="/image-files/mysql-replica_set-up-8.png"></p>
<!-- ![Image of check slave status](/image-files/mysql-replica_set-up-8.png) -->

## <b>F. Restore master server database data to test replication on slave server</b>

<p align="justify">
<a id="21"></a>
21.  In step 12, I have stored the database data inside /home/admintelecom. Now I'm gonna restore the database data back by importing this file using SQL syntax below.
</p>
<p align="center"><img src="/image-files/mysql-replica_restore-data-1.png"></p>
<!-- ![Image of restoring database data](/image-files/mysql-replica_restore-data-1.png) -->

<p align="justify">
22.  To check if the data was inserted or not, simply login and navigate to check the database table data on master server.
</p>
<p align="center"><img src="/image-files/mysql-replica_restore-data-2.png"></p>
<!-- ![Image of Checking database table data](/image-files/mysql-replica_restore-data-2.png) -->
</p>

<p align="justify">
23.  Technically, the database replication would sync the data asynchronously from the master source. To verify if the replication process is running correctly, you need to check the status on both master and slave server like this below. You can see that a match connection between master and slave server by just seeing Source_log_File and Read_Source_Log_Pos values.
</p>
<p align="center"><img src="/image-files/mysql-replica_restore-data-3.png"></p>
<!-- ![Image of replication check on master server](/image-files/mysql-replica_restore-data-3.png) -->
<p align="center"><img src="/image-files/mysql-replica_restore-data-4.png"></p>
<!-- ![Image of replication check on slave server](/image-files/mysql-replica_restore-data-4.png) -->

<p align="justify">
24.  If those value are the same, now you are already know the implementation of the database replication. You can set it up on beginning, or whenever you need to scaling-up your current infrastructure you can do with similar method like this.
</p>
<p align="center"><img src="/image-files/mysql-replica_restore-data-5.png"></p>
<!-- ![Image of restoring data](/image-files/mysql-replica_restore-data-5.png) -->