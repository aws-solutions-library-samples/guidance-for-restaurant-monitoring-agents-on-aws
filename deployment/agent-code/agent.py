"""Restaurant Monitoring Agent.

Supports both:
- BedrockAgentCoreApp entrypoint for text chat (invoked via invoke_agent_runtime)
- WebSocket /ws endpoint for bidirectional voice (Nova Sonic BidiAgent)

The BedrockAgentCoreApp runs on port 8080 and handles the AgentCore protocol.
For voice, the frontend connects directly to AgentCore's WebSocket endpoint.
"""

import logging
import os
import json
import uuid
import re
from datetime import datetime
from decimal import Decimal
from typing import Optional

import boto3
from boto3.dynamodb.conditions import Attr
from strands import Agent, tool
from bedrock_agentcore.runtime import BedrockAgentCoreApp

# BidiAgent requires Python 3.12+ — import conditionally
import sys
BIDI_AVAILABLE = sys.version_info >= (3, 12)
if BIDI_AVAILABLE:
    try:
        from strands.experimental.bidi import BidiAgent
        from strands.experimental.bidi.models import BidiNovaSonicModel
    except ImportError:
        BIDI_AVAILABLE = False

logger = logging.getLogger(__name__)

app = BedrockAgentCoreApp()

# DynamoDB Table Names
RESTAURANTS_TABLE = 'restaurant-kitchen-assistant-restaurants-production'
EQUIPMENT_TABLE = 'restaurant-kitchen-assistant-equipment-readings-production'
INVENTORY_TABLE = 'restaurant-kitchen-assistant-inventory-items-prod'
STAFFING_TABLE = 'restaurant-kitchen-assistant-staffing-requirements-prod'
TICKETS_TABLE = 'restaurant-kitchen-assistant-tickets-production'

REGION = os.environ.get('AWS_REGION', 'us-east-1')

# ============================================================
# TOOLS
# ============================================================

@tool
def get_restaurants() -> dict:
    """Get all restaurants from the database"""
    dynamodb = boto3.resource('dynamodb', region_name=REGION)
    table = dynamodb.Table(RESTAURANTS_TABLE)
    response = table.scan()
    return {"status": "success", "content": [{"text": json.dumps(response.get('Items', []), default=str)}]}

@tool
def get_equipment(restaurant_id: str = None) -> dict:
    """Get equipment status for a restaurant or all restaurants"""
    dynamodb = boto3.resource('dynamodb', region_name=REGION)
    table = dynamodb.Table(EQUIPMENT_TABLE)
    if restaurant_id:
        response = table.scan(FilterExpression=Attr('restaurant_id').eq(restaurant_id))
    else:
        response = table.scan()
    return {"status": "success", "content": [{"text": json.dumps(response.get('Items', []), default=str)}]}

@tool
def analyze_temperature(equipment_id: str, current_temp: float) -> dict:
    """Analyze temperature readings for equipment"""
    specs = {
        "REF-001": {"type": "Walk-in Cooler", "normal_range": [35, 40], "critical": 45},
        "FRZ-001": {"type": "Walk-in Freezer", "normal_range": [-10, 0], "critical": 10},
        "GRILL-001": {"type": "Commercial Grill", "normal_range": [300, 500], "critical": 550},
        "FRYER-001": {"type": "Deep Fryer", "normal_range": [325, 375], "critical": 400}
    }
    s = specs.get(equipment_id, {})
    normal_range = s.get('normal_range', [0, 0])
    target = sum(normal_range) / 2
    deviation = abs(current_temp - target)
    urgency = "critical" if current_temp >= s.get('critical', 999) else "high" if deviation > 10 else "medium"
    return {"status": "success", "content": [{"text": json.dumps({"equipment_id": equipment_id, "current_temp": current_temp, "target": target, "deviation": deviation, "urgency": urgency})}]}


