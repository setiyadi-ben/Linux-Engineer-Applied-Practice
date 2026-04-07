package com.techinnovators.employeemanagement;

import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@CrossOrigin
public class SmokeTestController {
@GetMapping("/smoke-test")
public String isThisWorking() {
	return "situation nomal, all fried, up!";
}

}
