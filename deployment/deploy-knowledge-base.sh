#!/bin/bash
# =============================================================================
# Deploy Bedrock Knowledge Base for Equipment Manuals
# =============================================================================
# Two-step deployment:
# 1. CloudFormation: S3 bucket, IAM roles, AOSS collection + policies
# 2. Script: Create vector index, create KB, create data source, ingest docs
# =============================================================================
set -e

REGION="us-east-1"
STACK_NAME="restaurant-agent-knowledge-base-prod"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INDEX_NAME="bedrock-kb-equipment-idx"

echo "============================================"
echo "Knowledge Base Deployment"
echo "============================================"

# Step 1: Deploy CloudFormation
echo ""
echo "Step 1: Deploying infrastructure (S3, IAM, AOSS)..."
aws cloudformation deploy \
    --template-file "$SCRIPT_DIR/knowledge-base.yaml" \
    --stack-name $STACK_NAME \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
    --region $REGION \
    --no-fail-on-empty-changeset

echo "  ✅ Infrastructure deployed"

# Get outputs
KB_BUCKET=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==`KBBucketName`].OutputValue' --output text --region $REGION)
KB_ROLE_ARN=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==`KBServiceRoleArn`].OutputValue' --output text --region $REGION)
COLLECTION_ARN=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==`AossCollectionArn`].OutputValue' --output text --region $REGION)
COLLECTION_ENDPOINT=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==`AossCollectionEndpoint`].OutputValue' --output text --region $REGION)

echo "  Bucket: $KB_BUCKET"
echo "  AOSS Endpoint: $COLLECTION_ENDPOINT"

# Step 2: Upload manuals
echo ""
echo "Step 2: Uploading equipment manuals..."
aws s3 sync "$SCRIPT_DIR/knowledge-base/manuals/" "s3://$KB_BUCKET/manuals/" --region $REGION
echo "  ✅ Manuals uploaded"

# Step 3: Create vector index (with retry for policy propagation)
echo ""
echo "Step 3: Creating vector index..."

python3 << PYEOF
import json, time, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import http.client, ssl
from urllib.parse import urlparse
from botocore.auth import SigV4Auth
from botocore.awsrequest import AWSRequest
from botocore.session import Session

endpoint = "$COLLECTION_ENDPOINT"
index_name = "$INDEX_NAME"
region = "$REGION"
host = urlparse(endpoint).hostname

body = json.dumps({
    "settings": {"index": {"knn": True, "knn.algo_param.ef_search": 512}},
    "mappings": {
        "properties": {
            "AMAZON_BEDROCK_METADATA": {"type": "text", "index": False},
            "AMAZON_BEDROCK_TEXT_CHUNK": {"type": "text"},
            "bedrock-knowledge-base-default-vector": {
                "type": "knn_vector", "dimension": 1024,
                "method": {"engine": "faiss", "name": "hnsw", "parameters": {}}
            }
        }
    }
})

for attempt in range(20):
    if attempt > 0:
        wait = min(30, 10 + attempt * 5)
        print(f"  Retry {attempt}/19, waiting {wait}s...")
        time.sleep(wait)

    url = f"{endpoint}/{index_name}"
    req = AWSRequest(method="PUT", url=url, data=body, headers={"Content-Type": "application/json", "host": host})
    SigV4Auth(Session().get_credentials().get_frozen_credentials(), "aoss", region).add_auth(req)

    try:
        conn = http.client.HTTPSConnection(host, context=ssl.create_default_context(), timeout=30)
        conn.request("PUT", f"/{index_name}", body.encode(), dict(req.headers))
        resp = conn.getresponse()
        result = resp.read().decode()
        status = resp.status
        conn.close()
    except Exception as e:
        print(f"  Attempt {attempt}: Connection error: {e}")
        continue

    print(f"  Attempt {attempt}: HTTP {status}")

    if status in [200, 201]:
        print("  ✅ Vector index created")
        sys.exit(0)
    if "resource_already_exists" in result.lower() or "already exists" in result.lower():
        print("  ✅ Vector index already exists")
        sys.exit(0)
    if status != 403:
        print(f"  ❌ Unexpected error: {result[:200]}")
        sys.exit(1)

print("  ❌ Failed after 20 attempts — AOSS policy not propagated")
sys.exit(1)
PYEOF

echo "  ✅ Vector index ready"

# Step 4: Create Knowledge Base
echo ""
echo "Step 4: Creating Bedrock Knowledge Base..."

# Check if KB already exists
EXISTING_KB=$(aws bedrock-agent list-knowledge-bases --region $REGION --query "knowledgeBaseSummaries[?name=='restaurant-kitchen-assistant-equipment-manuals'].knowledgeBaseId" --output text 2>/dev/null || echo "")

