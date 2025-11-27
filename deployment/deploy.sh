#!/bin/bash

echo "🚀 Restaurant Monitoring System - Direct Code Deploy"
echo "===================================================="
echo ""

# Step 1: Deploy infrastructure
echo "📦 Step 1: Deploying infrastructure..."
aws cloudformation deploy \
  --template-file infrastructure/cloudformation/complete-infrastructure.yaml \
  --stack-name rest-monitor-base-infrastructure-prod \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides Environment=production

if [ $? -ne 0 ]; then
    echo "❌ Infrastructure deployment failed"
    exit 1
fi
echo "✅ Infrastructure deployed"
echo ""

# Step 2: Deploy AgentCore agent
echo "🤖 Step 2: Deploying AgentCore agent (direct code)..."
cd ../src/agentcore-direct/
if [ ! -d "venv" ]; then
    python3 -m venv venv
    source venv/bin/activate
    pip install bedrock-agentcore-starter-toolkit --quiet
else
    source venv/bin/activate
fi

./venv/bin/agentcore launch --agent restaurant_ops_full --auto-update-on-conflict

if [ $? -ne 0 ]; then
    echo "❌ AgentCore deployment failed"
    exit 1
fi
echo "✅ AgentCore agent deployed"
cd ../../deployment
echo ""

# Step 3: Deploy frontend
echo "🌐 Step 3: Deploying frontend..."
BUCKET_NAME=$(aws cloudformation describe-stacks \
    --stack-name rest-monitor-base-infrastructure-prod \
    --query 'Stacks[0].Outputs[?OutputKey==`WebsiteBucket`].OutputValue' \
    --output text)

if [ -z "$BUCKET_NAME" ]; then
    echo "❌ Could not find S3 bucket"
    exit 1
fi

aws s3 sync ../frontend/ s3://$BUCKET_NAME/ --exclude "*.DS_Store"

DISTRIBUTION_ID=$(aws cloudfront list-distributions --query "DistributionList.Items[?Origins.Items[0].DomainName==\`${BUCKET_NAME}.s3.us-east-1.amazonaws.com\`].Id" --output text)
if [ -n "$DISTRIBUTION_ID" ]; then
    aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths "/*" > /dev/null
fi

echo "✅ Frontend deployed"
echo ""

# Step 4: Load data
echo "📊 Step 4: Loading data..."
./scripts/data-loading/load-all-normal-data.sh
python3 scripts/data-loading/simple_simulator.py
echo "✅ Data loaded"
echo ""

# Get CloudFront URL
CLOUDFRONT_URL=$(aws cloudformation describe-stacks \
    --stack-name rest-monitor-base-infrastructure-prod \
    --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontURL`].OutputValue' \
    --output text)

echo "===================================================="
echo "✅ Deployment Complete!"
echo "===================================================="
echo ""
echo "🌐 Frontend: $CLOUDFRONT_URL"
echo "📊 Data: 10 restaurants, 70 equipment, 102 inventory, 140 staffing"
echo "🤖 Agent: Direct code deploy (30 sec updates)"
echo ""
echo "🔐 Sign up at the dashboard to get started!"
echo ""
