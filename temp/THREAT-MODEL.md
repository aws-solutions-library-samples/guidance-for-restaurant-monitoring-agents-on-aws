# Threat Model: Guidance for AI-Powered Restaurant Visibility on AWS

## 1. What are we building?

Guidance for AI-Powered Restaurant Visibility on AWS is an AWS Guidance that demonstrates how to build an AI-powered restaurant visibility system using Amazon Bedrock AgentCore. It monitors kitchen equipment temperatures, inventory levels, and staffing across 10 Georgia restaurant locations, with text and voice chat interfaces for operators.

### Technical Components

**Amazon CloudFront:** CDN for frontend hosting with TLS 1.2 enforcement, security response headers (HSTS, X-Frame-Options: DENY), and Origin Access Control for S3. Deployed in AWS, managed by AWS.

**AWS WAF:** Web application firewall on CloudFront with AWS Managed Rules (Common Rule Set, Known Bad Inputs Rule Set). Deployed in AWS, managed by AWS.

**Amazon S3:** Static website hosting for the monitoring dashboard (HTML/JS/CSS). Block public access enabled, versioning, AES-256 encryption, access logging to dedicated logs bucket with 90-day lifecycle.

**Amazon Cognito User Pool:** User authentication with optional MFA (software tokens), admin-only registration, 12+ character password policy with complexity requirements. OAuth2 Authorization Code flow.

**Amazon API Gateway:** REST API with Cognito authorizer on all protected endpoints. Six data endpoints (/restaurants, /equipment, /inventory, /staffing, /tickets, /voice-token) plus /chat. Request validation enabled.

**AWS Lambda (API Function):** Python 3.13 serverless compute for data queries and voice token generation. 256MB memory, 30s timeout, reserved concurrency of 10. KMS-encrypted environment variables. SQS dead letter queue for failed invocations.

**AWS Lambda (Chat Function):** Python 3.13 serverless compute for AgentCore invocation. 512MB memory, 300s timeout, reserved concurrency of 10. KMS-encrypted environment variables. SQS dead letter queue.

**Amazon Bedrock AgentCore Runtime:** Executes the Strands SDK agent with Amazon Nova Lite model (us.amazon.nova-lite-v1:0). Nine tools for restaurant operations (get_restaurants, get_equipment, get_inventory, get_staffing, get_tickets, create_ticket, analyze_temperature, get_troubleshooting, search_equipment_manual).

**Amazon Bedrock AgentCore Memory:** Short-term and long-term conversation memory (STM + LTM) for personalized operator interactions across sessions.

**Amazon Nova Sonic:** Bidirectional voice streaming via AgentCore WebSocket endpoint at 16kHz audio sample rate for hands-free kitchen interaction.

**Amazon Bedrock Knowledge Base:** RAG over 6 equipment manuals using Amazon Titan Embed Text v2 for vector embeddings. Connected to OpenSearch Serverless for vector search.

**Amazon OpenSearch Serverless:** Vector search backend for the Knowledge Base. VECTORSEARCH collection type with encryption and network security policies.

**Amazon DynamoDB (6 tables):** NoSQL storage for restaurants, equipment-readings, inventory-items, staffing-requirements, tickets, and chat-history. PAY_PER_REQUEST billing, KMS CMK encryption, Point-in-Time Recovery enabled on all tables. TTL on chat-history table.

**AWS KMS (2 Customer Managed Keys):** DynamoDB table encryption key and Lambda environment variable encryption key. Both with automatic annual rotation.

**Amazon SQS:** Dead letter queues for both Lambda functions. SSL-only access policies enforced.

**Amazon CloudWatch:** Logs and metrics for all Lambda functions, API Gateway, and DynamoDB tables.

**AWS CloudTrail:** API call auditing across all services.

**AWS CloudFormation:** Infrastructure as Code. Stacks: base infrastructure, knowledge base, chat endpoint.

### Architecture

The solution provides an AI-powered restaurant monitoring system with text and voice interfaces:

- **Monitoring Dashboard:** Real-time equipment temperatures, inventory levels, staffing schedules, and maintenance tickets across 10 locations
- **AI Chat Agent:** Strands-based agent that queries operational data, analyzes temperature anomalies, creates maintenance tickets, and searches equipment manuals
- **Voice Interface:** Bidirectional voice streaming via Nova Sonic for hands-free kitchen operation

Data flows:

