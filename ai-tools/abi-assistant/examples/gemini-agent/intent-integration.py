#!/usr/bin/env python3
"""
Example showing how to integrate Gemini with the ABI Assistant's intent resolution system.

This demonstrates:
1. Using Gemini for natural language understanding
2. Sending intents to ABI Assistant for resolution
3. Processing the structured responses
4. Building transactions from the suggestions
"""

import os
import json
import asyncio
import aiohttp
from typing import Dict, Any, List, Optional
from dataclasses import dataclass
import google.generativeai as genai

# Configuration
MCP_SERVER = os.getenv("MCP_SERVER", "http://localhost:3000")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

@dataclass
class IntentResult:
    """Structured intent resolution result"""
    category: str
    confidence: float
    parameters: Dict[str, Any]
    suggestions: List[Dict[str, Any]]

class GeminiIntentProcessor:
    """Process DeFi intents using Gemini and ABI Assistant"""
    
    def __init__(self, gemini_api_key: str, mcp_server: str):
        self.mcp_server = mcp_server
        self.session_id = None
        
        # Configure Gemini
        genai.configure(api_key=gemini_api_key)
        self.model = genai.GenerativeModel('gemini-pro')
        
        # Prompt for intent enhancement
        self.system_prompt = """
You are a DeFi assistant that helps users clarify their intentions.
When a user provides a vague or incomplete request, help them be more specific.

For example:
- "trade tokens" -> "swap 100 USDC for ETH"
- "earn yield" -> "lend 1000 DAI to earn interest"
- "get more tokens" -> "borrow 500 USDC using ETH as collateral"

Respond with a clarified, specific intent that includes:
1. The exact action (swap, lend, borrow, stake, etc.)
2. Specific amounts and tokens
3. Any constraints (slippage, deadline, etc.)
4. Protocol preferences if mentioned

Return ONLY the clarified intent text, nothing else.
"""
    
    async def initialize_mcp_session(self) -> bool:
        """Initialize MCP session with the server"""
        async with aiohttp.ClientSession() as session:
            payload = {
                "jsonrpc": "2.0",
                "method": "initialize",
                "params": {
                    "protocolVersion": "0.1.0",
                    "capabilities": {"tools": True},
                    "clientInfo": {
                        "name": "gemini-intent-processor",
                        "version": "1.0.0"
                    }
                },
                "id": 1
            }
            
            headers = {
                "Content-Type": "application/json",
                "Accept": "application/json, text/event-stream"
            }
            
            async with session.post(
                f"{self.mcp_server}/sse/message",
                json=payload,
                headers=headers
            ) as response:
                if response.status == 200:
                    result = await response.json()
                    print(f"✓ MCP session initialized: {result}")
                    return True
                else:
                    print(f"✗ Failed to initialize MCP session: {response.status}")
                    return False
    
    async def enhance_intent_with_gemini(self, user_input: str) -> str:
        """Use Gemini to clarify and enhance user intent"""
        prompt = f"{self.system_prompt}\n\nUser request: {user_input}"
        
        response = self.model.generate_content(prompt)
        enhanced_intent = response.text.strip()
        
        print(f"Original: {user_input}")
        print(f"Enhanced: {enhanced_intent}")
        
        return enhanced_intent
    
    async def resolve_intent(self, intent_text: str) -> Optional[IntentResult]:
        """Send intent to ABI Assistant for resolution"""
        async with aiohttp.ClientSession() as session:
            payload = {
                "jsonrpc": "2.0",
                "method": "tools/call",
                "params": {
                    "name": "interpret_intent",
                    "arguments": {
                        "intent": intent_text
                    }
                },
                "id": 2
            }
            
            headers = {
                "Content-Type": "application/json",
                "Accept": "application/json, text/event-stream"
            }
            
            async with session.post(
                f"{self.mcp_server}/sse/message",
                json=payload,
                headers=headers
            ) as response:
                if response.status == 200:
                    result = await response.json()
                    
                    # Parse the response
                    if "result" in result and "content" in result["result"]:
                        content = json.loads(result["result"]["content"][0]["text"])
                        
                        return IntentResult(
                            category=content.get("category", "unknown"),
                            confidence=content.get("confidence", 0.0),
                            parameters=content.get("parameters", {}),
                            suggestions=content.get("suggestions", [])
                        )
                
                return None
    
    async def process_user_request(self, user_input: str) -> Dict[str, Any]:
        """Complete pipeline: enhance with Gemini, then resolve with ABI Assistant"""
        
        print(f"\n{'='*50}")
        print(f"Processing: {user_input}")
        print(f"{'='*50}\n")
        
        # Step 1: Enhance intent with Gemini
        print("Step 1: Enhancing intent with Gemini...")
        enhanced_intent = await self.enhance_intent_with_gemini(user_input)
        
        # Step 2: Resolve intent with ABI Assistant
        print("\nStep 2: Resolving intent with ABI Assistant...")
        result = await self.resolve_intent(enhanced_intent)
        
        if result:
            print(f"\n✓ Intent resolved successfully!")
            print(f"  Category: {result.category}")
            print(f"  Confidence: {result.confidence:.2%}")
            print(f"  Parameters: {json.dumps(result.parameters, indent=2)}")
            
            if result.suggestions:
                print(f"\n  Suggested protocols ({len(result.suggestions)}):")
                for i, suggestion in enumerate(result.suggestions, 1):
                    print(f"    {i}. {suggestion.get('protocol', 'Unknown')}")
                    print(f"       Function: {suggestion.get('function', 'N/A')}")
                    print(f"       Confidence: {suggestion.get('confidence', 0):.2%}")
                    if 'gas_estimate' in suggestion:
                        print(f"       Gas: ~{suggestion['gas_estimate']:,}")
            
            return {
                "success": True,
                "original_input": user_input,
                "enhanced_intent": enhanced_intent,
                "result": result.__dict__
            }
        else:
            print("✗ Failed to resolve intent")
            return {
                "success": False,
                "original_input": user_input,
                "enhanced_intent": enhanced_intent,
                "error": "Failed to resolve intent"
            }

