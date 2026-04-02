# Well-Architected Pillars – Guidance Template

**Guidance Name:** Guidance for AI-Powered Restaurant Visibility on AWS
**Solution Domain name:** Restaurants (Retail & CPG)
**Guidance Owner/Team:** Manikandan Karimanal (@maniyes)

---

## Operational Excellence

**What service(s) are you using to enhance operational excellence?**

Amazon CloudWatch, AWS CloudTrail, AWS Lambda, Amazon API Gateway, Amazon DynamoDB, and Amazon Bedrock AgentCore

**How do these services help the user with operational excellence?**

Amazon CloudWatch collects metrics and logs from Lambda functions, API Gateway endpoints, and DynamoDB tables, enabling alarms on API error rates, DynamoDB throttling, and agent invocation failures. AWS CloudTrail records all API calls — including Bedrock AgentCore invocations and DynamoDB access — for audit and incident investigation. AWS Lambda integrates with CloudWatch Logs to capture every agent invocation and equipment query with execution details, while SQS dead letter queues preserve failed requests for analysis. Amazon API Gateway provides per-endpoint metrics (latency, error rates) across the six REST endpoints. DynamoDB Streams on the equipment-readings table enable event-driven anomaly detection, automatically triggering the Strands agent for ticket creation when temperature deviations occur.

**Why are you using these services to support operational excellence?**

CloudWatch alarms enable automated incident detection — for example, alerting when equipment-readings table throttling occurs during peak monitoring. CloudTrail's immutable log supports post-incident analysis for unauthorized access or unexpected agent behavior. Lambda's DLQ pattern ensures failed chat and API requests are captured for retry rather than silently dropped. API Gateway's endpoint-level metrics isolate whether degradation originates from the frontend API layer or the AgentCore chat endpoint. DynamoDB Streams close the loop between anomaly detection and response without manual intervention.

---

## Security

**What service(s) are you using to enhance security?**

Amazon Cognito, AWS IAM, AWS KMS, AWS WAF, Amazon CloudFront, and Amazon API Gateway

**How do these services help the user with security?**

Amazon Cognito enforces authentication with optional MFA (software tokens), a 12+ character password policy with complexity requirements, and admin-only user creation to prevent unauthorized accounts. AWS IAM implements least-privilege — the API Lambda role can only read from the five specific DynamoDB tables and invoke AgentCore, while the Knowledge Base role can only access the manuals S3 bucket and Titan embedding model. AWS KMS provides two customer-managed keys with automatic rotation: one encrypts all six DynamoDB tables at rest, another encrypts Lambda environment variables. AWS WAF protects CloudFront with managed rule sets (Common Rule Set, Known Bad Inputs) blocking SQL injection and XSS. Amazon CloudFront enforces HTTPS-only (TLS 1.2 minimum) with security headers (HSTS, X-Frame-Options: DENY, X-Content-Type-Options). API Gateway uses Cognito authorizers on all protected endpoints, ensuring only authenticated users access operational data.

**Why are you using these services to support security?**

Cognito's admin-only registration and MFA prevent unauthorized access to sensitive restaurant data. KMS CMK encryption ensures equipment readings, tickets, and chat history remain encrypted with customer-controlled keys. Separating the Lambda env var encryption key from the DynamoDB key follows key isolation — compromising one does not expose the other. WAF's managed rules provide OWASP Top 10 protection without custom rule authoring. CloudFront's Origin Access Control ensures the S3 bucket is only accessible through the CDN. IAM condition keys (aws:RequestedRegion, aws:SourceAccount) on Lambda roles prevent cross-region and cross-account escalation.

---

## Reliability

**What service(s) are you using to enhance reliability?**

Amazon CloudFront, Amazon DynamoDB, AWS Lambda, Amazon API Gateway, Amazon Bedrock AgentCore, and Amazon SQS

**How do these services help the user with reliability?**

Amazon CloudFront distributes the dashboard from edge locations with automatic failover and custom error responses redirecting 404s to the SPA's index.html. Amazon DynamoDB replicates all six tables across three Availability Zones, with Point-in-Time Recovery (PITR) enabled on every table for restoration to any second within 35 days. AWS Lambda uses reserved concurrency (10) to prevent noisy-neighbor effects, with SQS dead letter queues capturing failed invocations for both API and Chat Lambda functions. The Strands agent implements a 3-retry mechanism — transient errors (premature termination, timeouts) trigger retries while permanent errors fail fast. API Gateway throttling prevents cascading failures during peak meal periods across 10 locations.

**Why are you using these services to support reliability?**

DynamoDB PITR is critical because equipment-readings and tickets contain time-sensitive data — losing temperature anomaly history could mean missed food safety violations. The Lambda DLQ pattern preserves failed chat request payloads for investigation and replay. The agent's retry logic targets Bedrock's transient errors common during high-concurrency invocations, ensuring operators get responses during model load spikes. Reserved concurrency prevents chat request surges from starving the data API endpoints the dashboard depends on.

