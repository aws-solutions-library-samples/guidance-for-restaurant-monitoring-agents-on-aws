# Deployment

## Quick Start

```bash
./deployment/deploy-all.sh           # Full deployment (5 steps)
bash deployment/load-data.sh         # Reload sample data
bash deployment/cleanup.sh           # Delete all stacks
```

## Structure

```
deployment/
├── deploy-all.sh                              # Full deployment (run this)
├── deploy-agentcore-cli.sh                    # Agent-only deploy
├── restaurant-monitoring-base-template.yaml   # CloudFormation: DynamoDB, API GW, S3, CloudFront, Cognito
├── chat-endpoint.yaml                         # CloudFormation: Chat Lambda + API Gateway
├── load-data.sh                               # Sample data with realistic issues
├── load-sample-data.py                        # Fallback data loader
├── cleanup.sh                                 # Delete all CloudFormation stacks
├── invalidate-frontend-cache.sh               # CloudFront cache invalidation
└── agent-code/                                # Strands agent for Bedrock AgentCore
    ├── agent.py                               #   Text (@app.entrypoint) + Voice (@app.websocket)
    └── requirements.txt                       #   strands-agents[bidi], boto3, bedrock-agentcore
```

## Deployment Steps (deploy-all.sh)

1. **Infrastructure** — CloudFormation creates 6 DynamoDB tables, API Gateway (7 endpoints), S3, CloudFront, Cognito, Lambda
2. **Sample Data** — Loads 5 restaurants, 25 equipment (5 issues), 30 inventory (5 critical), 35 staffing (7 gaps), 8 tickets
3. **AgentCore Agent** — Deploys Python 3.12 Strands agent with text (Nova Lite) + voice (Nova Sonic BidiAgent) endpoints. Updates API Lambda with correct agent ARN.
4. **Chat Endpoint** — Lambda that calls `invoke_agent_runtime` for text chat
5. **Frontend** — Updates API URL + Cognito credentials in frontend files, syncs to S3, invalidates CloudFront

## Prerequisites

- AWS CLI configured
- Python 3.12+
- AgentCore CLI: `pipx install bedrock-agentcore-starter-toolkit`
- Bedrock model access: Nova Lite + Nova Sonic
