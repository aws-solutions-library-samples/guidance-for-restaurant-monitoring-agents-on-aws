#!/bin/bash
# Load inventory data with historical consumption patterns

set -e

DAYS=30
PROJECT="rest-monitor"
ENV="prod"

while [[ $# -gt 0 ]]; do
    case $1 in
        --days) DAYS="$2"; shift 2 ;;
        --project) PROJECT="$2"; shift 2 ;;
        --env) ENV="$2"; shift 2 ;;
        --help)
            echo "Usage: $0 [--days N] [--project NAME] [--env ENV]"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

echo "Loading inventory data (${DAYS} days historical)..."

python3 << EOF
import boto3
from datetime import datetime, timedelta
from decimal import Decimal
import random

dynamodb = boto3.resource('dynamodb')

RESTAURANTS = ['AFC-001', 'AFC-002', 'AFC-003', 'AFC-004', 'AFC-005',
               'AFC-006', 'AFC-007', 'AFC-008', 'AFC-009', 'AFC-010']

INVENTORY_ITEMS = {
    'burger-buns': {'name': 'Burger Buns', 'unit': 'count', 'category': 'bread',
                    'base_daily_usage': 150, 'variance': 30, 'reorder_point': 300,
                    'reorder_quantity': 1000, 'unit_cost': Decimal('0.25')},
    'beef-patties': {'name': 'Beef Patties', 'unit': 'lbs', 'category': 'meat',
                     'base_daily_usage': 80, 'variance': 20, 'reorder_point': 150,
                     'reorder_quantity': 500, 'unit_cost': Decimal('4.50')},
    'french-fries': {'name': 'French Fries', 'unit': 'lbs', 'category': 'frozen',
                     'base_daily_usage': 60, 'variance': 15, 'reorder_point': 100,
                     'reorder_quantity': 400, 'unit_cost': Decimal('1.20')},
    'chicken-tenders': {'name': 'Chicken Tenders', 'unit': 'lbs', 'category': 'meat',
                        'base_daily_usage': 40, 'variance': 10, 'reorder_point': 80,
                        'reorder_quantity': 300, 'unit_cost': Decimal('5.00')},
    'lettuce': {'name': 'Lettuce', 'unit': 'heads', 'category': 'produce',
                'base_daily_usage': 20, 'variance': 5, 'reorder_point': 30,
                'reorder_quantity': 100, 'unit_cost': Decimal('1.50')},
    'tomatoes': {'name': 'Tomatoes', 'unit': 'lbs', 'category': 'produce',
                 'base_daily_usage': 15, 'variance': 5, 'reorder_point': 25,
                 'reorder_quantity': 80, 'unit_cost': Decimal('2.00')},
    'cheese-slices': {'name': 'Cheese Slices', 'unit': 'count', 'category': 'dairy',
                      'base_daily_usage': 120, 'variance': 25, 'reorder_point': 250,
                      'reorder_quantity': 800, 'unit_cost': Decimal('0.15')},
    'soda-syrup': {'name': 'Soda Syrup', 'unit': 'gallons', 'category': 'beverage',
                   'base_daily_usage': 8, 'variance': 2, 'reorder_point': 15,
                   'reorder_quantity': 50, 'unit_cost': Decimal('12.00')},
    'cooking-oil': {'name': 'Cooking Oil', 'unit': 'gallons', 'category': 'supplies',
                    'base_daily_usage': 5, 'variance': 1, 'reorder_point': 10,
                    'reorder_quantity': 30, 'unit_cost': Decimal('8.50')},
    'napkins': {'name': 'Napkins', 'unit': 'count', 'category': 'supplies',
                'base_daily_usage': 500, 'variance': 100, 'reorder_point': 1000,
                'reorder_quantity': 5000, 'unit_cost': Decimal('0.01')}
}

items_table = dynamodb.Table('${PROJECT}-inventory-items-${ENV}')
history_table = dynamodb.Table('${PROJECT}-inventory-history-${ENV}')
reorder_table = dynamodb.Table('${PROJECT}-reorder-recommendations-${ENV}')

# Seed inventory items
print(f"Seeding {len(INVENTORY_ITEMS) * len(RESTAURANTS)} inventory items...")
for item_id, item_data in INVENTORY_ITEMS.items():
    for restaurant_id in RESTAURANTS:
        items_table.put_item(Item={
            'restaurant_id': restaurant_id,
            'item_id': item_id,
            'item_name': item_data['name'],
            'unit': item_data['unit'],
            'category': item_data['category'],
            'current_quantity': item_data['reorder_quantity'],
            'reorder_point': item_data['reorder_point'],
            'reorder_quantity': item_data['reorder_quantity'],
            'unit_cost': item_data['unit_cost'],
            'last_updated': datetime.now().isoformat()
        })

# Generate historical data
print(f"Generating ${DAYS} days of historical data...")
end_date = datetime.now()
for day_offset in range(${DAYS}, 0, -1):
    date = end_date - timedelta(days=day_offset)
    day_of_week = date.weekday()
    for restaurant_id in RESTAURANTS:
        for item_id, item_data in INVENTORY_ITEMS.items():
            multiplier = 1.3 if day_of_week in [4, 5, 6] else 1.0
            usage = int(max(0, item_data['base_daily_usage'] * multiplier + random.uniform(-item_data['variance'], item_data['variance'])))
            history_table.put_item(Item={
                'restaurant_id': restaurant_id,
                'timestamp_item_id': f"{date.isoformat()}#{item_id}",
                'item_id': item_id,
                'date': date.strftime('%Y-%m-%d'),
                'timestamp': date.isoformat(),
                'quantity_used': usage,
                'quantity_remaining': item_data['reorder_quantity'] - usage,
                'unit': item_data['unit']
            })

# Update current inventory
print("Updating current inventory levels...")
for restaurant_id in RESTAURANTS:
    for item_id, item_data in INVENTORY_ITEMS.items():
        current_qty = int(item_data['reorder_quantity'] * random.uniform(1.0, 2.0))
        items_table.update_item(
            Key={'restaurant_id': restaurant_id, 'item_id': item_id},
            UpdateExpression='SET current_quantity = :qty, last_updated = :ts',
            ExpressionAttributeValues={':qty': current_qty, ':ts': datetime.now().isoformat()}
        )

print("✅ Inventory data loaded successfully")
EOF
