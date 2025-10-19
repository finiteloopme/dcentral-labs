import React from 'react';
import '../styles/ProtocolCard.css';

interface ProtocolCardProps {
  protocol: {
    id: string;
    name: string;
    symbol?: string;
    chains: string[];
    tvl: number;
    category: string;
    description?: string;
    change_1d: number;
    change_7d: number;
  };
  onAnalyze: () => void;
}

const ProtocolCard: React.FC<ProtocolCardProps> = ({ protocol, onAnalyze }) => {
  const formatTVL = (tvl: number) => {
    if (tvl >= 1e9) return `$${(tvl / 1e9).toFixed(2)}B`;
    if (tvl >= 1e6) return `$${(tvl / 1e6).toFixed(2)}M`;
    return `$${(tvl / 1e3).toFixed(2)}K`;
  };

  return (
    <div className="protocol-card">
      <div className="protocol-header">
        <h3>{protocol.name}</h3>
        {protocol.symbol && <span className="symbol">{protocol.symbol}</span>}
      </div>
      
      <div className="protocol-category">{protocol.category}</div>
      
      <div className="protocol-stats">
        <div className="stat">
          <span className="label">TVL:</span>
          <span className="value">{formatTVL(protocol.tvl)}</span>
        </div>
        <div className="stat">
          <span className="label">24h:</span>
          <span className={`value ${protocol.change_1d > 0 ? 'positive' : 'negative'}`}>
            {protocol.change_1d > 0 ? '+' : ''}{protocol.change_1d.toFixed(2)}%
          </span>
        </div>
        <div className="stat">
          <span className="label">7d:</span>
          <span className={`value ${protocol.change_7d > 0 ? 'positive' : 'negative'}`}>
            {protocol.change_7d > 0 ? '+' : ''}{protocol.change_7d.toFixed(2)}%
          </span>
        </div>
      </div>
      
      <div className="protocol-chains">
        {protocol.chains.slice(0, 3).map(chain => (
          <span key={chain} className="chain-badge">{chain}</span>
        ))}
        {protocol.chains.length > 3 && (
          <span className="chain-badge">+{protocol.chains.length - 3}</span>
        )}
      </div>
      
      <button className="analyze-btn" onClick={onAnalyze}>
        Analyze Protocol
      </button>
    </div>
  );
};

export default ProtocolCard;