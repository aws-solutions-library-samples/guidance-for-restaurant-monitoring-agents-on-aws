# Guidance for AI-Powered Restaurant Visibility on AWS

## Overview

AI-powered restaurant equipment monitoring system using Amazon Bedrock AgentCore, Nova Sonic speech-to-speech, and DynamoDB. Monitors 5 Georgia restaurant locations with real-time anomaly detection, automated ticket creation, and both text and voice conversational AI interfaces.

### Key Features

- **AI Agent**: Strands SDK agent on Bedrock AgentCore with 8 tools (equipment, inventory, staffing, tickets)
- **Voice Chat**: Nova Sonic BidiAgent for real-time speech-to-speech conversations via WebSocket
- **AgentCore Memory**: Short-term + long-term memory for conversation continuity
- **Voice Chat**: Nova Sonic BidiAgent for real-time speech-to-speech conversations via WebSocket
- **Text Chat**: Nova Lite model for text-based queries via API Gateway
- **3D Digital Twin**: Interactive Three.js visualization of restaurants and equipment status
- **Real-time Monitoring**: Equipment temperature tracking, inventory levels, staffing schedules
- **Automated Tickets**: Agent creates maintenance tickets with category tagging
- **Security Hardened**: Cognito auth (MFA), KMS CMK encryption, WAF, TLS 1.2, DLQ, least privilege IAM

### Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Frontend (S3 + CloudFront)                  │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ │
│  │Dashboard │ │3D Twin   │ │Inventory │ │Staffing  │ │Tickets   │ │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘ │
│       │    Chat Widget (Text + Voice)         │             │       │
└───────┼────────────┼──────────────────────────┼─────────────┼───────┘
        │            │                          │             │
        ▼            ▼                          ▼             ▼
┌───────────────────────────────────────────────────────────────────┐
│                    Amazon API Gateway (REST)                       │
│  /restaurants  /equipment  /inventory  /staffing  /tickets         │
│  /chat (POST)                         /voice-token (GET)          │
└───────┬───────────────────────────────────┬───────────────────────┘
        │                                   │
        ▼                                   ▼
┌───────────────────┐            ┌─────────────────────────┐
│  API Lambda        │            │  Chat Lambda             │
│  (DynamoDB CRUD +  │            │  (invoke_agent_runtime)  │
│   voice-token)     │            └──────────┬──────────────┘
└───────┬───────────┘                        │
        │                                    ▼
        ▼                         ┌─────────────────────────┐
┌───────────────────┐             │  Bedrock AgentCore       │
│  Amazon DynamoDB   │◄───────────│  ┌───────────────────┐   │
│  • restaurants     │   tools    │  │ Strands Agent      │   │
│  • equipment       │◄──────────│  │ (Python 3.12)      │   │
│  • inventory       │            │  │ • Text: Nova Lite  │   │
│  • staffing        │            │  │ • Voice: Nova Sonic│   │
│  • tickets         │            │  │ • 8 DynamoDB tools │   │
│  • chat-history    │            │  └───────────────────┘   │
└───────────────────┘             └──────────┬──────────────┘
                                             │ WebSocket /ws
                                             ▼
                                  ┌─────────────────────────┐
                                  │  Browser (Voice Client)  │
                                  │  Mic → PCM 16kHz →       │
                                  │  AgentCore WebSocket →   │
                                  │  Nova Sonic BidiAgent →  │
                                  │  Audio Playback          │
                                  └─────────────────────────┘

Authentication: Amazon Cognito (User Pool + Identity Pool)
```


### Cost

Approximate monthly cost for 5 restaurant locations in US East (N. Virginia):

| AWS Service | Usage | Cost |
|---|---|---|
| Amazon Bedrock (Nova Lite + Nova Sonic) | Text + voice queries | ~$2,400 |
| Amazon DynamoDB (on-demand) | 6 tables, low throughput | ~$19 |
| AWS Lambda | API + Chat functions | ~$30 |
| Amazon S3 + CloudFront | Static frontend hosting | ~$2 |
| Amazon Cognito | User authentication | ~$10 |
| Amazon API Gateway | REST API | ~$3 |
| Bedrock AgentCore | Agent runtime | ~$18 |
| **Total** | | **~$2,482/month** |

## Prerequisites

- AWS CLI v2 configured with appropriate permissions
- Python 3.12+
- Bash shell
- `uv` (Python package manager): `curl -LsSf https://astral.sh/uv/install.sh | sh`
- AgentCore CLI: `pipx install bedrock-agentcore-starter-toolkit`
- Amazon Bedrock model access enabled for Nova Lite, Nova Sonic, and Titan Embed Text v2

## Deployment

### Quick Start

```bash
git clone <repo-url>
cd guidance-for-ai-powered-restaurant-visibility-on-aws
./deployment/deploy-all.sh
```

This runs 7 steps:
1. **Infrastructure** — CloudFormation: DynamoDB (KMS CMK), API Gateway (Cognito auth), S3, CloudFront (WAF + TLS 1.2), Cognito (MFA), KMS keys, SQS DLQ
2. **Sample Data** — Loads restaurants, equipment (with issues), inventory, staffing, tickets
3. **AgentCore Agent** — Deploys Strands agent with text + voice endpoints + STM/LTM memory
5. **Chat Endpoint** — Lambda + API Gateway `/chat` with Cognito authorizer
6. **Frontend** — Syncs to S3, updates API/Cognito credentials, invalidates CloudFront
7. **Demo User** — Creates Cognito user for testing

