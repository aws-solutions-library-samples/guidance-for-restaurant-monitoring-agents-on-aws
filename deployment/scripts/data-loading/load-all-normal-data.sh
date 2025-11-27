#!/bin/bash

echo "📊 Loading ALL Normal Data (No Gaps)"
echo "======================================"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Step 1: Load restaurants
echo "Step 1: Loading restaurants..."
"$SCRIPT_DIR/load-restaurant-data.sh"
echo ""

# Step 2: Load equipment (all operational)
echo "Step 2: Loading equipment (all operational)..."
"$SCRIPT_DIR/load-equipment-data.sh"
echo ""

# Step 3: Load inventory (normal stock levels)
echo "Step 3: Loading inventory (normal stock levels)..."
"$SCRIPT_DIR/load-inventory-data.sh"
echo ""

# Step 4: Load staffing (normal coverage)
echo "Step 4: Loading staffing (normal coverage)..."
"$SCRIPT_DIR/load-staffing-data.sh"
echo ""

echo "======================================"
echo "✅ All Normal Data Loaded!"
echo "======================================"
echo ""
echo "📊 Summary:"
echo "   • 10 restaurants - ALL OPERATIONAL"
echo "   • 70 equipment sensors - ALL NORMAL"
echo "   • 102 inventory items - NORMAL STOCK LEVELS"
echo "   • 14 days staffing - NORMAL COVERAGE"
echo ""
echo "💡 To create gaps for testing, run:"
echo "   ./run-simulator-once.sh"
echo ""
