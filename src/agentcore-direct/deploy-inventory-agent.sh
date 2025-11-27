#!/bin/bash

echo "🚀 Deploying Inventory Agent - Direct Code Deploy"
echo "=================================================="
echo ""

# Setup virtual environment
echo "📦 Step 1: Setting up virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install CLI
echo "📦 Step 2: Installing Bedrock AgentCore CLI..."
pip install bedrock-agentcore-starter-toolkit --quiet

# Configure agent
echo "⚙️  Step 3: Configuring inventory agent..."
python -m bedrock_agentcore.cli configure \
  --entrypoint agent_inventory.py \
  --name restaurant-inventory-agent \
  --deployment-type direct_code_deploy \
  --runtime PYTHON_3_13 \
  --region us-east-1 \
  --disable-memory \
  --non-interactive

if [ $? -ne 0 ]; then
    echo "❌ Configuration failed"
    exit 1
fi
echo "✅ Agent configured"
echo ""

# Deploy agent
echo "🚀 Step 4: Deploying agent (3-4 minutes)..."
python -m bedrock_agentcore.cli launch --agent restaurant-inventory-agent

if [ $? -ne 0 ]; then
    echo "❌ Deployment failed"
    exit 1
fi
echo "✅ Agent deployed"
echo ""

# Test agent
echo "🧪 Step 5: Testing agent..."
python -m bedrock_agentcore.cli invoke '{"prompt": "What is the inventory status?"}' --agent restaurant-inventory-agent

if [ $? -ne 0 ]; then
    echo "❌ Test failed"
    exit 1
fi
echo "✅ Test successful"
echo ""

# Get endpoint URL
echo "📊 Step 6: Getting endpoint URL..."
python -m bedrock_agentcore.cli status --agent restaurant-inventory-agent --verbose | grep -A 5 "endpoint_url"

echo ""
echo "=================================================="
echo "✅ Inventory Agent Deployed!"
echo "=================================================="
echo ""
echo "📝 Agent Details:"
echo "   • Name: restaurant-inventory-agent"
echo "   • Method: direct_code_deploy (ZIP)"
echo "   • Runtime: Python 3.13"
echo "   • Tools: get_inventory_status, get_low_stock_items"
echo ""
echo "🧪 Test Commands:"
echo "   python -m bedrock_agentcore.cli invoke '{\"prompt\": \"Show low stock items\"}' --agent restaurant-inventory-agent"
echo "   python -m bedrock_agentcore.cli invoke '{\"prompt\": \"Check inventory for AFC-001\"}' --agent restaurant-inventory-agent"
echo ""
echo "🔄 Update Agent:"
echo "   1. Edit agent_inventory.py"
echo "   2. Run: python -m bedrock_agentcore.cli launch --agent restaurant-inventory-agent"
echo "   3. Wait: 3-4 minutes"
echo ""
echo "🧹 Cleanup:"
echo "   python -m bedrock_agentcore.cli destroy --agent restaurant-inventory-agent --force"
echo "   deactivate"
echo ""
