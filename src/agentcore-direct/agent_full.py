"""
Restaurant Operations Agent - Direct Code Deploy
Full agent with inventory, staffing, equipment, and ticket management
"""

from bedrock_agentcore.runtime import BedrockAgentCoreApp
from strands import Agent
import boto3
import os
from datetime import datetime, date, timedelta
from decimal import Decimal
import json

app = BedrockAgentCoreApp()
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')

SYSTEM_PROMPT = """You are a restaurant operations AI assistant managing 10 Georgia restaurant locations.

You help managers with:
- Equipment monitoring and maintenance
- Inventory tracking and reorder management
- Staffing schedule and gap analysis
- Ticket management and resolution

Use the available tools to query data and provide actionable insights."""

# Equipment Tools
def get_equipment_status(restaurant_id: str = None) -> str:
    """Get equipment status for restaurants"""
    table = dynamodb.Table('rest-monitor-equipment-readings-prod')
    if restaurant_id:
        response = table.query(KeyConditionExpression='restaurant_id = :rid', ExpressionAttributeValues={':rid': restaurant_id})
    else:
        response = table.scan()
    
    items = response.get('Items', [])
    critical = [i for i in items if i.get('status') == 'critical']
    warning = [i for i in items if i.get('status') == 'warning']
    
    summary = f"Equipment Status:\n- Critical: {len(critical)}\n- Warning: {len(warning)}\n- OK: {len(items) - len(critical) - len(warning)}\n"
    
    if critical:
        summary += "\nCritical Equipment:\n"
        for item in critical[:5]:
            summary += f"  • {item.get('equipment_name', 'Unknown')} at {item['restaurant_id']}: {item.get('temperature', 'N/A')}°F\n"
    
    return summary

# Inventory Tools
def get_inventory_status(restaurant_id: str = None) -> str:
    """Get inventory status"""
    table = dynamodb.Table('rest-monitor-inventory-items-prod')
    if restaurant_id:
        response = table.query(KeyConditionExpression='restaurant_id = :rid', ExpressionAttributeValues={':rid': restaurant_id})
    else:
        response = table.scan()
    
    items = response.get('Items', [])
    critical = [i for i in items if float(i.get('current_quantity', 0)) < float(i.get('reorder_point', 0)) * 0.5]
    low = [i for i in items if float(i.get('reorder_point', 0)) * 0.5 <= float(i.get('current_quantity', 0)) < float(i.get('reorder_point', 0))]
    
    summary = f"Inventory Status:\n- Critical: {len(critical)}\n- Low: {len(low)}\n- OK: {len(items) - len(critical) - len(low)}\n"
    
    if critical:
        summary += "\nCritical Items:\n"
        for item in critical[:5]:
            summary += f"  • {item['item_name']} at {item['restaurant_id']}: {item['current_quantity']} {item['unit']}\n"
    
    return summary

# Staffing Tools
def get_staffing_status(restaurant_id: str = None) -> str:
    """Get staffing status and gaps"""
    req_table = dynamodb.Table('rest-monitor-staffing-requirements-prod')
    sched_table = dynamodb.Table('rest-monitor-staffing-schedule-prod')
    today = date.today().isoformat()
    
    if restaurant_id:
        req_response = req_table.query(
            KeyConditionExpression='restaurant_id = :rid',
            FilterExpression='shift_date = :date',
            ExpressionAttributeValues={':rid': restaurant_id, ':date': today}
        )
        sched_response = sched_table.query(
            KeyConditionExpression='restaurant_id = :rid',
            FilterExpression='shift_date = :date',
            ExpressionAttributeValues={':rid': restaurant_id, ':date': today}
        )
    else:
        req_response = req_table.scan(FilterExpression='shift_date = :date', ExpressionAttributeValues={':date': today})
        sched_response = sched_table.scan(FilterExpression='shift_date = :date', ExpressionAttributeValues={':date': today})
    
    requirements = req_response.get('Items', [])
    scheduled = sched_response.get('Items', [])
    
    total_required = sum(int(r.get('required_count', 0)) for r in requirements)
    total_scheduled = len(scheduled)
    gap = total_required - total_scheduled
    coverage = (total_scheduled / total_required * 100) if total_required > 0 else 100
    
    summary = f"Staffing Status (Today):\n"
    summary += f"- Required: {total_required}\n"
    summary += f"- Scheduled: {total_scheduled}\n"
    summary += f"- Gap: {gap}\n"
    summary += f"- Coverage: {coverage:.1f}%\n"
    
    if gap > 0:
        summary += f"\n⚠️ Staffing shortage of {gap} positions"
    
    return summary

# Ticket Tools
def get_tickets(restaurant_id: str = None, status: str = None) -> str:
    """Get maintenance tickets"""
    table = dynamodb.Table('rest-monitor-tickets-prod')
    
    if restaurant_id:
        response = table.scan(FilterExpression='restaurant_id = :rid', ExpressionAttributeValues={':rid': restaurant_id})
    else:
        response = table.scan()
    
    tickets = response.get('Items', [])
    
    if status:
        tickets = [t for t in tickets if t.get('status') == status]
    
    open_tickets = [t for t in tickets if t.get('status') == 'open']
    
    summary = f"Tickets:\n- Total: {len(tickets)}\n- Open: {len(open_tickets)}\n"
    
    if open_tickets:
        summary += "\nOpen Tickets:\n"
        for ticket in open_tickets[:5]:
            summary += f"  • {ticket.get('ticket_id')}: {ticket.get('description', 'No description')}\n"
    
    return summary

# Restaurant Overview
def get_restaurant_overview(restaurant_id: str) -> str:
    """Get complete overview of a restaurant"""
    table = dynamodb.Table('rest-monitor-restaurants-prod')
    response = table.get_item(Key={'id': restaurant_id})
    
    if 'Item' not in response:
        return f"Restaurant {restaurant_id} not found"
    
    restaurant = response['Item']
    
    # Get status from other tools
    equipment = get_equipment_status(restaurant_id)
    inventory = get_inventory_status(restaurant_id)
    staffing = get_staffing_status(restaurant_id)
    tickets = get_tickets(restaurant_id, 'open')
    
    summary = f"Restaurant: {restaurant.get('name', 'Unknown')}\n"
    summary += f"Location: {restaurant.get('location', 'Unknown')}\n"
    summary += f"Status: {restaurant.get('status', 'Unknown')}\n\n"
    summary += f"{equipment}\n{inventory}\n{staffing}\n{tickets}"
    
    return summary

@app.entrypoint
def invoke(payload, context):
    """Main entry point"""
    user_message = payload.get("prompt", "")
    session_id = payload.get("sessionId")
    
    # Create agent with all tools
    agent = Agent(
        model="anthropic.claude-3-sonnet-20240229-v1:0",
        system_prompt=SYSTEM_PROMPT,
        tools=[
            get_equipment_status,
            get_inventory_status,
            get_staffing_status,
            get_tickets,
            get_restaurant_overview
        ]
    )
    
    result = agent(user_message)
    
    return {
        "response": str(result),
        "sessionId": session_id or f"session-{datetime.now().timestamp()}"
    }

if __name__ == "__main__":
    app.run()
