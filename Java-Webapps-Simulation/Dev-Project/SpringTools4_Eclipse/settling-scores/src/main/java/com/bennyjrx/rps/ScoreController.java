/*
 This is the Class thats contain your Rest API. Used to keep track of the score. 
 */
package com.bennyjrx.rps;

import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
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
	
	/*
//	return only wins, losses and ties
	@GetMapping ("/score/wins")
	public int getWins() {
//		all return value are reference from  Score.java class
		return score.wins;
	}
	
	@GetMapping ("/score/losses")
	public int getLosses() {
		return score.losses;
	}
	
	@GetMapping ("/score/ties")
	public int getTies() {
		return score.ties;
	}
	*/
	
//	performing @PathVariable
	@GetMapping("/score/{winslossesorties}")
//	untuk winlossesorties di-copy saja ke if di bawah untuk menghindari error
	public int getWinsLossesOrTies(@PathVariable String winslossesorties) {
		if (winslossesorties.equalsIgnoreCase("wins")) {
			return score.wins;
		}
		if (winslossesorties.equalsIgnoreCase("ties")) {
			return score.ties;
		}
		return score.losses;
	}
	
//	Increase the number of wins by one and return the user full score
	@PostMapping("/score/wins") //@PostMapping can't directly accessing it from the browser
	public Score increaseWins() {
		score.wins++;
		return score;
	}
	
	@PostMapping("/score/losses") 
	public Score increaseLosses() {
		score.losses++;
		return score;
	}
	
	@PostMapping("/score/ties") 
	public Score increaseTies() {
		score.ties++;
		return score;
	}
	
	/*
	Try to invoke @PostMapping via MS PowerShell
	curl.exe -X POST http://127.0.0.1:8080/score/wins
	curl.exe -X POST http://127.0.0.1:8080/score/losses
	curl.exe -X POST http://127.0.0.1:8080/score/ties
	 */
	
//	Update new data only for wins (one property) using query request or @RequestParameter
	@PatchMapping("/score/wins")
	public Score updateWins(@RequestParam(name="new-value")int newvalue) {
		score.wins = newvalue;
		return score;
	}
	
//	Update new data only for losses (one property) using query request or @RequestParameter
	@PatchMapping("/score/losses")
	public Score updateLosses(@RequestParam(name="new-value")int newValue) {
		score.losses = newValue;
		return score;
	}
	
//	Update new data only for ties (one property) using query request or @RequestParameter
	@PatchMapping("score/ties")
//	trying to make the value of @RequestParam different, will it make a conflict?
	public Score updateTies(@RequestParam(name="new-value1")int newValue1) {
		score.ties = newValue1;
		return score;
	}
	
//	Completely replace the data from the server using @PutMapping and @RequestBody is used in order to be able to send raw data especially in JSON format
	@PutMapping("/score")
	public Score replaceScore(@RequestBody Score newScore) {
		score = newScore;
		return score;
	}
	
// Completely remove data from the server
	@DeleteMapping("/score")
	public void deleteScore() {
		score = null;
	}
	
	
}
