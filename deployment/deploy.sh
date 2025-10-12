#!/bin/bash
# Restaurant Kitchen Assistant - Linux Deployment Script
# Deploys all infrastructure components in correct order

PROJECT_NAME="rest-monitor"
ENVIRONMENT="prod"
REGION="us-east-1"

echo "🚀 Starting Restaurant Kitchen Assistant Deployment"
echo "Project: $PROJECT_NAME"
echo "Environment: $ENVIRONMENT"
echo "Region: $REGION"
echo

# Change to project root directory
cd "$(dirname "$0")/.."

# Step 0: Validate Templates
echo "🔍 Step 0: Validating CloudFormation Templates..."
echo "Validating Restaurant Monitoring Base Template..."
if ! aws cloudformation validate-template --template-body file://deployment/restaurant-monitoring-base-template.yaml > /dev/null; then
    echo "❌ Restaurant Monitoring Base Template validation failed"
    exit 1
fi

echo "Validating Strands Agent Chat Workflow template..."
if ! aws cloudformation validate-template --template-body file://deployment/strands-agent-chat-workflow.yaml > /dev/null; then
    echo "❌ Strands Agent Chat Workflow template validation failed"
    exit 1
fi

echo "✅ All templates validated successfully"

echo

# Step 1: Deploy Restaurant Monitoring Base Infrastructure
echo "🏗️ Step 1: Deploying Restaurant Monitoring Base Infrastructure..."
DEPLOY_OUTPUT=$(aws cloudformation deploy \
  --template-file deployment/restaurant-monitoring-base-template.yaml \
  --stack-name $PROJECT_NAME-base-infrastructure-$ENVIRONMENT \
  --parameter-overrides ProjectName=$PROJECT_NAME Environment=$ENVIRONMENT \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --region $REGION 2>&1)

DEPLOY_STATUS=$?
if [ $DEPLOY_STATUS -eq 0 ] || echo "$DEPLOY_OUTPUT" | grep -q "No changes to deploy"; then
    echo "✅ Restaurant Monitoring Base Infrastructure deployed successfully (or already up to date)"
    
    # Get API Gateway URL
    API_URL=$(aws cloudformation describe-stacks \
      --stack-name $PROJECT_NAME-base-infrastructure-$ENVIRONMENT \
      --query "Stacks[0].Outputs[?OutputKey=='ApiUrl'].OutputValue" \
      --output text \
      --region $REGION)
    
    # Get fresh Cognito details from CloudFormation
    echo "🔑 Getting Cognito configuration from CloudFormation..."
    USER_POOL_ID=$(aws cloudformation describe-stacks \
      --stack-name $PROJECT_NAME-base-infrastructure-$ENVIRONMENT \
      --query "Stacks[0].Outputs[?OutputKey=='UserPoolId'].OutputValue" \
      --output text \
      --region $REGION)
    
    CLIENT_ID=$(aws cloudformation describe-stacks \
      --stack-name $PROJECT_NAME-base-infrastructure-$ENVIRONMENT \
      --query "Stacks[0].Outputs[?OutputKey=='UserPoolClientId'].OutputValue" \
      --output text \
      --region $REGION)
    
    IDENTITY_POOL_ID=$(aws cloudformation describe-stacks \
      --stack-name $PROJECT_NAME-base-infrastructure-$ENVIRONMENT \
      --query "Stacks[0].Outputs[?OutputKey=='IdentityPoolId'].OutputValue" \
      --output text \
      --region $REGION)
    
    # Get CloudFront URL
    DASHBOARD_URL=$(aws cloudformation describe-stacks \
      --stack-name $PROJECT_NAME-base-infrastructure-$ENVIRONMENT \
      --query "Stacks[0].Outputs[?OutputKey=='CloudFrontURL'].OutputValue" \
      --output text \
      --region $REGION)
    
    echo "   User Pool ID: $USER_POOL_ID"
    echo "   Client ID: $CLIENT_ID"
    echo "   Identity Pool ID: $IDENTITY_POOL_ID"
    
    # Update website files with current Cognito configuration
    echo "🔧 Updating Cognito configuration in website files..."
    
    # Replace any existing Cognito IDs with current ones
    sed -i "" "s/userPoolId: '[^']*'/userPoolId: '$USER_POOL_ID'/g" source/auth.js
    sed -i "" "s/userPoolWebClientId: '[^']*'/userPoolWebClientId: '$CLIENT_ID'/g" source/auth.js
    sed -i "" "s/identityPoolId: '[^']*'/identityPoolId: '$IDENTITY_POOL_ID'/g" source/auth.js
    
    # Update login.html with current Cognito configuration
    sed -i "" "s/us-east-1_[A-Za-z0-9]*/$USER_POOL_ID/g" source/login.html
    sed -i "" "s/[0-9a-z]\{26\}/$CLIENT_ID/g" source/login.html
    
    echo "📡 API Gateway URL: $API_URL"
    echo "🌐 Dashboard URL: $DASHBOARD_URL"
