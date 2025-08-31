import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import type { Competition } from '../types';
import config from '../config';

/**
 * A component that displays a list of available competitions.
 */
function CompetitionList() {
  const [competitions, setCompetitions] = useState<Competition[]>([]);

  // Fetch the list of competitions from the backend when the component mounts.
  useEffect(() => {
    fetch(`${config.backendUrl}${config.api.competitions}`)
      .then(response => response.json())
      .then(data => setCompetitions(data));
  }, []);

  return (
    <div>
      <h2>Competitions</h2>
      <ul>
        {competitions.map(comp => (
          <li key={comp.id}>
            <Link to={`/competitions/${comp.id}`}>{comp.name}</Link>
          </li>
        ))}
      </ul>
    </div>
  );
}

export default CompetitionList;
