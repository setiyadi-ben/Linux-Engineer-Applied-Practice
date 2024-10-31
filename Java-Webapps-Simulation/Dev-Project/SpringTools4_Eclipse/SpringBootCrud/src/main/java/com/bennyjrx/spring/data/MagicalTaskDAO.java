package com.bennyjrx.spring.data;

import java.util.ArrayList;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

//Using CRUD Repository
@Component
public class MagicalTaskDAO implements TaskDAO {
	
	@Autowired
	TaskRepository taskRepository;

	@Override
	public void create(Task task) {
		// TODO Auto-generated method stub
		taskRepository.save(task);
	}

	@Override
	public List<Task> retrieveALL() {
		// TODO Auto-generated method stub
		/*
		 * The `TaskRepository` has a `findAll` method that returns a group 
		 * of tasks you can loop through. You can then turn this group into a list.
		 */
		Iterable<Task> tasks = taskRepository.findAll();
		List<Task> taskList = new ArrayList<>();
		tasks.forEach(taskList::add);
		return taskList;
	}

	@Override
	public void update(Task task) {
		// TODO Auto-generated method stub
		/*
		 *The `save` method in `TaskRepository` does indeed handle both creating 
		 *new records and updating existing ones. If the task has a primary key 
		 *that matches an existing record in the database, `save` will update 
		 *that record. If there is no primary key, or if the primary key doesn't 
		 *match any existing records, `save` will create a new one. 
		 
		 **Simplified version:*
		 *The `save` method in `TaskRepository` will either update a task if it 
		 *already exists (using the primary key) or create a new task if it 
		 *doesn’t.
		 */
		taskRepository.save(task);

	}

	@Override
	public void delete(Task task) {
		// TODO Auto-generated method stub

	}

}
