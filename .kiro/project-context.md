# Project: Guidance for AI-Powered Restaurant Visibility on AWS

## Objective
AWS Solutions Library guidance demonstrating AI-powered restaurant equipment monitoring using Amazon Bedrock AgentCore, DynamoDB, and real-time anomaly detection across 10 Georgia locations.

## Current Status
✅ Core infrastructure deployed
✅ AgentCore agent with 8 tools
✅ Frontend dashboard with 3D visualization
⚠️ Security vulnerabilities identified (see security/)
🔄 Ready for publication review

## Scope

### In Scope
- Restaurant equipment monitoring (70 sensors across 10 locations)
- AI-powered anomaly detection using Bedrock AgentCore
- Automated ticket creation for maintenance
- Real-time dashboard with 3D digital twin
- Inventory and staffing management
- Chat interface (standard + streaming)
- CloudFormation deployment automation
- Security assessment and remediation

### Out of Scope
- Production deployment (security issues must be addressed first)
- IoT sensor integration (uses simulated data)
- Mobile app
- Multi-region deployment
- Historical data analytics/ML models

## Key Constraints
- Must address security vulnerabilities before production use
- Budget: ~$2,482/month for 10 locations
- Uses Amazon Bedrock Nova Lite model
- Requires AgentCore CLI for agent deployment
- Frontend must work with CloudFront + S3

## Architecture
- **Frontend**: S3 + CloudFront + Cognito
- **Backend**: API Gateway + Lambda + DynamoDB
- **AI Agent**: Bedrock AgentCore with 8 tools
- **Data**: DynamoDB (equipment, inventory, staffing, tickets)
- **Monitoring**: 7 appliances per location, 10 locations

## Key Files
- `README.md` - Main documentation
- `deployment/deploy-all.sh` - Full deployment script
- `deployment/agent-code/agent.py` - AgentCore agent implementation
- `deployment/templates/restaurant-monitoring-base-template.yaml` - Main CFN template
- `frontend/index.html` - Main dashboard
- `security/SECURITY_REPORT.md` - Security assessment

## Equipment Types
1. Walk-in Cooler (38°F)
2. Beverage Cooler (35°F)
3. Freezer Unit (-5°F)
4. Burger Grill (450°F)
5. French Fry Station (375°F)
6. Chicken Fryer (375°F)
7. Ice Cream Freezer (-10°F)

## Restaurant Locations (10 Georgia locations)
AFC-001 through AFC-010: Atlanta, Savannah, Augusta, Macon, Athens, Columbus, Brunswick, Albany, Valdosta, Cumming

## Next Steps
- [ ] Address security vulnerabilities
- [ ] Complete publication review
- [ ] Add automated testing
- [ ] Create deployment video/tutorial
- [ ] Add cost optimization guidance