### Manual Commands

```bash
./deployment/deploy-all.sh                    # Full deployment
./deployment/deploy-agentcore-cli.sh          # Agent only
./deployment/load-data.sh                     # Reload sample data
./deployment/cleanup.sh                       # Delete all stacks
./deployment/invalidate-frontend-cache.sh     # Clear CloudFront cache
```

### Deployment Output

The script outputs:
- CloudFront URL (frontend)
- API Gateway URL (REST endpoints)
- Agent ARN (AgentCore runtime)
- Demo login credentials

### Post-Deployment Login

```
URL:      https://<cloudfront-domain>.cloudfront.net
Email:    demo@anycompany.com
Password: DemoPass#2026!
```

Note: Self-registration is disabled. Additional users must be created by an admin via:
```bash
aws cognito-idp admin-create-user --user-pool-id <pool-id> --username user@example.com \
    --user-attributes Name=email,Value=user@example.com Name=name,Value="User Name" Name=email_verified,Value=true \
    --temporary-password 'TempPass123!'
```

## Data Model

### DynamoDB Tables

| Table | Key | Data |
|---|---|---|
| restaurants | `id` (HASH) | 5 Georgia locations with status |
| equipment-readings | `restaurant_id` (HASH) + `equipment_id` (RANGE) | 5 equipment per restaurant |
| inventory-items | `item_id` (HASH) | 6 items per restaurant (composite key: `AFC-001_INV-001`) |
| staffing-requirements | `restaurant_id` (HASH) + `date` (RANGE) | Nested staffing array per day |
| tickets | `ticket_id` (HASH) | Equipment/inventory/staffing issues with category |

### Sample Data Issues (for demo)

| Restaurant | Issues |
|---|---|
| Atlanta (AFC-001) | Grill overheating 520°F, cooler warm 48.5°F, oil low, understaffed |
| Savannah (AFC-002) | Freezer failure 15°F, chicken low, fries low |
| Augusta (AFC-003) | Fryer underheating 310°F, lettuce critical |
| Macon (AFC-004) | Minor cashier gap |
| Athens (AFC-005) | Minor manager gap |

## Agent Tools

| Tool | Description |
|---|---|
| `get_restaurants` | List all restaurant locations |
| `get_equipment` | Get equipment status and temperatures |
| `get_inventory` | Get inventory levels |
| `get_staffing` | Get staffing schedules |
| `get_tickets` | Get maintenance tickets |
| `create_ticket` | Create new maintenance ticket |
| `analyze_temperature` | Analyze equipment temperature deviation |
| `get_troubleshooting` | Get troubleshooting steps by equipment type |

## API Endpoints

| Endpoint | Method | Description |
|---|---|---|
| `/restaurants` | GET | List all restaurants |
| `/equipment` | GET | Equipment status |
| `/inventory` | GET | Inventory levels |
| `/staffing` | GET | Staffing schedules |
| `/tickets` | GET | Maintenance tickets |
| `/chat` | POST | Text chat (Nova Lite via AgentCore) |
| `/voice-token` | GET | Presigned WebSocket URL for voice (Nova Sonic) |

## Frontend Pages

| Page | Description |
|---|---|
| `index.html` | Dashboard — restaurant cards with equipment/ticket counts |
| `3d-twin.html` | 3D Digital Twin — Georgia map, click-through to restaurant interiors |
| `inventory.html` | Inventory — table with stock levels, filters, status badges |
| `staffing.html` | Staffing — schedule with gap detection |
| `tickets.html` | Tickets — grouped by restaurant with category column |
| `login.html` | Cognito authentication |

All pages include a chat widget (text + voice) via `shared.js`.

## Project Structure

```
├── README.md
├── assets/
│   └── architecture-diagram.drawio            # Architecture diagram (draw.io)
├── deployment/
│   ├── deploy-all.sh                          # Full deployment
│   ├── deploy-agentcore-cli.sh                # Agent-only deploy
│   ├── restaurant-monitoring-base-template.yaml  # CloudFormation (infra)
│   ├── chat-endpoint.yaml                     # Chat Lambda + API Gateway
│   ├── load-data.sh / load-sample-data.py     # Sample data loaders
│   ├── cleanup.sh                             # Delete all stacks
│   ├── agent-code/
│   │   ├── agent.py                           # Strands agent (8 tools + memory)
│   │   └── requirements.txt
│           ├── beverage-cooler-manual.md
│           ├── freezer-unit-manual.md
│           ├── burger-grill-manual.md
│           ├── fryer-manual.md
│           └── ice-cream-freezer-manual.md
├── frontend/
│   ├── shared.js          # Nav, chat widget, auth, voice loader
│   ├── voice-client.js    # WebSocket voice client for Nova Sonic
│   ├── api.js             # API Gateway client (with auth)
│   ├── auth.js            # Cognito auth
│   ├── index.html         # Dashboard
│   ├── 3d-twin.html       # 3D Digital Twin
│   ├── inventory.html     # Inventory
│   ├── staffing.html      # Staffing
│   ├── tickets.html       # Tickets
│   └── login.html         # Login
├── security/              # Security scan reports (ASH)
└── .ash/                  # ASH security scanner config
```

## Cleanup

```bash
bash deployment/cleanup.sh
```

## Notices

This guidance is for informational purposes only and represents AWS current product offerings. Customers are responsible for making their own independent assessment. See `security/` for known security considerations.
