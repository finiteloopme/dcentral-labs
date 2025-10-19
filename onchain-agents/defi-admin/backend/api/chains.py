from fastapi import APIRouter, HTTPException, Query
from typing import List, Dict, Any, Optional
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config.chain_manager import chain_manager

router = APIRouter()

@router.get("/list")
async def list_chains(
    include_testnets: bool = Query(False, description="Include testnet chains")
) -> Dict[str, Any]:
    """Get list of all supported chains"""
    try:
        chains = chain_manager.get_all_chains(include_testnets=include_testnets)
        return {
            'total': len(chains),
            'chains': [
                {
                    'id': name,
                    'name': config.get('name'),
                    'chain_id': config.get('chain_id'),
                    'symbol': config.get('symbol'),
                    'native_token': config.get('native_token'),
                    'is_testnet': config.get('is_testnet', False),
                    'explorer': config.get('explorer'),
                    'layer': config.get('layer', 1)
                }
                for name, config in chains.items()
            ]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/categories")
async def get_chain_categories() -> Dict[str, List[str]]:
    """Get chains grouped by categories"""
    try:
        return chain_manager.categories
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{chain_name}")
async def get_chain_info(chain_name: str) -> Dict[str, Any]:
    """Get detailed information about a specific chain"""
    try:
        chain_info = chain_manager.get_chain_info(chain_name)
        if not chain_info:
            raise HTTPException(status_code=404, detail=f"Chain {chain_name} not found")
        return chain_info
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{chain_name}/rpc")
async def get_chain_rpc(
    chain_name: str,
    random_selection: bool = Query(True, description="Randomly select from available RPCs")
) -> Dict[str, Any]:
    """Get RPC URL for a specific chain"""
    try:
        if not chain_manager.validate_chain(chain_name):
            raise HTTPException(status_code=404, detail=f"Chain {chain_name} not found")
        
        rpc_url = chain_manager.get_chain_rpc(chain_name, random_selection)
        if not rpc_url:
            raise HTTPException(status_code=404, detail=f"No RPC URL available for {chain_name}")
        
        return {
            'chain': chain_name,
            'rpc_url': rpc_url,
            'chain_id': chain_manager.get_chain_id(chain_name)
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{chain_name}/explorer")
async def get_explorer_url(
    chain_name: str,
    tx_hash: Optional[str] = Query(None, description="Transaction hash"),
    address: Optional[str] = Query(None, description="Address")
) -> Dict[str, Any]:
    """Get explorer URL for a chain"""
    try:
        if not chain_manager.validate_chain(chain_name):
            raise HTTPException(status_code=404, detail=f"Chain {chain_name} not found")
        
        explorer_url = chain_manager.get_explorer_url(chain_name, tx_hash, address)
        if not explorer_url:
            raise HTTPException(status_code=404, detail=f"No explorer URL available for {chain_name}")
        
        return {
            'chain': chain_name,
            'explorer_url': explorer_url,
            'type': 'transaction' if tx_hash else 'address' if address else 'home'
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/category/{category}")
async def get_chains_by_category(category: str) -> Dict[str, Any]:
    """Get chains in a specific category"""
    try:
        chains = chain_manager.get_chains_by_category(category)
        if not chains:
            raise HTTPException(status_code=404, detail=f"Category {category} not found or empty")
        
        chain_details = []
        for chain_name in chains:
            info = chain_manager.get_chain_info(chain_name)
            if info:
                chain_details.append(info)
        
        return {
            'category': category,
            'total': len(chain_details),
            'chains': chain_details
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/reload")
async def reload_chain_config() -> Dict[str, str]:
    """Reload chain configuration from file"""
    try:
        chain_manager.reload_config()
        return {'status': 'success', 'message': 'Chain configuration reloaded'}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))