import { useState, useEffect } from 'react';
import AdminDashboard from '../components/AdminDashboard';
import AdminCompetitionList from '../components/AdminCompetitionList';
import type { Competition } from '../types';
import config from '../config';

function AdminPage() {
  const [competitions, setCompetitions] = useState<Competition[]>([]);

  useEffect(() => {
    fetchCompetitions();
  }, []);

  const fetchCompetitions = () => {
    fetch(`${config.backendUrl}${config.api.competitions}`)
      .then(response => response.json())
      .then(data => setCompetitions(data));
  };

  return (
    <div>
      <h1>Admin</h1>
      <AdminDashboard onCompetitionCreated={fetchCompetitions} />
      <AdminCompetitionList competitions={competitions} onUpdate={fetchCompetitions} />
    </div>
  );
}

export default AdminPage;