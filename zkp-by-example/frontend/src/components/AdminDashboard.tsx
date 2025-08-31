import { useState } from 'react';
import config from '../config';

interface AdminDashboardProps {
  onCompetitionCreated: () => void;
}

/**
 * A component for the admin dashboard.
 *
 * This component provides functionality for admins to create new competitions.
 */
function AdminDashboard({ onCompetitionCreated }: AdminDashboardProps) {
  const [competitionName, setCompetitionName] = useState('');

  /**
   * Creates a new competition.
   *
   * This function is called when the admin clicks the "Create Competition" button.
   * It sends a request to the backend to create a new competition.
   * The backend will generate a new Sudoku puzzle for the competition.
   */
  const createCompetition = () => {
    fetch(`${config.backendUrl}${config.api.admin.competitions}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ name: competitionName }),
    })
    .then(() => {
        setCompetitionName('');
        onCompetitionCreated();
    });
  };

  const handleKeyDown = (event: React.KeyboardEvent<HTMLInputElement>) => {
    if (event.key === 'Enter') {
      createCompetition();
    }
  };

  return (
    <div>
      <h3>Admin Dashboard</h3>
      <input
        type="text"
        value={competitionName}
        onChange={e => setCompetitionName(e.target.value)}
        onKeyDown={handleKeyDown}
        placeholder="Competition Name"
      />
      <button onClick={createCompetition}>Create Competition</button>
    </div>
  );
}

export default AdminDashboard;
