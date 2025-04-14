/*
 Use Cases of the Code
Represents tasks in a task management system.
Maps Java objects (Task) to database records (rows in TASK table).
Supports basic CRUD operations:
Create: Use the constructor without id.
Read/Update: Use getters and setters.
Delete: Use the constructor with id.
*/

/*
 	Key Concepts | TERMINOLOGIES THAT MATTERS
 	1. Constructor
A constructor is a special method used to initialize objects. It is called automatically when 
an object of the class is created.
- Default Constructor:
public Task() { }
	- Initializes the object without any arguments.
- Parameterized Constructor:
public Task(int id, String name, boolean completed) {
    this.id = id;
    this.name = name;
    this.completed = completed;
}
	- Allows initializing the object with specific values.
	2. Annotation
Annotations in Java provide metadata about code that can be used by the compiler or runtime 
frameworks.
Annotations in Java provide metadata about code that can be used by the compiler or runtime frameworks.
- Examples in Code:
	@Id: Indicates the primary key of the table.
	@Table: Maps the class to the table in the database.
- Spring Data-Specific Annotations:
	- Enable automatic mapping and database-related configurations.
	3. JavaBean
A JavaBean is a reusable class that follows specific conventions:
- Encapsulation: Fields are private with public getters and setters.
- Zero-argument constructor: Required for easy instantiation.
- Serializable: (Optional) Implements the Serializable interface.
- Purpose: Simplifies data sharing between layers of an application.
- In the Code: The Task class is a JavaBean because:
	- It has private fields.
	- Provides public getters and setters.
	- Includes a zero-argument constructor.

 */

package com.bennyjrx.spring.data;
//	Declares the package in which the class resides.

import org.springframework.data.annotation.Id;
//@Id: Marks the id field as the primary key.

import org.springframework.data.relational.core.mapping.Table;
// @Table: Associates the class Task with the database table TASK.

 @Table(name = "TASK")
// The @Table(name = "TASK") annotation specifies that this class maps to the TASK table in the database.
public class Task {

// We have to put @Id annotation in order to work
	@Id 
//	These are the variables that are used inside the database TASK table as an individual columns
	/*
	 * By declaring the fields as private, you ensure proper encapsulation, which is a 
	 * key requirement of the JavaBean standard.
	 */
	int id;
//	id: Primary key (annotated with @Id).
	String name;
//	name: Represents the name of the task.
	boolean completed;
//	completed: Boolean flag to indicate if the task is completed.
	
	//6.Generate Constructor for zero args constructor
	public Task() {
		super();
	}
	//5.Generate Constructor that uses only id | To delete something
	public Task(int id) {
		super();
		this.id = id;
	}
	//4.Generate Constructor that uses all Fields except id | To create new object
	public Task(String name, boolean completed) {
		super();
		this.name = name;
		this.completed = completed;
	}
	//3.Generate Constructor that uses all Fields
	public Task(int id, String name, boolean completed) {
		super();
		this.id = id;
		this.name = name;
		this.completed = completed;
	}
	//1.Generate Getters and Setters
//	Getters and Setters can also be generated using Lombok
//	Provide controlled access to the fields. Essential for JavaBeans.
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
//	Converts the object to a human-readable string.
	@Override
	public String toString() {
		return "Task [id=" + id + ", name=" + name + ", completed=" + completed + "]";
	}
	
	

}
