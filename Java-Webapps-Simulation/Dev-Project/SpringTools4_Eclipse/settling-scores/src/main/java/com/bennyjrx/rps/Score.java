package com.bennyjrx.rps;

// this is a class to represent a score in-game
public class Score {
//	define several data in it
	int wins;
	int losses;
	int ties;
	
	// generate getters and setters --> Right click --> Source --> generate getters and setters
	public int getWins() {
		return wins;
	}
	public void setWins(int wins) {
		this.wins = wins;
	}
	public int getLosses() {
		return losses;
	}
	public void setLosses(int losses) {
		this.losses = losses;
	}
	public int getTies() {
		return ties;
	}
	public void setTies(int ties) {
		this.ties = ties;
	}
	
	// generate constructor using fields --> Right click --> Source --> generate constructor using fields
	public Score(int wins, int losses, int ties) {
		super();
		this.wins = wins;
		this.losses = losses;
		this.ties = ties;
	}
	
	// default constructor	
	public Score( ) {}
	
}
