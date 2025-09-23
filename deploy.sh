#!/bin/bash

# Restaurant Kitchen Assistant Infrastructure Deployment Script

set -e

# Configuration
STACK_NAME="restaurant-kitchen-assistant-base"
TEMPLATE_FILE="infrastructure/restaurant-monitoring-base-template.yaml"
REGION="us-east-1"
PROJECT_NAME="restaurant-kitchen-assistant"
ENVIRONMENT="production"

echo "🚀 Deploying Restaurant Kitchen Assistant Infrastructure..."
echo "Stack Name: $STACK_NAME"
echo "Region: $REGION"
echo "Template: $TEMPLATE_FILE"

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

echo "✅ AWS CLI configured"

# Deploy the base infrastructure
echo "📦 Deploying base infrastructure stack..."
aws cloudformation deploy \
    --template-file "$TEMPLATE_FILE" \
    --stack-name "$STACK_NAME" \
    --parameter-overrides \
        ProjectName="$PROJECT_NAME" \
        Environment="$ENVIRONMENT" \
    --capabilities CAPABILITY_NAMED_IAM \
    --region "$REGION" \
    --no-fail-on-empty-changeset

if [ $? -eq 0 ]; then
    echo "✅ Base infrastructure deployed successfully!"
    
    # Get outputs
    echo "📋 Stack Outputs:"
    aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$REGION" \
        --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
        --output table
    
    # Deploy Strands workflow if base stack succeeded
    STRANDS_STACK_NAME="restaurant-kitchen-assistant-strands"
    STRANDS_TEMPLATE="infrastructure/strands-agent-chat-workflow.yaml"
    
    # Get required parameters from base stack
    REST_API_ID=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`RestApiId`].OutputValue' \
        --output text)
    
    REST_API_ROOT_RESOURCE_ID=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`RestApiRootResourceId`].OutputValue' \
        --output text)
    
    if [ -n "$REST_API_ID" ] && [ -n "$REST_API_ROOT_RESOURCE_ID" ]; then
        echo "🔗 Deploying Strands workflow stack..."
        aws cloudformation deploy \
            --template-file "$STRANDS_TEMPLATE" \
            --stack-name "$STRANDS_STACK_NAME" \
            --parameter-overrides \
                ProjectName="$PROJECT_NAME" \
                Environment="$ENVIRONMENT" \
                RestApiId="$REST_API_ID" \
                RestApiRootResourceId="$REST_API_ROOT_RESOURCE_ID" \
            --capabilities CAPABILITY_NAMED_IAM \
            --region "$REGION" \
            --no-fail-on-empty-changeset
        
        if [ $? -eq 0 ]; then
            echo "✅ Strands workflow deployed successfully!"
        else
            echo "⚠️  Strands workflow deployment failed, but base infrastructure is ready"
        fi
    else
        echo "⚠️  Could not get API Gateway details, skipping Strands workflow deployment"
    fi
    
else
    echo "❌ Base infrastructure deployment failed!"
    exit 1
fi

echo "🎉 Deployment complete!"