---

## Performance Efficiency

**What service(s) are you using to enhance performance efficiency?**

Amazon Bedrock (Nova Lite, Nova Sonic, Titan Embeddings), Amazon Bedrock AgentCore, Amazon OpenSearch Serverless, Amazon CloudFront, AWS Lambda, and Amazon DynamoDB

**How do these services help the user with performance efficiency?**

Amazon Bedrock Nova Lite provides low-latency inference for real-time operations queries — operators asking about equipment status need sub-second responses, not the higher latency of larger models. Nova Sonic enables bidirectional voice streaming through AgentCore's WebSocket endpoint at 16kHz, allowing hands-free interaction without the latency of separate speech-to-text-to-LLM-to-text-to-speech pipelines. Titan Embed Text v2 generates vector embeddings for six equipment manuals in the Knowledge Base, enabling semantic search that matches informal queries ("fryer acting weird") to formal procedures. OpenSearch Serverless provides auto-scaling vector search with no capacity planning. CloudFront caches static dashboard assets at edge locations for single-digit millisecond loads. Lambda memory is right-sized — 256MB for lightweight DynamoDB scans, 512MB for AgentCore payload processing. DynamoDB on-demand mode delivers consistent single-digit millisecond reads without capacity planning.

**Why are you using these services to support performance efficiency?**

Nova Lite was chosen over larger models because restaurant monitoring queries (temperature checks, inventory lookups, ticket creation) don't require deep reasoning — this keeps p50 latency under 2 seconds. Nova Sonic's bidirectional architecture eliminates multi-hop latency of separate ASR/LLM/TTS services for natural conversational flow. OpenSearch Serverless eliminates cluster capacity management, scaling automatically with query volume. The Knowledge Base returns top 5 results, balancing relevance with response time. DynamoDB on-demand suits the burst pattern of equipment readings arriving every few minutes per location.

---

## Cost Optimization

**What service(s) are you using to enhance cost optimization?**

Amazon Bedrock (Nova Lite), AWS Lambda, Amazon DynamoDB, Amazon S3, and Amazon CloudFront

**How do these services help the user with cost optimization?**

Amazon Bedrock Nova Lite charges only for tokens consumed per invocation — no idle infrastructure cost when operators aren't chatting. AWS Lambda bills in 1ms increments; between meal rushes, costs drop to zero. DynamoDB on-demand (PAY_PER_REQUEST) on all six tables aligns costs with actual usage across 10 locations with variable access patterns. The ChatHistory table uses TTL to auto-expire old conversations without consuming write throughput. S3 access logs have a 90-day lifecycle policy to prevent unbounded storage growth. CloudFront PriceClass_100 limits distribution to North America and Europe, avoiding premium pricing for edge locations the Georgia-based restaurants don't need. Lambda reserved concurrency (10) acts as a cost ceiling against runaway invocations.

**Why are you using these services to support cost optimization?**

Nova Lite was chosen over Nova Pro or third-party models because restaurant monitoring queries are straightforward tool-calling tasks that don't justify the 5-10x cost premium of larger models. DynamoDB on-demand eliminates over-provisioning risk for variable read/write patterns. TTL on chat history prevents linear storage cost growth. CloudFront PriceClass_100 saves ~20-30% compared to PriceClass_All since all restaurants are in Georgia. The fully serverless architecture targets ~$2,482/month for 10 locations with no EC2 instances, managed clusters, or minimum commitments.

---

## Sustainability

**What service(s) are you using to enhance sustainability?**

AWS Lambda, Amazon DynamoDB, Amazon Bedrock, Amazon CloudFront, and Amazon OpenSearch Serverless

**How do these services help the user with sustainability?**

AWS Lambda allocates compute only for request duration — no idle resources between requests, directly reducing energy consumption versus always-on servers. DynamoDB on-demand scales to match current load, consuming minimal resources overnight when restaurants are closed. Amazon Bedrock shares GPU resources across customers for model inference, achieving higher utilization than dedicated single-tenant AI infrastructure. CloudFront caches dashboard assets at edge locations, reducing repeated origin fetches and associated data transfer energy. OpenSearch Serverless scales vector search compute to near-zero when no manual searches are active.

**Why are you using these services to support sustainability?**

The fully serverless architecture (Lambda + DynamoDB on-demand + Bedrock + OpenSearch Serverless) scales to near-zero when idle — particularly impactful for restaurant operations with clear peak (meal times) and off-peak (overnight) patterns, reducing compute usage by 60-70% versus always-on alternatives. Nova Lite requires fewer GPU cycles per token than larger models, reducing per-inference energy consumption for a use case that doesn't need deep reasoning. CloudFront edge caching is effective because 10 locations repeatedly load the same dashboard assets, avoiding redundant origin transfers. DynamoDB TTL cleanup of expired chat records reduces storage footprint without scheduled batch jobs consuming additional compute.
