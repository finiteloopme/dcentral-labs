import toml
import os
from typing import Dict, List, Any, Optional
from pathlib import Path
from web3 import Web3
import random

class ChainManager:
    """Manages blockchain configurations loaded from chains.toml"""
    
    def __init__(self, config_path: str = None):
        if config_path is None:
            config_path = Path(__file__).parent / "chains.toml"
        
        self.config_path = config_path
        self.chains = {}
        self.categories = {}
        self.defaults = {}
        self.w3_connections = {}
        
        self._load_config()
    
    def _load_config(self):
        """Load chain configurations from TOML file"""
        try:
            with open(self.config_path, 'r') as f:
                config = toml.load(f)
            
            # Load chain configurations
            if 'chains' in config:
                self.chains = config['chains']
            
            # Load categories
            if 'categories' in config:
                self.categories = config['categories']
            
            # Load defaults
            if 'defaults' in config:
                self.defaults = config['defaults']
                
        except FileNotFoundError:
            raise Exception(f"Chain configuration file not found: {self.config_path}")
        except Exception as e:
            raise Exception(f"Error loading chain configuration: {e}")
    
    def get_chain(self, chain_name: str) -> Optional[Dict[str, Any]]:
        """Get configuration for a specific chain"""
        return self.chains.get(chain_name.lower())
    
    def get_all_chains(self, include_testnets: bool = False) -> Dict[str, Any]:
        """Get all chain configurations"""
        if include_testnets:
            return self.chains
        
        return {
            name: config for name, config in self.chains.items()
            if not config.get('is_testnet', False)
        }
    
    def get_chains_by_category(self, category: str) -> List[str]:
        """Get chains in a specific category"""
        return self.categories.get(category, [])
    
    def get_chain_rpc(self, chain_name: str, random_selection: bool = True) -> Optional[str]:
        """Get RPC URL for a chain"""
        chain = self.get_chain(chain_name)
        if not chain or 'rpc_urls' not in chain:
            return None
        
        rpc_urls = chain['rpc_urls']
        if random_selection and len(rpc_urls) > 1:
            return random.choice(rpc_urls)
        return rpc_urls[0] if rpc_urls else None
    
    def get_web3_connection(self, chain_name: str) -> Optional[Web3]:
        """Get or create Web3 connection for a chain"""
        if chain_name in self.w3_connections:
            return self.w3_connections[chain_name]
        
        rpc_url = self.get_chain_rpc(chain_name)
        if not rpc_url:
            return None
        
        try:
            w3 = Web3(Web3.HTTPProvider(rpc_url))
            if w3.is_connected():
                self.w3_connections[chain_name] = w3
                return w3
        except Exception as e:
            print(f"Failed to connect to {chain_name}: {e}")
            
        return None
    
    def get_chain_id(self, chain_name: str) -> Optional[int]:
        """Get chain ID for a specific chain"""
        chain = self.get_chain(chain_name)
        return chain.get('chain_id') if chain else None
    
    def get_native_token(self, chain_name: str) -> Optional[str]:
        """Get native token symbol for a chain"""
        chain = self.get_chain(chain_name)
        return chain.get('native_token') if chain else None
    
    def get_explorer_url(self, chain_name: str, tx_hash: str = None, address: str = None) -> Optional[str]:
        """Get explorer URL for a chain"""
        chain = self.get_chain(chain_name)
        if not chain or 'explorer' not in chain:
            return None
        
        base_url = chain['explorer']
        if tx_hash:
            return f"{base_url}/tx/{tx_hash}"
        elif address:
            return f"{base_url}/address/{address}"
        return base_url
    
    def get_supported_chains_list(self) -> List[str]:
        """Get list of all supported chain names"""
        return list(self.get_all_chains(include_testnets=False).keys())
    
    def get_high_throughput_chains(self) -> List[str]:
        """Get list of high throughput chains"""
        return self.categories.get('high_throughput', [])
    
    def get_layer2_chains(self) -> List[str]:
        """Get list of Layer 2 chains"""
        return self.categories.get('layer2', [])
    
    def validate_chain(self, chain_name: str) -> bool:
        """Check if a chain is supported"""
        return chain_name.lower() in self.chains
    
    def get_chain_info(self, chain_name: str) -> Dict[str, Any]:
        """Get formatted chain information for display"""
        chain = self.get_chain(chain_name)
        if not chain:
            return {}
        
        return {
            'name': chain.get('name'),
            'symbol': chain.get('symbol'),
            'chain_id': chain.get('chain_id'),
            'native_token': chain.get('native_token'),
            'explorer': chain.get('explorer'),
            'block_time': chain.get('block_time'),
            'is_testnet': chain.get('is_testnet', False),
            'layer': chain.get('layer', 1),
            'rpc_count': len(chain.get('rpc_urls', []))
        }
    
    def get_chains_for_protocol(self, protocol_chains: List[str]) -> List[Dict[str, Any]]:
        """Get chain configurations for chains supported by a protocol"""
        chain_configs = []
        for chain_name in protocol_chains:
            chain_info = self.get_chain_info(chain_name)
            if chain_info:
                chain_configs.append(chain_info)
        return chain_configs
    
    def reload_config(self):
        """Reload configuration from file"""
        self.chains.clear()
        self.categories.clear()
        self.defaults.clear()
        self.w3_connections.clear()
        self._load_config()

# Singleton instance
chain_manager = ChainManager()