---
inclusion: fileMatch
fileMatchPattern: "**/*.py,**/agent*.py"
---

# Agent Development Guidelines

## File Organization

⚠️ **IMPORTANT**: All test outputs, reference code, and working documents MUST be saved to `temp/` folder.

```
temp/src-reference/agentcore/     # Reference agent code
temp/src-reference/lambda/        # Reference Lambda code
```

**DO NOT** create test files or documentation in the project root.

## Strands SDK Patterns

### Tool Definition

```python
from strands import Agent, tool

@tool
def tool_name(param: str, optional_param: str = None) -> dict:
    """Brief description of what the tool does.
    
    Args:
        param: Description of required parameter
        optional_param: Description of optional parameter
    """
    # Implementation
    return {"status": "success", "content": [{"text": json.dumps(result)}]}
```

### Agent Creation

```python
agent = Agent(
    tools=[tool1, tool2, tool3],
    system_prompt="Clear, concise instructions",
    name="AgentName",
    model="us.amazon.nova-lite-v1:0"
)
```

## Nova Sonic Agent Rules

1. **Data Source**: Only use data from tools - never invent data
2. **Scope**: No access to food prep, orders, recipes, or cooking status
3. **Response Style**: Keep responses SHORT and factual, use bullet points
4. **Restaurant Lookup**: When user mentions restaurant by name, first call `get_restaurants` to find the ID

## Tool Return Format

Always return this structure:
```python
{"status": "success|error", "content": [{"text": "response string"}]}
```

## Error Handling

Implement retry logic for transient Bedrock errors:
```python
max_retries = 3
for attempt in range(max_retries):
    try:
        result = agent(query)
        return result
    except Exception as e:
        if "response ended prematurely" in str(e).lower():
            if attempt < max_retries - 1:
                continue
        raise
```

## DynamoDB Operations

```python
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
table = dynamodb.Table(TABLE_NAME)

# Query with filter
response = table.scan(FilterExpression=Attr('restaurant_id').eq(restaurant_id))

# Put item
table.put_item(Item=item_dict)
```

## Equipment Specs Reference

| Equipment ID | Type | Normal Range | Critical |
|-------------|------|--------------|----------|
| REF-001 | Walk-in Cooler | 35-40°F | 45°F |
| FRZ-001 | Walk-in Freezer | -10-0°F | 10°F |
| GRILL-001 | Commercial Grill | 300-500°F | 550°F |
| FRYER-001 | Deep Fryer | 325-375°F | 400°F |
