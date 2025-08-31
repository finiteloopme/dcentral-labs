import { useState, useEffect } from 'react';
import type { LadderEntry } from '../types';
import config from '../config';

/**
 * Props for the Ladder component.
 */
interface LadderProps {
  /**
   * The ID of the competition to display the ladder for.
   */
  competitionId: string;
}

/**
 * A component that displays the competition ladder.
 *
 * The ladder shows the scores of all players in the competition.
 */
function Ladder({ competitionId }: LadderProps) {
  const [ladder, setLadder] = useState<LadderEntry[]>([]);

  // Fetch the ladder data from the backend when the component mounts or the competition ID changes.
  useEffect(() => {
    const interval = setInterval(() => {
      fetch(`${config.backendUrl}${config.api.competitions}/${competitionId}/ladder`)
        .then(response => response.json())
        .then(data => setLadder(data));
    }, 5000);

    return () => clearInterval(interval);
  }, [competitionId]);

  return (
    <div>
      <h3>Ladder</h3>
      <table>
        <thead>
          <tr>
            <th>Player</th>
            <th>Score</th>
          </tr>
        </thead>
        <tbody>
          {ladder.map(entry => (
            <tr key={entry.player_name}>
              <td>{entry.player_name}</td>
              <td>{entry.score}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default Ladder;
