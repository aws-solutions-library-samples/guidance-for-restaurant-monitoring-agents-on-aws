# Chat Fix Instructions

## Issue
Chat widget not working because AgentCore Runtime requires AWS SDK, not direct HTTP calls.

## Solution
Added `/chat` endpoint to existing Lambda API Gateway to proxy requests to AgentCore.

## Changes Made

### 1. Lambda Function Updated
**File**: `deployment/infrastructure/cloudformation/complete-infrastructure.yaml`

**Added**: `/chat` endpoint that:
- Receives: `{prompt, sessionId, agentArn}`
- Invokes: Bedrock AgentCore Runtime via boto3
- Returns: `{response, sessionId}`

### 2. Frontend Updated
**File**: `frontend/index.html`

**Changed**: Chat endpoint from fake URL to real API Gateway
```javascript
// OLD (fake endpoint)
const agentcoreUrl = `https://bedrock-agentcore-runtime.us-east-1.amazonaws.com/invoke`;

// NEW (real API Gateway)
const agentcoreUrl = `https://mojgf9gmfk.execute-api.us-east-1.amazonaws.com/prod/chat`;
```

## Deployment Steps

### Wait for Stack Cleanup
```bash
# Check stack status
aws cloudformation describe-stacks --stack-name rest-monitor-base-infrastructure-prod --query 'Stacks[0].StackStatus' --output text

# Wait until status is: UPDATE_COMPLETE
```

### Deploy Updated Lambda
```bash
cd deployment
aws cloudformation deploy \
  --template-file infrastructure/cloudformation/complete-infrastructure.yaml \
  --stack-name rest-monitor-base-infrastructure-prod \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides Environment=production
```

### Deploy Updated Frontend
```bash
# Get bucket name
BUCKET_NAME=$(aws cloudformation describe-stacks \
  --stack-name rest-monitor-base-infrastructure-prod \
  --query 'Stacks[0].Outputs[?OutputKey==`WebsiteBucket`].OutputValue' \
  --output text)

# Upload frontend
aws s3 sync frontend/ s3://$BUCKET_NAME/ --exclude "*.DS_Store"

# Invalidate CloudFront
aws cloudfront create-invalidation \
  --distribution-id E149M80HTI82SV \
  --paths "/*"
```

### Test Chat
1. Open: https://ddjlwfnv5wd1y.cloudfront.net
2. Click chat widget (bottom right)
3. Type: "What restaurants have issues?"
4. Verify response from AgentCore

## Technical Details

### Lambda /chat Endpoint
```python
elif path == '/chat':
    # Parse request
    body_data = json.loads(event.get('body', '{}'))
    prompt = body_data.get('prompt', '')
    session_id = body_data.get('sessionId', '')
    agent_arn = body_data.get('agentArn', '')
    
    # Invoke AgentCore
    bedrock_client = boto3.client('bedrock-agent-runtime')
    agent_id = agent_arn.split('/')[-1]
    
    response = bedrock_client.invoke_agent(
        agentId=agent_id,
        agentAliasId='DEFAULT',
        sessionId=session_id,
        inputText=prompt
    )
    
    # Parse streaming response
    result_text = ''
    for event_chunk in response.get('completion', []):
        if 'chunk' in event_chunk:
            chunk_data = event_chunk['chunk']
            if 'bytes' in chunk_data:
                result_text += chunk_data['bytes'].decode('utf-8')
    
    return {
        'statusCode': 200,
        'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
        'body': json.dumps({'response': result_text, 'sessionId': session_id})
    }
```

### Frontend Chat Call
```javascript
const response = await fetch('https://mojgf9gmfk.execute-api.us-east-1.amazonaws.com/prod/chat', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({ 
        prompt: message,
        sessionId: chatSessionId,
        agentArn: 'arn:aws:bedrock-agentcore:us-east-1:986635652628:runtime/restaurant_ops_full-Ni2asWG82Q'
    })
});
```

## Status

- ✅ Lambda code updated
- ✅ Frontend code updated
- ⏳ Stack deployment pending (cleanup in progress)
- ⏳ Frontend deployment pending
- ⏳ Testing pending

## Current Stack Status

**Stack**: rest-monitor-base-infrastructure-prod
**Status**: UPDATE_COMPLETE_CLEANUP_IN_PROGRESS

Wait for status to become `UPDATE_COMPLETE` before deploying.
