# Appliance Maintenance Support for Nova Sonic

## Overview
Nova Sonic now understands and responds to appliance temperature issues with comprehensive analysis, troubleshooting guidance, and safety warnings.

## Status
✅ **DEPLOYED** - Live at `https://g38q85ace8.execute-api.us-east-1.amazonaws.com/prod/strands-agent-chat`

## Features Implemented

### Temperature Analysis
- Severity assessment (normal/medium/high/critical)
- Deviation calculation from target ranges
- Urgency determination
- Recurring issue detection

### Equipment Database
- REF-001: Walk-in Cooler (35-40°F)
- REF-002: Beverage Cooler (33-38°F)
- FRZ-001: Walk-in Freezer (-10 to 0°F)
- GRILL-001: Commercial Grill (300-500°F)
- FRYER-001: Deep Fryer (325-375°F)

### Troubleshooting Guides
- Refrigerator high temperature (7 steps)
- Freezer high temperature (6 steps)
- Grill temperature issues (5 steps)
- Fryer temperature issues (4 steps)
- All include safety warnings

### Maintenance History
- Checks last 30 days of tickets
- Identifies recurring issues
- Warns about patterns

## How It Works

```
User: "Why is the walk-in cooler temperature high?"
    ↓
Lambda detects temperature keywords
    ↓
Identifies equipment (walk-in cooler → REF-001)
    ↓
Gets current temperature from DynamoDB
    ↓
Analyzes severity and urgency
    ↓
Checks maintenance history
    ↓
Gets troubleshooting steps
    ↓
Returns comprehensive response
```

## Example Response

```
⚠️ HIGH PRIORITY: Create maintenance ticket and begin troubleshooting

Current Status:
- Temperature: 48.0°F
- Target Range: 35-40°F
- Deviation: 10.5°F
- Severity: too_warm

⚠️ WARNING: 2 temperature-related tickets in last 30 days
This is a recurring issue - professional inspection recommended.

Troubleshooting Steps:
1. Check if the door is fully closed and seals properly
2. Verify the thermostat setting (should be 35-40°F)
3. Inspect door gaskets for wear or damage
4. Check for blocked air vents inside the unit
5. Ensure condenser coils are clean
6. Verify the evaporator fan is running
⚠️ SAFETY: If temperature exceeds 45°F for >2 hours, move perishables

If these steps don't resolve the issue, I can create a maintenance ticket.
```

## Implementation

**Location:** `deployment/strands-agent-chat-workflow.yaml`

The appliance analysis logic is embedded directly in the Lambda function:
- Equipment specs database (lines 100-108)
- Troubleshooting guides (lines 110-145)
- Temperature analysis function (lines 147-195)
- Troubleshooting function (lines 197-212)
- Query handler (lines 214-280)

## Requirements Coverage

| Requirement | Status |
|-------------|--------|
| Equipment Information Retrieval | ✅ Complete |
| Maintenance Ticket Management | ✅ Complete |
| Maintenance History Tracking | ✅ Complete |
| Troubleshooting Assistance | ✅ Complete |
| Equipment Lifecycle Management | ⚠️ Partial |
| Multi-Equipment Issue Correlation | ✅ Complete |
| Integration with Existing Systems | ✅ Complete |
| Natural Language Understanding | ✅ Complete |

**7/8 requirements implemented**

## Testing

```bash
curl -X POST https://g38q85ace8.execute-api.us-east-1.amazonaws.com/prod/strands-agent-chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Why is the walk-in cooler temperature high?", "session_id": "test"}'
```

## Documentation

See [requirements.md](requirements.md) for detailed feature requirements.

## Deployment Status

✅ Deployed: 2026-01-04T23:26:23 UTC
✅ Stack Status: UPDATE_COMPLETE
✅ Endpoint: Active and responding
✅ Frontend: Already configured

**Ready for production use!**