if [ -n "$EXISTING_KB" ] && [ "$EXISTING_KB" != "None" ]; then
    KB_ID="$EXISTING_KB"
    echo "  Knowledge Base already exists: $KB_ID"
else
    KB_ID=$(aws bedrock-agent create-knowledge-base \
        --name "restaurant-kitchen-assistant-equipment-manuals" \
        --description "Equipment product manuals with usage, maintenance, warranty, and troubleshooting info" \
        --role-arn "$KB_ROLE_ARN" \
        --knowledge-base-configuration '{"type":"VECTOR","vectorKnowledgeBaseConfiguration":{"embeddingModelArn":"arn:aws:bedrock:'$REGION'::foundation-model/amazon.titan-embed-text-v2:0"}}' \
        --storage-configuration "{\"type\":\"OPENSEARCH_SERVERLESS\",\"opensearchServerlessConfiguration\":{\"collectionArn\":\"${COLLECTION_ARN}\",\"fieldMapping\":{\"metadataField\":\"AMAZON_BEDROCK_METADATA\",\"textField\":\"AMAZON_BEDROCK_TEXT_CHUNK\",\"vectorField\":\"bedrock-knowledge-base-default-vector\"},\"vectorIndexName\":\"${INDEX_NAME}\"}}" \
        --region $REGION \
        --query 'knowledgeBase.knowledgeBaseId' --output text)
    echo "  ✅ Knowledge Base created: $KB_ID"
fi

# Step 5: Create Data Source
echo ""
echo "Step 5: Creating data source..."

EXISTING_DS=$(aws bedrock-agent list-data-sources --knowledge-base-id "$KB_ID" --region $REGION --query "dataSourceSummaries[?name=='equipment-manuals'].dataSourceId" --output text 2>/dev/null || echo "")

if [ -n "$EXISTING_DS" ] && [ "$EXISTING_DS" != "None" ]; then
    DS_ID="$EXISTING_DS"
    echo "  Data source already exists: $DS_ID"
else
    DS_ID=$(aws bedrock-agent create-data-source \
        --name "equipment-manuals" \
        --knowledge-base-id "$KB_ID" \
        --data-source-configuration "{\"type\":\"S3\",\"s3Configuration\":{\"bucketArn\":\"arn:aws:s3:::${KB_BUCKET}\",\"inclusionPrefixes\":[\"manuals/\"]}}" \
        --region $REGION \
        --query 'dataSource.dataSourceId' --output text)
    echo "  ✅ Data source created: $DS_ID"
fi

# Step 6: Trigger ingestion
echo ""
echo "Step 6: Ingesting documents..."
JOB_ID=$(aws bedrock-agent start-ingestion-job \
    --knowledge-base-id "$KB_ID" \
    --data-source-id "$DS_ID" \
    --region $REGION \
    --query 'ingestionJob.ingestionJobId' --output text)
echo "  Ingestion job: $JOB_ID"

# Wait for ingestion
for i in $(seq 1 30); do
    sleep 10
    STATUS=$(aws bedrock-agent get-ingestion-job \
        --knowledge-base-id "$KB_ID" \
        --data-source-id "$DS_ID" \
        --ingestion-job-id "$JOB_ID" \
        --region $REGION \
        --query 'ingestionJob.status' --output text 2>/dev/null || echo "UNKNOWN")
    echo "  [$i/30] $STATUS"
    if [ "$STATUS" = "COMPLETE" ]; then
        STATS=$(aws bedrock-agent get-ingestion-job --knowledge-base-id "$KB_ID" --data-source-id "$DS_ID" --ingestion-job-id "$JOB_ID" --region $REGION --query 'ingestionJob.statistics' --output json)
        echo "  $STATS"
        break
    fi
    if [ "$STATUS" = "FAILED" ]; then
        echo "  ❌ Ingestion failed"
        aws bedrock-agent get-ingestion-job --knowledge-base-id "$KB_ID" --data-source-id "$DS_ID" --ingestion-job-id "$JOB_ID" --region $REGION --query 'ingestionJob.failureReasons' --output text
        break
    fi
done

echo ""
echo "============================================"
echo "Knowledge Base Deployment Complete"
echo "============================================"
echo "  KB ID:        $KB_ID"
echo "  Data Source:  $DS_ID"
echo "  S3 Bucket:    $KB_BUCKET"
echo ""
echo "Set this in your agent environment:"
echo "  KNOWLEDGE_BASE_ID=$KB_ID"
