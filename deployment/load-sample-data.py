#!/usr/bin/env python3
"""
Simple Data Loader for Restaurant Agent
Loads sample data for restaurants, equipment, inventory, and staffing
"""

import os
import boto3
import random
from datetime import datetime, date, timedelta
from decimal import Decimal

dynamodb = boto3.resource('dynamodb', region_name=os.environ.get('AWS_REGION', 'us-east-1'))

# Configuration - table names from environment (set by config.env / deploy-all.sh).
# Defaults match restaurant-monitoring-base-template.yaml with default parameters.
PROJECT_NAME = os.environ.get('PROJECT_NAME', 'restaurant-kitchen-assistant')
ENVIRONMENT = os.environ.get('ENVIRONMENT', 'production')
RESTAURANTS_TABLE = os.environ.get('RESTAURANTS_TABLE', f'{PROJECT_NAME}-restaurants-{ENVIRONMENT}')
EQUIPMENT_TABLE = os.environ.get('EQUIPMENT_TABLE', f'{PROJECT_NAME}-equipment-readings-{ENVIRONMENT}')
INVENTORY_TABLE = os.environ.get('INVENTORY_TABLE', f'{PROJECT_NAME}-inventory-items-{ENVIRONMENT}')
STAFFING_TABLE = os.environ.get('STAFFING_TABLE', f'{PROJECT_NAME}-staffing-requirements-{ENVIRONMENT}')

# Sample Data
RESTAURANTS = [
    {'id': 'AFC-001', 'name': 'Atlanta Kitchen', 'location': 'Atlanta, GA', 'manager': 'Sarah Johnson'},
    {'id': 'AFC-002', 'name': 'Savannah Kitchen', 'location': 'Savannah, GA', 'manager': 'Mike Davis'},
    {'id': 'AFC-003', 'name': 'Augusta Kitchen', 'location': 'Augusta, GA', 'manager': 'Lisa Chen'},
    {'id': 'AFC-004', 'name': 'Macon Kitchen', 'location': 'Macon, GA', 'manager': 'John Smith'},
    {'id': 'AFC-005', 'name': 'Athens Kitchen', 'location': 'Athens, GA', 'manager': 'Emma Wilson'},
]

EQUIPMENT = [
    {'id': 'REF-001', 'name': 'Walk-in Cooler', 'type': 'refrigerator', 'target': 38.0},
    {'id': 'REF-002', 'name': 'Beverage Cooler', 'type': 'refrigerator', 'target': 35.0},
    {'id': 'FRZ-001', 'name': 'Walk-in Freezer', 'type': 'freezer', 'target': -5.0},
    {'id': 'GRILL-001', 'name': 'Main Grill', 'type': 'grill', 'target': 400.0},
    {'id': 'FRYER-001', 'name': 'Deep Fryer', 'type': 'fryer', 'target': 350.0},
]

INVENTORY_ITEMS = [
    {'id': 'INV-001', 'name': 'Beef Patties', 'category': 'proteins', 'unit': 'pounds', 'reorder': 100},
    {'id': 'INV-002', 'name': 'Burger Buns', 'category': 'buns_and_bread', 'unit': 'count', 'reorder': 200},
    {'id': 'INV-003', 'name': 'Lettuce', 'category': 'produce', 'unit': 'pounds', 'reorder': 50},
    {'id': 'INV-004', 'name': 'French Fries', 'category': 'frozen_items', 'unit': 'pounds', 'reorder': 150},
]

ROLES = ['Manager', 'Cook', 'Server', 'Dishwasher', 'Cashier']
SHIFTS = ['morning', 'afternoon', 'evening']

def load_restaurants():
    """Load restaurant data"""
    print("📍 Loading restaurants...")
    table = dynamodb.Table(RESTAURANTS_TABLE)
    
    for restaurant in RESTAURANTS:
        item = {
            'id': restaurant['id'],
            'name': restaurant['name'],
            'location': restaurant['location'],
            'manager': restaurant['manager'],
            'status': 'operational',
            'status_color': 'green',
            'equipment_count': len(EQUIPMENT),
            'last_updated': datetime.now().isoformat()
        }
        table.put_item(Item=item)
        print(f"  ✓ {restaurant['name']}")
    
    print(f"✅ Loaded {len(RESTAURANTS)} restaurants\n")

