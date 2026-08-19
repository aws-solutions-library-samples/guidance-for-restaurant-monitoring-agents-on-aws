# Guidance for Restaurant Visibility using Agents on AWS

## Table of Contents

1. [Overview](#1-overview)
    - [Architecture](#architecture)
    - [Cost](#cost)
2. [Prerequisites](#2-prerequisites)
    - [Operating System](#operating-system)
    - [Third-party tools](#third-party-tools)
    - [AWS account requirements](#aws-account-requirements)
    - [Supported Regions](#supported-regions)
    - [External Dependencies](#external-dependencies)
    - [Configuration (edit before deploying)](#configuration-edit-before-deploying)
3. [Deployment Steps](#3-deployment-steps)
4. [Deployment Validation](#4-deployment-validation)
5. [Running the Guidance](#5-running-the-guidance)
6. [Next Steps](#6-next-steps)
7. [Cleanup](#7-cleanup)
8. [FAQ, Known Issues, and Limitations](#8-faq-known-issues-and-limitations)
9. [Notices](#9-notices)
10. [Authors](#10-authors)

---

## 1. Overview

This Guidance demonstrates how to build an AI-powered restaurant equipment monitoring system using Amazon Bedrock AgentCore, Amazon Bedrock Nova models, and Amazon DynamoDB. It monitors 5 Georgia restaurant locations with real-time anomaly detection, automated maintenance ticket creation, and both text and voice conversational AI interfaces.

The AI agent, built with the Strands SDK and running on Amazon Bedrock AgentCore, uses 8 tools to query equipment temperatures, inventory levels, staffing schedules, and maintenance tickets. Restaurant managers interact with the system through a web dashboard that includes a chat widget supporting both text (Amazon Bedrock Nova Lite) and real-time speech-to-speech voice (Amazon Bedrock Nova Sonic).

### Key Features

- **AI Agent** — Strands SDK agent on Amazon Bedrock AgentCore with 8 tools (equipment, inventory, staffing, tickets)
- **Voice Chat** — Nova Sonic BidiAgent for real-time speech-to-speech conversations over WebSocket
- **Text Chat** — Nova Lite model for text-based queries through Amazon API Gateway
- **AgentCore Memory** — Short-term and long-term memory for conversation continuity
- **3D Digital Twin** — Interactive Three.js visualization of restaurants and equipment status
- **Real-time Monitoring** — Equipment temperature tracking, inventory levels, and staffing schedules
- **Automated Tickets** — Agent creates maintenance tickets with category tagging
- **Security Hardened** — Amazon Cognito authentication (MFA), AWS KMS customer managed key encryption, AWS WAF, TLS 1.2, dead-letter queues, and least-privilege IAM

### Architecture

![Architecture Diagram](assets/architecture-diagram.png)

```
┌─────────────────────────────────────────────────────────────────────┐
│                       Frontend (S3 + CloudFront)                     │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐   │
│  │Dashboard │ │3D Twin   │ │Inventory │ │Staffing  │ │Tickets   │   │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘   │
│       │      Chat Widget (Text + Voice)      │            │         │
└───────┼────────────┼──────────────────────────┼───────────┼─────────┘
        │            │                          │           │
        ▼            ▼                          ▼           ▼
┌───────────────────────────────────────────────────────────────────┐
│                    Amazon API Gateway (REST)                       │
│  /restaurants  /equipment  /inventory  /staffing  /tickets         │
│  /chat (POST)                          /voice-token (GET)          │
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
┌───────────────────┐             │  Amazon Bedrock AgentCore│
│  Amazon DynamoDB   │◄───────────│  ┌───────────────────┐   │
│  • restaurants     │   tools    │  │ Strands Agent      │   │
│  • equipment       │◄──────────│  │ (Python 3.12)      │   │
│  • inventory       │            │  │ • Text: Nova Lite  │   │
│  • staffing        │            │  │ • Voice: Nova Sonic│   │
│  • tickets         │            │  │ • 8 DynamoDB tools │   │
│  • chat-history    │            │  └───────────────────┘   │
└───────────────────┘             └──────────┬──────────────┘
                                             │ WebSocket
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

You are responsible for the cost of the AWS services used while running this Guidance. As of July 2026, the cost for running this Guidance with the default settings in the US East (N. Virginia) `us-east-1` Region is approximately **$2,482 per month** for monitoring 5 restaurant locations.

We recommend creating a [budget](https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html) through [AWS Cost Explorer](https://aws.amazon.com/aws-cost-management/aws-cost-explorer/) to help manage costs. Prices are subject to change. For full details, refer to the pricing webpage for each AWS service used in this Guidance.

### Sample Cost Table

The following table provides a sample cost breakdown for deploying this Guidance with the default parameters in the US East (N. Virginia) Region for one month.

| AWS Service | Dimensions | Cost [USD] |
|---|---|---|
| Amazon Bedrock (Nova Lite + Nova Sonic) | Text and voice queries | $2,400.00 |
| Amazon Bedrock AgentCore | Agent runtime | $18.00 |
| AWS Lambda | API and chat functions | $30.00 |
| Amazon DynamoDB (on-demand) | 6 tables, low throughput | $19.00 |
| Amazon Cognito | User authentication | $10.00 |
| Amazon API Gateway | REST API | $3.00 |
| Amazon S3 + Amazon CloudFront | Static frontend hosting | $2.00 |
| **Total** | | **~$2,482.00/month** |

---

## 2. Prerequisites

### Operating System

These deployment instructions are optimized to best work on **macOS** or **Amazon Linux 2023 / Linux**. Deployment on Windows is possible using WSL2 (Windows Subsystem for Linux). The deployment scripts require a Bash shell.

### Third-party tools

Before deploying this Guidance, ensure the following tools are installed:

- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html), configured with credentials
- [Python 3.12+](https://www.python.org/downloads/)
- Bash shell
- [`uv`](https://docs.astral.sh/uv/getting-started/installation/) Python package manager: `curl -LsSf https://astral.sh/uv/install.sh | sh`
- Amazon Bedrock AgentCore starter toolkit: `pipx install bedrock-agentcore-starter-toolkit`

### AWS account requirements

This deployment requires that you have access to the following in your AWS account:

- Permissions to create and manage AWS CloudFormation stacks, IAM roles and policies, DynamoDB tables, Lambda functions, API Gateway, Amazon S3, Amazon CloudFront, Amazon Cognito, AWS WAF, AWS KMS keys, and Amazon SQS.
- Amazon Bedrock model access enabled for **Amazon Nova Lite** (`us.amazon.nova-lite-v1:0`), **Amazon Nova Sonic**, and **Amazon Titan Text Embeddings V2**. See [Manage access to Amazon Bedrock foundation models](https://docs.aws.amazon.com/bedrock/latest/userguide/model-access.html).
- Amazon Bedrock AgentCore availability in your chosen Region.

### Supported Regions

This Guidance is developed and tested in the **US East (N. Virginia) `us-east-1`** Region. Amazon Bedrock AgentCore, Amazon Nova Lite, and Amazon Nova Sonic must be available in the Region you deploy to. Deploy to a Region where all of these services are supported.

### External Dependencies

The frontend loads a small number of third-party assets from public CDNs at runtime. They are pinned to specific versions and (where supported) include Subresource Integrity (SRI) hashes and a Content Security Policy. Be aware that they create availability and privacy dependencies on the CDN providers. If your environment requires it, self-host these assets and update the `<script>` / `<link>` references in the `frontend/*.html` files accordingly.

| Asset | Source | Used by |
|---|---|---|
| Tailwind CSS (browser build) | `cdn.jsdelivr.net` | dashboard pages |
| Tabler Icons webfont | `cdn.jsdelivr.net` | dashboard pages |
| Leaflet (map) | `unpkg.com` | `index.html` |
| Amazon Cognito Identity SDK | `unpkg.com` | `login.html`, `shared.js` |
| Three.js + OrbitControls (3D) | `cdnjs.cloudflare.com`, `cdn.jsdelivr.net` | `3d-twin.html` |

No application code, secrets, or customer data is sent to these CDNs — they serve static library and font files only.

### Configuration (edit before deploying)

All account- and environment-specific values are centralized in **[`deployment/config.env`](deployment/config.env)**. No account IDs, Cognito IDs, API URLs, or credentials are hardcoded in the source. Edit this file before running any deployment script:

| Variable | Purpose | Default |
|---|---|---|
| `AWS_REGION` | Target Region (must support AgentCore + Nova) | `us-east-1` |
| `PROJECT_NAME` | Prefix for stack resources and DynamoDB tables | `restaurant-kitchen-assistant` |
| `ENVIRONMENT` | Environment suffix for resource names | `production` |
| `AGENT_NAME` | Logical AgentCore runtime name | `restaurant_agent` |
| `TEXT_MODEL_ID` | Bedrock model for text chat | `us.amazon.nova-lite-v1:0` |
| `VOICE_MODEL_ID` | Bedrock model for voice chat | `amazon.nova-2-sonic-v1:0` |
| `DEMO_USER_EMAIL` | Email for the demo login user | `demo@example.com` |
| `DEMO_USER_PASSWORD` | Password for the demo login user | **must be changed** |

`RESTAURANTS_TABLE`, `EQUIPMENT_TABLE`, `INVENTORY_TABLE`, `STAFFING_TABLE`, and `TICKETS_TABLE` are derived from `PROJECT_NAME`/`ENVIRONMENT` and rarely need changing.

Notes:
- **The deploy script refuses to run** until you change `DEMO_USER_PASSWORD` from its placeholder. Use a strong password that meets the Cognito policy (min 12 chars, upper, lower, number, symbol).
- **`frontend/config.js` is populated automatically at deploy time** from the CloudFormation stack outputs (Cognito IDs, API URL). The committed file contains only `__PLACEHOLDER__` tokens, and the deploy script restores those placeholders after uploading, so real identifiers are never written back into the repository.
- **The agent** (`deployment/agent-code/agent.py`) reads `PROJECT_NAME`, `ENVIRONMENT`, the table names, and the model IDs from its environment, falling back to the same defaults. If you change `PROJECT_NAME` or `ENVIRONMENT`, set the matching values as environment variables on the AgentCore runtime so the agent resolves the correct table names.

### Populating config.env from CloudFormation Outputs

After the initial deployment completes, you can retrieve resource identifiers from the CloudFormation stack outputs. Run the following to inspect outputs for the base infrastructure stack:

```bash
aws cloudformation describe-stacks \
  --stack-name restaurant-kitchen-assistant-infrastructure-production \
  --query "Stacks[0].Outputs" --output table
```

Map the outputs to `deployment/config.env` as follows:

| CloudFormation Output Key | config.env Variable | Description |
|---|---|---|
| `CognitoUserPoolId` | *(auto-injected into frontend/config.js)* | User Pool for authentication |
| `CognitoUserPoolClientId` | *(auto-injected into frontend/config.js)* | App Client ID |
| `ApiGatewayUrl` | *(auto-injected into frontend/config.js)* | REST API endpoint |
| `CloudFrontDistributionUrl` | — | Your application URL |
| `RestaurantsTableName` | `RESTAURANTS_TABLE` | Override only if you customized |
| `EquipmentTableName` | `EQUIPMENT_TABLE` | Override only if you customized |
| `InventoryTableName` | `INVENTORY_TABLE` | Override only if you customized |
| `StaffingTableName` | `STAFFING_TABLE` | Override only if you customized |
| `TicketsTableName` | `TICKETS_TABLE` | Override only if you customized |

> **Note:** Most users only need to set `AWS_REGION`, `DEMO_USER_EMAIL`, and `DEMO_USER_PASSWORD` before deploying. The table names, Cognito IDs, and API URLs are resolved automatically by the deployment scripts from CloudFormation outputs. Only override table names in `config.env` if you renamed them in the CloudFormation template.

---

## 3. Deployment Steps

1. Clone the repository to your local machine:

    ```bash
    git clone <repo-url>
    cd guidance-for-restaurant-monitoring-agents-on-aws
    ```

2. Confirm your AWS CLI is configured for the target account:

    ```bash
    aws sts get-caller-identity
    ```

3. Edit the configuration file with your values. At minimum, set a strong `DEMO_USER_PASSWORD` — the deploy script refuses to run while it is left at the placeholder. See [Configuration](#configuration-edit-before-deploying) for all settings.

    ```bash
    # edit deployment/config.env in your editor of choice
    nano deployment/config.env
    ```

4. Run the full deployment script:

    ```bash
    ./deployment/deploy-all.sh
    ```

    The script runs the following steps:

    1. **Infrastructure** — Deploys the CloudFormation stack `restaurant-agent-infrastructure-prod` (with your `ProjectName`/`Environment`), creating DynamoDB tables (KMS CMK encryption), API Gateway (Cognito authorizer), Amazon S3, Amazon CloudFront (AWS WAF + TLS 1.2), Amazon Cognito (MFA), KMS keys, and an SQS dead-letter queue.
    2. **Sample Data** — Loads 5 restaurants, 25 equipment readings (with realistic issues), 30 inventory items, staffing schedules, and 8 maintenance tickets.
    3. **AgentCore Agent** — Deploys the Python 3.12 Strands agent with text and voice endpoints and short-term/long-term memory, attaches a least-privilege IAM policy (DynamoDB scoped to this project's tables; Bedrock scoped to the Nova model family), then updates the API Lambda with the agent ARN.
    4. **Chat Endpoint** — Deploys the `restaurant-agent-chat-prod` stack: a Lambda function and API Gateway `/chat` route with a Cognito authorizer.
    5. **Frontend** — Generates `frontend/config.js` from the stack outputs (Cognito IDs + API URL), syncs the frontend to Amazon S3, invalidates the CloudFront cache, then restores the committed placeholders locally so no account-specific IDs remain in the working tree.
    6. **Demo User** — Creates the Cognito user defined by `DEMO_USER_EMAIL` / `DEMO_USER_PASSWORD`.

### Individual Commands

You can also run individual stages:

```bash
./deployment/deploy-all.sh                    # Full deployment
./deployment/deploy-agentcore-cli.sh          # Agent only
bash deployment/load-data.sh                  # Reload sample data
./deployment/invalidate-frontend-cache.sh     # Clear CloudFront cache
bash deployment/cleanup.sh                    # Delete all stacks
```

---

## 4. Deployment Validation

After deployment completes, the script prints a summary containing the CloudFront URL, API Gateway URL, and Agent ARN. To validate the deployment:

1. Confirm both CloudFormation stacks reached `CREATE_COMPLETE` or `UPDATE_COMPLETE`:

    ```bash
    aws cloudformation describe-stacks --stack-name restaurant-agent-infrastructure-prod \
        --query 'Stacks[0].StackStatus' --output text
    aws cloudformation describe-stacks --stack-name restaurant-agent-chat-prod \
        --query 'Stacks[0].StackStatus' --output text
    ```

2. Confirm the DynamoDB tables were created and populated:

    ```bash
    aws dynamodb scan --table-name restaurant-kitchen-assistant-restaurants-production \
        --select COUNT --query 'Count'
    ```

    This should return `5`.

3. Confirm the AgentCore agent is deployed:

    ```bash
    cd deployment/agent-code && agentcore status
    ```

---

## 5. Running the Guidance

1. Open the CloudFront URL printed by the deployment script in your browser:

    ```
    https://<cloudfront-domain>.cloudfront.net
    ```

2. Sign in with the demo user you configured in `deployment/config.env`:

    ```
    Email:    <DEMO_USER_EMAIL from config.env>
    Password: <DEMO_USER_PASSWORD from config.env>
    ```

3. Explore the application:
    - **Dashboard** — Restaurant cards with equipment and ticket counts, color-coded by status.
    - **3D Twin** — Interactive Georgia map with click-through to restaurant interiors.
    - **Inventory** — Stock levels with status badges and filters.
    - **Staffing** — Schedules with automatic gap detection.
    - **Tickets** — Maintenance tickets grouped by restaurant and category.

4. Use the chat widget (available on every page) to ask the AI agent questions in text or voice, for example:
    - "Which restaurants have equipment issues right now?"
    - "What is the temperature of the walk-in freezer at the Savannah location?"
    - "Create a maintenance ticket for the overheating grill in Atlanta."
    - "Which locations are understaffed this week?"

> **Note:** Self-registration is disabled. Additional users must be created by an administrator:
>
> ```bash
> aws cognito-idp admin-create-user --user-pool-id <pool-id> --username user@example.com \
>     --user-attributes Name=email,Value=user@example.com Name=name,Value="User Name" Name=email_verified,Value=true \
>     --temporary-password '<a-strong-temporary-password>'
> ```

### Data Model

| DynamoDB Table | Partition Key | Sort Key | Contents |
|---|---|---|---|
| restaurants | `id` | – | 5 Georgia locations with status |
| equipment-readings | `restaurant_id` | `equipment_id` | 5 equipment units per restaurant |
| inventory-items | `item_id` | – | 6 items per restaurant (composite key `AFC-001_INV-001`) |
| staffing-requirements | `restaurant_id` | `date` | Nested staffing array per day |
| tickets | `ticket_id` | – | Equipment, inventory, and staffing issues with category |

### Agent Tools

| Tool | Description |
|---|---|
| `get_restaurants` | List all restaurant locations |
| `get_equipment` | Get equipment status and temperatures |
| `get_inventory` | Get inventory levels |
| `get_staffing` | Get staffing schedules |
| `get_tickets` | Get maintenance tickets |
| `create_ticket` | Create a new maintenance ticket |
| `analyze_temperature` | Analyze equipment temperature deviation |
| `get_troubleshooting` | Get troubleshooting steps by equipment type |

### API Endpoints

| Endpoint | Method | Description |
|---|---|---|
| `/restaurants` | GET | List all restaurants |
| `/equipment` | GET | Equipment status |
| `/inventory` | GET | Inventory levels |
| `/staffing` | GET | Staffing schedules |
| `/tickets` | GET | Maintenance tickets |
| `/chat` | POST | Text chat (Nova Lite via AgentCore) |
| `/voice-token` | GET | Presigned WebSocket URL for voice (Nova Sonic) |

All endpoints require a valid Amazon Cognito authentication token.

---

## 6. Next Steps

Consider the following to adapt this Guidance to your own needs:

- **Add more locations** — Extend `deployment/load-data.sh` with additional restaurant entries beyond the 5 sample Georgia locations.
- **Connect real telemetry** — Replace the sample data loader with an ingestion pipeline (for example, AWS IoT Core) that writes live equipment readings into the `equipment-readings` table.
- **Customize the agent** — Add or modify tools in `deployment/agent-code/agent.py` to support new data sources or actions.
- **Tune the model** — Experiment with different Amazon Bedrock models or prompts to balance cost and response quality.
- **Add observability** — Configure Amazon CloudWatch alarms for Lambda errors, API Gateway 4xx/5xx responses, and DynamoDB throttling.

---

## 7. Cleanup

To avoid ongoing charges, delete all resources created by this Guidance:

```bash
bash deployment/cleanup.sh
```

This deletes the `restaurant-agent-infrastructure-prod` and `restaurant-agent-chat-prod` CloudFormation stacks and the AgentCore agent.

> **Note:** DynamoDB tables are configured with a `DeletionPolicy: Retain` to protect data. After running cleanup, verify whether any retained tables or KMS keys remain and delete them manually if they are no longer needed.

---

## 8. FAQ, Known Issues, and Limitations

- **Amazon Bedrock model access is required.** If deployment fails at the agent step, confirm that Nova Lite, Nova Sonic, and Titan Text Embeddings V2 access is enabled in your Region.
- **AgentCore CLI must be installed.** The agent deployment step is skipped if the `agentcore` CLI is not found. Install it with `pipx install bedrock-agentcore-starter-toolkit` and re-run `./deployment/deploy-agentcore-cli.sh`.
- **Voice chat requires microphone access.** Browsers only grant microphone access over HTTPS, which the CloudFront distribution provides.
- **IAM is scoped to least privilege.** The agent runtime policy grants DynamoDB access only to this project's tables (`<PROJECT_NAME>-*`) and Bedrock access only to the Nova model family (foundation models plus `us.amazon.nova-*` cross-region inference profiles). If you add models or data sources, extend the policy in `deployment/deploy-all.sh` rather than widening it to `"Resource": "*"`.
- **External CDN dependencies.** The frontend loads JavaScript libraries from public CDNs — see [External Dependencies](#external-dependencies). Self-host them if your environment prohibits third-party CDN access. (Fonts are already self-hosted in `frontend/fonts/`.)
- **This Guidance is for demonstration purposes.** Review the security considerations in the [`security/`](security/) directory before adapting it for production use.

---

## 9. Notices

Customers are responsible for making their own independent assessment of the information in this Guidance. This Guidance: (a) is for informational purposes only, (b) represents AWS current product offerings and practices, which are subject to change without notice, and (c) does not create any commitments or assurances from AWS and its affiliates, suppliers, or licensors. AWS products or services are provided "as is" without warranties, representations, or conditions of any kind, whether express or implied. AWS responsibilities and liabilities to its customers are controlled by AWS agreements, and this Guidance is not part of, nor does it modify, any agreement between AWS and its customers.

See the [`security/`](security/) directory for known security considerations.

---

## 10. Authors

- AWS Solutions Library
