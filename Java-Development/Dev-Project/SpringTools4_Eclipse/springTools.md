# Start Code Java Webapps Project - Eclipse IDE
## Using Spring Tools 4
## [**back to Linux-Engineer-Applied-Practice**](/README.md)
### [**back to Java Procedure**](/Java-Webapps-Simulation/Java-Procedure.md)

### [**back to Code-editor_setup**](/Java-Webapps-Simulation/2/Code-editor_setup.md)

## Quick Note
Using Eclipse IDE with Spring Tools built-in has an **advantages compared to the other such as this app has pre-installed java and maven also working fine on windows 10 or later**.

## Installation, Setup and Exercising the Demo Project
  
For the installation steps, I'm referring to Mr. [**McKenzie's video on YouTube**](https://www.youtube.com/watch?v=U-6_gJoWYwM). For the installation only on Spring Tools 4, I'm changing my directory installation files into .gitginore-files in this repository. The intention is to bypass the file being tracked by git and make the repository lighter on storage usage.

<p align="center"><b>Extract and unzip "contents.zip", follow Mr. McKenzie instructional video</b></p>
<p align="center"><img src="/image-files/spring-tools4-1.png"></p>
<!-- ![Extracting the files](/image-files/spring-tools4-1.png) -->

<p align="center"><b>Select your Workspace</b></p>
<p align="center"><img src="/image-files/spring-tools4-2.png"></p>
<!-- ![Select workspace](/image-files/spring-tools4-2.png)  -->
 
<p align="center"><b>Filling the Project Metadata</b></p>
<p align="center"><img src="/image-files/spring-tools4-3.png"></p>
<!-- ![Project Metadata](/image-files/spring-tools4-3.png) -->

<p align="center"><b>Selecting Dependencies</b></p>
<p align="center"><img src="/image-files/spring-tools4-4.png"></p>
<!-- ![Dependencies](/image-files/spring-tools4-4.png) -->

Continue your steps by following Mr. [**McKenzie's video on YouTube**](https://www.youtube.com/watch?v=U-6_gJoWYwM)</b>
<p align="center"><img src="/image-files/spring-tools4-5.png"></p>
<!-- ![Code](/image-files/spring-tools4-5.png) -->
<p align="center"><img src="/image-files/spring-tools4-6.png"></p>
<!-- ![results](/image-files/spring-tools4-6.png) -->

If you can manage into this result, let's head over to the serious coding process.

## Start Practice Coding in Java
Like most of the elders said, in order to master something in your field you need to try it out by yourself. 

In my view, the most important thing is to replicate the work that is available on YouTube especially until you are familiar with the environment of that code. 

So, when you have successfully doing that, you will be having an insight of what's going to do next or you will probably be able to solve the real world problem with your self driven mentality.

### 1. Practice Spring Boot Restful APIS 
- **Source 1** [**YouTube Tutorial**](https://www.youtube.com/watch?v=9brw7UzFdTA)
Lesson learned:

    a. Theory at duration 03:14 until 07:45.
    
    b. Rest is not CRUD, [**read more here**](/Additional-Notes/RestAPI&CRUD.md).

    c. There are **8 commonly used HTTP methods** and also the **concept of idempotent and non idempotent**, [**read more here**](/Additional-Notes/HTTP_Methods.md).

    d. Progress as follows

<p align="center"><img src="/image-files/sts4_progress-1.png"></p>
    <!-- ![1](/image-files/sts4_progress-1.png) -->
    <p align="center"><b>@GetMapping</b> invocation and return the value in JSON format</p>
<p align="center"><img src="/image-files/sts4_progress-2.png"></p>
    <!-- ![2](/image-files/sts4_progress-2.png) -->
    <p align="center"><b>@PostMapping</b> increase the number of wins by one and return the user full score</p>
<p align="center"><img src="/image-files/sts4_progress-3.png"></p>
    <!-- ![3](/image-files/sts4_progress-3.png) -->
    <p align="center"><b>@PatchMapping & RequestParam</b> to able to perform query request<br>
<p align="center"><img src="/image-files/sts4_progress-4.png"></p>
    <!-- ![4](/image-files/sts4_progress-4.png) -->
    <p align="center"><b>@PutMapping</b> is used to completely replace the resource from the server, while <b>@RequestBody</b> is used in order to able to send raw data especially using JSON format</p>
<p align="center"><img src="/image-files/sts4_progress-5.png"></p>    
    <!-- ![5](/image-files/sts4_progress-5.png) -->
    <p align="center">Verify the new data from the server using <b>GET</b> method.<br>
<p align="center"><img src="/image-files/sts4_progress-6.png"></p>
    <!-- ![6](/image-files/sts4_progress-6.png) -->
    <p align="center"><b>@DeleteMapping</b> will erase the entire data on the server and can be restored back using <b>@PostMapping</b></p>
<p align="center"><img src="/image-files/sts4_progress-7.png"></p>
    <!-- ![7](/image-files/sts4_progress-7.png) -->
   <p align="center">Creating a new folder for a html file in order to make rock paper scissor game </p>
<p align="center"><img src="/image-files/sts4_progress-8.png"></p>
    <!-- ![8](/image-files/sts4_progress-8.png) -->
  

### 2. Crud Operations with Spring Data & Spring JDBC
- **Source 1** [**YouTube Tutorial**](https://www.youtube.com/watch?v=oE3h-YNlqss&t=741s)
Lesson learned:

    a. Theory duration 0:30 until 01:30.

    b. CRUD concept

    c.

    d. Progress as follows (Timestamps to jump in: 2:37, 3:09, 4:29, 5:45 )

<p align="Justify">
<b>Main topic:</b> Creating a Persistance Layer for a To-Do Application. This kind of job can be achieved by using
CRUD Operations using 2 ways, like: Spring Data (TaskRepository | MagicalTaskDAO.java) & Spring JDBC (Jdbctemplate | HonestTaskDAO.java).
<br><b>Additional Notes:</b>
<ol>
<li>Creating a database called TODO (while I'm using the existing database "id-lcm-prd1" that is used in previous simulation) and a table called Task (I'm using the same MySQL database that is used in 
<a href="https://github.com/setiyadi-ben/Linux-Engineer-Applied-Practice/blob/main/Database-Replication-Simulation/readme.md">
<b>Database Replication Simulation</b></a>).</li>
<p align="center"><img src="/image-files/crud-db1.png"></p>
<li>Inside the database table, a row has multiple columns inside such as: id (primary key & auto increment), name (varchar) and completed (boolean).</li>

~~~sql
CREATE TABLE `id-lcm-prd1`.`TASK` 
(`id` INT NOT NULL AUTO_INCREMENT ,
 `name` VARCHAR(45) NOT NULL ,
  `completed` BOOLEAN NOT NULL ,
   PRIMARY KEY (`id`)) ENGINE = InnoDB;
~~~

<p align="center"><img src="/image-files/crud-db2.png"></p>
<li>Setup <b>application.properties</b> in order to make Java program gain access to the database.</li>
<p align="center"><img src="/image-files/crud-db3.png"></p>

<li>Create Java class called "Task.java", and here are the explanations that I've gathered so far.</li>
<a href="/Java-Webapps-Simulation/Dev-Project/SpringTools4_Eclipse/SpringBootCrud/src/main/java/com/bennyjrx/spring/data/">file can be found here</a>

## Use Cases of the Code
- Represents tasks in a task management system.  
- Maps Java objects (`Task`) to database records (rows in `TASK` table).  
- Supports basic CRUD operations:  
  - **Create**: Use the constructor without `id`.  
  - **Read/Update**: Use getters and setters.  
  - **Delete**: Use the constructor with `id`.

## Key Concepts | TERMINOLOGIES THAT MATTERS

### 1. Constructor
A **constructor** is a special method used to initialize objects. It is called automatically when an object of the class is created.

- **Default Constructor**: 
  ~~~java
  public Task() { } 
  ~~~ 
  
  - Initializes the object without any arguments.

- **Parameterized Constructor**:  
  ~~~java
  public Task(int id, String name, boolean completed) {
    this.id = id;
    this.name = name;
    this.completed = completed;

    /*
    - The fields id, name, and completed are package-private (accessible within the same package but not outside it).
    - These fields should be declared private to strictly follow the JavaBean conventions.
    */
    
  }
  ~~~
  - Allows initializing the object with specific values.

---

### 2. JavaBean
A **JavaBean** is a reusable class that follows specific conventions:  
- **Encapsulate its fields (make them** `private`).
  - Why Encapsulation Matters?
   1. Protects the `internal state` of an object from `unintended changes`.
   2. Allows validation or additional logic when setting/getting values.
   ~~~java
   // Example: Ensuring name is not null:
    public void setName(String name) {
        if (name == null || name.isEmpty()) {
            throw new IllegalArgumentException("Name cannot be null or empty");
        }
        this.name = name;
    }
   ~~~
- Provide **public getters and setters** to access the fields.
- Include a **zero-argument constructor**.
- Optionally, override methods like `toString`, `equals`, and `hashCode`.

**Purpose**: Simplifies data sharing between layers of an application.

---
### 3. How Fields, Getters, and Setters Work Together

1. `Fields` store the data.
2. `Getters` allow reading the data in a controlled way.
3. `Setters` allow modifying the data, often with validation.

---


<!-- <li></li> -->
</ol>

</p>