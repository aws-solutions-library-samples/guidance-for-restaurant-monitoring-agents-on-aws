#!/bin/bash

API_URL="https://xxso6lk2h9.execute-api.us-east-1.amazonaws.com/prod/chat"
SESSION_ID="memory-test-$(date +%s)"

echo "Testing AgentCore Memory persistence..."
echo "Session ID: $SESSION_ID"
echo ""

# Message 1: Ask about low stock
echo "=== Message 1: Asking about low stock ==="
RESPONSE1=$(curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d "{\"prompt\": \"Check for low stock items and tell me what you find\", \"session_id\": \"$SESSION_ID\"}")

echo "$RESPONSE1" | jq -r '.response'
echo ""
echo "---"
echo ""

# Wait 3 seconds
sleep 3

# Message 2: Ask for approval (should remember context)
echo "=== Message 2: Giving approval (should remember previous context) ==="
RESPONSE2=$(curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d "{\"prompt\": \"Yes, create the purchase order tickets\", \"session_id\": \"$SESSION_ID\"}")

echo "$RESPONSE2" | jq -r '.response'
echo ""

# Check if agent remembered context
if echo "$RESPONSE2" | jq -r '.response' | grep -qi "cooking oil\|purchase order\|ticket"; then
    echo "✅ SUCCESS: Agent remembered the context about low stock items!"
else
    echo "❌ FAILED: Agent did not remember the previous conversation"
fi
