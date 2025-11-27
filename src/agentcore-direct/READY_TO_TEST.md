# ✅ Ready to Test: Inventory Agent Direct Code Deploy

## What Was Created

**Branch**: `feature-direct-code-deploy`
**Agent**: `agent_inventory.py` (Inventory management)
**Method**: Direct Code Deploy (ZIP file)

### Files Created
1. `agent_inventory.py` - Full inventory agent with 2 tools
2. `requirements.txt` - Dependencies
3. `deploy-inventory-agent.sh` - Automated deployment
4. `DEPLOY_AND_TEST.md` - Full testing guide

## Deploy Now

```bash
cd /Users/maniyes/github-repo/guidance-for-restaurant-monitoring-agents-on-aws/src/agentcore-direct/
./deploy-inventory-agent.sh
```

## What It Will Do

1. ✅ Create virtual environment
2. ✅ Install Bedrock AgentCore CLI
3. ✅ Configure agent (direct_code_deploy)
4. ✅ Deploy to AWS (3-4 minutes)
5. ✅ Test with sample query
6. ✅ Show endpoint URL

## Expected Results

**Deployment Time**: 3-4 minutes (vs 15-20 min container)
**Cold Start**: 10-20 seconds (vs 5-10 min container)
**Update Time**: 3-4 minutes (vs 15-20 min container)

## Agent Features

**Tools**:
- `get_inventory_status()` - Check inventory across restaurants
- `get_low_stock_items()` - Find items below reorder point

**Capabilities**:
- Query DynamoDB directly
- Categorize items (critical, low, ok)
- Provide actionable summaries
- Handle restaurant-specific queries

## Test Queries

After deployment:

```bash
source venv/bin/activate

# Test 1: Overall status
python -m bedrock_agentcore.cli invoke '{"prompt": "What is the inventory status?"}' --agent restaurant-inventory-agent

# Test 2: Low stock
python -m bedrock_agentcore.cli invoke '{"prompt": "Show low stock items"}' --agent restaurant-inventory-agent

# Test 3: Specific restaurant
python -m bedrock_agentcore.cli invoke '{"prompt": "Check inventory for AFC-001"}' --agent restaurant-inventory-agent
```

## Verification Checklist

After deployment, verify:

- [ ] Deployment completed in 3-4 minutes
- [ ] Agent status shows ACTIVE
- [ ] Endpoint URL is returned
- [ ] Test query returns inventory data
- [ ] Tools execute correctly
- [ ] Response format is correct

## If Test Succeeds

1. ✅ Direct code deploy confirmed working
2. ✅ 5x faster than container deployment
3. ✅ Ready to convert other agents
4. ✅ Can update frontend with new URL
5. ✅ Can delete old CloudFormation stack

## If Test Fails

1. Check error message
2. Verify AWS credentials
3. Confirm region is us-east-1
4. Check IAM permissions
5. Review logs in CloudWatch

**Fallback**: Switch to backup branch
```bash
git checkout backup-before-direct-code-deploy
```

## Comparison

| Metric | Container (Backup) | Direct Code (New) |
|--------|-------------------|-------------------|
| Deploy | 15-20 min | 3-4 min |
| Update | 15-20 min | 3-4 min |
| Cold Start | 5-10 min | 10-20 sec |
| Docker | Required | Not required |
| Complexity | High | Low |

## Next Steps After Success

1. Deploy staffing agent with direct code
2. Update frontend with new endpoint URLs
3. Test all functionality from UI
4. Delete old container-based stack
5. Merge to main branch
6. Update documentation

## Status

🚀 **READY TO DEPLOY**

Run `./deploy-inventory-agent.sh` to begin test.
