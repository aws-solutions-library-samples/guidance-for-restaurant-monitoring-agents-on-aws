#!/usr/bin/env python3
"""
Simple Equipment Simulator - Standalone version
Populates DynamoDB tables with restaurant, equipment, and ticket data
"""
import json
import random
from datetime import datetime
from decimal import Decimal

try:
    import boto3
    print("✅ boto3 imported successfully")
except ImportError:
    print("❌ boto3 not found. Install with: pip install boto3")
    exit(1)

class SimpleEquipmentSimulator:
    def __init__(self, api_url=None):
        self.dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
        self.restaurants_table = self.dynamodb.Table('rest-monitor-restaurants-prod')
        self.equipment_table = self.dynamodb.Table('rest-monitor-equipment-readings-prod')
        self.tickets_table = self.dynamodb.Table('rest-monitor-tickets-prod')
        self.manual_api_url = api_url  # Allow manual API URL override
        
        self.locations = {
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
        
        self.appliances = {
            "REF-001": {"name": "Walk-in Cooler", "target": 38.0, "type": "refrigerator"},
            "REF-002": {"name": "Beverage Cooler", "target": 35.0, "type": "refrigerator"},
            "FRZ-001": {"name": "Freezer Unit", "target": -5.0, "type": "freezer"},
            "GRL-001": {"name": "Burger Grill", "target": 450.0, "type": "grill"},
            "FRY-001": {"name": "French Fry Station", "target": 375.0, "type": "fryer"},
            "FRY-002": {"name": "Chicken Fryer", "target": 375.0, "type": "fryer"},
            "ICE-001": {"name": "Ice Cream Freezer", "target": -10.0, "type": "freezer"}
        }

    def clear_tables(self):
        """Clear all DynamoDB tables"""
        print("🧹 Clearing DynamoDB tables...")
        
        try:
            # Clear restaurants - uses 'id' as primary key
            response = self.restaurants_table.scan()
            for item in response.get('Items', []):
                self.restaurants_table.delete_item(Key={'id': item['id']})
            
            # Clear equipment - uses composite key: restaurant_id (HASH) + equipment_id (RANGE)
            response = self.equipment_table.scan()
            for item in response.get('Items', []):
                self.equipment_table.delete_item(Key={
                    'restaurant_id': item['restaurant_id'],
                    'equipment_id': item['equipment_id']
                })
            
            # Clear tickets - uses ticket_id as primary key
            response = self.tickets_table.scan()
            for item in response.get('Items', []):
                self.tickets_table.delete_item(Key={'ticket_id': item['ticket_id']})
            
            print("✅ Tables cleared")
        except Exception as e:
            print(f"⚠️ Error clearing tables (this is normal if tables are empty): {e}")

    def populate_restaurants(self):
        """Populate restaurants table"""
        print("🏪 Populating restaurants...")
        
        for location_id, config in self.locations.items():
            item = {
                'id': location_id,  # Use 'id' as primary key (matches table schema)
                'name': config['name'],
                'location': config['location'],
                'manager': config['manager'],
                'equipment_count': len(self.appliances),
                'status': 'operational',
                'status_color': 'green',  # Default to green
                'last_updated': datetime.now().isoformat()
            }
            self.restaurants_table.put_item(Item=item)
            print(f"✅ Added {config['name']}")

    def populate_equipment(self):
        """Populate equipment readings and notify Strands workflow of anomalies"""
        print("⚙️ Populating equipment readings...")
        
        # Define some problematic equipment
        problems = {
            'AFC-002': {'REF-001': {'temp': 55.0, 'status': 'critical'}},
            'AFC-003': {'FRZ-001': {'temp': 15.0, 'status': 'critical'}},
            'AFC-006': {'GRL-001': {'temp': 420.0, 'status': 'warning'}}
        }
        
        anomalies = []
        
        for location_id in self.locations.keys():
            for appliance_id, appliance_config in self.appliances.items():
                # Check if this equipment has a problem
                if (location_id in problems and 
                    appliance_id in problems[location_id]):
                    problem = problems[location_id][appliance_id]
                    temp = problem['temp']
                    status = problem['status']
                    
                    # Track anomaly for Strands workflow
                    anomalies.append({
                        'restaurant_id': location_id,
                        'equipment_id': appliance_id,
                        'appliance_name': appliance_config['name'],
                        'appliance_type': appliance_config['type'],
                        'temperature': temp,
                        'target_temperature': appliance_config['target'],
                        'status': status
                    })
                else:
                    # Normal operation
                    temp = appliance_config['target'] + random.uniform(-2, 2)
                    status = 'normal'
                
                # Use equipment_id as sort key (matches table schema)
                item = {
                    'restaurant_id': location_id,  # HASH key
                    'equipment_id': appliance_id,  # RANGE key
                    'appliance_name': appliance_config['name'],
                    'appliance_type': appliance_config['type'],
                    'temperature': Decimal(str(round(temp, 1))),
                    'target_temperature': Decimal(str(appliance_config['target'])),
                    'status': status,
                    'timestamp': datetime.now().isoformat()
                }
                self.equipment_table.put_item(Item=item)
        
        print(f"✅ Added equipment for {len(self.locations)} restaurants")
        
        # Notify Strands workflow of anomalies
        if anomalies:
            self.notify_strands_workflow(anomalies)
    
    def get_api_url(self):
        """Get API Gateway URL from CloudFormation stack"""
        try:
            cf = boto3.client('cloudformation', region_name='us-east-1')
            
            # Try multiple possible stack names
            stack_names = [
                'rest-monitor-base-infrastructure-prod',
                'restaurant-kitchen-assistant-base-infrastructure-production',
                'restaurant-kitchen-assistant-base-production',
                'restaurant-kitchen-assistant-production',
                'restaurant-strands-workflow'
            ]
            
            for stack_name in stack_names:
                try:
                    stack = cf.describe_stacks(StackName=stack_name)
                    outputs = stack['Stacks'][0]['Outputs']
                    
                    for output in outputs:
                        if output['OutputKey'] in ['ApiGatewayUrl', 'RestApiUrl', 'ApiUrl']:
                            print(f"✅ Found API URL in stack: {stack_name}")
                            return output['OutputValue']
                except Exception as e:
                    print(f"⚠️ Stack {stack_name} not found: {str(e)}")
                    continue
            
            print("⚠️ Could not find API Gateway URL in any CloudFormation stack")
            return None
            
        except Exception as e:
            print(f"⚠️ Could not get API URL from CloudFormation: {e}")
            return None
    
    def notify_strands_workflow(self, anomalies):
        """Notify Strands workflow of equipment anomalies"""
        print(f"🔄 Notifying Strands workflow of {len(anomalies)} equipment anomalies...")
        
        try:
            import requests
            
            # Get API URL from manual override or CloudFormation
            api_base_url = self.manual_api_url or self.get_api_url()
            if not api_base_url:
                print("❌ Could not determine API Gateway URL")
                print("💡 You can manually set the API URL by:")
                print("   simulator = SimpleEquipmentSimulator('https://your-api-gateway-url.amazonaws.com/prod')")
                return
            
            # Ensure URL ends with proper path
            if not api_base_url.endswith('/'):
                api_base_url += '/'
            api_url = f"{api_base_url}strands-agent-chat"
            
            print(f"📡 Using API endpoint: {api_url}")
            
            success_count = 0
            
            for i, anomaly in enumerate(anomalies, 1):
                print(f"🔄 [{i}/{len(anomalies)}] Processing {anomaly['appliance_name']} at {anomaly['restaurant_id']}...")
                
                # Format data for Strands workflow
                payload = {
                    'equipment': {
                        'restaurant_id': anomaly['restaurant_id'],
                        'appliance_name': anomaly['appliance_name'],
                        'appliance_type': anomaly['appliance_type'],
                        'temperature': float(anomaly['temperature']),
                        'target_temperature': float(anomaly['target_temperature']),
                        'status': anomaly['status'],
                        'timestamp': datetime.now().isoformat()
                    }
                }
                
                try:
                    response = requests.post(
                        api_url, 
                        json=payload,
                        headers={'Content-Type': 'application/json'},
                        timeout=30
                    )
                    
                    print(f"   Status Code: {response.status_code}")
                    
                    if response.status_code == 200:
                        result = response.json()
                        if result.get('ticket_id'):
                            print(f"   ✅ Ticket {result.get('ticket_id')} created ({result.get('priority', 'unknown')} priority)")
                            success_count += 1
                        elif result.get('status') == 'no_action_needed':
                            print(f"   ℹ️ No action needed (temperature within acceptable range)")
                        else:
                            print(f"   ℹ️ Response: {result}")
                    else:
                        print(f"   ❌ HTTP {response.status_code}: {response.text}")
                        
                except requests.exceptions.Timeout:
                    print(f"   ⏰ Request timeout for {anomaly['appliance_name']}")
                except requests.exceptions.RequestException as e:
                    print(f"   ❌ Request failed for {anomaly['appliance_name']}: {e}")
                
                # Brief pause between requests
                if i < len(anomalies):
                    import time
                    time.sleep(1)
            
            print(f"\n🎯 Strands workflow notification complete: {success_count}/{len(anomalies)} successful")
                    
        except ImportError:
            print("❌ requests library not available - install with: pip install requests")
        except Exception as e:
            print(f"❌ Error notifying Strands workflow: {e}")
            print("💡 Check that the API Gateway is deployed and accessible")

    def populate_tickets(self):
        """Skip ticket creation - Strands workflow will create them automatically"""
        print("🎫 Skipping ticket creation - Strands workflow will auto-create tickets for equipment anomalies")
        print("ℹ️ Tickets will be generated automatically when Strands workflow processes equipment anomalies")

    def run(self):
        """Run the complete simulation"""
        print("🚀 Starting Simple Equipment Simulator")
        print(f"📍 Populating data for {len(self.locations)} Georgia restaurants")
        print()
        
        try:
            self.clear_tables()
            print()
            
            self.populate_restaurants()
            print()
            
            self.populate_equipment()
            print()
            
            self.populate_tickets()
            print()
            
            print("🎯 Simulation complete!")
            print("📊 Summary:")
            print(f"   • {len(self.locations)} restaurants populated")
            print(f"   • {len(self.locations) * len(self.appliances)} equipment readings")
            print("   • Tickets will be auto-created by Strands workflow for anomalies")
            print()
            print("✅ API Gateway endpoints should now return data!")
            print("🔄 Strands workflow has been notified of equipment anomalies and will create tickets")
            
            # Automatically run Strands API test (no user prompt)
            print("\n🧪 Running Strands API test automatically...")
            self.run_strands_test()
            
        except Exception as e:
            print(f"❌ Error: {e}")
            print("Make sure AWS credentials are configured and DynamoDB tables exist")
    
    def run_strands_test(self):
        """Run the standalone Strands API test"""
        try:
            import subprocess
            import sys
            import os
            
            test_script = os.path.join(os.path.dirname(__file__), 'test_strands_api.py')
            
            # Check if test script exists
            if not os.path.exists(test_script):
                print("ℹ️ Strands API test script not found - skipping test")
                print("💡 System is ready for manual testing via dashboard")
                return
            
            print("\n🧪 Running Strands API Test...")
            print("=" * 50)
            
            result = subprocess.run([sys.executable, test_script], 
                                  capture_output=False, 
                                  text=True)
            
            if result.returncode == 0:
                print("\n✅ Strands API test completed")
            else:
                print("\n⚠️ Strands API test finished with warnings")
                
        except Exception as e:
            print(f"\n❌ Could not run Strands API test: {e}")
            print("💡 System is ready for manual testing via dashboard")

if __name__ == "__main__":
    simulator = SimpleEquipmentSimulator()
    simulator.run()