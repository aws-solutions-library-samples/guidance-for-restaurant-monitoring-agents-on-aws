#!/bin/bash
set -e

echo "🗑️  Cleaning up all restaurant agent resources..."

STACKS=(
    "restaurant-agent-chat-prod"
    "restaurant-agent-infrastructure-prod"
)

for STACK in "${STACKS[@]}"; do
    echo "Checking stack: $STACK"
    if aws cloudformation describe-stacks --stack-name $STACK &>/dev/null; then
        echo "  Deleting $STACK..."
        
        # Empty S3 buckets first
        BUCKETS=$(aws cloudformation describe-stack-resources --stack-name $STACK --query 'StackResources[?ResourceType==`AWS::S3::Bucket`].PhysicalResourceId' --output text 2>/dev/null || echo "")
        for BUCKET in $BUCKETS; do
            if [ ! -z "$BUCKET" ]; then
                echo "    Emptying bucket: $BUCKET"
                aws s3 rm s3://$BUCKET --recursive 2>/dev/null || true
            fi
        done
        
        aws cloudformation delete-stack --stack-name $STACK
    else
        echo "  Stack not found, skipping"
    fi
done

echo "⏳ Waiting for stacks to delete..."
for STACK in "${STACKS[@]}"; do
    if aws cloudformation describe-stacks --stack-name $STACK &>/dev/null; then
        echo "  Waiting for $STACK..."
        aws cloudformation wait stack-delete-complete --stack-name $STACK 2>/dev/null || true
    fi
done

echo "✅ Cleanup complete!"
