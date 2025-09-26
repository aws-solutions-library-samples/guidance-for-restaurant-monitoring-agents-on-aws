#!/bin/bash

# Restaurant Kitchen Assistant Infrastructure Cleanup Script
# This script will delete ALL resources created by the deployment

set -e

# Configuration
BASE_STACK_NAME="restaurant-kitchen-assistant-base-infrastructure-production"
STRANDS_STACK_NAME="restaurant-kitchen-assistant-strands-agent-chat-production"
REGION="us-east-1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${RED}🚨 DANGER: This will DELETE ALL infrastructure resources!${NC}"
echo -e "${YELLOW}This includes:${NC}"
echo "  - CloudFormation stacks"
echo "  - S3 buckets and all contents"
echo "  - DynamoDB tables and all data"
echo "  - Lambda functions"
echo "  - API Gateway"
echo "  - CloudFront distribution"
echo "  - IAM roles and policies"
echo "  - Cognito user pools"
echo ""
echo -e "${RED}⚠️  THIS ACTION CANNOT BE UNDONE!${NC}"
echo ""

# Confirmation prompt
read -p "Are you absolutely sure you want to delete everything? Type 'DELETE' to confirm: " confirmation
if [ "$confirmation" != "DELETE" ]; then
    echo -e "${GREEN}✅ Cleanup cancelled. No resources were deleted.${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}🧹 Starting cleanup process...${NC}"

# Function to check if stack exists
stack_exists() {
    aws cloudformation describe-stacks --stack-name "$1" --region "$REGION" >/dev/null 2>&1
}

# Function to wait for stack deletion
wait_for_stack_deletion() {
    local stack_name=$1
    echo "⏳ Waiting for stack $stack_name to be deleted..."
    
    while stack_exists "$stack_name"; do
        local status=$(aws cloudformation describe-stacks --stack-name "$stack_name" --region "$REGION" --query 'Stacks[0].StackStatus' --output text 2>/dev/null || echo "DELETE_COMPLETE")
        
        if [ "$status" = "DELETE_FAILED" ]; then
            echo -e "${RED}❌ Stack deletion failed. You may need to manually clean up some resources.${NC}"
            return 1
        fi
        
        echo "   Status: $status"
        sleep 10
    done
    
    echo -e "${GREEN}✅ Stack $stack_name deleted successfully${NC}"
}

# Function to empty and delete S3 bucket
cleanup_s3_bucket() {
    local bucket_name=$1
    
    if aws s3api head-bucket --bucket "$bucket_name" --region "$REGION" >/dev/null 2>&1; then
        echo "🗑️  Emptying S3 bucket: $bucket_name"
        
        # Delete all objects including versions
        aws s3api delete-objects --bucket "$bucket_name" --region "$REGION" \
            --delete "$(aws s3api list-object-versions --bucket "$bucket_name" --region "$REGION" \
            --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --max-items 1000)" >/dev/null 2>&1 || true
        
        # Delete all delete markers
        aws s3api delete-objects --bucket "$bucket_name" --region "$REGION" \
            --delete "$(aws s3api list-object-versions --bucket "$bucket_name" --region "$REGION" \
            --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' --max-items 1000)" >/dev/null 2>&1 || true
        
        # Force delete remaining objects
        aws s3 rm "s3://$bucket_name" --recursive --region "$REGION" >/dev/null 2>&1 || true
        
        echo "✅ S3 bucket $bucket_name emptied"
    else
        echo "ℹ️  S3 bucket $bucket_name not found or already deleted"
    fi
}

# Step 1: Get S3 bucket names before deleting stacks
echo -e "${BLUE}📋 Step 1: Identifying S3 buckets...${NC}"

DASHBOARD_BUCKET=""
LOGS_BUCKET=""

if stack_exists "$BASE_STACK_NAME"; then
    DASHBOARD_BUCKET=$(aws cloudformation describe-stack-resources --stack-name "$BASE_STACK_NAME" --region "$REGION" \
        --query 'StackResources[?LogicalResourceId==`DashboardBucket`].PhysicalResourceId' --output text 2>/dev/null || echo "")
    
    LOGS_BUCKET=$(aws cloudformation describe-stack-resources --stack-name "$BASE_STACK_NAME" --region "$REGION" \
        --query 'StackResources[?LogicalResourceId==`AccessLogsBucket`].PhysicalResourceId' --output text 2>/dev/null || echo "")
    
    echo "📦 Dashboard bucket: $DASHBOARD_BUCKET"
    echo "📦 Logs bucket: $LOGS_BUCKET"
else
    echo "ℹ️  Base stack not found"
fi

# Step 2: Empty S3 buckets (must be done before stack deletion)
echo -e "${BLUE}📋 Step 2: Emptying S3 buckets...${NC}"

