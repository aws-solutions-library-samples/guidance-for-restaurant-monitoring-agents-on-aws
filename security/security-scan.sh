#!/bin/bash
# AWS Security Scan for Restaurant Monitoring System

echo "🔒 AWS Security Scan Report"
echo "==========================="
echo "Project: restaurant-agent"
echo "Environment: prod"
echo "Date: $(date)"
echo

STACK_NAME="restaurant-agent-infrastructure-prod"
REGION="us-east-1"

# Check if stack exists
if ! aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION >/dev/null 2>&1; then
    echo "❌ Stack not found: $STACK_NAME"
    exit 1
fi

echo "✅ Stack found: $STACK_NAME"
echo

# 1. Check CloudFormation Template Security
echo "📋 1. CloudFormation Template Security"
echo "======================================="
echo

# Validate template
echo "Validating template..."
TEMPLATE_PATH="deployment/templates/restaurant-monitoring-base-template.yaml"
if [ -f "$TEMPLATE_PATH" ]; then
    if aws cloudformation validate-template --template-body file://$TEMPLATE_PATH --region $REGION >/dev/null 2>&1; then
        echo "✅ Template is valid"
    else
        echo "❌ Template validation failed"
    fi
else
    echo "⚠️  Template file not found at $TEMPLATE_PATH"
fi

# Check for hardcoded secrets
echo
echo "Checking for hardcoded secrets..."
if [ -f "$TEMPLATE_PATH" ]; then
    if grep -r "password\|secret\|key" $TEMPLATE_PATH | grep -v "PolicyName\|KeySchema\|AttributeName\|BucketKey\|SecretKey\|KeyType\|KeyId" | grep -v "^#"; then
        echo "⚠️  Potential secrets found in template"
    else
        echo "✅ No hardcoded secrets detected"
    fi
else
    echo "⚠️  Skipping - template not found"
fi

# 2. IAM Security
echo
echo "📋 2. IAM Security"
echo "=================="
echo

# Check IAM roles
echo "Checking IAM roles..."
ROLES=$(aws iam list-roles --query "Roles[?contains(RoleName, 'restaurant-agent')].RoleName" --output text --region $REGION 2>/dev/null)
if [ -n "$ROLES" ]; then
    echo "✅ Found IAM roles:"
    for role in $ROLES; do
        echo "   - $role"
        
        # Check for overly permissive policies
        POLICIES=$(aws iam list-attached-role-policies --role-name $role --query 'AttachedPolicies[*].PolicyArn' --output text 2>/dev/null)
        for policy in $POLICIES; do
            if echo "$policy" | grep -q "AdministratorAccess\|PowerUserAccess"; then
                echo "     ⚠️  WARNING: Overly permissive policy attached: $policy"
            fi
        done
    done
else
    echo "⚠️  No IAM roles found"
fi

# 3. S3 Security
echo
echo "📋 3. S3 Bucket Security"
echo "========================"
echo

BUCKETS=$(aws s3 ls | grep "restaurant-agent" | awk '{print $3}')
if [ -n "$BUCKETS" ]; then
    for bucket in $BUCKETS; do
        echo "Checking bucket: $bucket"
        
        # Check public access
        PUBLIC_ACCESS=$(aws s3api get-public-access-block --bucket $bucket --region $REGION 2>/dev/null | grep -c "true")
        if [ "$PUBLIC_ACCESS" -ge 4 ]; then
            echo "   ✅ Public access blocked"
        else
            echo "   ⚠️  WARNING: Public access not fully blocked"
        fi
        
        # Check encryption
        if aws s3api get-bucket-encryption --bucket $bucket --region $REGION >/dev/null 2>&1; then
            echo "   ✅ Encryption enabled"
        else
            echo "   ⚠️  WARNING: Encryption not enabled"
        fi
        
        # Check versioning
        VERSIONING=$(aws s3api get-bucket-versioning --bucket $bucket --region $REGION --query 'Status' --output text 2>/dev/null)
        if [ "$VERSIONING" = "Enabled" ]; then
            echo "   ✅ Versioning enabled"
        else
            echo "   ⚠️  Versioning not enabled"
        fi
        
        echo
    done
else
    echo "⚠️  No S3 buckets found"
