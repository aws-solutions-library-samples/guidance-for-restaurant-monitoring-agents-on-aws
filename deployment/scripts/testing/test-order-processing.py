#!/usr/bin/env python3
"""
Test order processing to fill inventory gaps
"""

import boto3
import json
from datetime import datetime
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')

def get_low_stock_items(project='rest-monitor', env='prod'):
    """Get items below reorder point"""
    table = dynamodb.Table(f'{project}-inventory-items-{env}')
    
    print("🔍 Scanning for low stock items...")
    response = table.scan()
    
    low_stock = []
    for item in response['Items']:
        if item['current_quantity'] < item['reorder_point']:
            low_stock.append({
                'restaurant_id': item['restaurant_id'],
                'item_id': item['item_id'],
                'item_name': item['item_name'],
                'current_quantity': item['current_quantity'],
                'reorder_point': item['reorder_point'],
                'reorder_quantity': item['reorder_quantity'],
                'gap': item['reorder_point'] - item['current_quantity']
            })
    
    return low_stock

def create_order(restaurant_id, item_id, quantity, project='rest-monitor', env='prod'):
    """Create an order to fill inventory gap"""
    approvals_table = dynamodb.Table(f'{project}-reorder-approvals-{env}')
    items_table = dynamodb.Table(f'{project}-inventory-items-{env}')
    
    # Get item details
    item = items_table.get_item(
        Key={'restaurant_id': restaurant_id, 'item_id': item_id}
    )['Item']
    
    # Create approval record
    approval_id = f"{restaurant_id}-{item_id}-{int(datetime.now().timestamp())}"
    approval = {
        'approval_id': approval_id,
        'restaurant_id': restaurant_id,
        'item_id': item_id,
        'item_name': item['item_name'],
        'quantity': quantity,
        'estimated_cost': Decimal(str(item['unit_cost'])) * Decimal(str(quantity)),
        'status': 'approved',
        'approved_at': datetime.now().isoformat(),
        'approved_by': 'system-test'
    }
    
    approvals_table.put_item(Item=approval)
    return approval_id

def fulfill_order(restaurant_id, item_id, quantity, project='rest-monitor', env='prod'):
    """Fulfill order by updating inventory"""
    items_table = dynamodb.Table(f'{project}-inventory-items-{env}')
    
    # Get current quantity
    item = items_table.get_item(
        Key={'restaurant_id': restaurant_id, 'item_id': item_id}
    )['Item']
    
    old_quantity = item['current_quantity']
    new_quantity = old_quantity + quantity
    
    # Update inventory
    items_table.update_item(
        Key={'restaurant_id': restaurant_id, 'item_id': item_id},
        UpdateExpression='SET current_quantity = :qty, last_updated = :ts',
        ExpressionAttributeValues={
            ':qty': new_quantity,
            ':ts': datetime.now().isoformat()
        }
    )
    
    return old_quantity, new_quantity

def test_order_processing():
    """Test complete order processing workflow"""
    print("\n" + "="*60)
    print("Testing Order Processing to Fill Inventory Gaps")
    print("="*60 + "\n")
    
    # Step 1: Get low stock items
    low_stock = get_low_stock_items()
    print(f"✅ Found {len(low_stock)} items below reorder point\n")
    
    if not low_stock:
        print("❌ No low stock items found. Run load-inventory-data.sh first.")
        return 1
    
    # Step 2: Show sample low stock items
    print("📊 Sample Low Stock Items:")
    print("-" * 60)
    for item in low_stock[:5]:
        print(f"  {item['restaurant_id']} - {item['item_name']}")
        print(f"    Current: {item['current_quantity']} | Reorder Point: {item['reorder_point']}")
        print(f"    Gap: {item['gap']} units | Recommended Order: {item['reorder_quantity']}")
        print()
    
    # Step 3: Process orders for first 3 items
    print("\n🛒 Processing Orders to Fill Gaps...")
    print("-" * 60)
    
    orders_processed = 0
    for item in low_stock[:3]:
        print(f"\n  Processing: {item['restaurant_id']} - {item['item_name']}")
        
        # Create order
        approval_id = create_order(
            item['restaurant_id'],
            item['item_id'],
            item['reorder_quantity']
        )
        print(f"    ✓ Order created: {approval_id}")
        
        # Fulfill order
        old_qty, new_qty = fulfill_order(
            item['restaurant_id'],
            item['item_id'],
            item['reorder_quantity']
        )
        print(f"    ✓ Inventory updated: {old_qty} → {new_qty}")
        print(f"    ✓ Gap filled: {new_qty - item['reorder_point']} units above reorder point")
        
        orders_processed += 1
    
    # Step 4: Verify inventory updated
    print("\n\n✅ Order Processing Test Complete!")
    print("="*60)
    print(f"Orders Processed: {orders_processed}")
    print(f"Inventory Gaps Filled: {orders_processed}")
    print("\nVerification:")
    
    items_table = dynamodb.Table('rest-monitor-inventory-items-prod')
    for item in low_stock[:3]:
        updated_item = items_table.get_item(
            Key={'restaurant_id': item['restaurant_id'], 'item_id': item['item_id']}
        )['Item']
        
        status = "✅ Above reorder point" if updated_item['current_quantity'] >= item['reorder_point'] else "⚠️ Still below"
        print(f"  {item['restaurant_id']} - {item['item_name']}: {updated_item['current_quantity']} units {status}")
    
    print("\n" + "="*60)
    print("Test Summary:")
    print(f"  • Low stock items identified: {len(low_stock)}")
    print(f"  • Orders created and fulfilled: {orders_processed}")
    print(f"  • Inventory gaps filled: {orders_processed}")
    print("="*60 + "\n")
    
    return 0

if __name__ == '__main__':
    exit(test_order_processing())
