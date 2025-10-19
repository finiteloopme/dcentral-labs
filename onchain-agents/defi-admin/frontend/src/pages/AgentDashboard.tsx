import React, { useState, useEffect } from 'react';
import { useQuery } from 'react-query';
import axios from 'axios';
import AgentCard from '../components/AgentCard';
import '../styles/AgentDashboard.css';

interface Agent {
  id: string;
  protocol: string;
  category: string;
  active: boolean;
  capabilities: {
    protocol: string;
    category: string;
    supported_chains: string[];
    available_strategies: string[];
  };
}

const AgentDashboard: React.FC = () => {
  const [agents, setAgents] = useState<Agent[]>([]);
  const [selectedAgent, setSelectedAgent] = useState<Agent | null>(null);
  const [strategyParams, setStrategyParams] = useState<any>({
    strategy: '',
    asset: 'USDC',
    amount: 1000,
    chain: 'ethereum'
  });

  const { data, isLoading, refetch } = useQuery(
    'agents',
    async () => {
      const response = await axios.get('/api/agents/list');
      return response.data;
    },
    {
      refetchInterval: 10000
    }
  );

  useEffect(() => {
    if (data) {
      setAgents(data);
    }
  }, [data]);

  const handleExecuteStrategy = async () => {
    if (!selectedAgent || !strategyParams.strategy) return;

    try {
      const response = await axios.post(
        `/api/agents/${selectedAgent.id}/execute`,
        {
          strategy: strategyParams.strategy,
          params: {
            asset: strategyParams.asset,
            amount: strategyParams.amount,
            chain: strategyParams.chain
          }
        }
      );

      alert(`Strategy executed: ${JSON.stringify(response.data, null, 2)}`);
    } catch (error) {
      console.error('Error executing strategy:', error);
      alert('Failed to execute strategy');
    }
  };

  const handleGenerateCode = async (protocolId: string) => {
    try {
      const response = await axios.post('/api/agents/generate-code', {
        protocol_id: protocolId
      });

      const blob = new Blob([response.data.code], { type: 'text/plain' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `${response.data.protocol.replace(' ', '_')}_agent.py`;
      a.click();
    } catch (error) {
      console.error('Error generating code:', error);
      alert('Failed to generate agent code');
    }
  };

  return (
    <div className="agent-dashboard">
      <div className="dashboard-header">
        <h2>AI Agent Dashboard</h2>
        <p>Manage and monitor your DeFi protocol agents</p>
        <button onClick={() => refetch()} className="refresh-btn">
          Refresh
        </button>
      </div>

      {isLoading && <div className="loading">Loading agents...</div>}

      {agents.length === 0 && !isLoading && (
        <div className="no-agents">
          <p>No agents created yet.</p>
          <p>Go to Protocol Discovery to analyze protocols and create agents.</p>
        </div>
      )}

      <div className="agents-grid">
        {agents.map(agent => (
          <AgentCard
            key={agent.id}
            agent={agent}
            onSelect={() => setSelectedAgent(agent)}
            onGenerateCode={() => handleGenerateCode(agent.protocol)}
          />
        ))}
      </div>

      {selectedAgent && (
        <div className="agent-control-panel">
          <h3>Control Panel: {selectedAgent.protocol}</h3>
          
          <div className="capabilities">
            <h4>Capabilities</h4>
            <div className="capability-list">
              <p><strong>Category:</strong> {selectedAgent.capabilities.category}</p>
              <p><strong>Chains:</strong> {selectedAgent.capabilities.supported_chains.join(', ')}</p>
              <p><strong>Strategies:</strong></p>
              <ul>
                {selectedAgent.capabilities.available_strategies.map((strategy, index) => (
                  <li key={index}>{strategy}</li>
                ))}
              </ul>
            </div>
          </div>

          <div className="strategy-executor">
            <h4>Execute Strategy</h4>
            <div className="strategy-form">
              <select
                value={strategyParams.strategy}
                onChange={(e) => setStrategyParams({ ...strategyParams, strategy: e.target.value })}
              >
                <option value="">Select Strategy</option>
                {selectedAgent.capabilities.available_strategies.map(strategy => (
                  <option key={strategy} value={strategy}>{strategy}</option>
                ))}
              </select>

              <input
                type="text"
                placeholder="Asset"
                value={strategyParams.asset}
                onChange={(e) => setStrategyParams({ ...strategyParams, asset: e.target.value })}
              />

              <input
                type="number"
                placeholder="Amount"
                value={strategyParams.amount}
                onChange={(e) => setStrategyParams({ ...strategyParams, amount: parseFloat(e.target.value) })}
              />

              <select
                value={strategyParams.chain}
                onChange={(e) => setStrategyParams({ ...strategyParams, chain: e.target.value })}
              >
                {selectedAgent.capabilities.supported_chains.map(chain => (
                  <option key={chain} value={chain}>{chain}</option>
                ))}
              </select>

              <button onClick={handleExecuteStrategy} className="execute-btn">
                Execute (Simulation)
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default AgentDashboard;