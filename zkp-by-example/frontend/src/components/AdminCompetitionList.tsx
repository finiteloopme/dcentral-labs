import type { Competition } from '../types';
import config from '../config';

interface AdminCompetitionListProps {
  competitions: Competition[];
  onUpdate: () => void;
}

function AdminCompetitionList({ competitions, onUpdate }: AdminCompetitionListProps) {
  const handlePause = (id: string) => {
    fetch(`${config.backendUrl}${config.api.admin.competitions}/${id}/pause`, {
      method: 'PUT',
    }).then(() => onUpdate());
  };

  const handleResume = (id: string) => {
    fetch(`${config.backendUrl}${config.api.admin.competitions}/${id}/resume`, {
      method: 'PUT',
    }).then(() => onUpdate());
  };

  return (
    <div>
      <h3>Competitions</h3>
      <table>
        <thead>
          <tr>
            <th>Name</th>
            <th>Status</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {competitions.map(comp => (
            <tr key={comp.id}>
              <td>{comp.name}</td>
              <td>{comp.is_paused ? 'Paused' : 'Active'}</td>
              <td>
                {comp.is_paused ? (
                  <button onClick={() => handleResume(comp.id)}>Resume</button>
                ) : (
                  <button onClick={() => handlePause(comp.id)}>Pause</button>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default AdminCompetitionList;
