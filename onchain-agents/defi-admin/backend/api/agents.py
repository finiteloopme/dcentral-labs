from fastapi import APIRouter, HTTPException, Body
from typing import Dict, Any, List
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from agents.agent_generator import AgentGenerator
from protocols.discovery import ProtocolDiscovery

router = APIRouter()
generator = AgentGenerator()
discovery = ProtocolDiscovery()

@router.post("/create")
async def create_agent(
    protocol_id: str = Body(..., embed=True, description="Protocol ID to create agent for")
) -> Dict[str, Any]:
    """Create an AI agent for a specific protocol"""
    try:
        protocol_data = await discovery.get_protocol_details(protocol_id)
        if not protocol_data:
            raise HTTPException(status_code=404, detail="Protocol not found")
        
        agent = await generator.create_agent(protocol_data)
        
        return {
            'status': 'created',
            'protocol': protocol_data.get('name'),
            'agent_id': f"{protocol_id}_{id(agent)}",
            'capabilities': agent.get_capabilities()
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/list")
async def list_agents() -> List[Dict[str, Any]]:
    """List all created agents"""
    try:
        return generator.list_agents()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/{agent_id}/execute")
async def execute_strategy(
    agent_id: str,
    strategy: str = Body(..., embed=True, description="Strategy type"),
    params: Dict[str, Any] = Body({}, description="Strategy parameters")
) -> Dict[str, Any]:
    """Execute a strategy using an agent"""
    try:
        agent = await generator.get_agent(agent_id)
        if not agent:
            raise HTTPException(status_code=404, detail="Agent not found")
        
        result = await agent.execute_strategy(strategy, params)
        return result
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{agent_id}/capabilities")
async def get_agent_capabilities(agent_id: str) -> Dict[str, Any]:
    """Get capabilities of a specific agent"""
    try:
        agent = await generator.get_agent(agent_id)
        if not agent:
            raise HTTPException(status_code=404, detail="Agent not found")
        
        return agent.get_capabilities()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/generate-code")
async def generate_agent_code(
    protocol_id: str = Body(..., embed=True, description="Protocol ID")
) -> Dict[str, Any]:
    """Generate standalone Python code for an agent"""
    try:
        protocol_data = await discovery.get_protocol_details(protocol_id)
        if not protocol_data:
            raise HTTPException(status_code=404, detail="Protocol not found")
        
        code = await generator.generate_agent_code(protocol_data)
        
        return {
            'protocol': protocol_data.get('name'),
            'language': 'python',
            'code': code
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))