- User → CloudFront (WAF) → S3 (static dashboard assets)
- User → CloudFront → API Gateway (Cognito authorizer) → API Lambda → DynamoDB (data queries)
- User → API Gateway (Cognito authorizer) → Chat Lambda → AgentCore Runtime → Strands Agent → DynamoDB (tool calls)
- Strands Agent → Bedrock Knowledge Base → OpenSearch Serverless (equipment manual RAG)
- User → AgentCore WebSocket → Nova Sonic (bidirectional voice)
- Equipment simulator → DynamoDB (temperature readings via load-data.sh)

### Deployment

Single deployment mode: CloudFormation templates deployed via `deploy-all.sh` shell script. AgentCore agent deployed separately via AgentCore CLI (`agentcore deploy`).

## 2. What can go wrong?

### Unauthorized API Access

**Risk:** Attackers could access the restaurant data API or chat endpoint without proper authentication.

**Impact:** Unauthorized access to equipment temperatures, inventory levels, staffing schedules, and ability to create maintenance tickets. Cost escalation from Bedrock model invocations.

**Likelihood:** Low — All data and chat endpoints are protected by Cognito User Pool authorizer. Admin-only user creation prevents self-registration.

### Stolen Cognito Token Replay

**Risk:** Stolen or leaked JWT tokens could be replayed to access API endpoints.

**Impact:** Unauthorized data access across all 10 restaurant locations for the token's validity period.

**Likelihood:** Medium — Tokens are transmitted over HTTPS but could be extracted from browser storage or intercepted via XSS if CORS is misconfigured.

### Prompt Injection

**Risk:** Malicious users could craft chat inputs to manipulate the Strands agent behavior, bypass tool routing, or extract system prompts.

**Impact:** Agent could create false maintenance tickets, return fabricated data, or disclose system configuration details.

**Likelihood:** Medium — The agent processes user input directly. System prompt defines boundaries but no Bedrock Guardrails are configured (no content filters, prompt attack detection, or PII filters).

### Sensitive Data Exposure in Agent Responses

**Risk:** Agent could inadvertently expose staffing PII (manager names), internal table names, or system configuration in chat responses.

**Impact:** Privacy violation, information disclosure enabling further attacks.

**Likelihood:** Low — Agent tools return only DynamoDB data. System prompt defines strict boundaries. Lambda error handler returns generic "Internal server error" messages.

### CORS Wildcard Allows Cross-Origin Data Access

**Risk:** `Access-Control-Allow-Origin: *` on all API responses allows any website to make authenticated requests to the API.

**Impact:** Cross-site data exfiltration if combined with token theft. Attacker-controlled website could read restaurant operational data.

**Likelihood:** Medium — CORS wildcard is present in both Lambda functions and API Gateway gateway responses.

### Demo Credentials in Deployment Script

**Risk:** The `deploy-all.sh` script contains hardcoded demo user credentials (email and password) created via `admin-set-user-password --permanent`.

**Impact:** Anyone with access to the repository can log into the deployed system.

**Likelihood:** Medium — Credentials are visible in the deployment script. Only mitigated by the fact that the Cognito User Pool ID is deployment-specific.

### Denial of Service

**Risk:** Excessive API requests could exhaust Lambda reserved concurrency (10), DynamoDB on-demand capacity, or Bedrock model quotas.

**Impact:** Dashboard unavailable for all 10 restaurant locations. Chat and voice interfaces unresponsive.

**Likelihood:** Medium — Lambda reserved concurrency acts as a ceiling but also limits legitimate traffic. No API Gateway throttling or WAF rate limiting is configured beyond the WAF managed rule sets.

### IAM Wildcard on AgentCore Permissions

**Risk:** Both Lambda roles use `Resource: *` for `bedrock-agentcore:InvokeAgentRuntime` permissions.

**Impact:** Lambda functions could invoke any AgentCore runtime in the account, not just the restaurant agent.

**Likelihood:** Low — Exploitation requires compromising the Lambda execution environment. Agent ARN is dynamic at deploy time, making resource scoping difficult.

### Knowledge Base Data Tampering

**Risk:** Tampered equipment manuals in the KB S3 bucket could provide incorrect troubleshooting guidance.

**Impact:** Operators following incorrect procedures could damage equipment or create safety hazards.

**Likelihood:** Low — S3 bucket has public access blocked, SSL-only policy, and versioning enabled. Access requires IAM credentials with explicit S3 permissions.

