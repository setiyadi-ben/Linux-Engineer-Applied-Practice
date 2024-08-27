# Choosing Code Editor and Skeleton Project for Java
### [**back to Table-of-Contents**](../Table-of-Contents.md)

## Skeleton Project 
In summary, a skeleton project, especially in the context of Spring Boot and Maven Archetypes, is a ready-to-use project template that helps you kickstart your application development with a predefined structure and configuration, ensuring consistency and saving time in the setup phase.

It typically includes the essential files, directory structure, and initial configurations necessary to get a project up and running quickly. **The idea is to provide developers with a clean, organized starting point so they can focus on writing the actual application code rather than spending time setting up the project from scratch.**

## Various Methods of Developing Java Webapps
From what I have been researching various tutorials on YouTube, I'm deciding to create the demo webapps that are the same with the different environments such as **Spring Boot Initializr, Spring Tools and Maven Archetype** on several IDEs.

**I'm doing it this way because each project template has its own configuration to make it work. So with that said, the aim is to be familiar with different project environments and can switch whenever someday you need it.**

## MUST KNOW | Initialize the Project (Project Setup)

### Prerequisites

- **Java Development Kit (JDK)**: Version 8 or higher
- **Apache Maven**: Version 3.6 or higher
- **Spring Boot**: Version 2.5 or higher
- **MySQL**: Version 5.7 or higher
- **IDE**: IntelliJ IDEA, Eclipse, or VS Code with Java support

#### Using Spring Boot Initializr:

1. **Fill in Project Metadata**
   - Visit [Spring Initializr](https://start.spring.io/) in your web browser. This is a web-based tool provided by the Spring community to help you quickly set up a new Spring Boot project with the necessary dependencies and configurations.
   - **Project**: Select "Maven Project." This means the project will be built using Maven, a popular build automation tool in Java.
   - **Language**: Choose "Java" as the programming language.
   - **Spring Boot Version**: Pick the latest stable version of Spring Boot. This ensures you get the latest features and updates.
   - **Group**: Enter a unique identifier for your project, often in the format of a domain name in reverse. For example, if your company is called "Tech Innovators," you might use `com.techinnovators`.
   - **Artifact**: This is the name of your project, which will also be the name of the generated JAR file. For instance, if you’re building an employee management system, you might name this `employee-management`.
   - **Name**: The project’s display name (usually the same as the artifact name). In this case, it could be `Employee Management`.
   - **Description**: Briefly describe the purpose of the project. For example, "A Java web application for managing employee records with CRUD RESTful API."
   - **Package Name**: The base package for your project, usually a combination of the group and artifact names. For example, `com.techinnovators.employeemanagement`.
   - **Packaging**: Select "Jar" to package your project as a JAR file, which is a common format for Java applications.
   - **Java Version**: Select the latest Java version available.

2. **Select Dependencies**
   - Dependencies are libraries and frameworks that your project will use. For a web application with a CRUD RESTful API connected to a MySQL database, you need to add the following:
   - **Spring Web**: This adds support for building web applications, including RESTful services using Spring MVC.
   - **Spring Data JPA**: This provides easy integration with databases using the Java Persistence API (JPA), which helps in managing data in your MySQL database.
   - **MySQL Driver**: This includes the JDBC driver needed to connect your application to a MySQL database.
   - **Spring Boot DevTools**: (Optional) Adds additional tools to improve the development experience, such as live reload.

3. **Generate and Download the Project**
   - Click "Generate" and download the ZIP file.

## Development Process

### 1. Spring Tools 4 - Eclipse IDE [(click here)](../Dev-Project/SpringTools4_Eclipse/springTools.md)

### 2. Spring Tools Initializr Extension & Web - VSCode [(click here)](../Dev-Project/SpringInitializr_Vscode/springInit.md)

### 3. Maven Archetype - IntelliJ Community [(click here)](../Dev-Project/MavenArchetype_IntellijCommunity/mavenArch.md)