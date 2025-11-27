#!/bin/bash

echo "🏪 Loading restaurant data..."

python3 << 'EOF'
import boto3
from datetime import datetime
from decimal import Decimal

dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
restaurants_table = dynamodb.Table('rest-monitor-restaurants-prod')

locations = {
    "AFC-001": {"name": "Atlanta Kitchen", "location": "Atlanta, GA", "manager": "Sarah Johnson"},
    "AFC-002": {"name": "Savannah Kitchen", "location": "Savannah, GA", "manager": "Mike Davis"},
    "AFC-003": {"name": "Augusta Kitchen", "location": "Augusta, GA", "manager": "Lisa Chen"},
    "AFC-004": {"name": "Macon Kitchen", "location": "Macon, GA", "manager": "John Smith"},
    "AFC-005": {"name": "Athens Kitchen", "location": "Athens, GA", "manager": "Emma Wilson"},
    "AFC-006": {"name": "Columbus Kitchen", "location": "Columbus, GA", "manager": "David Brown"},
    "AFC-007": {"name": "Brunswick Kitchen", "location": "Brunswick, GA", "manager": "Maria Garcia"},
    "AFC-008": {"name": "Albany Kitchen", "location": "Albany, GA", "manager": "Tom Anderson"},
    "AFC-009": {"name": "Valdosta Kitchen", "location": "Valdosta, GA", "manager": "Amy Taylor"},
    "AFC-010": {"name": "Cumming Kitchen", "location": "Cumming, GA", "manager": "Chris Lee"}
}

print(f"Loading {len(locations)} restaurants...")

for location_id, config in locations.items():
    item = {
        'id': location_id,
        'name': config['name'],
        'location': config['location'],
        'manager': config['manager'],
        'status': 'operational',
        'status_color': 'green',
        'equipment_count': Decimal('7'),
        'last_updated': datetime.now().isoformat()
    }
    restaurants_table.put_item(Item=item)
    print(f"✅ Added {config['name']}")

print(f"\n✅ Loaded {len(locations)} restaurants")
print("   All restaurants operational")

EOF
