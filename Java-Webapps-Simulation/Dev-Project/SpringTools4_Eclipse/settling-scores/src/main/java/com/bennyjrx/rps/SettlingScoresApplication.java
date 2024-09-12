package com.bennyjrx.rps;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class SettlingScoresApplication {

	public static void main(String[] args) {
		SpringApplication.run(SettlingScoresApplication.class, args);
	}

}

/*
INVOCATIONS EXPLAINED FUNCTIONS, SEE DETAILS ON https://github.com/setiyadi-ben/Linux-Engineer-Applied-Practice/blob/main/Additional-Notes/HTTP_Methods.md
@GetMapping --> Is supposed to get data from the server and leave the state of the server unchanged.
@PutMapping --> Update all data from the resource (database), Essentially you replace the existing data with the new one.
@PatchMapping --> You can update one property (property that exist inside database for example, email) to a specific value.
@PostMapping --> Update the data in unpredictable way follows the idempotent operation (https://id.wikipedia.org/wiki/Idempoten)
*/