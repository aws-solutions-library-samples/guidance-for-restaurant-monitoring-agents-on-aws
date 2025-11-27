# Deploy and Test Inventory Agent

## Agent Created

**File**: `agent_inventory.py`
**Type**: Direct Code Deploy (ZIP)
**Features**:
- ✅ BedrockAgentCoreApp wrapper
- ✅ Strands Agent with Claude 3 Sonnet
- ✅ 2 inventory tools (get_inventory_status, get_low_stock_items)
- ✅ DynamoDB integration
- ✅ Session management

## Deploy Agent

```bash
cd /Users/maniyes/github-repo/guidance-for-restaurant-monitoring-agents-on-aws/src/agentcore-direct/
./deploy-inventory-agent.sh
```

## What It Does

1. Creates virtual environment
2. Installs Bedrock AgentCore CLI
3. Configures agent (direct_code_deploy)
4. Deploys to AWS (3-4 minutes)
5. Tests with sample query
6. Shows endpoint URL

## Expected Output

```
🚀 Deploying Inventory Agent - Direct Code Deploy
==================================================

📦 Step 1: Setting up virtual environment...
📦 Step 2: Installing Bedrock AgentCore CLI...
⚙️  Step 3: Configuring inventory agent...
✅ Agent configured

🚀 Step 4: Deploying agent (3-4 minutes)...
✅ Agent deployed

🧪 Step 5: Testing agent...
{
  "response": "Inventory Status:\n- Critical: 30 items\n- Low: 40 items\n- OK: 32 items\n...",
  "sessionId": "session-..."
}
✅ Test successful

📊 Step 6: Getting endpoint URL...
endpoint_url: https://xxx.execute-api.us-east-1.amazonaws.com/prod/chat

✅ Inventory Agent Deployed!
```

## Test Queries

After deployment, test with:

```bash
# Activate venv first
source venv/bin/activate

# Test 1: Overall status
python -m bedrock_agentcore.cli invoke '{"prompt": "What is the inventory status?"}' --agent restaurant-inventory-agent

# Test 2: Low stock items
python -m bedrock_agentcore.cli invoke '{"prompt": "Show me low stock items"}' --agent restaurant-inventory-agent

# Test 3: Specific restaurant
python -m bedrock_agentcore.cli invoke '{"prompt": "Check inventory for AFC-001"}' --agent restaurant-inventory-agent

# Test 4: Critical items
python -m bedrock_agentcore.cli invoke '{"prompt": "What items are critically low?"}' --agent restaurant-inventory-agent
```

## Verify Deployment

### Check Status
```bash
python -m bedrock_agentcore.cli status --agent restaurant-inventory-agent --verbose
```

**Look for**:
- `status: ACTIVE`
- `endpoint_url: https://...`
- `deployment_type: direct_code_deploy`

### Check CloudFormation
```bash
aws cloudformation list-stacks --query 'StackSummaries[?contains(StackName, `restaurant-inventory-agent`)].{Name:StackName,Status:StackStatus}'
```

### Check Lambda
```bash
aws lambda list-functions --query 'Functions[?contains(FunctionName, `restaurant-inventory-agent`)].{Name:FunctionName,Runtime:Runtime,CodeSize:CodeSize}'
```

## Update Agent

To modify the agent:

```bash
# 1. Edit agent_inventory.py
nano agent_inventory.py

# 2. Redeploy (3-4 minutes)
python -m bedrock_agentcore.cli launch --agent restaurant-inventory-agent

# 3. Test
python -m bedrock_agentcore.cli invoke '{"prompt": "test"}' --agent restaurant-inventory-agent
```

## Compare to Container Deployment

### Container (Current)
- **Deploy time**: 15-20 minutes
- **Method**: Docker build + ECR push
- **Update**: Rebuild image, push, update Lambda
- **Cold start**: 5-10 minutes

### Direct Code (New)
- **Deploy time**: 3-4 minutes
- **Method**: ZIP upload via CodeBuild
- **Update**: Rerun launch command
- **Cold start**: 10-20 seconds

## Cleanup

```bash
python -m bedrock_agentcore.cli destroy --agent restaurant-inventory-agent --force
deactivate
rm -rf venv
```

## Troubleshooting

### Error: "No such command 'configure'"
**Issue**: Wrong agentcore CLI installed
**Fix**: Use `python -m bedrock_agentcore.cli` instead of `agentcore`

### Error: "Cannot install bedrock-agentcore-starter-toolkit"
**Issue**: System packages protected
**Fix**: Script creates venv automatically

### Error: "Agent deployment failed"
**Issue**: IAM permissions or region
**Fix**: Check AWS credentials and use us-east-1

### Error: "Invoke failed"
**Issue**: Agent not ready or cold start
**Fix**: Wait 30 seconds and retry

## Success Criteria

✅ Agent deploys in 3-4 minutes
✅ Invoke returns inventory data
✅ Status shows ACTIVE
✅ Endpoint URL is accessible
✅ Tools work correctly

## Next Steps After Success

1. **Update frontend** with new endpoint URL
2. **Test all inventory queries** from UI
3. **Deploy staffing agent** using same method
4. **Delete old CloudFormation stack** (container deployment)
5. **Update documentation** with new deployment method

## Status

⏳ Ready to deploy
⏳ Awaiting manual execution
⏳ Verification pending