@tool
def get_troubleshooting(equipment_type: str) -> dict:
    """Get troubleshooting steps for equipment type"""
    guides = {
        "refrigerator": ["Check door seals", "Verify thermostat", "Clean coils", "Move perishables if >45F"],
        "freezer": ["Check door seal", "Verify thermostat", "Move items if >10F"],
        "grill": ["Check gas supply", "Inspect flames", "Evacuate if gas smell"],
        "fryer": ["Check oil level", "Verify thermostat", "Never add water to hot oil"]
    }
    steps = guides.get(equipment_type.lower(), ["Check power", "Verify connections"])
    return {"status": "success", "content": [{"text": json.dumps({"steps": steps})}]}

@tool
def get_inventory(restaurant_id: str = None) -> dict:
    """Get inventory status for a restaurant or all restaurants"""
    dynamodb = boto3.resource('dynamodb', region_name=REGION)
    table = dynamodb.Table(INVENTORY_TABLE)
    if restaurant_id:
        response = table.scan(FilterExpression=Attr('restaurant_id').eq(restaurant_id))
    else:
        response = table.scan()
    return {"status": "success", "content": [{"text": json.dumps(response.get('Items', []), default=str)}]}

@tool
def get_staffing(restaurant_id: str = None) -> dict:
    """Get staffing status for a restaurant or all restaurants"""
    dynamodb = boto3.resource('dynamodb', region_name=REGION)
    table = dynamodb.Table(STAFFING_TABLE)
    if restaurant_id:
        response = table.scan(FilterExpression=Attr('restaurant_id').eq(restaurant_id))
    else:
        response = table.scan()
    return {"status": "success", "content": [{"text": json.dumps(response.get('Items', []), default=str)}]}

@tool
def get_tickets(restaurant_id: str = None) -> dict:
    """Get open tickets for a restaurant or all restaurants"""
    dynamodb = boto3.resource('dynamodb', region_name=REGION)
    table = dynamodb.Table(TICKETS_TABLE)
    if restaurant_id:
        response = table.scan(FilterExpression=Attr('restaurant_id').eq(restaurant_id))
    else:
        response = table.scan()
    return {"status": "success", "content": [{"text": json.dumps(response.get('Items', []), default=str)}]}

@tool
def create_ticket(restaurant_id: str, issue: str, priority: str = "medium", category: str = "equipment", equipment_id: str = None) -> dict:
    """Create a ticket for equipment maintenance, inventory reorder, or staffing request.

    Args:
        restaurant_id: Restaurant ID (e.g. AFC-001)
        issue: Description of the issue or request
        priority: Ticket priority — critical, high, medium, or low
        category: Type of ticket — equipment, inventory, or staffing
        equipment_id: Equipment ID (only for equipment tickets)
    """
    dynamodb = boto3.resource('dynamodb', region_name=REGION)
    table = dynamodb.Table(TICKETS_TABLE)
    ticket_id = f"TKT-{uuid.uuid4().hex[:8].upper()}"
    ticket = {
        'ticket_id': ticket_id, 'restaurant_id': restaurant_id,
        'issue': issue, 'priority': priority,
        'category': category, 'status': 'open',
        'created_at': datetime.now().isoformat()
    }
    if equipment_id:
        ticket['equipment_id'] = equipment_id
    table.put_item(Item=ticket)
    return {"status": "success", "content": [{"text": f"Ticket {ticket_id} created successfully for {category} — {issue}"}]}

# Knowledge Base ID — set via environment variable after KB creation
KNOWLEDGE_BASE_ID = os.environ.get('KNOWLEDGE_BASE_ID', 'RXNA4EHZKC')

