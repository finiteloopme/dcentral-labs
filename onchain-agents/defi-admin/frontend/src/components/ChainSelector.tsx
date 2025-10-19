import React, { useState, useEffect } from 'react';
import axios from 'axios';
import '../styles/ChainSelector.css';

interface Chain {
  id: string;
  name: string;
  chain_id: number;
  symbol: string;
  native_token: string;
  is_testnet: boolean;
  explorer: string;
  layer: number;
}

interface ChainSelectorProps {
  selectedChain: string;
  onChainSelect: (chain: string) => void;
  includeTestnets?: boolean;
  showCategories?: boolean;
}

const ChainSelector: React.FC<ChainSelectorProps> = ({
  selectedChain,
  onChainSelect,
  includeTestnets = false,
  showCategories = false
}) => {
  const [chains, setChains] = useState<Chain[]>([]);
  const [categories, setCategories] = useState<Record<string, string[]>>({});
  const [loading, setLoading] = useState(true);
  const [selectedCategory, setSelectedCategory] = useState<string>('all');

  useEffect(() => {
    fetchChains();
    if (showCategories) {
      fetchCategories();
    }
  }, [includeTestnets, showCategories]);

  const fetchChains = async () => {
    try {
      const response = await axios.get('/api/chains/list', {
        params: { include_testnets: includeTestnets }
      });
      setChains(response.data.chains);
      setLoading(false);
    } catch (error) {
      console.error('Error fetching chains:', error);
      setLoading(false);
    }
  };

  const fetchCategories = async () => {
    try {
      const response = await axios.get('/api/chains/categories');
      setCategories(response.data);
    } catch (error) {
      console.error('Error fetching categories:', error);
    }
  };

  const getFilteredChains = () => {
    if (selectedCategory === 'all' || !categories[selectedCategory]) {
      return chains;
    }
    return chains.filter(chain => categories[selectedCategory].includes(chain.id));
  };

  const getChainIcon = (chainId: string) => {
    const iconMap: Record<string, string> = {
      ethereum: '⟠',
      bsc: '🔶',
      polygon: '🟣',
      arbitrum: '🔵',
      optimism: '🔴',
      avalanche: '🔺',
      base: '🟦',
      sonic: '🎵',
      fantom: '👻',
      gnosis: '🦉',
      moonbeam: '🌙',
      celo: '🌿'
    };
    return iconMap[chainId] || '🔗';
  };

  if (loading) {
    return <div className="chain-selector-loading">Loading chains...</div>;
  }

  return (
    <div className="chain-selector">
      {showCategories && (
        <div className="category-tabs">
          <button
            className={selectedCategory === 'all' ? 'active' : ''}
            onClick={() => setSelectedCategory('all')}
          >
            All
          </button>
          {Object.keys(categories).map(category => (
            <button
              key={category}
              className={selectedCategory === category ? 'active' : ''}
              onClick={() => setSelectedCategory(category)}
            >
              {category.replace('_', ' ').toUpperCase()}
            </button>
          ))}
        </div>
      )}

      <div className="chain-grid">
        {getFilteredChains().map(chain => (
          <div
            key={chain.id}
            className={`chain-card ${selectedChain === chain.id ? 'selected' : ''}`}
            onClick={() => onChainSelect(chain.id)}
          >
            <div className="chain-icon">{getChainIcon(chain.id)}</div>
            <div className="chain-info">
              <div className="chain-name">{chain.name}</div>
              <div className="chain-details">
                <span className="chain-id">ID: {chain.chain_id}</span>
                <span className="chain-token">{chain.native_token}</span>
                {chain.layer === 2 && <span className="layer-badge">L2</span>}
                {chain.is_testnet && <span className="testnet-badge">Testnet</span>}
              </div>
            </div>
            <a
              href={chain.explorer}
              target="_blank"
              rel="noopener noreferrer"
              className="explorer-link"
              onClick={(e) => e.stopPropagation()}
            >
              🔍
            </a>
          </div>
        ))}
      </div>

      <div className="chain-stats">
        <span>Total Chains: {chains.length}</span>
        {selectedCategory !== 'all' && (
          <span>Filtered: {getFilteredChains().length}</span>
        )}
      </div>
    </div>
  );
};

export default ChainSelector;