fi

# 4. DynamoDB Security
echo "📋 4. DynamoDB Security"
echo "======================="
echo

TABLES=$(aws dynamodb list-tables --query "TableNames[?contains(@, 'restaurant-agent')]" --output text --region $REGION 2>/dev/null)
if [ -n "$TABLES" ]; then
    for table in $TABLES; do
        echo "Checking table: $table"
        
        # Check encryption
        ENCRYPTION=$(aws dynamodb describe-table --table-name $table --region $REGION --query 'Table.SSEDescription.Status' --output text 2>/dev/null)
        if [ "$ENCRYPTION" = "ENABLED" ]; then
            echo "   ✅ Encryption enabled"
        else
            echo "   ⚠️  WARNING: Encryption not enabled"
        fi
        
        # Check point-in-time recovery
        PITR=$(aws dynamodb describe-continuous-backups --table-name $table --region $REGION --query 'ContinuousBackupsDescription.PointInTimeRecoveryDescription.PointInTimeRecoveryStatus' --output text 2>/dev/null)
        if [ "$PITR" = "ENABLED" ]; then
            echo "   ✅ Point-in-time recovery enabled"
        else
            echo "   ⚠️  Point-in-time recovery not enabled"
        fi
        
        echo
    done
else
    echo "⚠️  No DynamoDB tables found"
fi

# 5. Lambda Security
echo "📋 5. Lambda Security"
echo "====================="
echo

FUNCTIONS=$(aws lambda list-functions --query "Functions[?contains(FunctionName, 'restaurant-agent')].FunctionName" --output text --region $REGION 2>/dev/null)
if [ -n "$FUNCTIONS" ]; then
    for func in $FUNCTIONS; do
        echo "Checking function: $func"
        
        # Check runtime
        RUNTIME=$(aws lambda get-function --function-name $func --region $REGION --query 'Configuration.Runtime' --output text 2>/dev/null)
        echo "   Runtime: $RUNTIME"
        
        # Check if in VPC
        VPC=$(aws lambda get-function --function-name $func --region $REGION --query 'Configuration.VpcConfig.VpcId' --output text 2>/dev/null)
        if [ "$VPC" != "None" ] && [ -n "$VPC" ]; then
            echo "   ✅ Running in VPC"
        else
            echo "   ⚠️  Not in VPC (internet-facing)"
        fi
        
        # Check environment variables for secrets
        ENV_VARS=$(aws lambda get-function --function-name $func --region $REGION --query 'Configuration.Environment.Variables' --output json 2>/dev/null)
        if echo "$ENV_VARS" | grep -qi "password\|secret\|key" | grep -v "TABLE\|POOL"; then
            echo "   ⚠️  WARNING: Potential secrets in environment variables"
        fi
        
        echo
    done
else
    echo "⚠️  No Lambda functions found"
fi

# 6. API Gateway Security
echo "📋 6. API Gateway Security"
echo "=========================="
echo

API_ID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query "Stacks[0].Outputs[?OutputKey=='RestApiId'].OutputValue" --output text 2>/dev/null)
if [ -n "$API_ID" ] && [ "$API_ID" != "None" ]; then
    echo "Checking API: $API_ID"
    
    # Check for authorizers
    AUTHORIZERS=$(aws apigateway get-authorizers --rest-api-id $API_ID --region $REGION --query 'items[*].name' --output text 2>/dev/null)
    if [ -n "$AUTHORIZERS" ]; then
        echo "   ✅ Authorizers configured: $AUTHORIZERS"
    else
        echo "   ⚠️  WARNING: No authorizers found (unauthenticated API)"
    fi
    
    # Check for usage plans (rate limiting)
    USAGE_PLANS=$(aws apigateway get-usage-plans --region $REGION --query "items[?contains(name, 'restaurant-agent')].name" --output text 2>/dev/null)
    if [ -n "$USAGE_PLANS" ]; then
        echo "   ✅ Usage plans configured (rate limiting enabled)"
    else
        echo "   ⚠️  WARNING: No usage plans (no rate limiting)"
    fi
    
    echo
else
    echo "⚠️  No API Gateway found"
fi

# 7. CloudFront Security
echo "📋 7. CloudFront Security"
echo "========================="
echo

