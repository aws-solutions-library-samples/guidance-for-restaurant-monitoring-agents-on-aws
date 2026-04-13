#!/bin/bash
# =============================================================================
# Load All Sample Data — includes realistic issues for demo
# Uses actual DynamoDB table names and schemas from deployed stacks
# =============================================================================

set -e
echo "📊 Loading Complete Sample Data with Realistic Issues"
echo "======================================================"

python3 << 'PYEOF'
import boto3, os
from datetime import datetime, timedelta
from decimal import Decimal
import random

dynamodb = boto3.resource('dynamodb', region_name=os.environ.get('AWS_REGION', 'us-east-1'))
now = datetime.now()

# Actual table names from deployed CloudFormation
RESTAURANTS_TABLE = 'restaurant-kitchen-assistant-restaurants-production'
EQUIPMENT_TABLE   = 'restaurant-kitchen-assistant-equipment-readings-production'
INVENTORY_TABLE   = 'restaurant-kitchen-assistant-inventory-items-prod'
STAFFING_TABLE    = 'restaurant-kitchen-assistant-staffing-requirements-prod'
TICKETS_TABLE     = 'restaurant-kitchen-assistant-tickets-production'

restaurants_tbl = dynamodb.Table(RESTAURANTS_TABLE)
equipment_tbl   = dynamodb.Table(EQUIPMENT_TABLE)
inventory_tbl   = dynamodb.Table(INVENTORY_TABLE)
staffing_tbl    = dynamodb.Table(STAFFING_TABLE)
tickets_tbl     = dynamodb.Table(TICKETS_TABLE)

# ============================================================
# 1. RESTAURANTS (5 Georgia locations)
# ============================================================
print("\n🏪 Loading restaurants...")
locations = {
    "AFC-001": {"name": "Atlanta Kitchen",   "location": "Atlanta, GA",   "manager": "Sarah Johnson"},
    "AFC-002": {"name": "Savannah Kitchen",  "location": "Savannah, GA",  "manager": "Mike Davis"},
    "AFC-003": {"name": "Augusta Kitchen",   "location": "Augusta, GA",   "manager": "Lisa Chen"},
    "AFC-004": {"name": "Macon Kitchen",     "location": "Macon, GA",     "manager": "John Smith"},
    "AFC-005": {"name": "Athens Kitchen",    "location": "Athens, GA",    "manager": "Emma Wilson"},
}
restaurant_statuses = {
    "AFC-001": "warning",
    "AFC-002": "critical",
    "AFC-003": "operational",
    "AFC-004": "operational",
    "AFC-005": "operational",
}
for rid, cfg in locations.items():
    status = restaurant_statuses[rid]
    restaurants_tbl.put_item(Item={
        'id': rid,
        'name': cfg['name'],
        'location': cfg['location'],
        'manager': cfg['manager'],
        'status': status,
        'status_color': 'red' if status == 'critical' else 'orange' if status == 'warning' else 'green',
        'equipment_count': Decimal('5'),
        'last_updated': now.isoformat()
    })
    print(f"  ✅ {cfg['name']} — {status}")


# ============================================================
# 2. EQUIPMENT — key: (restaurant_id HASH, equipment_id RANGE)
# ============================================================
print("\n⚙️ Loading equipment...")
appliances = {
    "REF-001":   {"name": "Walk-in Cooler",  "target": 38.0,  "type": "refrigerator"},
    "REF-002":   {"name": "Beverage Cooler", "target": 35.0,  "type": "refrigerator"},
    "FRZ-001":   {"name": "Walk-in Freezer", "target": -5.0,  "type": "freezer"},
    "GRILL-001": {"name": "Main Grill",      "target": 400.0, "type": "grill"},
    "FRYER-001": {"name": "Deep Fryer",      "target": 350.0, "type": "fryer"},
}
equipment_issues = {
    ("AFC-001", "GRILL-001"): {"status": "critical", "temp": 520.0},
    ("AFC-001", "REF-001"):   {"status": "warning",  "temp": 48.5},
    ("AFC-002", "FRZ-001"):   {"status": "critical", "temp": 15.0},
    ("AFC-002", "REF-002"):   {"status": "warning",  "temp": 42.0},
    ("AFC-003", "FRYER-001"): {"status": "warning",  "temp": 310.0},
}
eq_count = 0
for rid in locations:
    for eid, acfg in appliances.items():
        issue = equipment_issues.get((rid, eid))
        temp = issue["temp"] if issue else round(acfg["target"] + random.uniform(-2, 2), 1)
        status = issue["status"] if issue else "normal"
        equipment_tbl.put_item(Item={
            'restaurant_id': rid, 'equipment_id': eid,
            'appliance_name': acfg['name'], 'appliance_type': acfg['type'],
            'temperature': Decimal(str(temp)),
            'target_temperature': Decimal(str(acfg['target'])),
            'status': status, 'timestamp': now.isoformat()
        })
        eq_count += 1
        if status != 'normal':
            print(f"  🔴 {rid}/{eid} {acfg['name']} — {status} ({temp}°F vs {acfg['target']}°F)")
