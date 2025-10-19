import React from 'react';
import '../styles/AgentCard.css';

interface AgentCardProps {
  agent: {
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
  };
  onSelect: () => void;
  onGenerateCode: () => void;
}

const AgentCard: React.FC<AgentCardProps> = ({ agent, onSelect, onGenerateCode }) => {
  return (
    <div className="agent-card">
      <div className="agent-header">
        <h3>{agent.protocol}</h3>
        <span className={`status ${agent.active ? 'active' : 'inactive'}`}>
          {agent.active ? 'Active' : 'Inactive'}
        </span>
      </div>
      
      <div className="agent-info">
        <p><strong>Category:</strong> {agent.category}</p>
        <p><strong>Strategies:</strong> {agent.capabilities.available_strategies.length}</p>
        <p><strong>Chains:</strong> {agent.capabilities.supported_chains.length}</p>
      </div>
      
      <div className="agent-strategies">
        <h4>Available Strategies:</h4>
        <div className="strategy-tags">
          {agent.capabilities.available_strategies.map((strategy, index) => (
            <span key={index} className="strategy-tag">{strategy}</span>
          ))}
        </div>
      </div>
      
      <div className="agent-actions">
        <button onClick={onSelect} className="control-btn">
          Control Panel
        </button>
        <button onClick={onGenerateCode} className="code-btn">
          Generate Code
        </button>
      </div>
    </div>
  );
};

export default AgentCard;