async def main():
    """Main demo function"""
    
    # Check for API key
    if not GEMINI_API_KEY:
        print("Error: GEMINI_API_KEY environment variable not set")
        print("Please set it with: export GEMINI_API_KEY='your-api-key'")
        return
    
    # Create processor
    processor = GeminiIntentProcessor(GEMINI_API_KEY, MCP_SERVER)
    
    # Initialize MCP session
    if not await processor.initialize_mcp_session():
        print("Failed to initialize MCP session. Is the server running?")
        return
    
    # Test cases: from vague to specific
    test_cases = [
        # Vague requests that Gemini will enhance
        "I want to trade some tokens",
        "earn yield on my stablecoins",
        "need liquidity",
        "get more ETH",
        
        # More specific requests
        "swap my USDC for ETH with low slippage",
        "provide liquidity to earn fees",
        "stake ETH for rewards",
        
        # Complex multi-step
        "borrow against my collateral and then invest it",
    ]
    
    print("\n" + "="*60)
    print("GEMINI + ABI ASSISTANT INTENT RESOLUTION DEMO")
    print("="*60)
    
    for test_case in test_cases:
        result = await processor.process_user_request(test_case)
        
        # Save result for analysis
        filename = f"result_{test_case[:20].replace(' ', '_')}.json"
        with open(filename, 'w') as f:
            json.dump(result, f, indent=2)
        print(f"\nResult saved to: {filename}")
        
        # Wait a bit between requests
        await asyncio.sleep(1)
    
    print("\n" + "="*60)
    print("Demo complete! Check the generated JSON files for full results.")
    print("="*60)

if __name__ == "__main__":
    asyncio.run(main())