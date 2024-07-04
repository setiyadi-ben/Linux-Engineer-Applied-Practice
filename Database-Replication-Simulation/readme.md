# Database Replication - Tools and materials that need to be prepared

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
- Any syntax/script or software to initialize HTTP POST requests for sending the dummy data
- Linux commands for configuring master slave simulations

## Simulation steps

[**Commands are putting up here**](../Database-Replication-Simulation/terminal-command.md)

<br>
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