def load_equipment():
    """Load equipment readings"""
    print("⚙️  Loading equipment...")
    table = dynamodb.Table(EQUIPMENT_TABLE)
    
    count = 0
    for restaurant in RESTAURANTS:
        for equipment in EQUIPMENT:
            # Normal temperature with small variation
            temp = equipment['target'] + random.uniform(-2, 2)
            
            item = {
                'restaurant_id': restaurant['id'],
                'equipment_id': equipment['id'],
                'appliance_name': equipment['name'],
                'appliance_type': equipment['type'],
                'temperature': Decimal(str(round(temp, 1))),
                'target_temperature': Decimal(str(equipment['target'])),
                'status': 'normal',
                'timestamp': datetime.now().isoformat()
            }
            table.put_item(Item=item)
            count += 1
    
    print(f"✅ Loaded {count} equipment readings\n")

def load_inventory():
    """Load inventory data"""
    print("📦 Loading inventory...")
    table = dynamodb.Table(INVENTORY_TABLE)
    
    count = 0
    for restaurant in RESTAURANTS:
        for item in INVENTORY_ITEMS:
            # Normal stock levels
            quantity = item['reorder'] * random.uniform(1.5, 3.0)
            
            # Make item_id unique per restaurant
            unique_item_id = f"{restaurant['id']}_{item['id']}"
            
            inventory_item = {
                'restaurant_id': restaurant['id'],
                'item_id': unique_item_id,
                'item_name': item['name'],
                'category': item['category'],
                'quantity': Decimal(str(round(quantity, 1))),
                'unit_of_measure': item['unit'],
                'reorder_point': Decimal(str(item['reorder'])),
                'status': 'adequate',
                'last_updated': datetime.now().isoformat()
            }
            table.put_item(Item=inventory_item)
            count += 1
    
    print(f"✅ Loaded {count} inventory items\n")

def load_staffing():
    """Load staffing data"""
    print("👥 Loading staffing...")
    table = dynamodb.Table(STAFFING_TABLE)
    
    count = 0
    today = date.today()
    
    for restaurant in RESTAURANTS:
        for day_offset in range(7):  # Next 7 days
            shift_date = (today + timedelta(days=day_offset)).isoformat()
            
            for shift in SHIFTS:
                for role in ROLES:
                    # Normal staffing
                    required = random.randint(2, 5)
                    
                    staffing_item = {
                        'schedule_id': f"{restaurant['id']}_{role}_{shift}_{shift_date}",
                        'restaurant_id': restaurant['id'],
                        'role': role,
                        'shift': shift,
                        'shift_date': shift_date,
                        'required_count': required,
                        'scheduled_count': required,  # Fully staffed
                        'status': 'adequate'
                    }
                    table.put_item(Item=staffing_item)
                    count += 1
    
    print(f"✅ Loaded {count} staffing records\n")

def main():
    print("\n🚀 Loading Sample Data for Restaurant Agent")
    print("=" * 50)
    print("")
    
    try:
        load_restaurants()
        load_equipment()
        load_inventory()
        load_staffing()
        
        print("=" * 50)
        print("✅ All Sample Data Loaded Successfully!")
        print("=" * 50)
        print("")
        print("📊 Summary:")
        print(f"   • {len(RESTAURANTS)} restaurants")
        print(f"   • {len(RESTAURANTS) * len(EQUIPMENT)} equipment readings")
        print(f"   • {len(RESTAURANTS) * len(INVENTORY_ITEMS)} inventory items")
        print(f"   • Staffing for next 7 days")
        print("")
        print("🧪 Test the system:")
        print("   • Open the frontend in your browser")
        print("   • Check Dashboard for restaurant status")
        print("   • View Equipment tab for temperature data")
        print("   • Check Inventory and Staffing tabs")
        print("")
        
    except Exception as e:
        print(f"\n❌ Error loading data: {e}")
        print("\nMake sure:")
        print("  1. AWS credentials are configured")
        print("  2. DynamoDB tables exist (run infrastructure deployment first)")
        print("  3. You have permissions to write to DynamoDB")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())
