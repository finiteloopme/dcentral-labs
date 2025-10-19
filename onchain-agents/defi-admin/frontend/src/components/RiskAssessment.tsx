import React from 'react';
import '../styles/RiskAssessment.css';

interface RiskAssessmentProps {
  assessment: {
    score: number;
    level: string;
    factors: string[];
    audits_count: number;
    security_score: number;
  };
}

const RiskAssessment: React.FC<RiskAssessmentProps> = ({ assessment }) => {
  const getRiskColor = (level: string) => {
    switch (level.toLowerCase()) {
      case 'low': return '#00ff00';
      case 'medium': return '#ffaa00';
      case 'high': return '#ff0000';
      default: return '#999999';
    }
  };

  return (
    <div className="risk-assessment">
      <h3>Risk Assessment</h3>
      <div className="risk-overview">
        <div className="risk-score">
          <div className="score-circle" style={{ borderColor: getRiskColor(assessment.level) }}>
            <span className="score-value">{(assessment.score * 100).toFixed(0)}</span>
            <span className="score-label">Risk Score</span>
          </div>
        </div>
        <div className="risk-details">
          <div className="risk-metric">
            <span className="label">Risk Level:</span>
            <span className={`value risk-${assessment.level.toLowerCase()}`}>
              {assessment.level}
            </span>
          </div>
          <div className="risk-metric">
            <span className="label">Security Score:</span>
            <span className="value">{assessment.security_score}%</span>
          </div>
          <div className="risk-metric">
            <span className="label">Audits:</span>
            <span className="value">{assessment.audits_count}</span>
          </div>
        </div>
      </div>
      
      {assessment.factors.length > 0 && (
        <div className="risk-factors">
          <h4>Risk Factors:</h4>
          <ul>
            {assessment.factors.map((factor, index) => (
              <li key={index}>{factor}</li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
};

export default RiskAssessment;