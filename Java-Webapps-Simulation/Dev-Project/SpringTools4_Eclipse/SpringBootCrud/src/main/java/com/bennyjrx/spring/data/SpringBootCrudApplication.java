package com.bennyjrx.spring.data;

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
		Task task = new Task("Do meal prep.", false);
		taskDAO.create(task);
		System.out.println("Created!");
	}

}
