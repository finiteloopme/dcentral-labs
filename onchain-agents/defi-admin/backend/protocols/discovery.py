import aiohttp
import asyncio
from typing import List, Dict, Any, Optional
from datetime import datetime
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from config.chain_manager import chain_manager

class ProtocolDiscovery:
    def __init__(self):
        self.defillama_api = "https://api.llama.fi"
        self.chain_manager = chain_manager
        self.chains = self.chain_manager.get_supported_chains_list()
        
    async def fetch_protocols(self, chain: str = None) -> List[Dict[str, Any]]:
        """Fetch DeFi protocols from DefiLlama API"""
        async with aiohttp.ClientSession() as session:
            try:
                async with session.get(f"{self.defillama_api}/protocols") as response:
                    if response.status == 200:
                        data = await response.json()
                        protocols = []
                        
                        for protocol in data:
                            if chain and chain.lower() not in [c.lower() for c in protocol.get('chains', [])]:
                                continue
                                
                            protocols.append({
                                'id': protocol.get('id'),
                                'name': protocol.get('name'),
                                'symbol': protocol.get('symbol'),
                                'chains': protocol.get('chains', []),
                                'tvl': protocol.get('tvl', 0),
                                'category': protocol.get('category'),
                                'description': protocol.get('description'),
                                'url': protocol.get('url'),
                                'logo': protocol.get('logo'),
                                'mcap': protocol.get('mcap', 0),
                                'change_1d': protocol.get('change_1d', 0),
                                'change_7d': protocol.get('change_7d', 0)
                            })
                        
                        return sorted(protocols, key=lambda x: x['tvl'], reverse=True)[:20]
                    else:
                        return []
            except Exception as e:
                print(f"Error fetching protocols: {e}")
                return []
    
    async def get_protocol_details(self, protocol_id: str) -> Dict[str, Any]:
        """Get detailed information about a specific protocol"""
        async with aiohttp.ClientSession() as session:
            try:
                async with session.get(f"{self.defillama_api}/protocol/{protocol_id}") as response:
                    if response.status == 200:
                        data = await response.json()
                        return {
                            'id': data.get('id'),
                            'name': data.get('name'),
                            'symbol': data.get('symbol'),
                            'chains': data.get('chains', []),
                            'tvl': data.get('tvl', []),
                            'treasury': data.get('treasury', 0),
                            'description': data.get('description'),
                            'url': data.get('url'),
                            'twitter': data.get('twitter'),
                            'github': data.get('github', []),
                            'audits': data.get('audits', '0'),
                            'category': data.get('category'),
                            'gecko_id': data.get('gecko_id'),
                            'contracts': self._extract_contracts(data)
                        }
                    else:
                        return {}
            except Exception as e:
                print(f"Error fetching protocol details: {e}")
                return {}
    
    def _extract_contracts(self, protocol_data: Dict) -> Dict[str, List[str]]:
        """Extract contract addresses from protocol data"""
        contracts = {}
        for chain in protocol_data.get('chains', []):
            chain_data = protocol_data.get('chainTvls', {}).get(chain, {})
            if isinstance(chain_data, dict) and 'tokens' in chain_data:
                contracts[chain] = chain_data.get('tokens', [])
        return contracts
    
    async def search_protocols(self, query: str, filters: Dict[str, Any] = None) -> List[Dict[str, Any]]:
        """Search protocols by name or category with optional filters"""
        all_protocols = await self.fetch_protocols()
        
        results = []
        for protocol in all_protocols:
            if query.lower() in protocol['name'].lower():
                if filters:
                    if 'min_tvl' in filters and protocol['tvl'] < filters['min_tvl']:
                        continue
                    if 'category' in filters and protocol['category'] != filters['category']:
                        continue
                    if 'chain' in filters and filters['chain'] not in protocol['chains']:
                        continue
                
                results.append(protocol)
        
        return results