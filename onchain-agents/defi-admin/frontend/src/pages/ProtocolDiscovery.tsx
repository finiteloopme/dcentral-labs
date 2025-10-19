import React, { useState, useEffect } from 'react';
import { useQuery } from 'react-query';
import axios from 'axios';
import ProtocolCard from '../components/ProtocolCard';
import SearchBar from '../components/SearchBar';
import '../styles/ProtocolDiscovery.css';

interface Protocol {
  id: string;
  name: string;
  symbol?: string;
  chains: string[];
  tvl: number;
  category: string;
  description?: string;
  change_1d: number;
  change_7d: number;
}

const ProtocolDiscovery: React.FC = () => {
  const [selectedChain, setSelectedChain] = useState<string>('');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [protocols, setProtocols] = useState<Protocol[]>([]);

  const { data, isLoading, error } = useQuery(
    ['protocols', selectedChain],
    async () => {
      const response = await axios.get('/api/protocols/discover', {
        params: { chain: selectedChain || undefined }
      });
      return response.data;
    },
    {
      refetchInterval: 30000
    }
  );

  useEffect(() => {
    if (data) {
      setProtocols(data);
    }
  }, [data]);

  const handleSearch = async () => {
    if (searchQuery) {
      try {
        const response = await axios.get('/api/protocols/search', {
          params: { query: searchQuery, chain: selectedChain || undefined }
        });
        setProtocols(response.data);
      } catch (error) {
        console.error('Search error:', error);
      }
    }
  };

  const [availableChains, setAvailableChains] = useState<string[]>([]);

  // Fetch available chains
  useEffect(() => {
    const fetchChains = async () => {
      try {
        const response = await axios.get('/api/chains/list');
        const chainNames = response.data.chains.map((c: any) => c.id);
        setAvailableChains(chainNames);
      } catch (error) {
        console.error('Error fetching chains:', error);
        // Fallback to default chains
        setAvailableChains(['ethereum', 'bsc', 'polygon', 'arbitrum', 'optimism', 'avalanche', 'base', 'sonic']);
      }
    };
    fetchChains();
  }, []);

  return (
    <div className="protocol-discovery">
      <div className="discovery-header">
        <h2>Discover DeFi Protocols</h2>
        <p>Find and analyze the best DeFi protocols across EVM chains</p>
      </div>

      <div className="filters">
        <SearchBar
          value={searchQuery}
          onChange={setSearchQuery}
          onSearch={handleSearch}
          placeholder="Search protocols..."
        />
        
        <select
          value={selectedChain}
          onChange={(e) => setSelectedChain(e.target.value)}
          className="chain-selector"
        >
          <option value="">All Chains</option>
          {availableChains.map(chain => (
            <option key={chain} value={chain}>
              {chain.charAt(0).toUpperCase() + chain.slice(1)}
            </option>
          ))}
        </select>
      </div>

      {isLoading && <div className="loading">Loading protocols...</div>}
      {error && <div className="error">Error loading protocols</div>}

      <div className="protocols-grid">
        {protocols.map(protocol => (
          <ProtocolCard
            key={protocol.id}
            protocol={protocol}
            onAnalyze={() => window.location.href = `/analysis?protocol=${protocol.id}`}
          />
        ))}
      </div>
    </div>
  );
};

export default ProtocolDiscovery;