"""
Restaurant Inventory Agent - Direct Code Deploy
Handles inventory queries, low stock alerts, and purchase orders
"""

from bedrock_agentcore.runtime import BedrockAgentCoreApp
from strands import Agent
import boto3
import os
from datetime import datetime
from decimal import Decimal

app = BedrockAgentCoreApp()
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')

# System prompt
SYSTEM_PROMPT = """You are a restaurant inventory management AI assistant.

You help managers with:
- Checking inventory status across all restaurants
- Identifying low stock items
- Analyzing consumption patterns
- Creating purchase orders

When asked about inventory, use the available tools to query DynamoDB and provide clear, actionable summaries."""

# Tool: Get inventory status
def get_inventory_status(restaurant_id: str = None) -> str:
    """Get current inventory status for a restaurant or all restaurants"""
    table = dynamodb.Table('rest-monitor-inventory-items-prod')
    
    if restaurant_id:
        response = table.query(
            KeyConditionExpression='restaurant_id = :rid',
            ExpressionAttributeValues={':rid': restaurant_id}
        )
    else:
        response = table.scan()
    
    items = response.get('Items', [])
    
    # Categorize items
    critical = [i for i in items if float(i.get('current_quantity', 0)) < float(i.get('reorder_point', 0)) * 0.5]
    low = [i for i in items if float(i.get('reorder_point', 0)) * 0.5 <= float(i.get('current_quantity', 0)) < float(i.get('reorder_point', 0))]
    ok = [i for i in items if float(i.get('current_quantity', 0)) >= float(i.get('reorder_point', 0))]
    
    summary = f"Inventory Status:\n"
    summary += f"- Critical (< 50% reorder point): {len(critical)} items\n"
    summary += f"- Low (50-100% reorder point): {len(low)} items\n"
    summary += f"- OK (> reorder point): {len(ok)} items\n\n"
    
    if critical:
        summary += "Critical Items:\n"
        for item in critical[:5]:
            summary += f"  • {item['item_name']} at {item['restaurant_id']}: {item['current_quantity']} {item['unit']} (reorder at {item['reorder_point']})\n"
    
    return summary

# Tool: Get low stock items
def get_low_stock_items(restaurant_id: str = None) -> str:
    """Get items below reorder point"""
    table = dynamodb.Table('rest-monitor-inventory-items-prod')
    
    if restaurant_id:
        response = table.query(
            KeyConditionExpression='restaurant_id = :rid',
            ExpressionAttributeValues={':rid': restaurant_id}
        )
    else:
        response = table.scan()
    
    items = response.get('Items', [])
    low_items = [i for i in items if float(i.get('current_quantity', 0)) < float(i.get('reorder_point', 0))]
    
    if not low_items:
        return "No low stock items found."
    
    result = f"Low Stock Items ({len(low_items)}):\n\n"
    for item in low_items:
        result += f"Restaurant: {item['restaurant_id']}\n"
        result += f"Item: {item['item_name']}\n"
        result += f"Current: {item['current_quantity']} {item['unit']}\n"
        result += f"Reorder Point: {item['reorder_point']} {item['unit']}\n"
        result += f"Suggested Order: {item['reorder_quantity']} {item['unit']}\n\n"
    
    return result

@app.entrypoint
def invoke(payload, context):
    """Main entry point for AgentCore Runtime"""
    user_message = payload.get("prompt", "")
    session_id = payload.get("sessionId")
    
    # Create agent with inventory tools
    agent = Agent(
        model="anthropic.claude-3-sonnet-20240229-v1:0",
        system_prompt=SYSTEM_PROMPT,
        tools=[get_inventory_status, get_low_stock_items]
    )
    
    # Get agent response
    result = agent(user_message)
    
    return {
        "response": str(result),
        "sessionId": session_id or f"session-{datetime.now().timestamp()}"
    }

if __name__ == "__main__":
    app.run()