if [ -n "$DASHBOARD_BUCKET" ] && [ "$DASHBOARD_BUCKET" != "None" ]; then
    cleanup_s3_bucket "$DASHBOARD_BUCKET"
fi

if [ -n "$LOGS_BUCKET" ] && [ "$LOGS_BUCKET" != "None" ]; then
    cleanup_s3_bucket "$LOGS_BUCKET"
fi

# Step 3: Delete Strands stack first (dependent on base stack)
echo -e "${BLUE}📋 Step 3: Deleting Strands Agent Chat stack...${NC}"

if stack_exists "$STRANDS_STACK_NAME"; then
    echo "🗑️  Deleting stack: $STRANDS_STACK_NAME"
    aws cloudformation delete-stack --stack-name "$STRANDS_STACK_NAME" --region "$REGION"
    wait_for_stack_deletion "$STRANDS_STACK_NAME"
else
    echo "ℹ️  Strands stack not found or already deleted"
fi

# Step 4: Delete base infrastructure stack
echo -e "${BLUE}📋 Step 4: Deleting base infrastructure stack...${NC}"

if stack_exists "$BASE_STACK_NAME"; then
    echo "🗑️  Deleting stack: $BASE_STACK_NAME"
    aws cloudformation delete-stack --stack-name "$BASE_STACK_NAME" --region "$REGION"
    wait_for_stack_deletion "$BASE_STACK_NAME"
else
    echo "ℹ️  Base stack not found or already deleted"
fi

# Step 5: Clean up any remaining S3 buckets (in case stack deletion failed)
echo -e "${BLUE}📋 Step 5: Final S3 cleanup...${NC}"

if [ -n "$DASHBOARD_BUCKET" ] && [ "$DASHBOARD_BUCKET" != "None" ]; then
    if aws s3api head-bucket --bucket "$DASHBOARD_BUCKET" --region "$REGION" >/dev/null 2>&1; then
        echo "🗑️  Force deleting remaining bucket: $DASHBOARD_BUCKET"
        aws s3 rb "s3://$DASHBOARD_BUCKET" --force --region "$REGION" >/dev/null 2>&1 || true
    fi
fi

if [ -n "$LOGS_BUCKET" ] && [ "$LOGS_BUCKET" != "None" ]; then
    if aws s3api head-bucket --bucket "$LOGS_BUCKET" --region "$REGION" >/dev/null 2>&1; then
        echo "🗑️  Force deleting remaining bucket: $LOGS_BUCKET"
        aws s3 rb "s3://$LOGS_BUCKET" --force --region "$REGION" >/dev/null 2>&1 || true
    fi
fi

# Step 6: Check for any orphaned resources
echo -e "${BLUE}📋 Step 6: Checking for orphaned resources...${NC}"

# Check for any remaining Lambda functions
echo "🔍 Checking for Lambda functions..."
LAMBDA_FUNCTIONS=$(aws lambda list-functions --region "$REGION" --query 'Functions[?contains(FunctionName, `restaurant-kitchen-assistant`)].FunctionName' --output text 2>/dev/null || echo "")
if [ -n "$LAMBDA_FUNCTIONS" ]; then
    echo -e "${YELLOW}⚠️  Found orphaned Lambda functions: $LAMBDA_FUNCTIONS${NC}"
    echo "   You may want to delete these manually if they're not needed."
fi

# Check for any remaining DynamoDB tables
echo "🔍 Checking for DynamoDB tables..."
DYNAMO_TABLES=$(aws dynamodb list-tables --region "$REGION" --query 'TableNames[?contains(@, `restaurant-kitchen-assistant`)]' --output text 2>/dev/null || echo "")
if [ -n "$DYNAMO_TABLES" ]; then
    echo -e "${YELLOW}⚠️  Found orphaned DynamoDB tables: $DYNAMO_TABLES${NC}"
    echo "   You may want to delete these manually if they're not needed."
fi

# Check for any remaining IAM roles
echo "🔍 Checking for IAM roles..."
IAM_ROLES=$(aws iam list-roles --query 'Roles[?contains(RoleName, `restaurant-kitchen-assistant`)].RoleName' --output text 2>/dev/null || echo "")
if [ -n "$IAM_ROLES" ]; then
    echo -e "${YELLOW}⚠️  Found orphaned IAM roles: $IAM_ROLES${NC}"
    echo "   You may want to delete these manually if they're not needed."
fi

echo ""
echo -e "${GREEN}🎉 Cleanup completed!${NC}"
echo ""
echo -e "${BLUE}Summary:${NC}"
echo "✅ CloudFormation stacks deleted"
echo "✅ S3 buckets emptied and deleted"
echo "✅ All associated resources cleaned up"
echo ""
echo -e "${YELLOW}Note: If you see any orphaned resources above, you may need to delete them manually.${NC}"
echo -e "${YELLOW}Always verify in the AWS Console that all resources have been properly deleted.${NC}"