else
    echo "❌ Failed to deploy Restaurant Monitoring Base Infrastructure"
    echo "$DEPLOY_OUTPUT"
    exit 1
fi

# Step 2: Deploy Strands Agent Chat Workflow
echo
echo "🤖 Step 2: Deploying Strands Agent Chat Workflow..."
# Get API Gateway details from base stack
API_GATEWAY_ID=$(aws cloudformation describe-stacks \
  --stack-name $PROJECT_NAME-base-infrastructure-$ENVIRONMENT \
  --query "Stacks[0].Outputs[?OutputKey=='RestApiId'].OutputValue" \
  --output text \
  --region $REGION)

API_ROOT_RESOURCE_ID=$(aws cloudformation describe-stacks \
  --stack-name $PROJECT_NAME-base-infrastructure-$ENVIRONMENT \
  --query "Stacks[0].Outputs[?OutputKey=='RestApiRootResourceId'].OutputValue" \
  --output text \
  --region $REGION)

DEPLOY_OUTPUT=$(aws cloudformation deploy \
  --template-file deployment/strands-agent-chat-workflow.yaml \
  --stack-name $PROJECT_NAME-strands-agent-chat-$ENVIRONMENT \
  --parameter-overrides ProjectName=$PROJECT_NAME Environment=$ENVIRONMENT RestApiId=$API_GATEWAY_ID RestApiRootResourceId=$API_ROOT_RESOURCE_ID \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --region $REGION 2>&1)

DEPLOY_STATUS=$?
if [ $DEPLOY_STATUS -eq 0 ] || echo "$DEPLOY_OUTPUT" | grep -q "No changes to deploy"; then
    echo "✅ Strands Agent Chat Workflow deployed successfully (with DynamoDB conversation history)"
else
    echo "⚠️ Failed to deploy Strands Agent Chat Workflow"
    echo "$DEPLOY_OUTPUT"
fi

# Step 3: Deploy website and load initial data
echo
echo "🌐 Step 3: Deploying website and loading initial data..."
if [ -f "deployment/deploy-loaddata.sh" ]; then
    bash deployment/deploy-loaddata.sh
    echo "✅ Website deployed and initial data loaded"
else
    echo "⚠️ deploy-loaddata.sh not found, please run it manually"
fi

echo
echo "📋 Next Steps:"
echo "1. Initial data has been populated via deploy-loaddata.sh"
echo "2. Test API endpoints: /restaurants, /tickets, /equipment"
echo "3. Test strands-agent-chat: POST to /strands-agent-chat endpoint"
echo "4. Access dashboard and test contextual chat with any location"
echo "5. For continuous monitoring, restart simulator: python3 deployment/simple_simulator.py"
echo
echo "✅ Restaurant Kitchen Assistant with Strands Agent Chat Workflow is ready!"