print(f"  ✅ {eq_count} equipment readings ({len(equipment_issues)} with issues)")

# ============================================================
# 3. INVENTORY — key: item_id (HASH), format: {rid}_{inv_id}
# ============================================================
print("\n📦 Loading inventory...")
inv_items = [
    {"id": "INV-001", "name": "Chicken Breast", "cat": "Protein",  "unit": "lbs",     "max": 200, "reorder": 50},
    {"id": "INV-002", "name": "Burger Patties",  "cat": "Protein",  "unit": "lbs",     "max": 150, "reorder": 40},
    {"id": "INV-003", "name": "French Fries",    "cat": "Frozen",   "unit": "lbs",     "max": 300, "reorder": 80},
    {"id": "INV-004", "name": "Lettuce",         "cat": "Produce",  "unit": "lbs",     "max": 100, "reorder": 25},
    {"id": "INV-005", "name": "Cooking Oil",     "cat": "Supplies", "unit": "gallons", "max": 50,  "reorder": 15},
    {"id": "INV-006", "name": "Burger Buns",     "cat": "Bakery",   "unit": "units",   "max": 500, "reorder": 100},
]
inv_issues = {
    ("AFC-001", "INV-005"): 5,
    ("AFC-002", "INV-001"): 18,
    ("AFC-002", "INV-003"): 30,
    ("AFC-003", "INV-004"): 10,
    ("AFC-004", "INV-006"): 40,
}
inv_count = 0
for rid in locations:
    for item in inv_items:
        composite_id = f"{rid}_{item['id']}"
        issue_stock = inv_issues.get((rid, item["id"]))
        stock = issue_stock if issue_stock is not None else round(random.uniform(item["reorder"] * 1.5, item["max"]), 1)
        pct = (stock / item["reorder"]) * 100
        status = "critical" if pct < 50 else "low" if pct < 100 else "adequate"
        inventory_tbl.put_item(Item={
            'item_id': composite_id, 'restaurant_id': rid,
            'item_name': item["name"], 'name': item["name"],
            'category': item["cat"], 'unit_of_measure': item["unit"], 'unit': item["unit"],
            'quantity': Decimal(str(stock)), 'current_stock': Decimal(str(stock)),
            'max_stock': Decimal(str(item["max"])),
            'reorder_point': Decimal(str(item["reorder"])),
            'status': status, 'last_updated': now.isoformat()
        })
        inv_count += 1
        if status != 'adequate':
            print(f"  ⚠️ {composite_id} {item['name']} — {status} ({stock} {item['unit']})")
print(f"  ✅ {inv_count} inventory items ({len(inv_issues)} with issues)")

# ============================================================
# 4. STAFFING — key: (restaurant_id HASH, date RANGE), nested staffing array
# ============================================================
print("\n👥 Loading staffing...")
roles_shifts = [
    ("Manager",  {"morning": 1, "afternoon": 1, "evening": 1}),
    ("Cook",     {"morning": 3, "afternoon": 4, "evening": 3}),
    ("Cashier",  {"morning": 2, "afternoon": 3, "evening": 2}),
    ("Prep",     {"morning": 2, "afternoon": 2, "evening": 1}),
]
staffing_gaps = {
    ("AFC-001", 0, "morning", "Cook"):    1,
    ("AFC-001", 0, "morning", "Manager"): 0,
    ("AFC-002", 1, "evening", "Cook"):    1,
    ("AFC-002", 1, "evening", "Cashier"): 0,
    ("AFC-003", 2, "afternoon", "Prep"):  0,
    ("AFC-004", 0, "morning", "Cashier"): 1,
    ("AFC-005", 3, "evening", "Manager"): 0,
}

# First delete old data
print("  Clearing old staffing data...")
resp = staffing_tbl.scan()
with staffing_tbl.batch_writer() as batch:
    for item in resp['Items']:
        batch.delete_item(Key={'restaurant_id': item['restaurant_id'], 'date': item['date']})

staff_count = 0
for rid in locations:
    for day_off in range(7):
        date_str = (now + timedelta(days=day_off)).strftime('%Y-%m-%d')
        staffing_entries = []
        for role, shifts in roles_shifts:
            for shift, required in shifts.items():
                scheduled = staffing_gaps.get((rid, day_off, shift, role), required)
                staffing_entries.append({
                    'role': role,
                    'shift': shift,
                    'required_count': Decimal(str(required)),
                    'scheduled_count': Decimal(str(scheduled))
                })
        staffing_tbl.put_item(Item={
            'restaurant_id': rid,
            'date': date_str,
            'staffing': staffing_entries,
            'updated_at': now.isoformat()
        })
        staff_count += 1
        # Log gaps
        for e in staffing_entries:
            if e['scheduled_count'] < e['required_count']:
                print(f"  🚨 {rid} {date_str} {e['role']} {e['shift']} — need {e['required_count']} have {e['scheduled_count']}")
