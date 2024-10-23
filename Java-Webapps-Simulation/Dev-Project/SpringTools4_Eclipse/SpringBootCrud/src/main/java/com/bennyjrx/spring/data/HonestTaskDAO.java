package com.bennyjrx.spring.data;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

@Component
//Using JDBC Template
public class HonestTaskDAO implements TaskDAO {
	@Autowired
	JdbcTemplate jdbcTemplate;

	@Override
	public void create(Task task) {
		// TODO Auto-generated method stub
		// Prepared Statements
		var sql = "INSERT INTO TASK (name, completed) VALUES (?, ?)";
		jdbcTemplate.update(sql, task.name, task.completed);

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