@tool
def search_equipment_manual(query: str, equipment_type: str = None) -> dict:
    """Search equipment manuals for information about usage, maintenance, warranty, troubleshooting, and operating procedures.
    Use this tool when operators ask questions about how to use equipment, maintenance schedules,
    warranty coverage, safety procedures, cleaning instructions, or temperature settings.

    Args:
        query: The question or topic to search for in equipment manuals
        equipment_type: Optional equipment type filter (e.g. 'walk-in cooler', 'fryer', 'grill', 'freezer', 'ice cream freezer', 'beverage cooler')
    """
    if not KNOWLEDGE_BASE_ID:
        return {"status": "error", "content": [{"text": "Knowledge base not configured. Set KNOWLEDGE_BASE_ID environment variable."}]}

    try:
        client = boto3.client('bedrock-agent-runtime', region_name=REGION)

        search_query = query
        if equipment_type:
            search_query = f"{equipment_type}: {query}"

        response = client.retrieve(
            knowledgeBaseId=KNOWLEDGE_BASE_ID,
            retrievalQuery={'text': search_query},
            retrievalConfiguration={
                'vectorSearchConfiguration': {
                    'numberOfResults': 5
                }
            }
        )

        results = []
        for result in response.get('retrievalResults', []):
            content = result.get('content', {}).get('text', '')
            source = result.get('location', {}).get('s3Location', {}).get('uri', 'Unknown source')
            score = result.get('score', 0)
            if content:
                results.append(f"[Source: {source.split('/')[-1]}, Relevance: {score:.2f}]\n{content}")

        if results:
            return {"status": "success", "content": [{"text": "\n\n---\n\n".join(results)}]}
        else:
            return {"status": "success", "content": [{"text": "No relevant information found in equipment manuals for that query."}]}

    except Exception as e:
        logger.error(f"Knowledge base query error: {e}")
        return {"status": "error", "content": [{"text": f"Error searching equipment manuals: {str(e)}"}]}

ALL_TOOLS = [get_restaurants, get_equipment, analyze_temperature, get_troubleshooting,
             get_inventory, get_staffing, get_tickets, create_ticket, search_equipment_manual]


# ============================================================
# SYSTEM PROMPT
# ============================================================

SYSTEM_PROMPT = """You are a friendly restaurant operations assistant for AnyCompany's Georgia restaurant network.

PERSONALITY:
- Be warm, conversational, and helpful — like a knowledgeable colleague.
- For greetings, respond naturally: "Hey! How can I help you today?"
- NEVER show internal thinking or reasoning. Never use <thinking> tags. Only show the final answer.
- Ask clarifying questions when needed (e.g., "Which restaurant?")
- Keep voice responses SHORT — 1-2 sentences max for natural conversation flow.

CAPABILITIES — You can help with ALL of these:
1. EQUIPMENT: Monitor status, temperatures, create maintenance tickets, troubleshoot issues.
2. INVENTORY: Check stock levels, identify low/critical items, create reorder tickets.
3. STAFFING: Check coverage, identify gaps, create staffing request tickets.
4. TICKETS: View, create, and track tickets for equipment, inventory, AND staffing.

CREATING TICKETS:
- Use create_ticket for ANY type of request — equipment maintenance, inventory reorders, or staffing requests.
- Set category to "equipment", "inventory", or "staffing" based on the request type.
- For inventory reorders: create a ticket with category="inventory" and include item name, quantity needed, and restaurant.
- For staffing requests: create a ticket with category="staffing" and include shift, date, number of staff needed.
- For equipment issues: create a ticket with category="equipment" and include equipment_id.
- Always confirm the ticket was created and provide the ticket ID.

EQUIPMENT KNOWLEDGE BASE:
- You have access to detailed equipment manuals via the search_equipment_manual tool.
- Use it when operators ask about: how to use equipment, startup/shutdown procedures, maintenance schedules,
  warranty information, troubleshooting steps, safety procedures, cleaning instructions, or temperature settings.
- Always cite the manual when providing maintenance or warranty information.
- Equipment types: Walk-In Cooler (WC-3800), Beverage Cooler (BC-3500), Freezer Unit (FZ-500),
  Burger Grill (BG-450), Deep Fryer (DF-375), Ice Cream Freezer (ICF-1000).

RESPONSE STYLE:
- Summarize data conversationally. Do NOT dump raw tables or lists.
- For staffing: highlight only gaps. Say "Fully staffed except Tuesday morning — 1 cook short."
- For equipment: lead with issues. Say "Grill is overheating at 520F. Other 4 units are fine."
- For inventory: highlight low items. Say "Cooking oil is critically low at 5 gallons."
- For tickets: group by severity. Say "4 open tickets — 1 critical, 2 high, 1 medium."
- Use plain language, not technical jargon.

RULES:
- Only use data from tools. Never invent data.
- Restaurant IDs: AFC-001 (Atlanta), AFC-002 (Savannah), AFC-003 (Augusta), AFC-004 (Macon), AFC-005 (Athens),
  AFC-006 (Columbus), AFC-007 (Brunswick), AFC-008 (Albany), AFC-009 (Valdosta), AFC-010 (Cumming).

TOOLS: get_restaurants, get_equipment, get_inventory, get_staffing, get_tickets, create_ticket, analyze_temperature, get_troubleshooting, search_equipment_manual"""

