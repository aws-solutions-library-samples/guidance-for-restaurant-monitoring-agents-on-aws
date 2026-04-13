---
inclusion: fileMatch
fileMatchPattern: "**/*.sh,**/deploy*,**/cleanup*"
---

# Deployment Standards

## File Organization

⚠️ **IMPORTANT**: All deployment logs, test outputs, and working documents MUST be saved to `temp/` folder.

```bash
# Correct locations for generated files:
temp/deployment-archive/     # Archived scripts
temp/deployment-legacy/      # Deprecated scripts
temp/infrastructure/         # Reference templates
```

**DO NOT** create deployment summaries or logs in the project root.

## Quick Reference

```bash
# Full deployment (recommended)
./deployment/deploy-all.sh

# AgentCore agent only
./deployment/deploy-agentcore-cli.sh

# Cleanup all resources
./deployment/utils/cleanup-all.sh
```

## Deployment Order

1. Base Infrastructure → `restaurant-agent-infrastructure-prod`
2. Inventory Tables → `restaurant-agent-inventory-prod`
3. Staffing Tables → `restaurant-agent-staffing-prod`
4. Sample Data → `load-sample-data.py`
5. AgentCore Agent → `agentcore deploy`
6. Chat Endpoints → `restaurant-agent-chat-prod`, `restaurant-agent-chat-streaming-prod`
7. Frontend → S3 sync + CloudFront invalidation

## CloudFormation Stack Names

| Stack | Template | Purpose |
|-------|----------|---------|
| `restaurant-agent-infrastructure-prod` | `restaurant-monitoring-base-template.yaml` | Base infra |
| `restaurant-agent-inventory-prod` | `inventory-infra.yaml` | Inventory tables |
| `restaurant-agent-staffing-prod` | `staffing-infra.yaml` | Staffing tables |
| `restaurant-agent-chat-prod` | `chat-endpoint.yaml` | Standard chat |
| `restaurant-agent-chat-streaming-prod` | `chat-endpoint-streaming.yaml` | Streaming chat |

## AgentCore CLI Commands

```bash
# Install CLI
pipx install bedrock-agentcore-starter-toolkit

# Configure agent
agentcore configure \
    --entrypoint agent.py \
    --name restaurant_agent \
    --runtime PYTHON_3_11 \
    --region us-east-1 \
    --disable-memory \
    --non-interactive

# Deploy
agentcore deploy

# Check status
agentcore status

# Test invoke
agentcore invoke '{"prompt": "List restaurants"}'

# View logs
aws logs tail /aws/bedrock-agentcore/runtimes/restaurant_agent-XXX-DEFAULT --follow
```

## Required IAM Permissions for AgentCore Role

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": ["dynamodb:GetItem", "dynamodb:Query", "dynamodb:Scan", "dynamodb:PutItem", "dynamodb:UpdateItem"],
            "Resource": [
                "arn:aws:dynamodb:us-east-1:*:table/restaurant-kitchen-assistant-*",
                "arn:aws:dynamodb:us-east-1:*:table/restaurant-agent-*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"],
            "Resource": "*"
        }
    ]
}
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/restaurants` | GET | List all restaurants |
| `/equipment` | GET | Get equipment status |
| `/inventory` | GET | Get inventory levels |
| `/staffing` | GET | Get staffing data |
| `/tickets` | GET | Get maintenance tickets |
| `/chat` | POST | Standard chat (request/response) |
| `/chat-stream` | POST | Streaming chat (API Gateway Response Streaming) |

## Testing Commands

```bash
# Get API URL
API_URL=$(aws cloudformation describe-stacks \
    --stack-name restaurant-agent-infrastructure-prod \
    --query 'Stacks[0].Outputs[?OutputKey==`RestApiUrl`].OutputValue' \
    --output text)

# Test streaming
curl --no-buffer -X POST "$API_URL/chat-stream" \
    -H 'Content-Type: application/json' \
    -d '{"prompt": "Atlanta kitchen status"}'

# Test standard
curl -X POST "$API_URL/chat" \
    -H 'Content-Type: application/json' \
    -d '{"prompt": "List restaurants"}'
```

## Frontend Deployment

```bash
# Get bucket and distribution
S3_BUCKET=$(aws cloudformation describe-stacks \
    --stack-name restaurant-agent-infrastructure-prod \
    --query 'Stacks[0].Outputs[?OutputKey==`BucketName`].OutputValue' \
    --output text)

CLOUDFRONT_ID=$(aws cloudformation describe-stacks \
    --stack-name restaurant-agent-infrastructure-prod \
    --query 'Stacks[0].Outputs[?OutputKey==`DistributionId`].OutputValue' \
    --output text)

# Sync and invalidate
aws s3 sync frontend/ "s3://$S3_BUCKET/" --delete
aws cloudfront create-invalidation --distribution-id $CLOUDFRONT_ID --paths "/*"
```

## Cleanup

### Full Cleanup (Recommended)
```bash
./deployment/utils/cleanup-all.sh
```

This script:
1. Empties S3 buckets (required before stack deletion)
2. Deletes stacks in reverse dependency order
3. Waits for each stack to complete deletion

### Manual Cleanup (Delete in this order)
```bash
# 1. Chat endpoints first
aws cloudformation delete-stack --stack-name restaurant-agent-chat-streaming-prod
aws cloudformation delete-stack --stack-name restaurant-agent-chat-prod

# 2. Data tables
aws cloudformation delete-stack --stack-name restaurant-agent-staffing-prod
aws cloudformation delete-stack --stack-name restaurant-agent-inventory-prod

# 3. Base infrastructure last (has S3 buckets)
# Empty buckets first!
S3_BUCKET=$(aws cloudformation describe-stacks \
    --stack-name restaurant-agent-infrastructure-prod \
    --query 'Stacks[0].Outputs[?OutputKey==`BucketName`].OutputValue' \
    --output text)
aws s3 rm s3://$S3_BUCKET --recursive
aws cloudformation delete-stack --stack-name restaurant-agent-infrastructure-prod
```

### Cleanup Order (Important!)
1. `restaurant-agent-chat-streaming-prod`
2. `restaurant-agent-chat-prod`
3. `restaurant-agent-staffing-prod`
4. `restaurant-agent-inventory-prod`
5. `restaurant-agent-infrastructure-prod` (empty S3 first!)

⚠️ **WARNING**: This permanently deletes ALL resources and data!

## Troubleshooting

- **Agent not responding**: Check CloudWatch logs, verify DynamoDB permissions
- **Streaming not working**: Verify Lambda uses `awslambda.streamifyResponse`
- **Frontend not updating**: Invalidate CloudFront cache
- **Stack deletion failed**: Empty S3 buckets first, check for resource dependencies
