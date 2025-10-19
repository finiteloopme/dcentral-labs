import React, { useState, useEffect } from 'react';
import { useSearchParams } from 'react-router-dom';
import { useQuery } from 'react-query';
import axios from 'axios';
import AnalysisChart from '../components/AnalysisChart';
import RiskAssessment from '../components/RiskAssessment';
import '../styles/ProtocolAnalysis.css';

interface Analysis {
  protocol_name: string;
  protocol_id: string;
  metrics: any;
  risk_assessment: any;
  yield_opportunities: any[];
  recommendations: any;
  technical_analysis: any;
}

const ProtocolAnalysis: React.FC = () => {
  const [searchParams] = useSearchParams();
  const protocolId = searchParams.get('protocol');
  const [analysis, setAnalysis] = useState<Analysis | null>(null);
  const [showAgentCreation, setShowAgentCreation] = useState(false);

  const { data, isLoading, error } = useQuery(
    ['analysis', protocolId],
    async () => {
      if (!protocolId) return null;
      const response = await axios.get(`/api/protocols/${protocolId}/analyze`);
      return response.data;
    },
    {
      enabled: !!protocolId
    }
  );

  useEffect(() => {
    if (data) {
      setAnalysis(data);
    }
  }, [data]);

  const handleCreateAgent = async () => {
    if (!protocolId) return;
    
    try {
      const response = await axios.post('/api/agents/create', {
        protocol_id: protocolId
      });
      
      if (response.data.status === 'created') {
        alert(`Agent created successfully! Agent ID: ${response.data.agent_id}`);
        window.location.href = '/agents';
      }
    } catch (error) {
      console.error('Error creating agent:', error);
      alert('Failed to create agent');
    }
  };

  if (!protocolId) {
    return <div className="error">No protocol selected</div>;
  }

  if (isLoading) {
    return <div className="loading">Analyzing protocol...</div>;
  }

  if (error || !analysis) {
    return <div className="error">Error analyzing protocol</div>;
  }

  return (
    <div className="protocol-analysis">
      <div className="analysis-header">
        <h2>{analysis.protocol_name} Analysis</h2>
        <button 
          className="create-agent-btn"
          onClick={() => setShowAgentCreation(true)}
        >
          Create AI Agent
        </button>
      </div>

      <div className="analysis-grid">
        <div className="metrics-section">
          <h3>Key Metrics</h3>
          <div className="metrics">
            <div className="metric">
              <span className="label">TVL:</span>
              <span className="value">${(analysis.metrics.tvl / 1e9).toFixed(2)}B</span>
            </div>
            <div className="metric">
              <span className="label">Market Cap:</span>
              <span className="value">${(analysis.metrics.market_cap / 1e9).toFixed(2)}B</span>
            </div>
            <div className="metric">
              <span className="label">TVL Ratio:</span>
              <span className="value">{analysis.metrics.tvl_ratio.toFixed(2)}</span>
            </div>
            <div className="metric">
              <span className="label">Chains:</span>
              <span className="value">{analysis.metrics.chains_count}</span>
            </div>
            <div className="metric">
              <span className="label">24h Change:</span>
              <span className={`value ${analysis.metrics.daily_change > 0 ? 'positive' : 'negative'}`}>
                {analysis.metrics.daily_change.toFixed(2)}%
              </span>
            </div>
            <div className="metric">
              <span className="label">7d Change:</span>
              <span className={`value ${analysis.metrics.weekly_change > 0 ? 'positive' : 'negative'}`}>
                {analysis.metrics.weekly_change.toFixed(2)}%
              </span>
            </div>
          </div>
        </div>

        <RiskAssessment assessment={analysis.risk_assessment} />

        <div className="yield-section">
          <h3>Yield Opportunities</h3>
          <div className="opportunities">
            {analysis.yield_opportunities.map((opp: any, index: number) => (
              <div key={index} className="opportunity-card">
                <h4>{opp.type}</h4>
                <p>{opp.description}</p>
                <div className="opp-details">
                  <span>APY: {opp.estimated_apy}</span>
                  <span className={`risk-badge ${opp.risk_level.toLowerCase()}`}>
                    {opp.risk_level}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="recommendations-section">
          <h3>Recommendations</h3>
          <div className="recommendations">
            <div>
              <h4>Suitable For:</h4>
              <ul>
                {analysis.recommendations.suitable_for.map((item: string, index: number) => (
                  <li key={index}>{item}</li>
                ))}
              </ul>
            </div>
            {analysis.recommendations.strategies.length > 0 && (
              <div>
                <h4>Strategies:</h4>
                <ul>
                  {analysis.recommendations.strategies.map((item: string, index: number) => (
                    <li key={index}>{item}</li>
                  ))}
                </ul>
              </div>
            )}
            {analysis.recommendations.warnings.length > 0 && (
              <div className="warnings">
                <h4>Warnings:</h4>
                <ul>
                  {analysis.recommendations.warnings.map((item: string, index: number) => (
                    <li key={index}>{item}</li>
                  ))}
                </ul>
              </div>
            )}
          </div>
        </div>
      </div>

      {showAgentCreation && (
        <div className="modal">
          <div className="modal-content">
            <h3>Create AI Agent for {analysis.protocol_name}</h3>
            <p>This will create an autonomous agent capable of:</p>
            <ul>
              <li>Monitoring yield opportunities</li>
              <li>Executing DeFi strategies</li>
              <li>Managing positions</li>
              <li>Providing real-time analysis</li>
            </ul>
            <div className="modal-actions">
              <button onClick={handleCreateAgent} className="confirm-btn">
                Create Agent
              </button>
              <button onClick={() => setShowAgentCreation(false)} className="cancel-btn">
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default ProtocolAnalysis;