import React from 'react';
import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from 'react-query';
import ProtocolDiscovery from './pages/ProtocolDiscovery';
import ProtocolAnalysis from './pages/ProtocolAnalysis';
import AgentDashboard from './pages/AgentDashboard';
import './App.css';

const queryClient = new QueryClient();

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <Router>
        <div className="App">
          <nav className="navbar">
            <h1>DeFi Admin</h1>
            <div className="nav-links">
              <Link to="/">Discover</Link>
              <Link to="/analysis">Analysis</Link>
              <Link to="/agents">Agents</Link>
            </div>
          </nav>
          
          <main className="main-content">
            <Routes>
              <Route path="/" element={<ProtocolDiscovery />} />
              <Route path="/analysis" element={<ProtocolAnalysis />} />
              <Route path="/agents" element={<AgentDashboard />} />
            </Routes>
          </main>
        </div>
      </Router>
    </QueryClientProvider>
  );
}

export default App;