print(f"  ✅ {staff_count} staffing records ({len(staffing_gaps)} with gaps)")


# ============================================================
# 5. TICKETS — key: ticket_id (HASH)
# ============================================================
print("\n🎫 Loading tickets...")
ticket_data = [
    {"ticket_id": "TKT-001", "restaurant_id": "AFC-001", "equipment_id": "GRILL-001",
     "title": "Main Grill overheating", "appliance_name": "Main Grill",
     "issue": "Main Grill at 520°F, target 400°F. Fire risk. Immediate inspection needed.",
     "priority": "critical", "status": "open",
     "temperature": Decimal("520.0"), "target_temperature": Decimal("400.0"), "deviation": Decimal("120.0"),
     "assigned_team": "Equipment Maintenance", "sla_hours": 4, "category": "equipment"},
    {"ticket_id": "TKT-002", "restaurant_id": "AFC-001", "equipment_id": "REF-001",
     "title": "Walk-in Cooler running warm", "appliance_name": "Walk-in Cooler",
     "issue": "Walk-in Cooler at 48.5°F, target 38°F. Food safety risk.",
     "priority": "high", "status": "open",
     "temperature": Decimal("48.5"), "target_temperature": Decimal("38.0"), "deviation": Decimal("10.5"),
     "assigned_team": "Refrigeration Team", "sla_hours": 8, "category": "equipment"},
    {"ticket_id": "TKT-003", "restaurant_id": "AFC-002", "equipment_id": "FRZ-001",
     "title": "Walk-in Freezer failure", "appliance_name": "Walk-in Freezer",
     "issue": "Walk-in Freezer at 15°F, target -5°F. Compressor failure. All frozen inventory at risk.",
     "priority": "critical", "status": "open",
     "temperature": Decimal("15.0"), "target_temperature": Decimal("-5.0"), "deviation": Decimal("20.0"),
     "assigned_team": "Emergency Repair", "sla_hours": 2, "category": "equipment"},
    {"ticket_id": "TKT-004", "restaurant_id": "AFC-002",
     "title": "Chicken breast critically low",
     "issue": "Chicken breast at 18 lbs, reorder at 50 lbs. Emergency restock needed.",
     "priority": "high", "status": "open",
     "assigned_team": "Supply Chain", "sla_hours": 12, "category": "inventory"},
    {"ticket_id": "TKT-005", "restaurant_id": "AFC-003", "equipment_id": "FRYER-001",
     "title": "Deep Fryer underheating", "appliance_name": "Deep Fryer",
     "issue": "Deep Fryer at 310°F, target 350°F. Fries coming out soggy.",
     "priority": "medium", "status": "open",
     "temperature": Decimal("310.0"), "target_temperature": Decimal("350.0"), "deviation": Decimal("40.0"),
     "assigned_team": "Equipment Maintenance", "sla_hours": 24, "category": "equipment"},
    {"ticket_id": "TKT-006", "restaurant_id": "AFC-003",
     "title": "Lettuce stock critical",
     "issue": "Lettuce at 10 lbs, reorder at 25 lbs. Salad menu items affected.",
     "priority": "medium", "status": "open",
     "assigned_team": "Supply Chain", "sla_hours": 24, "category": "inventory"},
    {"ticket_id": "TKT-007", "restaurant_id": "AFC-001",
     "title": "Morning shift understaffed",
     "issue": "No manager and only 1 of 3 cooks for morning shift. Service quality at risk.",
     "priority": "high", "status": "open",
     "assigned_team": "HR / Scheduling", "sla_hours": 12, "category": "staffing"},
    {"ticket_id": "TKT-008", "restaurant_id": "AFC-001",
     "title": "Cooking oil critically low",
     "issue": "Cooking oil at 5 gallons, reorder at 15 gallons. Fryer ops affected.",
     "priority": "high", "status": "open",
     "assigned_team": "Supply Chain", "sla_hours": 8, "category": "inventory"},
]
for t in ticket_data:
    t['created_at'] = now.isoformat()
    t['last_updated'] = now.isoformat()
    tickets_tbl.put_item(Item=t)
    print(f"  🎫 {t['ticket_id']} @ {t['restaurant_id']} — {t['priority'].upper()}: {t['title']}")
print(f"  ✅ {len(ticket_data)} tickets")

# ============================================================
print("\n" + "=" * 50)
print("✅ ALL DATA LOADED")
print("=" * 50)
print(f"  🏪 {len(locations)} restaurants")
print(f"  ⚙️ {eq_count} equipment ({len(equipment_issues)} issues)")
print(f"  📦 {inv_count} inventory ({len(inv_issues)} low/critical)")
print(f"  👥 {staff_count} staffing ({len(staffing_gaps)} gaps)")
print(f"  🎫 {len(ticket_data)} tickets")

PYEOF

echo ""
echo "✅ Done! Refresh the dashboard to see updated data."
