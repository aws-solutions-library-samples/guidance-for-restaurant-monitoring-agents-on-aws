#!/bin/bash
# Restaurant Kitchen Assistant - Linux Deployment Script
# Deploys all infrastructure components in correct order

PROJECT_NAME="restaurant-kitchen-assistant"
ENVIRONMENT="production"
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
if ! aws cloudformation validate-template --template-body file://infrastructure/restaurant-monitoring-base-template.yaml > /dev/null; then
    echo "❌ Restaurant Monitoring Base Template validation failed"
    exit 1
fi

echo "Validating Strands Agent Chat Workflow template..."
if ! aws cloudformation validate-template --template-body file://infrastructure/strands-agent-chat-workflow.yaml > /dev/null; then
    echo "❌ Strands Agent Chat Workflow template validation failed"
    exit 1
fi

echo "✅ All templates validated successfully"
echo

# Step 0.5: Clean up existing S3 bucket if it exists
echo "🧹 Step 0.5: Cleaning up existing S3 bucket..."
BUCKET_NAME="$PROJECT_NAME-dashboard-$ENVIRONMENT-986635652628"
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "Found existing bucket $BUCKET_NAME, deleting..."
    aws s3 rm s3://$BUCKET_NAME --recursive 2>/dev/null || true
    aws s3api delete-bucket --bucket $BUCKET_NAME 2>/dev/null || true
    echo "✅ Bucket cleanup attempted"
fi
echo

# Step 1: Deploy Restaurant Monitoring Base Infrastructure
echo "🏗️ Step 1: Deploying Restaurant Monitoring Base Infrastructure..."
DEPLOY_OUTPUT=$(aws cloudformation deploy \
  --template-file infrastructure/restaurant-monitoring-base-template.yaml \
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
    
    # Get Cognito details
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
    
    # Get CloudFront URL
    DASHBOARD_URL=$(aws cloudformation describe-stacks \
      --stack-name $PROJECT_NAME-base-infrastructure-$ENVIRONMENT \
      --query "Stacks[0].Outputs[?OutputKey=='CloudFrontURL'].OutputValue" \
      --output text \
      --region $REGION)
    
    # Get Identity Pool ID
    IDENTITY_POOL_ID=$(aws cloudformation describe-stacks \
      --stack-name $PROJECT_NAME-base-infrastructure-$ENVIRONMENT \
      --query "Stacks[0].Outputs[?OutputKey=='IdentityPoolId'].OutputValue" \
      --output text \
      --region $REGION)
    
    # Update website files with Cognito configuration
    sed -i "s/us-east-1_XXXXXXXXX/$USER_POOL_ID/g" static-website/auth.js
    sed -i "s/XXXXXXXXXXXXXXXXXXXXXXXXXX/$CLIENT_ID/g" static-website/auth.js
    sed -i "s/us-east-1:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/$IDENTITY_POOL_ID/g" static-website/auth.js
    
    # Update login.html with current Cognito configuration
    sed -i "s/us-east-1_XXXXXXXXX/$USER_POOL_ID/g" static-website/login.html
    sed -i "s/XXXXXXXXXXXXXXXXXXXXXXXXXX/$CLIENT_ID/g" static-website/login.html
    
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
  --template-file infrastructure/strands-agent-chat-workflow.yaml \
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

# Step 3: Start Equipment Simulator
echo
echo "🔧 Step 3: Starting Equipment Simulator..."
if [ -f "utils/equipment_simulator.py" ]; then
    echo "Starting simulator to populate initial data..."
    timeout 30 python utils/equipment_simulator.py &
    SIMULATOR_PID=$!
    sleep 5
    kill $SIMULATOR_PID 2>/dev/null || true
    echo "✅ Initial data populated by simulator"
else
    echo "⚠️ equipment_simulator.py not found, please run it manually"
fi

# Step 4: Refresh website with correct API Gateway URL
echo
echo "🌐 Step 4: Refreshing website with API Gateway URL..."
if [ -f "utils/refresh-website.sh" ]; then
    cd utils
    bash refresh-website.sh
    cd ..
    echo "✅ Website refreshed with correct API Gateway URL"
else
    echo "⚠️ refresh-website.sh not found, please run it manually"
fi

echo
echo "📋 Next Steps:"
echo "1. Equipment simulator has been started and initial data populated"
echo "2. Test API endpoints: /restaurants, /tickets, /equipment"
echo "3. Test strands-agent-chat: POST to /strands-agent-chat endpoint"
echo "4. Access dashboard and test contextual chat with any location"
echo "5. For continuous monitoring, restart simulator: python utils/equipment_simulator.py"
echo
echo "✅ Restaurant Kitchen Assistant with Strands Agent Chat Workflow is ready!"