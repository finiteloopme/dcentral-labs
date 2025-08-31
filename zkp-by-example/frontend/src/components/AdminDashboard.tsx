import { useState } from 'react';
import config from '../config';

/**
 * A component for the admin dashboard.
 *
 * This component provides functionality for admins to create new competitions.
 */
function AdminDashboard() {
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
    });
  };

  return (
    <div>
      <h3>Admin Dashboard</h3>
      <input
        type="text"
        value={competitionName}
        onChange={e => setCompetitionName(e.target.value)}
        placeholder="Competition Name"
      />
      <button onClick={createCompetition}>Create Competition</button>
    </div>
  );
}

export default AdminDashboard;
