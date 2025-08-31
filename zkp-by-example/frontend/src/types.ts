/**
 * This file contains the shared TypeScript types used throughout the frontend.
 */

/**
 * Represents a single Sudoku competition.
 */
export interface Competition {
  id: string;
  name: string;
  is_paused: boolean;
  board: (number | null)[][];
}

/**
 * Represents a player in the game.
 */
export interface Player {
  id: string;
  name: string;
}

/**
 * Represents a game in progress for a specific player and competition.
 */
export interface Game {
  competition_id: string;
  player_id: string;
  board: (number | null)[][];
  score: number;
}

export interface LadderEntry {
  player_name: string;
  score: number;
}
