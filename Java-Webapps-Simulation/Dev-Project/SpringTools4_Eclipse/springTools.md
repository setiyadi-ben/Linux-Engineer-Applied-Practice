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
