#!/bin/bash
# =============================================================================
# Load Sample Forecast Data into DynamoDB
# Simulates AI/ML pipeline output for demand forecasting
# =============================================================================
set -e
echo "📈 Loading Forecast Sample Data"
echo "================================"

REGION="${AWS_REGION:-us-east-1}"

python3 << 'PYEOF'
import boto3, os, json
from datetime import datetime, timedelta
from decimal import Decimal
import random

dynamodb = boto3.resource('dynamodb', region_name=os.environ.get('AWS_REGION', 'us-east-1'))
FORECASTS_TABLE = 'restaurant-kitchen-assistant-forecasts-prod'
table = dynamodb.Table(FORECASTS_TABLE)

restaurants = [
    {'id': 'AFC-001', 'name': 'AnyCompany Atlanta', 'city': 'Atlanta'},
    {'id': 'AFC-002', 'name': 'AnyCompany Savannah', 'city': 'Savannah'},
    {'id': 'AFC-003', 'name': 'AnyCompany Augusta', 'city': 'Augusta'},
    {'id': 'AFC-004', 'name': 'AnyCompany Macon', 'city': 'Macon'},
    {'id': 'AFC-005', 'name': 'AnyCompany Athens', 'city': 'Athens'},
    {'id': 'AFC-006', 'name': 'AnyCompany Columbus', 'city': 'Columbus'},
    {'id': 'AFC-007', 'name': 'AnyCompany Brunswick', 'city': 'Brunswick'},
    {'id': 'AFC-008', 'name': 'AnyCompany Albany', 'city': 'Albany'},
    {'id': 'AFC-009', 'name': 'AnyCompany Valdosta', 'city': 'Valdosta'},
    {'id': 'AFC-010', 'name': 'AnyCompany Cumming', 'city': 'Cumming'},
]

events = [
    {'date': '2026-04-04', 'name': 'Atlanta Braves Home Opener', 'impact': 40, 'type': 'Sports', 'locations': ['AFC-001']},
    {'date': '2026-04-05', 'name': 'Easter Sunday', 'impact': 25, 'type': 'Holiday', 'locations': 'all'},
    {'date': '2026-04-11', 'name': 'Masters Tournament Weekend', 'impact': 35, 'type': 'Sports', 'locations': ['AFC-003','AFC-004']},
    {'date': '2026-04-12', 'name': 'UGA Spring Game', 'impact': 30, 'type': 'Sports', 'locations': ['AFC-005']},
    {'date': '2026-04-15', 'name': 'Tax Day Rush', 'impact': 15, 'type': 'Seasonal', 'locations': 'all'},
    {'date': '2026-04-18', 'name': 'Atlanta United Match', 'impact': 25, 'type': 'Sports', 'locations': ['AFC-001','AFC-010']},
    {'date': '2026-04-25', 'name': 'Savannah Music Festival', 'impact': 30, 'type': 'Festival', 'locations': ['AFC-002']},
    {'date': '2026-05-01', 'name': 'May Day / School Events', 'impact': 20, 'type': 'Seasonal', 'locations': 'all'},
    {'date': '2026-05-10', 'name': "Mother's Day", 'impact': 35, 'type': 'Holiday', 'locations': 'all'},
    {'date': '2026-05-25', 'name': 'Memorial Day Weekend', 'impact': 30, 'type': 'Holiday', 'locations': 'all'},
]

inventory_items = ['Chicken Wings', 'Burger Patties', 'French Fries', 'Cooking Oil', 'Lettuce', 'Tomatoes', 'Cheese', 'Buns', 'Soft Drinks', 'Ice Cream']

today = datetime.now()
count = 0

for r in restaurants:
    base_orders = random.randint(35, 55)
    for day_offset in range(14):
        d = today + timedelta(days=day_offset)
        date_str = d.strftime('%Y-%m-%d')
        dow = d.weekday()

        # Weekend boost
        multiplier = 1.0
        if dow == 4: multiplier = 1.25
        if dow == 5: multiplier = 1.35
        if dow == 6: multiplier = 1.15

        # Event boost
        event_name = None
        event_impact = 0
        event_type = None
        for ev in events:
            if ev['date'] == date_str:
                if ev['locations'] == 'all' or r['id'] in ev['locations']:
                    multiplier += ev['impact'] / 100
                    event_name = ev['name']
                    event_impact = ev['impact']
                    event_type = ev['type']

        predicted = int(base_orders * multiplier * random.uniform(0.95, 1.05))
        historical = int(base_orders * random.uniform(0.85, 1.15))
        confidence = round(random.uniform(0.78, 0.95), 2)

        # Inventory projections
        inv_projections = []
        for item in random.sample(inventory_items, random.randint(3, 6)):
            current = round(random.uniform(5, 50), 1)
            daily_usage = round(current * 0.12 * multiplier, 1)
            projected_remaining = round(max(0, current - daily_usage * min(day_offset + 1, 7)), 1)
            reorder_point = round(current * 0.6, 1)
            inv_projections.append({
                'item': item,
                'current_qty': Decimal(str(current)),
                'daily_usage': Decimal(str(daily_usage)),
                'projected_remaining': Decimal(str(projected_remaining)),
                'reorder_point': Decimal(str(reorder_point)),
                'reorder_needed': projected_remaining < reorder_point
            })

        # Staffing recommendations
        staff_recs = []
        for shift in ['morning', 'afternoon', 'evening']:
            base_req = 3 if shift == 'morning' else 5 if shift == 'evening' else 4
            peak_req = int(base_req * multiplier)
            current_sched = base_req + random.randint(-1, 1)
            gap = max(0, peak_req - current_sched)
            staff_recs.append({
                'shift': shift,
                'current_scheduled': current_sched,
                'peak_required': peak_req,
                'gap': gap
            })

        item = {
            'restaurant_id': r['id'],
            'forecast_date': date_str,
            'restaurant_name': r['name'],
            'predicted_orders': predicted,
            'historical_avg': historical,
            'demand_multiplier': Decimal(str(round(multiplier, 2))),
            'confidence_score': Decimal(str(confidence)),
            'event_name': event_name or 'none',
            'event_impact_pct': event_impact,
            'event_type': event_type or 'none',
            'inventory_projections': inv_projections,
            'staffing_recommendations': staff_recs,
            'generated_at': datetime.now().isoformat()
        }

        table.put_item(Item=item)
        count += 1

print(f'✅ Loaded {count} forecast records for {len(restaurants)} restaurants x 14 days')
PYEOF

echo "✅ Forecast data loaded successfully"
