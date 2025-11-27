#!/usr/bin/env python3
import boto3
import json
import sys

# Get API endpoint
cf = boto3.client('cloudformation')
response = cf.describe_stacks(StackName='restaurant-monitoring-agentcore-chat-production')
api_url = next(o['OutputValue'] for o in response['Stacks'][0]['Outputs'] if o['OutputKey'] == 'ChatApiEndpoint')

# Send approval
import requests
session_id = sys.argv[1] if len(sys.argv) > 1 else "test-session"
response = requests.post(
    f"{api_url}/chat",
    json={"message": "Yes", "session_id": session_id}
)

print(response.json()['response'])
