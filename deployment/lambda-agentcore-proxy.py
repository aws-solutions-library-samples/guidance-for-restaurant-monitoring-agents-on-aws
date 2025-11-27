import json
import boto3
import os

# Initialize Bedrock AgentCore Runtime client
client = boto3.client('bedrock-agent-runtime', region_name='us-east-1')

AGENT_ARN = 'arn:aws:bedrock-agentcore:us-east-1:986635652628:runtime/restaurant_ops_full-Ni2asWG82Q'

def lambda_handler(event, context):
    """
    Proxy Lambda function to invoke Bedrock AgentCore Runtime
    """
    try:
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        prompt = body.get('prompt', '')
        session_id = body.get('sessionId', '')
        
        # Invoke AgentCore Runtime
        response = client.invoke_agent(
            agentId=AGENT_ARN.split('/')[-1],
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
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,Authorization',
                'Access-Control-Allow-Methods': 'POST,OPTIONS'
            },
            'body': json.dumps({
                'response': result_text,
                'sessionId': session_id
            })
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': str(e),
                'message': 'Failed to invoke AgentCore'
            })
        }
