#!/usr/bin/env python3
"""
Standalone Strands API Test Script
Tests the Strands agent chat workflow endpoint directly
"""
import json
import requests
import boto3
from datetime import datetime

def get_api_url():
    """Get API Gateway URL from CloudFormation"""
    try:
        cf = boto3.client('cloudformation', region_name='us-east-1')
        stack_names = [
            'restaurant-kitchen-assistant-base-infrastructure-production',
            'restaurant-kitchen-assistant-base-production',
            'restaurant-kitchen-assistant-production'
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
        
        print("❌ Could not find API Gateway URL in any CloudFormation stack")
        return None
        
    except Exception as e:
        print(f"❌ Error getting API URL: {e}")
        return None

def test_equipment_anomaly(api_url):
    """Test equipment anomaly processing"""
    print("🔧 Testing Equipment Anomaly Processing...")
    
    test_cases = [
        {
            "name": "Critical Temperature - Walk-in Cooler",
            "payload": {
                "equipment": {
                    "restaurant_id": "AFC-002",
                    "equipment_id": "REF-001", 
                    "appliance_name": "Walk-in Cooler",
                    "appliance_type": "refrigerator",
                    "temperature": 55.0,
                    "target_temperature": 38.0,
                    "status": "critical",
                    "timestamp": datetime.now().isoformat()
                }
            }
        },
        {
            "name": "Warning Temperature - Freezer Unit", 
            "payload": {
                "equipment": {
                    "restaurant_id": "AFC-003",
                    "equipment_id": "FRZ-001",
                    "appliance_name": "Freezer Unit", 
                    "appliance_type": "freezer",
                    "temperature": 15.0,
                    "target_temperature": -5.0,
                    "status": "warning",
                    "timestamp": datetime.now().isoformat()
                }
            }
        }
    ]
    
    for i, test_case in enumerate(test_cases, 1):
        print(f"\n📋 Test {i}: {test_case['name']}")
        
        try:
            response = requests.post(
                f"{api_url}/strands-agent-chat",
                json=test_case['payload'],
                headers={'Content-Type': 'application/json'},
                timeout=30
            )
            
            print(f"   Status: {response.status_code}")
            
            if response.status_code == 200:
                result = response.json()
                print(f"   ✅ Response: {json.dumps(result, indent=2)}")
            else:
                print(f"   ❌ Error: {response.text}")
                
        except Exception as e:
            print(f"   ❌ Request failed: {e}")

def test_chat_functionality(api_url):
    """Test chat functionality"""
    print("\n💬 Testing Chat Functionality...")
    
    chat_tests = [
        "How many critical issues are there?",
        "Show me the status of Atlanta kitchen",
        "What equipment needs attention?"
    ]
    
    session_id = f"test_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    
    for i, message in enumerate(chat_tests, 1):
        print(f"\n💭 Chat Test {i}: '{message}'")
        
        try:
            response = requests.post(
                f"{api_url}/strands-agent-chat",
                json={
                    "message": message,
                    "session_id": session_id
                },
                headers={'Content-Type': 'application/json'},
                timeout=30
            )
            
            print(f"   Status: {response.status_code}")
            
            if response.status_code == 200:
                result = response.json()
                print(f"   ✅ Bot Response: {result.get('response', 'No response')}")
                if result.get('session_id'):
                    session_id = result['session_id']
            else:
                print(f"   ❌ Error: {response.text}")
                
        except Exception as e:
            print(f"   ❌ Request failed: {e}")

def main():
    print("🚀 Strands API Endpoint Test")
    print("=" * 50)
    
    # Get API URL automatically
    api_url = get_api_url()
    if not api_url:
        print("💡 Attempting manual input as fallback:")
        api_url = input("Enter API Gateway URL (or press Enter to skip): ").strip()
        if not api_url:
            print("❌ No API URL provided. Exiting.")
            return
    
    print(f"📡 Using API: {api_url}")
    
    # Test equipment anomaly processing
    test_equipment_anomaly(api_url)
    
    # Test chat functionality  
    test_chat_functionality(api_url)
    
    print("\n🎯 Strands API testing complete!")

if __name__ == "__main__":
    main()