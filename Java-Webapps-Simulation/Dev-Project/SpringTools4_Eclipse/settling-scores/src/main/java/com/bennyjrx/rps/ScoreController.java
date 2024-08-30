/*
 This is the Class thats contain your Rest API. Used to keep track of the score. 
 */
package com.bennyjrx.rps;

import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

// @RestController & @CrossOrigin 
// are coming from Spring Framework so it's need to be imported by using Ctrl+Shift+O in Eclipse IDE.
@RestController
@CrossOrigin
public class ScoreController {
	
//	This is a property named score that keeps track of the score value in-game
	static Score score = new Score(30, 20, 10);

//	This is a method that will return string inside browser when somebody enter 127.0.0.1/health-check
//  With a @GetMapping Annotation
	@GetMapping("/health-check")
	public String getHealthCheck() {
		return "Situation Normal, All Fired Up!";
	}
	
	@GetMapping ("/score") // When browser request 127.0.0.1/score will trigger method below
//	This is a method that returns a score
	public Score getScore() {
//		returning the static score value from line 17
		return score;
	}
}
