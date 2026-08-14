#!/bin/bash
# Invalidate the CloudFront cache after a frontend update.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/config.env" ]; then
    source "$SCRIPT_DIR/config.env"
fi
REGION="${AWS_REGION:-us-east-1}"

echo "🔄 Invalidating CloudFront cache..."

# Resolve the distribution ID from the infrastructure stack output
DIST_ID=$(aws cloudformation describe-stacks \
    --stack-name restaurant-agent-infrastructure-prod \
    --query 'Stacks[0].Outputs[?OutputKey==`DistributionId`].OutputValue' \
    --output text --region "$REGION" 2>/dev/null || echo "")

if [ -z "$DIST_ID" ] || [ "$DIST_ID" == "None" ]; then
    echo "⚠️  Could not find a CloudFront distribution from the stack outputs."
    echo "    Ensure the infrastructure stack is deployed, then retry."
    echo "    You can also hard-refresh the browser (Cmd/Ctrl+Shift+R) to bypass cache."
    exit 0
fi

echo "Found CloudFront distribution: $DIST_ID"

# Create invalidation
aws cloudfront create-invalidation \
    --distribution-id "$DIST_ID" \
    --paths "/*" \
    --query 'Invalidation.{Id:Id,Status:Status,CreateTime:CreateTime}' \
    --output table

DOMAIN=$(aws cloudfront get-distribution --id "$DIST_ID" \
    --query 'Distribution.DomainName' --output text)

echo ""
echo "✅ CloudFront cache invalidation initiated"
echo "CloudFront URL: https://$DOMAIN"
