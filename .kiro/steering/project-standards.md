---
inclusion: always
---

# Restaurant Monitoring Project Standards

## File Organization Rules

⚠️ **IMPORTANT**: All temporary, working, reference, and generated documents MUST be created in the `temp/` folder.

| Folder | Purpose |
|--------|---------|
| `temp/` | Working documents, drafts, reference files, generated reports |
| `temp/deployment-archive/` | Archived deployment scripts |
| `temp/deployment-legacy/` | Legacy/deprecated deployment files |
| `temp/infrastructure/` | Infrastructure reference templates |
| `temp/src-reference/` | Reference source code |
| `temp/source-backup/` | Backup copies of source files |

**DO NOT** create markdown files, summaries, or documentation in the project root or other folders unless explicitly requested.

## Project Overview

This is an AWS Solutions Library guidance demonstrating AI-powered restaurant equipment monitoring using Amazon Bedrock AgentCore, DynamoDB, and real-time anomaly detection across 10 Georgia restaurant locations.

## Architecture

- **Frontend**: S3 + CloudFront + Cognito authentication
- **Backend**: API Gateway + Lambda + DynamoDB
- **AI Agent**: Bedrock AgentCore with Strands SDK (Nova Lite model)
- **Data**: DynamoDB tables for equipment, inventory, staffing, tickets

## Key Constraints

1. **Security First**: Address all security vulnerabilities before production deployment
2. **Budget**: ~$2,482/month for 10 locations
3. **Model**: Amazon Bedrock Nova Lite (`us.amazon.nova-lite-v1:0`)
4. **Deployment**: Requires AgentCore CLI for agent deployment
5. **Frontend**: Must work with CloudFront + S3 static hosting

## Code Standards

### Python (Agent Code)
- Use type hints for all function parameters
- All tools must use the `@tool` decorator from Strands SDK
- Return format: `{"status": "success|error", "content": [{"text": "..."}]}`
- Use `boto3.resource('dynamodb')` for DynamoDB operations
- Handle errors gracefully with retry logic for transient Bedrock errors

### JavaScript (Frontend)
- Use async/await for API calls
- Handle authentication via Cognito
- Display loading states during API operations
- Show user-friendly error messages

### CloudFormation
- Use `!Sub` for string interpolation
- Include proper IAM policies with least privilege
- Add `DeletionPolicy: Retain` for data tables
- Enable encryption at rest for all data stores

## DynamoDB Tables

| Table | Primary Key | Sort Key |
|-------|-------------|----------|
| restaurants | restaurant_id | - |
| equipment-readings | equipment_id | timestamp |
| inventory-items | restaurant_id | item_id |
| staffing-schedule | restaurant_id | shift_id |
| tickets | ticket_id | - |

## Restaurant Locations

10 Georgia locations: AFC-001 (Atlanta) through AFC-010 (Cumming)

## Equipment Types

1. Walk-in Cooler (38°F target)
2. Beverage Cooler (35°F target)
3. Freezer Unit (-5°F target)
4. Burger Grill (450°F target)
5. French Fry Station (375°F target)
6. Chicken Fryer (375°F target)
7. Ice Cream Freezer (-10°F target)

## Deployment

### Quick Commands
```bash
./deployment/deploy-all.sh          # Full deployment
./deployment/deploy-agentcore-cli.sh # Agent only
./deployment/utils/cleanup-all.sh    # Cleanup
```

### Stack Names
- `restaurant-agent-infrastructure-prod` - Base infrastructure
- `restaurant-agent-inventory-prod` - Inventory tables
- `restaurant-agent-staffing-prod` - Staffing tables
- `restaurant-agent-chat-prod` - Standard chat endpoint
- `restaurant-agent-chat-streaming-prod` - Streaming chat endpoint

### AgentCore CLI
```bash
pipx install bedrock-agentcore-starter-toolkit
agentcore configure --entrypoint agent.py --name restaurant_agent --runtime PYTHON_3_11 --disable-memory --non-interactive
agentcore deploy
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/restaurants` | GET | List all restaurants |
| `/equipment` | GET | Get equipment status |
| `/inventory` | GET | Get inventory levels |
| `/staffing` | GET | Get staffing data |
| `/tickets` | GET | Get maintenance tickets |
| `/chat` | POST | Standard chat |
| `/chat-stream` | POST | Streaming chat |

## Agent Tools

| Tool | Description |
|------|-------------|
| `get_restaurants` | List all restaurant locations |
| `get_equipment` | Get equipment status and temperatures |
| `get_inventory` | Get inventory levels |
| `get_staffing` | Get staffing schedules |
| `get_tickets` | Get maintenance tickets |
| `create_ticket` | Create new maintenance ticket |
| `analyze_temperature` | Analyze equipment temperature |
| `get_troubleshooting` | Get troubleshooting steps |
