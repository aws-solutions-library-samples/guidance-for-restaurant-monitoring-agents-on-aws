# Project Structure - Restaurant Monitoring with Nova Sonic

## Required Files (Production)

### Root Level
```
├── README.md                          # Main project documentation
├── requirements.txt                   # Python dependencies
├── DEPLOYMENT_SUMMARY.md              # Deployment status
└── PROJECT_STRUCTURE.md               # This file
```

### Deployment (Essential)
```
deployment/
├── README.md                                              # Deployment overview
├── DEPLOYMENT_GUIDE.md                                    # Step-by-step guide
├── AGENTCORE_MIGRATION.md                                 # AgentCore migration guide
├── restaurant-monitoring-base-template.yaml               # Base infrastructure (REQUIRED)
├── inventory-infra.yaml                                   # Inventory tables (REQUIRED)
├── staffing-infra.yaml                                    # Staffing tables (REQUIRED)
├── infrastructure/cloudformation/agentcore-chat.yaml      # AgentCore with appliance tools (PRIMARY)
├── strands-agent-chat-workflow.yaml                       # Alternative Lambda implementation (BACKUP)
├── simple_simulator.py                                    # Equipment data simulator
├── deploy-agentcore-with-appliance-tools.sh              # AgentCore deployment
├── deploy.sh                                              # Main deployment script
├── cleanup.sh                                             # Cleanup script
├── cleanup-all.sh                                         # Complete cleanup
└── invalidate-frontend-cache.sh                           # Cache management
```

### Frontend (Active Deployment)
```
frontend/
├── index.html                         # Main dashboard
├── 3d-twin.html                       # 3D equipment visualization
├── inventory.html                     # Inventory management
├── staffing.html                      # Staffing management
├── tickets.html                       # Maintenance tickets
├── chat-widget.js                     # Chat interface
└── [other frontend assets]
```

### Documentation
```
docs/
├── PROJECT_REQUIREMENTS_MATRIX.md     # Requirements tracking
└── VOICE_CHAT_FEATURE.md              # Voice chat documentation

.kiro/specs/appliance-maintenance-support/
├── README.md                          # Feature overview
└── requirements.md                    # Detailed requirements
```

## Files Moved to Temp (Reference/Backup)

### temp/source-backup/
Old source folder - replaced by frontend/
- **Reason:** frontend/ is the active deployment
- **Keep for:** Reference if needed

### temp/src/ (To be moved)
Reference implementations and experimental code
- **src/agentcore/** - Tool module references
- **src/agentcore-direct/** - Direct deployment experiments
- **src/lambda/** - Lambda function code
- **Reason:** AgentCore now has all tools embedded
- **Keep for:** Reference implementations, future enhancements

### temp/docs-archive/ (To be moved)
Interim documentation from development
- **Reason:** Superseded by final documentation
- **Keep for:** Historical reference

## Active Infrastructure

### Required Stacks:
1. **rest-monitor-base-infrastructure-prod**
   - Template: `restaurant-monitoring-base-template.yaml`
   - Creates: Equipment, tickets, restaurants tables
   - Status: ✅ Deployed

2. **restaurant-monitoring-inventory-infrastructure-production**
   - Template: `inventory-infra.yaml`
   - Creates: Inventory tables
   - Status: ✅ Deployed

3. **restaurant-monitoring-staffing-infrastructure-production**
   - Template: `staffing-infra.yaml`
   - Creates: Staffing tables
   - Status: ✅ Deployed

4. **restaurant-agentcore**
   - Template: `infrastructure/cloudformation/agentcore-chat.yaml`
   - Creates: AgentCore runtime with Nova Sonic agent
   - Status: ⏳ Updating with appliance tools

### Optional/Backup Stacks:
5. **restaurant-monitoring-strands-chat**
   - Template: `strands-agent-chat-workflow.yaml`
   - Creates: Alternative Lambda implementation
   - Status: ✅ Deployed (backup)

## Nova Sonic Capabilities

### AgentCore Agent Tools (12 total):

**Equipment & Maintenance (7):**
1. get_restaurants
2. get_equipment
3. get_tickets
4. create_ticket
5. analyze_temperature_issue ← NEW
6. get_troubleshooting_steps ← NEW
7. get_equipment_details ← NEW
8. get_maintenance_history ← NEW

**Inventory (3):**
9. get_inventory_status
10. update_inventory
11. get_inventory_alerts

**AWS Integration (1):**
12. use_aws

### Embedded Data:
- Equipment specs (5 equipment types)
- Troubleshooting guides (4 equipment categories)
- Temperature ranges and thresholds

## Deployment Commands

### Deploy Everything:
```bash
# 1. Base infrastructure
aws cloudformation create-stack \
  --stack-name rest-monitor-base-infrastructure-prod \
  --template-body file://deployment/restaurant-monitoring-base-template.yaml

# 2. Inventory infrastructure
aws cloudformation create-stack \
  --stack-name restaurant-monitoring-inventory-infrastructure-production \
  --template-body file://deployment/inventory-infra.yaml

# 3. Staffing infrastructure
aws cloudformation create-stack \
  --stack-name restaurant-monitoring-staffing-infrastructure-production \
  --template-body file://deployment/staffing-infra.yaml

# 4. AgentCore with appliance tools
cd deployment
./deploy-agentcore-with-appliance-tools.sh
```

### Test:
```bash
# Get endpoint
ENDPOINT=$(aws cloudformation describe-stacks \
    --stack-name restaurant-agentcore \
    --query 'Stacks[0].Outputs[?OutputKey==`ChatApiEndpoint`].OutputValue' \
    --output text)

# Test temperature
curl -X POST $ENDPOINT \
    -H "Content-Type: application/json" \
    -d '{"prompt": "Analyze temperature for REF-001", "sessionId": "test"}'
```

## Cleanup Plan

### Move to temp/:
- src/ folder (reference code)
- Interim documentation files
- Experimental implementations

### Keep in project:
- deployment/ (essential templates and scripts)
- frontend/ (active web app)
- docs/ (project documentation)
- README.md and key docs

## Summary

**Primary Implementation:** AgentCore with Strands Agents
**Backup Implementation:** Lambda with embedded logic (strands-agent-chat-workflow.yaml)
**Frontend:** frontend/ folder deployed to S3/CloudFront
**Status:** AgentCore updating with appliance tools (15-20 min)

**All required files documented and organized!**
