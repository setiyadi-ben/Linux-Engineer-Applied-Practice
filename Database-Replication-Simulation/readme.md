# Database Replication - Tools and materials that need to be prepared

### Use cases knowledge

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

### Tools & materials

- VMware for virtualization or other software that matches your preferences.
- 2 or more Linux OS that have been installed database in it
- Any syntax/script or software to initialize HTTP POST requests for sending the dummy data
- Linux commands for configuring master slave simulations

### Simulation steps

[**Commands are putting up here**](../Database-Replication-Simulation/terminal-command)

<justify>
I have make freedom from selecting those tools and materials I have provided above. So, I'm will straight to the things that are important below and I'm assuming you have understand the basics setup like installation process.
</justify>

1. Make sure you have installed the Linux OS with database inside the virtualization software.

<center>

![Image when installation is successful](/image-files/installation-done.png)

![Image when mysql installation is successful](/image-files/installation-mysql-done.png)
</center>

2. Create new user and also grant the permissions ([**Commands are putting up here**](../Database-Replication-Simulation/terminal-command)).
<center>

![Image when mysql installation is successful](/image-files/creating-auth-user-pass.png)
</center>

3. Install phpMyAdmin to get easy access creating a database table for a use of master database that you can use phpmyadmin for GUI based or you just write syntax below ([**Commands are putting up here**](../Database-Replication-Simulation/terminal-command)) inside myql terminal.
![Image when phpMyAdmin installation is successful](/image-files/installation-phpmyadmin-done.png)

![image creating new mysqldb](/image-files/creating-mysqldb-phpmyadmin-1.png)

4. trytrytrtyryt
