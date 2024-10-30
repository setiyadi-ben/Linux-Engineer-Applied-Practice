 package com.bennyjrx.spring.data;
 /*
	What is Spring Data?
	Spring Data is a part of the Spring Framework that focuses on simplifying
	data access. It provides tools to easily work with databases, NoSQL stores,
	and other data sources. By using Spring Data, developers can write less code
	and focus more on the business logic of their applications.
	
	What Does org.springframework.data.annotation Provide?
	The org.springframework.data.annotation package contains various 
	annotations that can be used to define how data is managed and processed.
	Some examples include:
	
	@Id: Marks a field as the primary key of a database record.
	@CreatedDate: Automatically stores the date and time when the data was
	 created.
	@LastModifiedDate: Automatically updates the date and time when the data
	 was last modified.
	@Transient: Indicates that a field should not be stored in the database.
  */
 import org.springframework.data.annotation.Id;
import org.springframework.data.relational.core.mapping.Table;

 @Table(name = "TASK")
public class Task {
	
	@Id
	int id;
	String name;
	boolean completed;
	
	
	//5.Generate using Fields for default constructor
	public Task() {
		super();
	}
	//4.Generate using Fields that uses only id | To delete something
	public Task(int id) {
		super();
		this.id = id;
	}
	//4.Generate using Fields that uses all Fields except id | To create new object
	public Task(String name, boolean completed) {
		super();
		this.name = name;
		this.completed = completed;
	}
	//3.Generate using Fields that uses all Fields
	public Task(int id, String name, boolean completed) {
		super();
		this.id = id;
		this.name = name;
		this.completed = completed;
	}
	//1.Generate Getters and Setters
	public int getId() {
		return id;
	}
	public void setId(int id) {
		this.id = id;
	}
	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}
	public boolean isCompleted() {
		return completed;
	}
	public void setCompleted(boolean completed) {
		this.completed = completed;
	}
	
	//2.Generate to String
	@Override
	public String toString() {
		return "Task [id=" + id + ", name=" + name + ", completed=" + completed + "]";
	}
	
	

}
