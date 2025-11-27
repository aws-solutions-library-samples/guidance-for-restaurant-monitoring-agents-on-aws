#!/bin/bash

echo "Loading Staffing Data..."

python3 << 'EOF'
import boto3
from datetime import datetime, timedelta
from decimal import Decimal
import random

dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
req_table = dynamodb.Table('rest-monitor-staffing-requirements-prod')
sched_table = dynamodb.Table('rest-monitor-staffing-schedule-prod')

restaurants = [f'AFC-{str(i).zfill(3)}' for i in range(1, 11)]
roles = ['Manager', 'Cook', 'Cashier', 'Server']

# Generate requirements for next 14 days (this week + next week)
for i in range(14):
    date = (datetime.now() + timedelta(days=i)).strftime('%Y-%m-%d')
    
    for restaurant_id in restaurants:
        forecasted = random.randint(200, 500)
        total_needed = max(8, forecasted // 25)
        
        requirements = {
            'restaurant_id': restaurant_id,
            'date': date,
            'forecasted_customers': Decimal(str(forecasted)),
            'roles': {
                'Manager': Decimal('1'),
                'Cook': Decimal(str(max(2, total_needed // 3))),
                'Cashier': Decimal(str(max(2, total_needed // 4))),
                'Server': Decimal(str(max(3, total_needed // 2)))
            },
            'updated_at': datetime.now().isoformat()
        }
        
        req_table.put_item(Item=requirements)

print("✅ Loaded staffing requirements for 14 days")

# Generate schedules
employees = {
    'Manager': ['Sarah Johnson', 'Mike Chen', 'Lisa Wong', 'Tom Anderson'],
    'Cook': ['Carlos Rodriguez', 'Maria Garcia', 'John Smith', 'Emma Wilson', 'David Kim', 'Rachel Green'],
    'Cashier': ['Amy Taylor', 'Chris Lee', 'Jessica Brown', 'Alex Turner'],
    'Server': ['Kevin Park', 'Sophia Martinez', 'James Wilson', 'Olivia Chen', 'Daniel Lee', 'Maya Patel']
}

shifts = [
    ('06:00', '14:00'),
    ('14:00', '22:00'),
    ('10:00', '18:00')
]

today = datetime.now().date()

for i in range(14):
    date = (datetime.now() + timedelta(days=i)).strftime('%Y-%m-%d')
    shift_date = datetime.now().date() + timedelta(days=i)
    
    # This week (days 0-6): 100% coverage except today has 80% (some absences)
    # Next week (days 7-13): 60% coverage (not fully confirmed)
    if i == 0:
        coverage = 0.8  # Today: 80% (some absences)
    elif i <= 6:
        coverage = 1.0  # Rest of this week: 100%
    else:
        coverage = 0.6  # Next week: 60% (not confirmed)
    
    for restaurant_id in restaurants:
        # Get requirements for this date
        req = req_table.get_item(Key={'restaurant_id': restaurant_id, 'date': date})
        if 'Item' not in req:
            continue
        
        required_roles = req['Item']['roles']
        
        for role, required_count in required_roles.items():
            needed = int(required_count)
            scheduled = int(needed * coverage)
            
            for j in range(scheduled):
                import uuid
                shift_id = f"SHIFT-{uuid.uuid4().hex[:8].upper()}"
                start, end = random.choice(shifts)
                
                item = {
                    'restaurant_id': restaurant_id,
                    'shift_id': shift_id,
                    'employee_name': random.choice(employees[role]),
                    'role': role,
                    'shift_date': date,
                    'start_time': start,
                    'end_time': end,
                    'status': 'scheduled',
                    'created_at': datetime.now().isoformat()
                }
                
                sched_table.put_item(Item=item)

print("✅ Loaded schedules:")
print("   - Today: 80% coverage (some staff absent)")
print("   - This week (days 1-6): 100% coverage")
print("   - Next week (days 7-13): 60% coverage (not fully confirmed)")

EOF