### Conversation Memory Data Retention

**Risk:** Conversation history stored in AgentCore Memory (STM + LTM) could contain sensitive operational details or PII.

**Impact:** Data retention beyond operator expectations, potential compliance issues.

**Likelihood:** Medium — Memory is enabled by default. No PII filtering is applied before storage. Chat-history DynamoDB table has TTL but AgentCore Memory retention is managed by the service.

### OpenSearch Serverless Wildcard Access

**Risk:** The Knowledge Base IAM role has `aoss:APIAccessAll` on all collections (`collection/*`).

**Impact:** If the role is compromised, it could access any OpenSearch Serverless collection in the account, not just the equipment manuals index.

**Likelihood:** Low — Role is only assumable by the Bedrock service principal. Exploitation requires compromising the Bedrock service chain.

## 3. What can we do about it?

### Access Control

- All API endpoints require Cognito JWT authorizer (data endpoints, chat, voice-token)
- Cognito User Pool: admin-only registration (`AllowAdminCreateUserOnly: true`), self-signup disabled
- Password policy: 12+ characters, uppercase, lowercase, numbers, symbols required
- MFA enforced via SOFTWARE_TOKEN_MFA (`MfaConfiguration: ON`)
- Cognito `AdvancedSecurityMode: ENFORCED` for adaptive authentication and compromised credential detection
- API Lambda IAM role scoped to five specific DynamoDB table ARNs with `aws:RequestedRegion` and `aws:SourceAccount` conditions
- Chat Lambda IAM role scoped to AgentCore invocation and SQS DLQ
- CloudFront Origin Access Control — S3 dashboard bucket only accessible through CDN
- S3 public access blocked on all buckets (dashboard, access logs, KB data)
- API Gateway request validation enabled

### Data Protection

- All 6 DynamoDB tables encrypted with KMS Customer Managed Key (automatic annual rotation)
- Lambda environment variables encrypted with separate KMS CMK (key isolation)
- CloudFront enforces HTTPS with TLS 1.2 minimum (`TLSv1.2_2021`)
- Security response headers: HSTS (`max-age=31536000`), X-Frame-Options: DENY, X-Content-Type-Options: nosniff, Referrer-Policy: strict-origin-when-cross-origin
- S3 bucket policies enforce SSL-only access (`aws:SecureTransport` deny condition)
- SQS dead letter queue policies enforce SSL-only access
- Chat-history DynamoDB table has TTL for automatic conversation expiry
- DynamoDB Point-in-Time Recovery enabled on all tables
- S3 versioning enabled on dashboard and KB data buckets
- Agent system prompt defines strict data boundaries — tools only return DynamoDB data
- Lambda error handlers return generic messages, no stack traces exposed

### Infrastructure Security

- AWS WAF on CloudFront with AWS Managed Rules: AWSManagedRulesCommonRuleSet (SQL injection, XSS) and AWSManagedRulesKnownBadInputsRuleSet
- Lambda reserved concurrency (10 per function) prevents noisy-neighbor exhaustion
- SQS dead letter queues capture failed Lambda invocations for analysis
- CloudFront access logging to dedicated S3 bucket with 90-day lifecycle
- S3 access logs bucket with lifecycle policy preventing unbounded growth
- CloudWatch Logs configured for all Lambda functions
- CloudTrail enabled for API call auditing
- All infrastructure deployed via CloudFormation templates

### Code Security

- ASH v3.2.3 scan completed (March 12, 2026) with 10 scanners:
  - Bandit (Python SAST): PASSED — 0 actionable findings (4 low: `random.uniform` usage in data loader)
  - cdk-nag (CloudFormation best practices): PASSED — 25 original findings resolved. Cognito MFA and AdvancedSecurityMode remediated. Remaining findings are false positives (SQS2: `SqsManagedSseEnabled` set, KMS5: `EnableKeyRotation` set, CFR4: `TLSv1.2_2021` set) or by design (APIG4: OPTIONS CORS preflight, IAM5: dynamic AgentCore ARNs)
  - Checkov (IaC security): PASSED — 8 original findings resolved. KB S3 logging and versioning remediated. Remaining findings are by design (Lambda VPC: serverless architecture, SQS encryption: `SqsManagedSseEnabled` set, IAM wildcards: dynamic AgentCore ARNs)
  - detect-secrets: PASSED — 1 finding confirmed as false positive (`GenerateSecret: false` in Cognito client config is not a secret)
  - Semgrep (code patterns): PASSED — 6 original findings resolved. SRI integrity attributes added to 3d-twin.html (2 findings), unsafe-formatstring fixed in api.js (1 finding). Remaining `innerHTML` usage in shared.js is by design with `escapeHtml()` sanitizer applied
  - npm-audit: PASSED — no dependency vulnerabilities
