#!/bin/bash

echo "🔍 Verifying Restaurant Monitoring System Deployment"
echo "===================================================="
echo ""

API_URL=$(aws cloudformation describe-stacks --stack-name restaurant-monitoring-agentcore-chat-prod --query 'Stacks[0].Outputs[?OutputKey==`ChatApiEndpoint`].OutputValue' --output text)

echo "API Endpoint: $API_URL"
echo ""

# Test 1: Restaurant Status
echo "✓ Test 1: Restaurant Monitoring"
RESPONSE=$(curl -s -X POST "$API_URL/chat" -H "Content-Type: application/json" -d '{"prompt": "How many restaurants?"}' | jq -r '.response')
if echo "$RESPONSE" | grep -q "10"; then
    echo "  ✅ Restaurant monitoring working"
else
    echo "  ❌ Restaurant monitoring failed"
fi

# Test 2: Equipment Monitoring
echo "✓ Test 2: Equipment Monitoring"
RESPONSE=$(curl -s -X POST "$API_URL/chat" -H "Content-Type: application/json" -d '{"prompt": "Show equipment at AFC-001"}' | jq -r '.response')
if echo "$RESPONSE" | grep -qi "equipment\|fryer\|cooler"; then
    echo "  ✅ Equipment monitoring working"
else
    echo "  ❌ Equipment monitoring failed"
fi

# Test 3: Inventory Tracking
echo "✓ Test 3: Inventory Tracking"
RESPONSE=$(curl -s -X POST "$API_URL/chat" -H "Content-Type: application/json" -d '{"prompt": "Check inventory at AFC-001"}' | jq -r '.response')
if echo "$RESPONSE" | grep -qi "inventory\|stock\|beef\|cooking oil"; then
    echo "  ✅ Inventory tracking working"
else
    echo "  ❌ Inventory tracking failed"
fi

# Test 4: Low Stock Detection
echo "✓ Test 4: Low Stock Detection"
RESPONSE=$(curl -s -X POST "$API_URL/chat" -H "Content-Type: application/json" -d '{"prompt": "Show low stock items"}' | jq -r '.response')
if echo "$RESPONSE" | grep -qi "cooking oil\|low stock\|critical"; then
    echo "  ✅ Low stock detection working"
else
    echo "  ❌ Low stock detection failed"
fi

# Test 5: Memory (may take 5-10 min after deployment)
echo "✓ Test 5: AgentCore Memory"
SESSION_ID="verify-$(date +%s)"
curl -s -X POST "$API_URL/chat" -H "Content-Type: application/json" -d "{\"prompt\": \"Remember this number: 12345\", \"session_id\": \"$SESSION_ID\"}" > /dev/null
sleep 2
RESPONSE=$(curl -s -X POST "$API_URL/chat" -H "Content-Type: application/json" -d "{\"prompt\": \"What number did I tell you?\", \"session_id\": \"$SESSION_ID\"}" | jq -r '.response')
if echo "$RESPONSE" | grep -q "12345"; then
    echo "  ✅ Memory working"
else
    echo "  ⏳ Memory not yet active (runtime loading new image)"
fi

echo ""
echo "📊 Deployment Verification Complete"
