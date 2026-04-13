#!/bin/bash

# Script to invalidate CloudFront cache for frontend updates

echo "🔄 Invalidating CloudFront cache..."

# Find CloudFront distribution
DIST_ID=$(aws cloudfront list-distributions --query 'DistributionList.Items[0].Id' --output text 2>/dev/null)

if [ -z "$DIST_ID" ] || [ "$DIST_ID" == "None" ]; then
    echo "⚠️  No CloudFront distribution found"
    echo ""
    echo "The frontend was uploaded directly to S3:"
    echo "  s3://restaurant-kitchen-assistant-frontend-production-799335355534/index.html"
    echo ""
    echo "To see the changes immediately:"
    echo "1. Access S3 directly (if public)"
    echo "2. Or wait for browser cache to expire"
    echo "3. Or use hard refresh: Ctrl+Shift+R (Windows) or Cmd+Shift+R (Mac)"
    exit 0
fi

echo "Found CloudFront distribution: $DIST_ID"

# Create invalidation
aws cloudfront create-invalidation \
    --distribution-id $DIST_ID \
    --paths "/*" \
    --query 'Invalidation.{Id:Id,Status:Status,CreateTime:CreateTime}' \
    --output table

echo ""
echo "✅ CloudFront cache invalidation initiated"
echo ""
echo "The updated frontend with voice chat icons will be available shortly."
echo "CloudFront URL: https://$(aws cloudfront get-distribution --id $DIST_ID --query 'Distribution.DomainName' --output text)"
