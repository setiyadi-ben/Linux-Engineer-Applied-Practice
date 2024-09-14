# Start Code Java Webapps Project - Eclipse IDE
## Using Spring Tools 4
### [**back to Table-of-Contents**](/Java-Webapps-Simulation/2/Code-editor_setup.md)
### [**back to Code-editor_setup**](/Java-Webapps-Simulation/2/Code-editor_setup.md)

## Quick Note
Using Eclipse IDE with Spring Tools built-in has an **advantages compared to the other such as this app has pre-installed java and maven also working fine on windows 10 or later**.

## Installation, Setup and Exercising the Demo Project
  
For the installation steps, I'm referring to Mr. [**McKenzie's video on YouTube**](https://www.youtube.com/watch?v=U-6_gJoWYwM). As a beginner of "Educationist Documenter", I'm only change my directory installation file into .gitginore-files in this repository. The intention is to bypass the file being tracked by git and make the repository lighter on storage usage.

<center>

<b>Extract and unzip "contents.zip", follow Mr. McKenzie instructional video
![Extracting the files](/image-files/spring-tools4-1.png)

Select your Workspace
![Select workspace](/image-files/spring-tools4-2.png) 

Filling the Project Metadata
![Project Metadata](/image-files/spring-tools4-3.png)

Selecting Dependencies
![Dependencies](/image-files/spring-tools4-4.png)

Continue your steps by following Mr. [**McKenzie's video on YouTube**](https://www.youtube.com/watch?v=U-6_gJoWYwM)</b>
![Code](/image-files/spring-tools4-5.png)

![results](/image-files/spring-tools4-6.png)
</center>

if you can manage into this result, let's head over to the serious coding process.

## Start Practice Coding in Java
Like most of the elders said, in order to master something in your field you need to try it out by yourself. 

In my view, the most important thing is to replicate the work that is available on YouTube especially until you are familiar with the environment of that code. 

So, when you have successfully doing that, you will be having an insight of what's going to do next or you will probably be able to solve the real world problem with your self driven mentality.

### 1. Practice Spring Boot Restful APIS 
- **Source 1** [**YouTube Tutorial**](https://www.youtube.com/watch?v=9brw7UzFdTA)
Lesson learned:

    a. Theory at duration 03:14 until 07:45.
    
    b. Rest is not CRUD, [**read more here**](/Additional-Notes/RestAPI&CRUD.md).

    c. There are 8 commonly used HTTP methods, [**read more here**](/Additional-Notes/HTTP_Methods.md).

    d. Progress as follows

    <center>
    
    ![1](/image-files/sts4_progress-1.png)
    <br><b>@GetMapping</b> invocation and return the value in JSON format</br>

    ![2](/image-files/sts4_progress-2.png)
    <br><b>@PostMapping</b> increase the number of wins by one and return the user full score</br>

    ![3](/image-files/sts4_progress-3.png)
    <br><b>@PatchMapping & RequestParam</b> to able to perform query request<br>

    ![4](/image-files/sts4_progress-4.png)
    <br><b>@PutMapping</b> is used to completely replace the resource from the server, while <b>@RequestBody</b> is used to send raw data especially using JSON format</br>
    
    ![5](/image-files/sts4_progress-5.png)
    <br>Verify the new data from the server using <b>GET</b> method.<br>
    </center>