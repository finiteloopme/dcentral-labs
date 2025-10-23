#!/usr/bin/env python3
"""
Simple example of using Gemini with the ABI Assistant MCP Server
"""

import json
import requests
import sys

# Configuration
MCP_SERVER = "http://127.0.0.1:3000"  # Use IPv4 explicitly to avoid IPv6 issues

# Choose ONE of these authentication methods:
# Option 1: API Key (easiest for testing)
GEMINI_API_KEY = "YOUR_API_KEY_HERE"  # Get from https://makersuite.google.com/app/apikey

# Option 2: Vertex AI (uncomment and configure for production)
# VERTEX_PROJECT_ID = "your-gcp-project"
# VERTEX_LOCATION = "us-central1"

def test_mcp_server():
    """Test if MCP server is running"""
    try:
        response = requests.post(f"{MCP_SERVER}/", 
            headers={"Content-Type": "application/json"},
            json={
                "jsonrpc": "2.0",
                "method": "tools/list",
                "params": {},
                "id": 1
            },
            timeout=2)
        return response.status_code == 200
    except Exception as e:
        return False

def interpret_intent(intent):
    """Use MCP server to interpret a DeFi intent"""
    response = requests.post(f"{MCP_SERVER}/", json={
        "jsonrpc": "2.0",
        "method": "tools/call",
        "params": {
            "name": "interpret_intent",
            "arguments": {"intent": intent}
        },
        "id": 1
    })
    return response.json()

def encode_function(function_name, params):
    """Encode a smart contract function call"""
    response = requests.post(f"{MCP_SERVER}/", json={
        "jsonrpc": "2.0",
        "method": "tools/call",
        "params": {
            "name": "encode_function_call",
            "arguments": {
                "function": function_name,
                "params": params
            }
        },
        "id": 1
    })
    return response.json()

def main():
    print("🚀 Gemini + MCP Server Example")
    print("==============================\n")
    
    # Check MCP server
    if not test_mcp_server():
        print("❌ MCP server not running on", MCP_SERVER)
        print("   Start it with: cd ../.. && make dev")
        sys.exit(1)
    
    print("✅ MCP server connected\n")
    
    # Example 1: Interpret intent
    print("Example 1: Interpret Intent")
    print("-" * 30)
    intent = "I want to swap 1000 USDC for ETH"
    print(f"Intent: {intent}")
    result = interpret_intent(intent)
    print(f"Result: {json.dumps(result.get('result', {}), indent=2)}\n")
    
    # Example 2: Encode function
    print("Example 2: Encode Function")
    print("-" * 30)
    print("Function: transfer(address,uint256)")
    result = encode_function("transfer", [
        "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb7",
        "1000000000000000000"
    ])
    print(f"Encoded: {result.get('result', {}).get('encoded', 'N/A')}\n")
    
    # Example 3: Using with Gemini (if configured)
    has_api_key = GEMINI_API_KEY != "YOUR_API_KEY_HERE"
    has_vertex = 'VERTEX_PROJECT_ID' in globals() and 'VERTEX_LOCATION' in globals()
    
    if has_api_key or has_vertex:
        try:
            import google.generativeai as genai  # type: ignore
            
            print("Example 3: Gemini Analysis")
            print("-" * 30)
            
            if has_api_key:
                # Use API key authentication
                genai.configure(api_key=GEMINI_API_KEY)
                model = genai.GenerativeModel('gemini-1.5-flash')
                print("Using Google AI Studio (API key)")
            else:
                # Use Vertex AI authentication
                import vertexai  # type: ignore
                from vertexai.generative_models import GenerativeModel  # type: ignore
                
                vertexai.init(project=VERTEX_PROJECT_ID, location=VERTEX_LOCATION)  # type: ignore
                model = GenerativeModel('gemini-1.5-flash')
                print(f"Using Vertex AI (Project: {VERTEX_PROJECT_ID})")  # type: ignore
            
            # Get intent interpretation
            intent_result = interpret_intent("provide liquidity to USDC-ETH pool with 10000 USDC")
            
            # Ask Gemini to explain
            prompt = f"""
            A user wants to make this DeFi transaction: {json.dumps(intent_result.get('result', {}))}
            
            Please explain:
            1. What this transaction will do
            2. Potential risks involved
            3. Estimated gas costs (assume 30 gwei gas price)
            """
            
            if has_api_key:
                response = model.generate_content(prompt)
                print(response.text)
            else:
                # Vertex AI has slightly different API
                response = model.generate_content(prompt)  # type: ignore
                print(response.text)  # type: ignore
        except ImportError as e:
            print(f"ℹ️ Missing dependencies: {e}")
            print("\nFor Google AI Studio (API key):")
            print("   pip install google-generativeai")
            print("\nFor Vertex AI:")
            print("   pip install google-cloud-aiplatform")
        except Exception as e:
            print(f"Error using Gemini: {e}")
    else:
        print("ℹ️ To use Gemini integration, choose one option:")
        print("\nOption 1: Google AI Studio (Easiest)")
        print("   1. Get API key from https://makersuite.google.com/app/apikey")
        print("   2. Replace YOUR_API_KEY_HERE in this script")
        print("   3. Install SDK: pip install google-generativeai")
        print("\nOption 2: Vertex AI (Production)")
        print("   1. Set up GCP project with Vertex AI enabled")
        print("   2. Configure VERTEX_PROJECT_ID and VERTEX_LOCATION in this script")
        print("   3. Install SDK: pip install google-cloud-aiplatform")
        print("   4. Authenticate: gcloud auth application-default login")

if __name__ == "__main__":
    main()