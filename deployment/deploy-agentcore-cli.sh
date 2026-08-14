#!/bin/bash
# Deploy Restaurant Agent using AgentCore CLI
# This is the recommended deployment approach

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_CODE_DIR="$SCRIPT_DIR/agent-code"

# Load user configuration (edit deployment/config.env before deploying)
if [ -f "$SCRIPT_DIR/config.env" ]; then
    source "$SCRIPT_DIR/config.env"
fi

REGION="${AWS_REGION:-us-east-1}"
export AWS_REGION="$REGION"
AGENT_NAME="${AGENT_NAME:-restaurant_agent}"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text --region "$REGION")"

echo "============================================"
echo "Restaurant Agent - AgentCore CLI Deployment"
echo "============================================"
echo ""

# Check for agentcore CLI
AGENTCORE_CLI=$(which agentcore 2>/dev/null | grep -v homebrew || echo "")
if [ -z "$AGENTCORE_CLI" ]; then
    # Try user local bin
    if [ -f "$HOME/.local/bin/agentcore" ]; then
        AGENTCORE_CLI="$HOME/.local/bin/agentcore"
    else
        echo "Error: agentcore CLI not found. Install with:"
        echo "  pipx install bedrock-agentcore-starter-toolkit"
        exit 1
    fi
fi

echo "Using AgentCore CLI: $AGENTCORE_CLI"
echo ""

# Step 1: Configure agent
echo "Step 1: Configuring agent..."
cd "$AGENT_CODE_DIR"

$AGENTCORE_CLI configure \
    --entrypoint agent.py \
    --name $AGENT_NAME \
    --runtime PYTHON_3_11 \
    --region $REGION \
    --disable-memory \
    --non-interactive

echo ""

# Step 2: Deploy to AgentCore
echo "Step 2: Deploying to AgentCore..."
$AGENTCORE_CLI deploy

echo ""

# Step 3: Get agent ARN
echo "Step 3: Getting agent details..."
AGENT_ARN=$($AGENTCORE_CLI status 2>&1 | grep -o 'arn:aws:bedrock-agentcore[^"]*' | head -1)
echo "Agent ARN: $AGENT_ARN"

# Step 4: Add DynamoDB and Bedrock permissions to the execution role
echo ""
echo "Step 4: Adding DynamoDB and Bedrock permissions..."
ROLE_NAME=$(aws iam list-roles --query "Roles[?contains(RoleName, 'AmazonBedrockAgentCoreSDKRuntime')].RoleName" --output text --region $REGION | head -1)

if [ -n "$ROLE_NAME" ]; then
    cat > /tmp/dynamo-bedrock-policy.json << POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:GetItem",
                "dynamodb:Query",
                "dynamodb:Scan",
                "dynamodb:PutItem",
                "dynamodb:UpdateItem"
            ],
            "Resource": "arn:aws:dynamodb:${REGION}:${ACCOUNT_ID}:table/${PROJECT_NAME}-*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "bedrock:InvokeModel",
                "bedrock:InvokeModelWithResponseStream",
                "bedrock:InvokeModelWithBidirectionalStream"
            ],
            "Resource": [
                "arn:aws:bedrock:*::foundation-model/amazon.nova-*",
                "arn:aws:bedrock:${REGION}:${ACCOUNT_ID}:inference-profile/us.amazon.nova-*"
            ]
        }
    ]
}
POLICY

    aws iam put-role-policy \
        --role-name "$ROLE_NAME" \
        --policy-name DynamoDBBedrockAccess \
        --policy-document file:///tmp/dynamo-bedrock-policy.json \
        --region $REGION 2>/dev/null || true
    
    echo "  Added permissions to role: $ROLE_NAME"
fi

# Step 5: Deploy Chat Endpoints (standard + streaming)
echo ""
echo "Step 5: Deploying Chat Endpoints..."
cd "$SCRIPT_DIR"

# Get infrastructure stack outputs
REST_API_ID=$(aws cloudformation describe-stacks \
    --stack-name restaurant-agent-infrastructure-prod \
    --query 'Stacks[0].Outputs[?OutputKey==`RestApiId`].OutputValue' \
    --output text --region $REGION)

ROOT_RESOURCE_ID=$(aws cloudformation describe-stacks \
    --stack-name restaurant-agent-infrastructure-prod \
    --query 'Stacks[0].Outputs[?OutputKey==`RestApiRootResourceId`].OutputValue' \
    --output text --region $REGION)

echo "  REST API ID: $REST_API_ID"
echo "  Root Resource ID: $ROOT_RESOURCE_ID"

# Deploy standard chat endpoint
echo "  Deploying standard chat endpoint..."
aws cloudformation deploy \
    --template-file chat-endpoint.yaml \
    --stack-name restaurant-agent-chat-prod \
    --parameter-overrides \
        AgentRuntimeArn="$AGENT_ARN" \
        RestApiId="$REST_API_ID" \
        RestApiRootResourceId="$ROOT_RESOURCE_ID" \
    --capabilities CAPABILITY_NAMED_IAM \
    --region $REGION \
    --no-fail-on-empty-changeset 2>/dev/null || true

# Deploy streaming chat endpoint
echo "  Deploying streaming chat endpoint..."
aws cloudformation deploy \
    --template-file chat-endpoint-streaming.yaml \
    --stack-name restaurant-agent-chat-streaming-prod \
    --parameter-overrides \
        AgentRuntimeArn="$AGENT_ARN" \
        RestApiId="$REST_API_ID" \
        RestApiRootResourceId="$ROOT_RESOURCE_ID" \
    --capabilities CAPABILITY_NAMED_IAM \
    --region $REGION \
    --no-fail-on-empty-changeset 2>/dev/null || true

# Redeploy API Gateway
aws apigateway create-deployment --rest-api-id $REST_API_ID --stage-name prod --region $REGION >/dev/null 2>&1

echo ""
echo "============================================"
echo "Deployment Complete!"
echo "============================================"
echo ""
echo "Agent ARN: $AGENT_ARN"
echo ""
echo "Endpoints:"
echo "  Standard:  https://$REST_API_ID.execute-api.$REGION.amazonaws.com/prod/chat"
echo "  Streaming: https://$REST_API_ID.execute-api.$REGION.amazonaws.com/prod/chat-stream"
echo ""
echo "Test with CLI:"
echo "  agentcore invoke '{\"prompt\": \"List restaurants\"}'"
echo ""
echo "Test streaming:"
echo "  curl --no-buffer -X POST https://$REST_API_ID.execute-api.$REGION.amazonaws.com/prod/chat-stream \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"prompt\": \"List restaurants\"}'"
