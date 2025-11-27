#!/bin/bash

echo "⚙️ Loading equipment data (all operational)..."

python3 << 'EOF'
import boto3
from datetime import datetime
from decimal import Decimal
import random

dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
equipment_table = dynamodb.Table('rest-monitor-equipment-readings-prod')

locations = {
    "AFC-001": "Atlanta Kitchen",
    "AFC-002": "Savannah Kitchen",
    "AFC-003": "Augusta Kitchen",
    "AFC-004": "Macon Kitchen",
    "AFC-005": "Athens Kitchen",
    "AFC-006": "Columbus Kitchen",
    "AFC-007": "Brunswick Kitchen",
    "AFC-008": "Albany Kitchen",
    "AFC-009": "Valdosta Kitchen",
    "AFC-010": "Cumming Kitchen"
}

appliances = {
    "REF-001": {"name": "Walk-in Cooler", "target": 38.0, "type": "refrigerator"},
    "REF-002": {"name": "Beverage Cooler", "target": 35.0, "type": "refrigerator"},
    "FRZ-001": {"name": "Freezer Unit", "target": -5.0, "type": "freezer"},
    "GRL-001": {"name": "Burger Grill", "target": 450.0, "type": "grill"},
    "FRY-001": {"name": "French Fry Station", "target": 375.0, "type": "fryer"},
    "FRY-002": {"name": "Chicken Fryer", "target": 375.0, "type": "fryer"},
    "ICE-001": {"name": "Ice Cream Freezer", "target": -10.0, "type": "freezer"}
}

print(f"Loading equipment data for {len(locations)} restaurants...")

for location_id in locations.keys():
    for appliance_id, appliance_config in appliances.items():
        # All equipment operating normally (within ±2 degrees of target)
        temp = appliance_config['target'] + random.uniform(-2, 2)
        
        item = {
            'restaurant_id': location_id,
            'equipment_id': appliance_id,
            'appliance_name': appliance_config['name'],
            'appliance_type': appliance_config['type'],
            'temperature': Decimal(str(round(temp, 1))),
            'target_temperature': Decimal(str(appliance_config['target'])),
            'status': 'normal',
            'timestamp': datetime.now().isoformat()
        }
        equipment_table.put_item(Item=item)

print(f"✅ Loaded {len(locations) * len(appliances)} equipment readings")
print("   All equipment operating normally (no failures)")

EOF
