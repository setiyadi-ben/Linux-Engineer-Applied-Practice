# Java Web Application Deployment with Apache HTTP and Apache Tomcat
### [**back to Table-of-Contents**](./Table-of-Contents.md)
## Overview

This guide explains the setup for deploying Java web applications using Apache Tomcat and Apache HTTP server. The architecture ensures efficient handling of customer requests, security, and scalability.

## Architecture

### Customer Access

- **Ports:** Customers access the web application via HTTP (port 80) or HTTPS (port 443).

### Apache HTTP Server

- **Function:** Handles incoming requests on ports 80 and 443.
- **Role:** Acts as a front-end server managing connections, security, and serving static content.

### Communication with Apache Tomcat

- **Connector:** Uses the AJP (Apache JServ Protocol) with the `mod_jk` library.
- **Ports:** Tomcat listens on ports 8080 (HTTP) and 8443 (HTTPS) for forwarded requests.

## Use Cases

1. **Load Balancing and Scalability:**
   - Apache HTTP distributes incoming traffic across multiple Tomcat servers, balancing the load and enhancing scalability.
   - Ensures the web application can handle more users without performance issues.

2. **Security and SSL Termination:**
   - Apache HTTP manages SSL/TLS encryption, providing secure connections (HTTPS) to customers.
   - Terminates SSL connections and forwards decrypted requests to Tomcat over a secure internal network.

3. **Static Content Serving:**
   - Apache HTTP efficiently serves static content (images, CSS, JavaScript), reducing the load on Tomcat.
   - Improves response times and overall performance.

4. **Centralized Management:**
   - Apache HTTP provides a single entry point for all requests, simplifying configuration and management.
   - Handles complex URL rewriting, redirection, and other HTTP-level configurations.

## Why Use `mod_jk`?

- `mod_jk` is a robust connector module that bridges Apache HTTP and Tomcat.
- Supports load balancing, fault tolerance, and efficient request forwarding.
- Facilitates seamless integration between the two servers, leveraging their strengths.

## Summary

This setup combines the strengths of Apache HTTP and Apache Tomcat:

- **Apache HTTP:** Manages incoming requests, SSL/TLS, static content, and load balancing.
- **Apache Tomcat:** Focuses on running Java web applications.
- **mod_jk:** Ensures smooth communication between the servers, providing reliable and efficient request handling.

This architecture is a common and powerful approach for web application deployment, ensuring scalability, security, and efficient resource utilization.
