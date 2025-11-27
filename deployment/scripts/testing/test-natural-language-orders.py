#!/usr/bin/env python3
"""
Test natural language order processing through Bedrock Agent
"""

import boto3
import json
import time
import sys

bedrock_agent = boto3.client('bedrock-agent-runtime')

# Use the restaurant AI agent with MCP
AGENT_ID = '8QUIMAX5VS'  # restaurant-ai-agent-mcp
AGENT_ALIAS_ID = 'TSTALIASID'

def invoke_agent(prompt, session_id=None):
    """Invoke agent with natural language prompt"""
    if not session_id:
        session_id = f"test-{int(time.time())}"
    
    print(f"\n{'='*60}")
    print(f"USER: {prompt}")
    print(f"{'='*60}")
    
    try:
        response = bedrock_agent.invoke_agent(
            agentId=AGENT_ID,
            agentAliasId=AGENT_ALIAS_ID,
            sessionId=session_id,
            inputText=prompt
        )
        
        # Collect response chunks
        full_response = ""
        for event in response['completion']:
            if 'chunk' in event:
                chunk = event['chunk']
                if 'bytes' in chunk:
                    text = chunk['bytes'].decode('utf-8')
                    full_response += text
        
        print(f"\nAGENT: {full_response}")
        print(f"{'='*60}\n")
        
        return full_response, session_id
        
    except Exception as e:
        print(f"\n❌ Error: {e}\n")
        return None, session_id

def test_order_sequence():
    """Test natural language order sequence"""
    print("\n" + "╔" + "="*58 + "╗")
    print("║  Natural Language Order Processing Test                  ║")
    print("╚" + "="*58 + "╝\n")
    
    session_id = f"order-test-{int(time.time())}"
    
    # Sequence of natural language requests
    prompts = [
        # Step 1: Check inventory status
        "What's the current inventory status? Show me items that are low on stock.",
        
        # Step 2: Ask for recommendations
        "What items need to be reordered? Show me the recommendations.",
        
        # Step 3: Request specific item details
        "Tell me more about the beef patties inventory at AFC-008. How much do we have and what's the reorder point?",
        
        # Step 4: Place an order
        "I want to order 500 units of beef patties for AFC-008. Can you process this order?",
        
        # Step 5: Verify order
        "Did the order go through? What's the new inventory level for beef patties at AFC-008?"
    ]
    
    results = []
    
    for i, prompt in enumerate(prompts, 1):
        print(f"\n{'#'*60}")
        print(f"# Step {i}/{len(prompts)}")
        print(f"{'#'*60}")
        
        response, session_id = invoke_agent(prompt, session_id)
        
        if response:
            results.append({
                'step': i,
                'prompt': prompt,
                'response': response,
                'success': True
            })
        else:
            results.append({
                'step': i,
                'prompt': prompt,
                'response': None,
                'success': False
            })
        
        # Wait between requests
        time.sleep(2)
    
    # Summary
    print("\n" + "╔" + "="*58 + "╗")
    print("║  Test Summary                                            ║")
    print("╚" + "="*58 + "╝\n")
    
    successful = sum(1 for r in results if r['success'])
    print(f"Total Steps: {len(results)}")
    print(f"Successful: {successful}")
    print(f"Failed: {len(results) - successful}")
    print()
    
    for result in results:
        status = "✅" if result['success'] else "❌"
        print(f"{status} Step {result['step']}: {result['prompt'][:50]}...")
    
    print("\n" + "="*60 + "\n")
    
    return 0 if successful == len(results) else 1

if __name__ == '__main__':
    try:
        exit(test_order_sequence())
    except KeyboardInterrupt:
        print("\n\nTest interrupted by user")
        exit(1)
