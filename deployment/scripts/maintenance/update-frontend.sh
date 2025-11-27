#!/bin/bash

echo "🚀 Deploying Updated Frontend..."

# Get S3 bucket name from CloudFormation
BUCKET_NAME=$(aws cloudformation describe-stacks \
    --stack-name rest-monitor-complete-infrastructure-prod \
    --query 'Stacks[0].Outputs[?OutputKey==`WebsiteBucket`].OutputValue' \
    --output text)

if [ -z "$BUCKET_NAME" ]; then
    echo "❌ Could not find S3 bucket name"
    exit 1
fi

echo "📦 Uploading to bucket: $BUCKET_NAME"

# Upload all frontend files
cd ../../frontend
aws s3 sync . s3://$BUCKET_NAME/ \
    --exclude "*.DS_Store" \
    --cache-control "max-age=300"

echo "✅ Frontend files uploaded"

# Get CloudFront distribution ID
DISTRIBUTION_ID=$(aws cloudformation describe-stacks \
    --stack-name rest-monitor-complete-infrastructure-prod \
    --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontDistributionId`].OutputValue' \
    --output text)

if [ -n "$DISTRIBUTION_ID" ]; then
    echo "🔄 Invalidating CloudFront cache..."
    aws cloudfront create-invalidation \
        --distribution-id $DISTRIBUTION_ID \
        --paths "/*" > /dev/null
    echo "✅ Cache invalidated"
fi

# Get CloudFront URL
CLOUDFRONT_URL=$(aws cloudformation describe-stacks \
    --stack-name rest-monitor-complete-infrastructure-prod \
    --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontURL`].OutputValue' \
    --output text)

echo ""
echo "✅ Frontend deployment complete!"
echo "🌐 Access your dashboard at: $CLOUDFRONT_URL"
