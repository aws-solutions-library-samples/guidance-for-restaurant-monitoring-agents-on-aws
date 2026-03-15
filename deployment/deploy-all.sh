#!/bin/bash
# =============================================================================
# Restaurant Monitoring Agent - Complete Deployment Script
# =============================================================================
# This script deploys the entire restaurant monitoring system:
# 1. Infrastructure (DynamoDB, API Gateway, S3, CloudFront, Cognito, WAF, KMS)
# 2. Sample Data (restaurants, equipment, inventory, staffing, tickets)
# 3. Knowledge Base (equipment manuals in Bedrock KB + OpenSearch Serverless)
# 4. AgentCore Agent (Strands-based AI agent with tools + memory)
# 5. Chat Endpoint (Lambda + API Gateway with Cognito auth)
# 6. Frontend (S3 + CloudFront with auth)
# =============================================================================

set -e

REGION="us-east-1"
export AWS_REGION="$REGION"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "============================================"
echo "Restaurant Monitoring Agent - Full Deployment"
echo "============================================"
echo ""

# =============================================================================
# Step 1: Deploy Base Infrastructure
# =============================================================================
echo "Step 1: Deploying Base Infrastructure..."

if ! aws cloudformation deploy \
    --template-file "$SCRIPT_DIR/restaurant-monitoring-base-template.yaml" \
    --stack-name restaurant-agent-infrastructure-prod \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
    --region $REGION \
    --no-fail-on-empty-changeset; then
    echo "  ❌ Base infrastructure deployment failed. Aborting."
    exit 1
fi

echo "  ✅ Base infrastructure deployed"

# =============================================================================
# Step 2: Load Sample Data
# =============================================================================
echo ""
echo "Step 2: Loading Sample Data..."

bash "$SCRIPT_DIR/load-data.sh"

echo "  ✅ Sample data loaded"

# =============================================================================
# Step 3: Deploy Knowledge Base
# =============================================================================
echo ""
echo "Step 3: Deploying Knowledge Base..."

if [ -f "$SCRIPT_DIR/deploy-knowledge-base.sh" ]; then
    bash "$SCRIPT_DIR/deploy-knowledge-base.sh"
    KB_ID=$(aws bedrock-agent list-knowledge-bases --region $REGION \
        --query "knowledgeBaseSummaries[?contains(name,'equipment-manuals')].knowledgeBaseId" \
        --output text 2>/dev/null || echo "")
    echo "  ✅ Knowledge Base deployed: $KB_ID"
else
    echo "  ⚠️  deploy-knowledge-base.sh not found, skipping KB deployment"
    KB_ID=""
fi

# =============================================================================
# Step 4: Deploy AgentCore Agent
# =============================================================================
echo ""
echo "Step 4: Deploying AgentCore Agent..."

AGENTCORE_CLI=$(which agentcore 2>/dev/null | grep -v homebrew || echo "")
if [ -z "$AGENTCORE_CLI" ]; then
    if [ -f "$HOME/.local/bin/agentcore" ]; then
        AGENTCORE_CLI="$HOME/.local/bin/agentcore"
    else
        echo "  ⚠️  AgentCore CLI not found. Install with:"
        echo "     pipx install bedrock-agentcore-starter-toolkit"
        echo "  Skipping agent deployment..."
        AGENT_ARN=""
    fi
fi