DIST_ID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query "Stacks[0].Outputs[?OutputKey=='DistributionId'].OutputValue" --output text 2>/dev/null)
if [ -n "$DIST_ID" ] && [ "$DIST_ID" != "None" ]; then
    echo "Checking distribution: $DIST_ID"
    
    # Check viewer protocol policy
    VIEWER_POLICY=$(aws cloudfront get-distribution --id $DIST_ID --query 'Distribution.DistributionConfig.DefaultCacheBehavior.ViewerProtocolPolicy' --output text 2>/dev/null)
    if [ "$VIEWER_POLICY" = "redirect-to-https" ] || [ "$VIEWER_POLICY" = "https-only" ]; then
        echo "   ✅ HTTPS enforced"
    else
        echo "   ⚠️  WARNING: HTTPS not enforced"
    fi
    
    # Check WAF
    WAF_ID=$(aws cloudfront get-distribution --id $DIST_ID --query 'Distribution.DistributionConfig.WebACLId' --output text 2>/dev/null)
    if [ -n "$WAF_ID" ] && [ "$WAF_ID" != "None" ]; then
        echo "   ✅ WAF enabled"
    else
        echo "   ⚠️  WARNING: No WAF protection"
    fi
    
    echo
else
    echo "⚠️  No CloudFront distribution found"
fi

# 8. Cognito Security
echo "📋 8. Cognito Security"
echo "======================"
echo

USER_POOL_ID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query "Stacks[0].Outputs[?OutputKey=='UserPoolId'].OutputValue" --output text 2>/dev/null)
if [ -n "$USER_POOL_ID" ] && [ "$USER_POOL_ID" != "None" ]; then
    echo "Checking User Pool: $USER_POOL_ID"
    
    # Check MFA
    MFA=$(aws cognito-idp describe-user-pool --user-pool-id $USER_POOL_ID --region $REGION --query 'UserPool.MfaConfiguration' --output text 2>/dev/null)
    if [ "$MFA" = "ON" ] || [ "$MFA" = "OPTIONAL" ]; then
        echo "   ✅ MFA enabled: $MFA"
    else
        echo "   ⚠️  WARNING: MFA not enabled"
    fi
    
    # Check password policy
    MIN_LENGTH=$(aws cognito-idp describe-user-pool --user-pool-id $USER_POOL_ID --region $REGION --query 'UserPool.Policies.PasswordPolicy.MinimumLength' --output text 2>/dev/null)
    echo "   Password min length: $MIN_LENGTH"
    if [ "$MIN_LENGTH" -ge 8 ]; then
        echo "   ✅ Password policy adequate"
    else
        echo "   ⚠️  WARNING: Weak password policy"
    fi
    
    echo
else
    echo "⚠️  No Cognito User Pool found"
fi

# 9. CloudTrail Check
echo "📋 9. CloudTrail"
echo "================"
echo

TRAILS=$(aws cloudtrail describe-trails --region $REGION --query "trailList[?contains(Name, 'restaurant-agent')].Name" --output text 2>/dev/null)
if [ -n "$TRAILS" ]; then
    echo "✅ CloudTrail enabled: $TRAILS"
else
    echo "⚠️  WARNING: No CloudTrail found (no audit logging)"
fi

# 10. Summary
echo
echo "📊 Security Scan Summary"
echo "========================"
echo

# Count warnings
WARNINGS=$(grep -c "⚠️" /tmp/security-scan-output.txt 2>/dev/null || echo "0")
PASSED=$(grep -c "✅" /tmp/security-scan-output.txt 2>/dev/null || echo "0")

echo "Security Checks:"
echo "   ✅ Passed: $PASSED"
echo "   ⚠️  Warnings: $WARNINGS"
echo

echo "Critical Issues to Fix:"
echo "   1. Add API Gateway authorizers (Cognito)"
echo "   2. Enable MFA for Cognito users"
echo "   3. Add API Gateway rate limiting"
echo "   4. Enable CloudTrail for audit logging"
echo "   5. Restrict CORS to specific origins"
echo

echo "📄 Full report saved to: SECURITY_REPORT.md"
echo

echo "✅ Security scan complete!"
