from typing import Dict, Any, List
import asyncio
from datetime import datetime, timedelta

class ProtocolAnalyzer:
    def __init__(self):
        self.risk_factors = {
            'tvl': {'weight': 0.3, 'threshold': 10000000},
            'age': {'weight': 0.2, 'threshold': 180},
            'audits': {'weight': 0.25, 'threshold': 2},
            'chains': {'weight': 0.15, 'threshold': 3},
            'volatility': {'weight': 0.1, 'threshold': 0.5}
        }
    
    async def analyze_protocol(self, protocol_data: Dict[str, Any]) -> Dict[str, Any]:
        """Comprehensive analysis of a DeFi protocol"""
        analysis = {
            'protocol_name': protocol_data.get('name'),
            'protocol_id': protocol_data.get('id'),
            'timestamp': datetime.now().isoformat(),
            'metrics': await self._calculate_metrics(protocol_data),
            'risk_assessment': await self._assess_risk(protocol_data),
            'yield_opportunities': await self._identify_yield_opportunities(protocol_data),
            'recommendations': await self._generate_recommendations(protocol_data),
            'technical_analysis': await self._technical_analysis(protocol_data)
        }
        
        return analysis
    
    async def _calculate_metrics(self, protocol_data: Dict[str, Any]) -> Dict[str, Any]:
        """Calculate key performance metrics"""
        tvl = protocol_data.get('tvl', 0)
        mcap = protocol_data.get('mcap', 0)
        
        return {
            'tvl': tvl,
            'market_cap': mcap,
            'tvl_ratio': tvl / mcap if mcap > 0 else 0,
            'chains_count': len(protocol_data.get('chains', [])),
            'category': protocol_data.get('category'),
            'daily_change': protocol_data.get('change_1d', 0),
            'weekly_change': protocol_data.get('change_7d', 0),
            'treasury': protocol_data.get('treasury', 0)
        }
    
    async def _assess_risk(self, protocol_data: Dict[str, Any]) -> Dict[str, Any]:
        """Assess protocol risk level"""
        risk_score = 0
        risk_details = []
        
        tvl = protocol_data.get('tvl', 0)
        if tvl < self.risk_factors['tvl']['threshold']:
            risk_score += (1 - tvl / self.risk_factors['tvl']['threshold']) * self.risk_factors['tvl']['weight']
            risk_details.append("Low TVL indicates lower market confidence")
        
        audits = int(protocol_data.get('audits', '0'))
        if audits < self.risk_factors['audits']['threshold']:
            risk_score += (1 - audits / self.risk_factors['audits']['threshold']) * self.risk_factors['audits']['weight']
            risk_details.append(f"Limited audits ({audits}) increases smart contract risk")
        
        chains = len(protocol_data.get('chains', []))
        if chains < self.risk_factors['chains']['threshold']:
            risk_score += (1 - chains / self.risk_factors['chains']['threshold']) * self.risk_factors['chains']['weight']
            risk_details.append("Limited chain presence reduces diversification")
        
        change_7d = abs(protocol_data.get('change_7d', 0))
        if change_7d > self.risk_factors['volatility']['threshold']:
            risk_score += min(change_7d, 1) * self.risk_factors['volatility']['weight']
            risk_details.append("High volatility in recent period")
        
        risk_level = "Low" if risk_score < 0.3 else "Medium" if risk_score < 0.6 else "High"
        
        return {
            'score': round(risk_score, 2),
            'level': risk_level,
            'factors': risk_details,
            'audits_count': audits,
            'security_score': round((1 - risk_score) * 100, 1)
        }
    
    async def _identify_yield_opportunities(self, protocol_data: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Identify potential yield opportunities"""
        opportunities = []
        category = protocol_data.get('category', '').lower()
        
        if 'dex' in category:
            opportunities.append({
                'type': 'Liquidity Provision',
                'description': 'Provide liquidity to trading pairs',
                'estimated_apy': '5-30%',
                'risk_level': 'Medium',
                'requirements': 'Equal value of two tokens'
            })
        
        if 'lending' in category or 'borrowing' in category:
            opportunities.append({
                'type': 'Lending',
                'description': 'Lend assets to earn interest',
                'estimated_apy': '2-15%',
                'risk_level': 'Low-Medium',
                'requirements': 'Stablecoins or major cryptocurrencies'
            })
            opportunities.append({
                'type': 'Yield Farming',
                'description': 'Leverage lending positions for higher yields',
                'estimated_apy': '10-50%',
                'risk_level': 'High',
                'requirements': 'Understanding of leveraged positions'
            })
        
        if 'yield' in category or 'farming' in category:
            opportunities.append({
                'type': 'Staking',
                'description': 'Stake protocol tokens for rewards',
                'estimated_apy': '10-40%',
                'risk_level': 'Medium',
                'requirements': 'Protocol native tokens'
            })
        
        if 'derivatives' in category:
            opportunities.append({
                'type': 'Options Strategies',
                'description': 'Covered calls, cash-secured puts',
                'estimated_apy': '15-60%',
                'risk_level': 'High',
                'requirements': 'Advanced DeFi knowledge'
            })
        
        return opportunities
    
    async def _generate_recommendations(self, protocol_data: Dict[str, Any]) -> Dict[str, Any]:
        """Generate actionable recommendations"""
        risk_assessment = await self._assess_risk(protocol_data)
        metrics = await self._calculate_metrics(protocol_data)
        
        recommendations = {
            'suitable_for': [],
            'strategies': [],
            'warnings': [],
            'entry_points': []
        }
        
        if risk_assessment['level'] == 'Low':
            recommendations['suitable_for'].append('Conservative investors')
            recommendations['suitable_for'].append('Long-term holders')
        elif risk_assessment['level'] == 'Medium':
            recommendations['suitable_for'].append('Balanced portfolios')
            recommendations['suitable_for'].append('Experienced DeFi users')
        else:
            recommendations['suitable_for'].append('Risk-tolerant investors')
            recommendations['suitable_for'].append('Short-term traders')
        
        if metrics['tvl_ratio'] > 1:
            recommendations['strategies'].append('Protocol may be undervalued relative to TVL')
        
        if metrics['daily_change'] < -5:
            recommendations['entry_points'].append('Recent dip may present buying opportunity')
        
        if risk_assessment['audits_count'] < 2:
            recommendations['warnings'].append('Limited audits - consider smaller positions')
        
        if metrics['chains_count'] > 5:
            recommendations['strategies'].append('Multi-chain presence allows for arbitrage opportunities')
        
        return recommendations
    
    async def _technical_analysis(self, protocol_data: Dict[str, Any]) -> Dict[str, Any]:
        """Perform technical analysis on protocol metrics"""
        return {
            'trend': 'Bullish' if protocol_data.get('change_7d', 0) > 0 else 'Bearish',
            'momentum': 'Strong' if abs(protocol_data.get('change_1d', 0)) > 5 else 'Weak',
            'support_level': protocol_data.get('tvl', 0) * 0.9,
            'resistance_level': protocol_data.get('tvl', 0) * 1.1,
            'volume_analysis': 'High' if protocol_data.get('tvl', 0) > 100000000 else 'Medium' if protocol_data.get('tvl', 0) > 10000000 else 'Low'
        }
    
    async def compare_protocols(self, protocols: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Compare multiple protocols"""
        comparison = {
            'protocols': [],
            'best_tvl': None,
            'best_risk': None,
            'best_yield': None
        }
        
        for protocol in protocols:
            analysis = await self.analyze_protocol(protocol)
            comparison['protocols'].append(analysis)
        
        if comparison['protocols']:
            comparison['best_tvl'] = max(comparison['protocols'], key=lambda x: x['metrics']['tvl'])
            comparison['best_risk'] = min(comparison['protocols'], key=lambda x: x['risk_assessment']['score'])
        
        return comparison