if [ -n "$AGENTCORE_CLI" ]; then
    pushd "$SCRIPT_DIR/agent-code" > /dev/null

    # Configure agent with memory enabled
    rm -rf .bedrock_agentcore .bedrock_agentcore.yaml 2>/dev/null

    $AGENTCORE_CLI configure \
        --entrypoint agent.py \
        --name restaurant_agent \
        --runtime PYTHON_3_12 \
        --region $REGION \
        --non-interactive 2>/dev/null || true

    # Enable STM + LTM memory in config
    if [ -f .bedrock_agentcore.yaml ]; then
        sed -i.bak 's/mode: NO_MEMORY/mode: STM_AND_LTM/' .bedrock_agentcore.yaml
        rm -f .bedrock_agentcore.yaml.bak
    fi

    # Deploy (use --auto-update-on-conflict for redeploys)
    $AGENTCORE_CLI deploy --auto-update-on-conflict 2>&1 | tail -10

    # Extract agent ARN
    AGENT_ARN=$($AGENTCORE_CLI status 2>&1 | tr -d '\n' | grep -o 'arn:aws:bedrock-agentcore[^[:space:]"]*' | head -1)

    popd > /dev/null

    # Add permissions to AgentCore role
    ROLE_NAME=$(aws iam list-roles --query "Roles[?contains(RoleName, 'AmazonBedrockAgentCoreSDKRuntime')].RoleName" --output text --region $REGION | head -1)
    DDB_KMS_KEY=$(aws cloudformation describe-stack-resources \
        --stack-name restaurant-agent-infrastructure-prod \
        --logical-resource-id DynamoDBEncryptionKey \
        --query 'StackResources[0].PhysicalResourceId' \
        --output text --region $REGION 2>/dev/null || echo "")
    DDB_KMS_ARN=""
    if [ -n "$DDB_KMS_KEY" ]; then
        DDB_KMS_ARN=$(aws kms describe-key --key-id "$DDB_KMS_KEY" --region $REGION --query 'KeyMetadata.Arn' --output text 2>/dev/null || echo "")
    fi

    if [ -n "$ROLE_NAME" ]; then
        # DynamoDB + Bedrock + KMS permissions
        cat > /tmp/agent-policy.json << POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": ["dynamodb:GetItem", "dynamodb:Query", "dynamodb:Scan", "dynamodb:PutItem", "dynamodb:UpdateItem"],
            "Resource": ["arn:aws:dynamodb:${REGION}:*:table/restaurant-kitchen-assistant-*"]
        },
        {
            "Effect": "Allow",
            "Action": ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": ["bedrock:Retrieve", "bedrock:RetrieveAndGenerate", "bedrock-agent-runtime:Retrieve", "bedrock-agent-runtime:RetrieveAndGenerate"],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": ["aoss:APIAccessAll"],
            "Resource": "*"
        }$([ -n "$DDB_KMS_ARN" ] && echo ",
        {
            \"Effect\": \"Allow\",
            \"Action\": [\"kms:Decrypt\", \"kms:DescribeKey\", \"kms:GenerateDataKey\"],
            \"Resource\": \"$DDB_KMS_ARN\"
        }")
    ]
}
POLICY
        aws iam put-role-policy --role-name "$ROLE_NAME" --policy-name AgentFullAccess \
            --policy-document file:///tmp/agent-policy.json --region $REGION 2>/dev/null || true
        rm -f /tmp/agent-policy.json
    fi

    echo "  ✅ AgentCore agent deployed: $AGENT_ARN"

    # Update API Lambda with agent ARN
    API_LAMBDA_FUNC=$(aws cloudformation describe-stack-resources \
        --stack-name restaurant-agent-infrastructure-prod \
        --logical-resource-id ApiLambdaFunction \
        --query 'StackResources[0].PhysicalResourceId' \
        --output text --region $REGION 2>/dev/null || echo "")
    if [ -n "$API_LAMBDA_FUNC" ] && [ -n "$AGENT_ARN" ]; then
        CURRENT_ENV=$(aws lambda get-function-configuration \
            --function-name "$API_LAMBDA_FUNC" \
            --query 'Environment.Variables' --output json --region $REGION 2>/dev/null || echo "{}")
        UPDATED_ENV=$(echo "$CURRENT_ENV" | python3 -c "
import sys,json
env = json.load(sys.stdin)
env['AGENT_RUNTIME_ARN'] = '$AGENT_ARN'
print(json.dumps({'Variables': env}))
")
        aws lambda update-function-configuration \
            --function-name "$API_LAMBDA_FUNC" \
            --environment "$UPDATED_ENV" \
            --region $REGION >/dev/null 2>&1
        echo "  ✅ API Lambda AGENT_RUNTIME_ARN updated"
    fi
fi

# =============================================================================
# Step 5: Deploy Chat Endpoint
# =============================================================================
echo ""
echo "Step 5: Deploying Chat Endpoint..."

REST_API_ID=$(aws cloudformation describe-stacks \
    --stack-name restaurant-agent-infrastructure-prod \
    --query 'Stacks[0].Outputs[?OutputKey==`RestApiId`].OutputValue' \
    --output text --region $REGION 2>/dev/null || echo "")

ROOT_RESOURCE_ID=$(aws cloudformation describe-stacks \
    --stack-name restaurant-agent-infrastructure-prod \
    --query 'Stacks[0].Outputs[?OutputKey==`RestApiRootResourceId`].OutputValue' \
    --output text --region $REGION 2>/dev/null || echo "")

USER_POOL_ARN=$(aws cloudformation describe-stacks \
    --stack-name restaurant-agent-infrastructure-prod \
    --query 'Stacks[0].Outputs[?OutputKey==`UserPoolArn`].OutputValue' \
    --output text --region $REGION 2>/dev/null || echo "")

if [ -n "$REST_API_ID" ] && [ -n "$AGENT_ARN" ]; then
    aws cloudformation deploy \
        --template-file "$SCRIPT_DIR/chat-endpoint.yaml" \
        --stack-name restaurant-agent-chat-prod \
        --parameter-overrides \
            AgentRuntimeArn="$AGENT_ARN" \
            RestApiId="$REST_API_ID" \
            RestApiRootResourceId="$ROOT_RESOURCE_ID" \
            UserPoolArn="$USER_POOL_ARN" \
        --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
        --region $REGION \
        --no-fail-on-empty-changeset 2>/dev/null || true

    # Redeploy API Gateway stage
    aws apigateway create-deployment --rest-api-id $REST_API_ID --stage-name prod --region $REGION >/dev/null 2>&1

    echo "  ✅ Chat endpoint deployed"
fi

# =============================================================================
# Step 6: Deploy Frontend
# =============================================================================
echo ""
echo "Step 6: Deploying Frontend..."

S3_BUCKET=$(aws cloudformation describe-stacks \
    --stack-name restaurant-agent-infrastructure-prod \
    --query 'Stacks[0].Outputs[?OutputKey==`BucketName`].OutputValue' \
    --output text --region $REGION 2>/dev/null || echo "")

CLOUDFRONT_ID=$(aws cloudformation describe-stacks \
    --stack-name restaurant-agent-infrastructure-prod \
    --query 'Stacks[0].Outputs[?OutputKey==`DistributionId`].OutputValue' \
    --output text --region $REGION 2>/dev/null || echo "")

CLOUDFRONT_URL=$(aws cloudformation describe-stacks \
    --stack-name restaurant-agent-infrastructure-prod \
    --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontURL`].OutputValue' \
    --output text --region $REGION 2>/dev/null || echo "")

if [ -n "$S3_BUCKET" ]; then
    # Update API endpoint in frontend files
    if [ -n "$REST_API_ID" ]; then
        API_ENDPOINT="https://$REST_API_ID.execute-api.$REGION.amazonaws.com/prod"
        for file in "$PROJECT_ROOT/frontend/api.js" "$PROJECT_ROOT/frontend/agent-api.js" "$PROJECT_ROOT/frontend/restaurant-agent-api.js" "$PROJECT_ROOT/frontend/shared.js"; do
            if [ -f "$file" ]; then
                sed -i.bak "s|https://[a-z0-9]*\.execute-api\.$REGION\.amazonaws\.com/prod|$API_ENDPOINT|g" "$file" 2>/dev/null || true
            fi
        done
    fi

    # Update Cognito config in frontend
    COGNITO_USER_POOL_ID=$(aws cloudformation describe-stacks \
        --stack-name restaurant-agent-infrastructure-prod \
        --query 'Stacks[0].Outputs[?OutputKey==`UserPoolId`].OutputValue' \
        --output text --region $REGION 2>/dev/null || echo "")
    COGNITO_CLIENT_ID=$(aws cloudformation describe-stacks \
        --stack-name restaurant-agent-infrastructure-prod \
        --query 'Stacks[0].Outputs[?OutputKey==`UserPoolClientId`].OutputValue' \
        --output text --region $REGION 2>/dev/null || echo "")
    COGNITO_IDENTITY_POOL_ID=$(aws cloudformation describe-stacks \
        --stack-name restaurant-agent-infrastructure-prod \
        --query 'Stacks[0].Outputs[?OutputKey==`IdentityPoolId`].OutputValue' \
        --output text --region $REGION 2>/dev/null || echo "")

    if [ -n "$COGNITO_USER_POOL_ID" ] && [ -n "$COGNITO_CLIENT_ID" ]; then
        for file in "$PROJECT_ROOT/frontend/auth.js" "$PROJECT_ROOT/frontend/shared.js" "$PROJECT_ROOT/frontend/login.html"; do
            if [ -f "$file" ]; then
                sed -i.bak "s|userPoolId: '[^']*'|userPoolId: '$COGNITO_USER_POOL_ID'|g" "$file"
                sed -i.bak "s|UserPoolId: '[^']*'|UserPoolId: '$COGNITO_USER_POOL_ID'|g" "$file"
                sed -i.bak "s|userPoolWebClientId: '[^']*'|userPoolWebClientId: '$COGNITO_CLIENT_ID'|g" "$file"
                sed -i.bak "s|ClientId: '[^']*'|ClientId: '$COGNITO_CLIENT_ID'|g" "$file"
                if [ -n "$COGNITO_IDENTITY_POOL_ID" ]; then
                    sed -i.bak "s|identityPoolId: '[^']*'|identityPoolId: '$COGNITO_IDENTITY_POOL_ID'|g" "$file"
                fi
            fi
        done
        echo "  ✅ Cognito credentials updated"
    fi

    rm -f "$PROJECT_ROOT/frontend/"*.bak 2>/dev/null || true

    # Sync to S3 and invalidate CloudFront
    aws s3 sync "$PROJECT_ROOT/frontend/" "s3://$S3_BUCKET/" --delete --region $REGION
    if [ -n "$CLOUDFRONT_ID" ]; then
        aws cloudfront create-invalidation --distribution-id $CLOUDFRONT_ID --paths "/*" --region $REGION >/dev/null 2>&1
    fi
    echo "  ✅ Frontend deployed"
fi

# =============================================================================
# Step 7: Create Demo User
# =============================================================================
echo ""
echo "Step 7: Creating demo user..."

COGNITO_USER_POOL_ID=$(aws cloudformation describe-stacks \
    --stack-name restaurant-agent-infrastructure-prod \
    --query 'Stacks[0].Outputs[?OutputKey==`UserPoolId`].OutputValue' \
    --output text --region $REGION 2>/dev/null || echo "")

if [ -n "$COGNITO_USER_POOL_ID" ]; then
    # Create user (ignore error if already exists)
    aws cognito-idp admin-create-user \
        --user-pool-id "$COGNITO_USER_POOL_ID" \
        --username demo@anycompany.com \
        --user-attributes Name=email,Value=demo@anycompany.com Name=name,Value="Demo User" Name=email_verified,Value=true \
        --temporary-password 'TempPass123!' \
        --region $REGION 2>/dev/null || true

    # Set permanent password
    aws cognito-idp admin-set-user-password \
        --user-pool-id "$COGNITO_USER_POOL_ID" \
        --username demo@anycompany.com \
        --password 'DemoPass#2026!' \
        --permanent \
        --region $REGION 2>/dev/null || true

    echo "  ✅ Demo user created: demo@anycompany.com / DemoPass#2026!"
fi

# =============================================================================
# Deployment Summary
# =============================================================================
echo ""
echo "============================================"
echo "Deployment Complete!"
echo "============================================"
echo ""
echo "Resources:"
echo "  Agent ARN:       $AGENT_ARN"
echo "  Knowledge Base:  $KB_ID"
echo "  API Gateway:     https://$REST_API_ID.execute-api.$REGION.amazonaws.com/prod"
echo "  CloudFront:      $CLOUDFRONT_URL"
echo ""
echo "Login:"
echo "  URL:      $CLOUDFRONT_URL"
echo "  Email:    demo@anycompany.com"
echo "  Password: DemoPass#2026!"
echo ""
echo "API Endpoints (require Cognito auth token):"
echo "  /restaurants  - List all restaurants"
echo "  /equipment    - Get equipment status"
echo "  /inventory    - Get inventory status"
echo "  /staffing     - Get staffing status"
echo "  /tickets      - Get maintenance tickets"
echo "  /voice-token  - Get presigned WebSocket URL"
echo "  /chat         - Chat with AI agent"
echo ""
echo "Features:"
echo "  - AI Chat with equipment knowledge base (6 manuals)"
echo "  - Voice chat via Nova Sonic (WebSocket)"
echo "  - AgentCore Memory (STM + LTM)"
echo "  - Security: Cognito MFA, KMS encryption, WAF, TLS 1.2"
echo ""
