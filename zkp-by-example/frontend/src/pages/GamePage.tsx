import { useState, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import SudokuGrid from '../components/SudokuGrid';
import Ladder from '../components/Ladder';
import type { Competition, Player, Game } from '../types';
import config from '../config';

function GamePage() {
  const { competitionId } = useParams<{ competitionId: string }>();
  const [competition, setCompetition] = useState<Competition | null>(null);
  const [game, setGame] = useState<Game | null>(null);
  const [player, setPlayer] = useState<Player | null>(null);
  const [proof, setProof] = useState<string | null>(null);

  useEffect(() => {
    if (competitionId) {
      fetch(`${config.backendUrl}${config.api.competitions}/${competitionId}`)
        .then(response => response.json())
        .then(data => setCompetition(data));
    }
  }, [competitionId]);

  const handleJoinGame = (playerName: string) => {
    if (competition) {
      fetch(`${config.backendUrl}${config.api.competitions}/${competition.id}/join`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ name: playerName }),
      })
        .then(response => response.json())
        .then(data => {
          setGame(data);
          setPlayer({ id: data.player_id, name: playerName });
        });
    }
  };

  const handleCellChange = (row: number, col: number, value: number | null) => {
    if (game) {
      const newBoard = [...game.board];
      newBoard[row][col] = value;
      setGame({ ...game, board: newBoard });
    }
  };

  const handleSubmit = () => {
    if (game && competition) {
      fetch(`${config.backendUrl}${config.api.competitions}/${competition.id}/submit`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(game),
      })
        .then(response => response.json())
        .then(data => setGame(data));
    }
  };

  const handleRequestProof = () => {
    if (game) {
      fetch(`${config.backendUrl}/request-proof`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(game),
      })
        .then(response => response.json())
        .then(data => setProof(data.proof));
    }
  };

  if (!competition) {
    return <div>Loading...</div>;
  }

  return (
    <div>
      <h2>{competition.name}</h2>
      {!game ? (
        <div>
          <input type="text" id="playerName" placeholder="Enter your name" />
          <button onClick={() => handleJoinGame((document.getElementById('playerName') as HTMLInputElement).value)}>Join Game</button>
        </div>
      ) : (
        <div>
          <p>Playing as: {player?.name}</p>
          <SudokuGrid board={game.board} initialBoard={competition.board} onCellChange={handleCellChange} />
          <button onClick={handleSubmit}>Submit</button>
          <button onClick={handleRequestProof}>Generate Proof</button>
          {game.score !== 0 && <p>Score: {game.score}</p>}
          {proof && <div><h3>Proof:</h3><p>{proof}</p></div>}
        </div>
      )}
      <Ladder competitionId={competition.id} />
    </div>
  );
}

export default GamePage;