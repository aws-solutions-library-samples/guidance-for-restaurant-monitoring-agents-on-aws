#!/bin/bash

# AnyCompany Restaurant Monitoring System - Website Refresh Utility
# This script syncs static website content to S3 and invalidates CloudFront cache

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
sed -i "" "s|API_GATEWAY_URL_PLACEHOLDER|$API_URL|g" static-website/index.html
sed -i "" "s|API_GATEWAY_URL_PLACEHOLDER|$API_URL|g" static-website/3d-twin.html
sed -i "" "s|API_GATEWAY_URL_PLACEHOLDER|$API_URL|g" static-website/tickets.html

# Update auth.js with current Cognito configuration
sed -i "" "s/us-east-1_XXXXXXXXX/$USER_POOL_ID/g" static-website/auth.js
sed -i "" "s/XXXXXXXXXXXXXXXXXXXXXXXXXX/$CLIENT_ID/g" static-website/auth.js
sed -i "" "s|us-east-1:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx|$IDENTITY_POOL_ID|g" static-website/auth.js

# Update index.html with current Cognito configuration
sed -i "" "s/us-east-1_Y1bnUq9j6/$USER_POOL_ID/g" static-website/index.html
sed -i "" "s/4a3vljujtpmq3g3r5hg3lnb7e0/$CLIENT_ID/g" static-website/index.html

# Update login.html with current Cognito configuration
sed -i "" "s/us-east-1_XXXXXXXXX/$USER_POOL_ID/g" static-website/login.html
sed -i "" "s/XXXXXXXXXXXXXXXXXXXXXXXXXX/$CLIENT_ID/g" static-website/login.html

echo "🚀 AnyCompany Restaurant Monitoring System - Website Refresh"
echo "============================================================"
echo ""

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

echo "📁 Syncing static website content to S3..."
echo "   Bucket: s3://${BUCKET_NAME}/"
echo "   Source: static-website/"
echo ""

# Sync static website to S3
aws s3 sync static-website/ s3://${BUCKET_NAME}/ --delete

if [ $? -eq 0 ]; then
    echo "✅ S3 sync completed successfully"
else
    echo "❌ S3 sync failed"
    exit 1
fi

echo ""
echo "🌐 Creating CloudFront invalidation..."
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
    echo ""
    echo "🎯 Website refresh completed!"
    echo "   Dashboard: ${CLOUDFRONT_URL}"
    echo "   Invalidation ID: ${INVALIDATION_ID}"
    echo "   Changes will be live within 5-15 minutes"
else
    echo "❌ CloudFront invalidation failed"
    echo "   Distribution ID: ${DISTRIBUTION_ID}"
    echo "   Please check if the distribution ID is correct"
    exit 1
fi

echo ""
echo "✨ All done! Your AnyCompany Restaurant Monitoring System is updated."