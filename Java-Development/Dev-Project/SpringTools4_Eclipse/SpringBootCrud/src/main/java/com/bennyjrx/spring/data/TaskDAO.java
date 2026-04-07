package com.bennyjrx.spring.data;
import java.util.List;

public interface TaskDAO {
//	Create task
	public void create(Task task);
//	Read task
	public List<Task> retrieveALL();
//	Update task
	public void update(Task task);
//	Delete task
	public void delete(Task task);

}
