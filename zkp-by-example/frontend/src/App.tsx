import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import HomePage from './pages/HomePage';
import GamePage from './pages/GamePage';
import AdminPage from './pages/AdminPage';
import Layout from './components/Layout';
import './App.css';

function App() {
  return (
    <Router>
      <Routes>
        <Route element={<Layout />}>
          <Route path="/" element={<HomePage />} />
          <Route path="/competitions/:competitionId" element={<GamePage />} />
          <Route path="/admin" element={<AdminPage />} />
        </Route>
      </Routes>
    </Router>
  );
}

export default App;
