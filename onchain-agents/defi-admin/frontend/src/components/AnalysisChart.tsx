import React from 'react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import '../styles/AnalysisChart.css';

interface AnalysisChartProps {
  data: any[];
  title: string;
}

const AnalysisChart: React.FC<AnalysisChartProps> = ({ data, title }) => {
  return (
    <div className="analysis-chart">
      <h3>{title}</h3>
      <ResponsiveContainer width="100%" height={300}>
        <LineChart data={data}>
          <CartesianGrid strokeDasharray="3 3" />
          <XAxis dataKey="date" />
          <YAxis />
          <Tooltip />
          <Legend />
          <Line type="monotone" dataKey="tvl" stroke="#8884d8" name="TVL" />
          <Line type="monotone" dataKey="volume" stroke="#82ca9d" name="Volume" />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
};

export default AnalysisChart;