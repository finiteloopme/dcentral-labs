from fastapi import APIRouter, HTTPException, Query
from typing import List, Dict, Any, Optional
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from protocols.discovery import ProtocolDiscovery
from protocols.analyzer import ProtocolAnalyzer

router = APIRouter()
discovery = ProtocolDiscovery()
analyzer = ProtocolAnalyzer()

@router.get("/discover")
async def discover_protocols(
    chain: Optional[str] = Query(None, description="Filter by blockchain"),
    limit: int = Query(20, description="Number of protocols to return")
) -> List[Dict[str, Any]]:
    """Discover top DeFi protocols"""
    try:
        protocols = await discovery.fetch_protocols(chain)
        return protocols[:limit]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/search")
async def search_protocols(
    query: str = Query(..., description="Search query"),
    min_tvl: Optional[float] = Query(None, description="Minimum TVL filter"),
    category: Optional[str] = Query(None, description="Protocol category filter"),
    chain: Optional[str] = Query(None, description="Chain filter")
) -> List[Dict[str, Any]]:
    """Search for specific protocols"""
    try:
        filters = {}
        if min_tvl:
            filters['min_tvl'] = min_tvl
        if category:
            filters['category'] = category
        if chain:
            filters['chain'] = chain
            
        results = await discovery.search_protocols(query, filters)
        return results
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{protocol_id}")
async def get_protocol_details(protocol_id: str) -> Dict[str, Any]:
    """Get detailed information about a specific protocol"""
    try:
        details = await discovery.get_protocol_details(protocol_id)
        if not details:
            raise HTTPException(status_code=404, detail="Protocol not found")
        return details
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{protocol_id}/analyze")
async def analyze_protocol(protocol_id: str) -> Dict[str, Any]:
    """Get comprehensive analysis of a protocol"""
    try:
        protocol_data = await discovery.get_protocol_details(protocol_id)
        if not protocol_data:
            raise HTTPException(status_code=404, detail="Protocol not found")
        
        analysis = await analyzer.analyze_protocol(protocol_data)
        return analysis
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/compare")
async def compare_protocols(protocol_ids: List[str]) -> Dict[str, Any]:
    """Compare multiple protocols"""
    try:
        if len(protocol_ids) > 5:
            raise HTTPException(status_code=400, detail="Maximum 5 protocols can be compared")
        
        protocols = []
        for protocol_id in protocol_ids:
            protocol_data = await discovery.get_protocol_details(protocol_id)
            if protocol_data:
                protocols.append(protocol_data)
        
        if not protocols:
            raise HTTPException(status_code=404, detail="No valid protocols found")
        
        comparison = await analyzer.compare_protocols(protocols)
        return comparison
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))