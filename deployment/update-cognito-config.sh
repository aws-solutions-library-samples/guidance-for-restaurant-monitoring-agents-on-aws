#!/bin/bash

# Update Cognito Configuration in Static Website Files
# Run this after deploying Cognito stack

PROJECT_NAME="restaurant-kitchen-assistant"
ENVIRONMENT="production"

echo "🔑 Updating Cognito Configuration..."

# Get Cognito details from CloudFormation
USER_POOL_ID=$(aws cloudformation describe-stacks \
  --stack-name ${PROJECT_NAME}-base-infrastructure-${ENVIRONMENT} \
  --query "Stacks[0].Outputs[?OutputKey=='UserPoolId'].OutputValue" \
  --output text \
  --region us-east-1)

CLIENT_ID=$(aws cloudformation describe-stacks \
  --stack-name ${PROJECT_NAME}-base-infrastructure-${ENVIRONMENT} \
  --query "Stacks[0].Outputs[?OutputKey=='UserPoolClientId'].OutputValue" \
  --output text \
  --region us-east-1)

IDENTITY_POOL_ID=$(aws cloudformation describe-stacks \
  --stack-name ${PROJECT_NAME}-base-infrastructure-${ENVIRONMENT} \
  --query "Stacks[0].Outputs[?OutputKey=='IdentityPoolId'].OutputValue" \
  --output text \
  --region us-east-1)

echo "User Pool ID: $USER_POOL_ID"
echo "Client ID: $CLIENT_ID"
echo "Identity Pool ID: $IDENTITY_POOL_ID"

# Update index.html
sed -i "" "s/userPoolId: 'us-east-1_XXXXXXXXX'/userPoolId: '$USER_POOL_ID'/g" static-website/index.html
sed -i "" "s/userPoolWebClientId: 'XXXXXXXXXXXXXXXXXXXXXXXXXX'/userPoolWebClientId: '$CLIENT_ID'/g" static-website/index.html

# Update login.html
sed -i "" "s/userPoolId: 'us-east-1_XXXXXXXXX'/userPoolId: '$USER_POOL_ID'/g" static-website/login.html
sed -i "" "s/userPoolWebClientId: 'XXXXXXXXXXXXXXXXXXXXXXXXXX'/userPoolWebClientId: '$CLIENT_ID'/g" static-website/login.html

echo "✅ Cognito configuration updated in static website files"
echo "📤 Run ./refresh-website.sh to upload changes to S3"