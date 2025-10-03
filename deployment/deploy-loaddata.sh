#!/bin/bash

# AnyCompany Restaurant Monitoring System - Deploy and Load Data Utility
# This script syncs static website content to S3, invalidates CloudFront cache, and loads initial data

set -e

# Configuration - Get from CloudFormation stack
PROJECT_NAME="restaurant-kitchen-assistant"
ENVIRONMENT="production"
STACK_NAME="$PROJECT_NAME-base-infrastructure-$ENVIRONMENT"

# Get values from CloudFormation stack
BUCKET_NAME=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --query "Stacks[0].Outputs[?OutputKey=='BucketName'].OutputValue" \
  --output text)

DISTRIBUTION_ID=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --query "Stacks[0].Outputs[?OutputKey=='DistributionId'].OutputValue" \
  --output text)

CLOUDFRONT_URL=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --query "Stacks[0].Outputs[?OutputKey=='CloudFrontURL'].OutputValue" \
  --output text)

# Get Cognito details and update auth.js
USER_POOL_ID=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --query "Stacks[0].Outputs[?OutputKey=='UserPoolId'].OutputValue" \
  --output text)

CLIENT_ID=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --query "Stacks[0].Outputs[?OutputKey=='UserPoolClientId'].OutputValue" \
  --output text)

IDENTITY_POOL_ID=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --query "Stacks[0].Outputs[?OutputKey=='IdentityPoolId'].OutputValue" \
  --output text)

# Get API Gateway URL
API_URL=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --query "Stacks[0].Outputs[?OutputKey=='ApiUrl'].OutputValue" \
  --output text)

# Update website files with API Gateway URL
sed -i "" "s|API_GATEWAY_URL_PLACEHOLDER|$API_URL|g" source/index.html
sed -i "" "s|API_GATEWAY_URL_PLACEHOLDER|$API_URL|g" source/3d-twin.html
sed -i "" "s|API_GATEWAY_URL_PLACEHOLDER|$API_URL|g" source/tickets.html

# Update auth.js with current Cognito configuration
echo "🔧 Updating Cognito configuration in auth.js..."
echo "   User Pool ID: $USER_POOL_ID"
echo "   Client ID: $CLIENT_ID"
echo "   Identity Pool ID: $IDENTITY_POOL_ID"

# Replace any existing Cognito IDs with current ones
sed -i "" "s/userPoolId: '[^']*'/userPoolId: '$USER_POOL_ID'/g" source/auth.js
sed -i "" "s/userPoolWebClientId: '[^']*'/userPoolWebClientId: '$CLIENT_ID'/g" source/auth.js
sed -i "" "s/identityPoolId: '[^']*'/identityPoolId: '$IDENTITY_POOL_ID'/g" source/auth.js

# Update index.html with current Cognito configuration
sed -i "" "s/us-east-1_Y1bnUq9j6/$USER_POOL_ID/g" source/index.html
sed -i "" "s/4a3vljujtpmq3g3r5hg3lnb7e0/$CLIENT_ID/g" source/index.html

# Update login.html with current Cognito configuration
sed -i "" "s/us-east-1_XXXXXXXXX/$USER_POOL_ID/g" source/login.html
sed -i "" "s/XXXXXXXXXXXXXXXXXXXXXXXXXX/$CLIENT_ID/g" source/login.html

echo "🚀 AnyCompany Restaurant Monitoring System - Deploy and Load Data"
echo "================================================================="
echo ""

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

echo "📁 Step 1: Syncing static website content to S3..."
echo "   Bucket: s3://${BUCKET_NAME}/"
echo "   Source: source/"
echo ""

# Sync static website to S3
aws s3 sync source/ s3://${BUCKET_NAME}/ --delete

if [ $? -eq 0 ]; then
    echo "✅ S3 sync completed successfully"
else
    echo "❌ S3 sync failed"
    exit 1
fi

echo ""
echo "🌐 Step 2: Creating CloudFront invalidation..."
echo "   Distribution ID: ${DISTRIBUTION_ID}"
echo "   Paths: /*"
echo ""

# Create CloudFront invalidation
echo "Creating invalidation for distribution: ${DISTRIBUTION_ID}"
INVALIDATION_ID=$(aws cloudfront create-invalidation \
    --distribution-id ${DISTRIBUTION_ID} \
    --paths "/*" \
    --query 'Invalidation.Id' \
    --output text 2>/dev/null)

if [ $? -eq 0 ] && [ ! -z "$INVALIDATION_ID" ]; then
    echo "✅ CloudFront invalidation created successfully"
    echo "   Invalidation ID: ${INVALIDATION_ID}"
else
    echo "❌ CloudFront invalidation failed"
    echo "   Distribution ID: ${DISTRIBUTION_ID}"
    echo "   Please check if the distribution ID is correct"
    exit 1
fi

echo ""
echo "📊 Step 3: Loading initial restaurant data..."

# Load initial data using the simulator
if [ -f "deployment/simple_simulator.py" ]; then
    echo "Starting equipment simulator to populate initial data..."
    python3 deployment/simple_simulator.py
    echo "✅ Initial restaurant data loaded successfully"
else
    echo "⚠️ simple_simulator.py not found, please run it manually"
fi

echo ""
echo "🎯 Deploy and Load Data completed!"
echo "   Dashboard: ${CLOUDFRONT_URL}"
echo "   Invalidation ID: ${INVALIDATION_ID}"
echo "   Changes will be live within 5-15 minutes"
echo ""
echo "✨ Your AnyCompany Restaurant Monitoring System is ready with initial data!"