# ============================================================
# WEBSOCKET ENTRYPOINT — BidiAgent with Nova Sonic (voice)
# Requires Python 3.12+ and strands-agents[bidi]
# ============================================================

if BIDI_AVAILABLE:
    @app.websocket
    async def websocket_handler(websocket, context):
        """Bidirectional voice streaming with Nova Sonic via AgentCore WebSocket."""
        from strands.experimental.bidi.types.events import (
            BidiAudioInputEvent, BidiTextInputEvent, BidiImageInputEvent,
        )

        logger.info("WebSocket connection initiated")
        try:
            await websocket.accept()

            voice_id = "tiffany"
            model = BidiNovaSonicModel(
                region=REGION,
                model_id="amazon.nova-2-sonic-v1:0",
                provider_config={
                    "audio": {
                        "input_sample_rate": 16000,
                        "output_sample_rate": 16000,
                        "voice": voice_id,
                    }
                },
                tools=ALL_TOOLS,
            )

            agent = BidiAgent(model=model, tools=ALL_TOOLS, system_prompt=SYSTEM_PROMPT)

            async def receive_and_convert():
                data = await websocket.receive_json()
                if not isinstance(data, dict) or "type" not in data:
                    return data
                event_type = data["type"]
                event_data = {k: v for k, v in data.items() if k != "type"}
                if event_type == "bidi_audio_input":
                    return BidiAudioInputEvent(**event_data)
                elif event_type == "bidi_text_input":
                    return BidiTextInputEvent(**event_data)
                elif event_type == "bidi_image_input":
                    return BidiImageInputEvent(**event_data)
                return data

            await agent.run(inputs=[receive_and_convert], outputs=[websocket.send_json])

        except Exception as e:
            logger.error("WebSocket error: %s", e)
            try:
                await websocket.close(code=1011, reason=str(e)[:120])
            except Exception:
                pass
else:
    logger.warning("BidiAgent not available (requires Python 3.12+). Voice WebSocket disabled.")

# ============================================================
# TEXT CHAT ENTRYPOINT (BedrockAgentCoreApp — invoked via invoke_agent_runtime)
# ============================================================

@app.entrypoint
async def invoke(payload=None):
    query = payload.get("prompt", "What is the current status?")
    os.environ["BYPASS_TOOL_CONSENT"] = "True"

    max_retries = 3
    last_error = None

    for attempt in range(max_retries):
        try:
            agent = Agent(
                tools=ALL_TOOLS,
                system_prompt=SYSTEM_PROMPT,
                name="RestaurantAgent",
                model="us.amazon.nova-lite-v1:0"
            )
            result = agent(query)
            response_text = result.message['content'][0]['text']
            response_text = re.sub(r'<thinking>.*?</thinking>\s*', '', response_text, flags=re.DOTALL).strip()
            return {"status": "completed", "result": response_text}
        except Exception as e:
            last_error = e
            error_msg = str(e).lower()
            if "response ended prematurely" in error_msg or "protocol" in error_msg or "timeout" in error_msg:
                if attempt < max_retries - 1:
                    continue
            else:
                break

    return {"status": "error", "result": f"Sorry, I encountered an error. Please try again. Error: {str(last_error)}"}

if __name__ == "__main__":
    app.run()
