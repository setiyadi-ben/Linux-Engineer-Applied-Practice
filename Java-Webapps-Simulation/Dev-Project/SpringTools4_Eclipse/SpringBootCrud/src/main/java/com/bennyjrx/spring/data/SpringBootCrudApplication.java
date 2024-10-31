package com.bennyjrx.spring.data;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.stereotype.Component;

@SpringBootApplication
@Component
public class SpringBootCrudApplication implements CommandLineRunner {
	@Autowired
//	HonestTaskDAO taskDAO;
	MagicalTaskDAO taskDAO;

	public static void main(String[] args) {
		SpringApplication.run(SpringBootCrudApplication.class, args);
	}
	
//	@Override
//	public void run(String... args) throws Exception {
//		Task task = new Task("Make my bed.", false);
//		taskDAO.create(task);
//		System.out.println("Created!");
//	}
	@Override
	public void run(String... args) throws Exception {
//		Creating records inside mysql using object on Task.java, 
//		MagicalTaskDAO.java and TaskDAO.java
		Task task = new Task("Do meal prep.", false);
		taskDAO.create(task);
//		Update the records inside mysql using object on Task.java,
//		MagicalTaskDAO.java and TaskDAO.java
//		Target the primary key (Id) on mysql to change the data
		Task updatedTask = new Task(4, "Do meal prep.", true);
		taskDAO.update(updatedTask);
//		Read the data inside mysql using object on Task.java,
//		Target the primary key (Id) on mysql to change the data
		List<Task> taskList = taskDAO.retrieveALL();
		for (Task t : taskList) {
//			Show the data in console
			System.out.println(t);
		}
		
//		Show that the procedure was done
		System.out.println("Done!!!");
	}

}
