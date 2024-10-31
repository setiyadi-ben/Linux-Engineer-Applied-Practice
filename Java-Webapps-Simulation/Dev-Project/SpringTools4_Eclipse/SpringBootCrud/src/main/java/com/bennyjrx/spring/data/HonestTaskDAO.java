package com.bennyjrx.spring.data;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.BeanPropertyRowMapper;
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
//	retrieve the data from the mysql database
	public List<Task> retrieveALL() {
		// TODO Auto-generated method stub
		var sql = "select * from TASK";
		/*
		 * Alright, let me make it even simpler:
		 * The `BeanPropertyRowMapper` automatically takes each row from your 
		 * database and turns it into a Java object. It does this by matching 
		 * the database column names with the names of the fields in your 
		 * Java class. So, if a database row has data, it creates a new object
		 * filled with that data.
		 */
		var bprm = new BeanPropertyRowMapper<Task>(Task.class);
		List <Task> taskList = jdbcTemplate.query(sql,  bprm);
		return null;
	}

	@Override
	public void update(Task task) {
		// TODO Auto-generated method stub
		// Same as taskRepository.save(task); but using jdbcTemplate
		var sql = "UPDATE TASK SET name =?, completed =?, WHERE id =?";
		jdbcTemplate.update(sql, task.name, task.completed, task.id);

	}

	@Override
	public void delete(Task task) {
		// TODO Auto-generated method stub

	}

}
