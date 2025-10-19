from fastapi import APIRouter, HTTPException, Body
from typing import Dict, Any, List
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from protocols.discovery import ProtocolDiscovery
from protocols.analyzer import ProtocolAnalyzer

router = APIRouter()
discovery = ProtocolDiscovery()
analyzer = ProtocolAnalyzer()

@router.post("/yield-opportunities")
async def find_yield_opportunities(
    min_apy: float = Body(5.0, description="Minimum APY threshold"),
    max_risk: float = Body(0.5, description="Maximum risk score"),
    chains: List[str] = Body(["ethereum"], description="Chains to search")
) -> List[Dict[str, Any]]:
    """Find yield opportunities across protocols"""
    try:
        opportunities = []
        
        for chain in chains:
            protocols = await discovery.fetch_protocols(chain)
            
            for protocol in protocols[:10]:
                protocol_details = await discovery.get_protocol_details(protocol['id'])
                if protocol_details:
                    analysis = await analyzer.analyze_protocol(protocol_details)
                    
                    if analysis['risk_assessment']['score'] <= max_risk:
                        for opp in analysis['yield_opportunities']:
                            apy_str = opp.get('estimated_apy', '0%')
                            min_apy_value = float(apy_str.split('-')[0].replace('%', ''))
                            
                            if min_apy_value >= min_apy:
                                opportunities.append({
                                    'protocol': protocol['name'],
                                    'chain': chain,
                                    'opportunity': opp,
                                    'risk_score': analysis['risk_assessment']['score']
                                })
        
        return sorted(opportunities, key=lambda x: x['risk_score'])
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/risk-assessment")
async def assess_portfolio_risk(
    protocols: List[str] = Body(..., description="List of protocol IDs")
) -> Dict[str, Any]:
    """Assess risk for a portfolio of protocols"""
    try:
        portfolio_analysis = {
            'total_protocols': len(protocols),
            'risk_breakdown': [],
            'average_risk': 0,
            'recommendations': []
        }
        
        total_risk = 0
        for protocol_id in protocols:
            protocol_data = await discovery.get_protocol_details(protocol_id)
            if protocol_data:
                analysis = await analyzer.analyze_protocol(protocol_data)
                risk = analysis['risk_assessment']
                
                portfolio_analysis['risk_breakdown'].append({
                    'protocol': protocol_data['name'],
                    'risk_score': risk['score'],
                    'risk_level': risk['level']
                })
                total_risk += risk['score']
        
        if portfolio_analysis['risk_breakdown']:
            portfolio_analysis['average_risk'] = total_risk / len(portfolio_analysis['risk_breakdown'])
            
            if portfolio_analysis['average_risk'] < 0.3:
                portfolio_analysis['recommendations'].append("Portfolio has low risk profile - consider higher yield opportunities")
            elif portfolio_analysis['average_risk'] > 0.6:
                portfolio_analysis['recommendations'].append("Portfolio has high risk - consider diversifying with stable protocols")
            else:
                portfolio_analysis['recommendations'].append("Portfolio has balanced risk profile")
        
        return portfolio_analysis
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/market-overview")
async def get_market_overview() -> Dict[str, Any]:
    """Get overview of DeFi market conditions"""
    try:
        protocols = await discovery.fetch_protocols()
        
        overview = {
            'total_protocols': len(protocols),
            'total_tvl': sum(p['tvl'] for p in protocols),
            'top_categories': {},
            'chain_distribution': {},
            'market_sentiment': 'neutral'
        }
        
        for protocol in protocols:
            category = protocol.get('category', 'Other')
            if category not in overview['top_categories']:
                overview['top_categories'][category] = 0
            overview['top_categories'][category] += 1
            
            for chain in protocol.get('chains', []):
                if chain not in overview['chain_distribution']:
                    overview['chain_distribution'][chain] = 0
                overview['chain_distribution'][chain] += 1
        
        avg_change = sum(p.get('change_7d', 0) for p in protocols) / len(protocols) if protocols else 0
        if avg_change > 5:
            overview['market_sentiment'] = 'bullish'
        elif avg_change < -5:
            overview['market_sentiment'] = 'bearish'
        
        return overview
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))