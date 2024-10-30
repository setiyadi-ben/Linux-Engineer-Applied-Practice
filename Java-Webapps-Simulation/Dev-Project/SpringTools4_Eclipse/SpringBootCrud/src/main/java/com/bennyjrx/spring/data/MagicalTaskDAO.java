package com.bennyjrx.spring.data;

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
		return null;
	}

	@Override
	public void update(Task task) {
		// TODO Auto-generated method stub

	}

	@Override
	public void delete(Task task) {
		// TODO Auto-generated method stub

	}

}