- Agent implements 3-retry mechanism with error classification for transient Bedrock failures
- Input validation on API Lambda (path length check, method validation)
- No hardcoded credentials in application code — table names and ARNs via CloudFormation environment variables

## 4. Did we do a good enough job (for now)?

### Review & Validation

- All infrastructure code scanned with ASH v3.2.3 (Bandit, cdk-nag, Checkov, detect-secrets, Semgrep, npm-audit)
- CloudFormation templates analyzed by cdk-nag with AwsSolutionsChecks enabled
- Python agent code analyzed by Bandit and Semgrep
- Architecture reviewed against STRIDE threat categories
- Well-Architected Framework assessment completed across all 6 pillars
- The solution is an AWS Guidance intended as a reference architecture and demo, not a production-ready deployment as-is

### Residual Risk

- **Bedrock Guardrails not configured:** No content filters, prompt attack detection, or PII filters are enabled. Customers MUST configure Bedrock Guardrails before production use
- **CORS wildcard:** `Access-Control-Allow-Origin: *` is set on all API responses. Customers MUST restrict to their CloudFront domain before production
- **API Gateway throttling not configured:** No rate/burst limits beyond WAF managed rules. Customers should add throttling settings for production
- **Demo credentials in deployment script:** `deploy-all.sh` contains hardcoded demo user email and password. Customers should remove and use Secrets Manager
- **IAM wildcards on AgentCore:** `Resource: *` for AgentCore invocation permissions. Customers should scope to specific agent ARN after deployment
- **OpenSearch Serverless wildcard:** `aoss:APIAccessAll` on `collection/*`. Customers should scope to specific collection ARN
- **CloudWatch Alarms not configured:** No automated alerting on Lambda errors, API 4xx/5xx, or DynamoDB throttling. Customers should add alarms for production
- **Conversation memory PII:** No PII filtering before storing conversation history in AgentCore Memory. Customers handling PII should implement filtering
- **ASH findings after remediation:** 40 original findings reduced by fixes applied. Remaining findings are false positives or by-design:
  - cdk-nag `AwsSolutions-SQS2`: False positive — `SqsManagedSseEnabled: true` is set but cdk-nag expects legacy `KmsMasterKeyId` property
  - cdk-nag `AwsSolutions-KMS5`: False positive — `EnableKeyRotation: true` is set on all 3 KMS keys
  - cdk-nag `AwsSolutions-CFR4`: False positive — `MinimumProtocolVersion: TLSv1.2_2021` is set but cdk-nag cannot verify with `CloudFrontDefaultCertificate: true`
  - cdk-nag `AwsSolutions-APIG4` on OPTIONS methods: By design — `AuthorizationType: NONE` is required for CORS preflight requests
  - cdk-nag `AwsSolutions-IAM5` on AgentCore: By design — Agent ARN is dynamic at deploy time, `Resource: *` is necessary
  - detect-secrets `SECRET-SECRET-KEYWORD`: False positive — flags `GenerateSecret: false` in Cognito client config, which is not a secret
  - Semgrep `insecure-document-method` in shared.js: By design — `innerHTML` usage applies `escapeHtml()` sanitizer on user content; static HTML templates are developer-controlled
  - Checkov `CKV_AWS_117` (Lambda in VPC): By design — serverless architecture does not require VPC placement for DynamoDB/API Gateway access

Given these constraints and the solution's purpose as an AWS Guidance (reference architecture), we have done enough to protect customers who decide to evaluate and adapt this solution. Customers must address the residual risks above before any production deployment.

## Notes

- This threat model was generated on 2026-03-15 and updated on 2026-03-15 after security remediation based on ASH v3.2.3 scan results and codebase analysis
- The threat model should be updated when the architecture changes or new features are added
- Customers should conduct their own security assessment and threat modeling before deploying to production
- Additional security measures (Bedrock Guardrails, enforced MFA, CORS restriction, API throttling, WAF rate limiting, VPC endpoints) are recommended for production use
