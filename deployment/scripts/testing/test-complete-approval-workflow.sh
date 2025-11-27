#!/bin/bash

API_URL="https://xxso6lk2h9.execute-api.us-east-1.amazonaws.com/prod/chat"
SESSION_ID="approval-test-$(date +%s)"

echo "Testing complete approval workflow..."
echo "Session ID: $SESSION_ID"
echo ""

# Step 1: Request purchase order creation
echo "Step 1: Requesting purchase order creation..."
RESPONSE1=$(curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d "{\"prompt\": \"Check for low stock items and create purchase order tickets if needed\", \"session_id\": \"$SESSION_ID\"}")

echo "$RESPONSE1" | jq -r '.response'
echo ""
echo "---"
echo ""

# Wait for agent to process
sleep 2

# Step 2: Send approval
echo "Step 2: Sending approval..."
RESPONSE2=$(curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d "{\"prompt\": \"Yes, please proceed\", \"session_id\": \"$SESSION_ID\"}")

echo "$RESPONSE2" | jq -r '.response'
echo ""

# Check if tickets were created
if echo "$RESPONSE2" | grep -q "purchase order ticket"; then
    echo "✅ Purchase order tickets created successfully"
else
    echo "⚠️  Response received but ticket creation unclear"
fi
