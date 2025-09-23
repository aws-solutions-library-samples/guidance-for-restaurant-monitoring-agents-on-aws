# Guidance for Restaurant Monitoring Agents on AWS

## Overview

This guidance provides a comprehensive implementation of Restaurant Monitoring Agents on AWS, demonstrating how to build an AI-powered monitoring system using AWS services. The solution uses intelligent agents to monitor restaurant equipment across 10 Georgia locations with real-time anomaly detection, automated ticket creation, and conversational AI interfaces for restaurant operations management.

This implementation serves as a reference architecture for deploying restaurant monitoring agents that can intelligently analyze equipment data, detect anomalies, and automate maintenance workflows using AWS native services.

## Table of Contents

- [Architecture](#architecture)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [API Reference](#api-reference)
- [Configuration](#configuration)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Architecture

The Restaurant Monitoring Agents solution uses a serverless architecture with AWS native services to implement intelligent monitoring workflows:

### Core Components
- **Restaurant Monitoring Agents**: AI-powered agents that analyze equipment data and detect anomalies
- **Equipment Data Simulator**: Generates realistic temperature data across 10 Georgia restaurant locations
- **DynamoDB Tables**: Stores restaurant data, equipment readings, maintenance tickets, and agent conversation history
- **API Gateway**: RESTful endpoints for dashboard data and agent interactions
- **Agent Workflow Engine**: Lambda functions orchestrating monitoring agents with conversation history and automated ticket management
- **Monitoring Dashboard**: HTML/CSS/JS frontend with 3D visualization and agent chat interface
- **Cognito Authentication**: Secure user management with self-registration and session handling

### Infrastructure Files
- `infrastructure/restaurant-monitoring-base-template.yaml` - Complete infrastructure (DynamoDB, API Gateway, Cognito, Dashboard)
- `infrastructure/strands-agent-chat-workflow.yaml` - Restaurant monitoring agent workflows with DynamoDB conversation history

## Features

### Restaurant Monitoring Agent Capabilities
- **Intelligent Conversation Management**: Persistent agent sessions stored in DynamoDB with 7-day TTL
- **Multi-Agent Workflow Orchestration**: Coordinated analysis of equipment status and maintenance priorities
- **Automated Issue Detection**: Restaurant monitoring agents integrate directly with equipment data for real-time anomaly detection
- **Location-Aware Intelligence**: Context-aware agent responses based on specific restaurant locations and equipment status
- **Resilient Agent Architecture**: Smart fallback responses when primary AI services are unavailable

### Equipment Monitoring Intelligence
- **Real-time Temperature Analysis**: Restaurant monitoring agents track 10 appliances per location across 10 restaurants
- **Intelligent Anomaly Detection**: Agents generate critical, warning, and operational status based on temperature deviations
- **Automated Maintenance Workflows**: Restaurant monitoring agents create and prioritize maintenance tickets for equipment issues
- **Predictive Maintenance**: Agents schedule preventive maintenance based on equipment patterns and historical data

### Interactive Dashboard Features
- **Agent-Powered Dashboard**: Live restaurant status with intelligent color coding driven by monitoring agents
- **3D Digital Twin Visualization**: Interactive Georgia map with restaurant locations and equipment status powered by agent analysis
- **Conversational Agent Interface**: Direct chat with restaurant monitoring agents for contextual responses and operational insights
- **Secure Authentication**: Cognito-based login with self-registration and automated configuration management

## Prerequisites

Before deploying this solution, ensure you have:

- AWS CLI configured with appropriate permissions
- AWS account with access to the following services:
  - DynamoDB
  - API Gateway
  - Lambda
  - S3
  - CloudFront
  - Cognito
  - Bedrock (for AI features)
- Python 3.9 or later
- Bash shell (for deployment scripts)

### Required AWS Permissions
The deployment requires permissions for:
- CloudFormation stack creation and management
- IAM role creation and management
- DynamoDB table creation and management
- API Gateway creation and configuration
- Lambda function deployment
- S3 bucket creation and management
- CloudFront distribution management
- Cognito User Pool and Identity Pool management

## Installation

### Quick Deployment

Use the automated deployment script for complete setup:

```bash
./utils/deploy.sh
```

This script will:
1. Deploy Restaurant Monitoring Agent Base Infrastructure (DynamoDB tables, API Gateway, Cognito, Dashboard)
2. Deploy Restaurant Monitoring Agent Workflow Lambda functions
3. Automatically update Cognito configuration in auth.js
4. Handle S3 bucket conflicts by cleaning up existing buckets

### Manual Deployment Steps

If you prefer manual deployment:

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd restaurant-monitoring-agents-aws
   ```

2. **Deploy restaurant monitoring agent base infrastructure**
   ```bash
   aws cloudformation deploy \
     --template-file infrastructure/restaurant-monitoring-base-template.yaml \
     --stack-name restaurant-monitoring-agents-base-infrastructure-production \
     --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM
   ```

3. **Deploy restaurant monitoring agent workflows**
   ```bash
   aws cloudformation deploy \
     --template-file infrastructure/strands-agent-chat-workflow.yaml \
     --stack-name restaurant-monitoring-agents-workflow-production \
     --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM
   ```

4. **Update website configuration**
   ```bash
   ./utils/refresh-website.sh
   ```

### Utility Scripts

The `utils/` folder contains essential deployment and maintenance scripts:

- `cleanup.sh` - Complete infrastructure cleanup and resource removal
- `deploy.sh` - Automated deployment of the entire stack
- `refresh-website.sh` - Sync static website content to S3 and invalidate CloudFront cache
- `update-cognito-config.sh` - Update Cognito configuration in static website files
- `simple_simulator.py` - Equipment data simulator for testing
- `test_strands_api.py` - API testing utility

## Cleanup

### Complete Infrastructure Cleanup

To completely remove all deployed resources and avoid ongoing AWS charges, use the automated cleanup script:

```bash
./utils/cleanup.sh
```

**⚠️ WARNING: This will permanently delete ALL resources and data!**

The cleanup script will:
1. **Require confirmation** - Type "DELETE" to proceed
2. **Empty S3 buckets** - Remove all objects including versions and delete markers
3. **Delete CloudFormation stacks** - Remove all infrastructure in proper order
4. **Clean up orphaned resources** - Identify any remaining resources for manual cleanup
5. **Provide cleanup summary** - Show what was deleted and any remaining items

### What Gets Deleted

The cleanup process removes:
- ✅ **CloudFormation Stacks**: Both base infrastructure and Strands workflow stacks
- ✅ **S3 Buckets**: Dashboard and access logs buckets (emptied first, then deleted)
- ✅ **DynamoDB Tables**: All restaurant, equipment, tickets, and chat history data
- ✅ **Lambda Functions**: All monitoring and API functions
- ✅ **API Gateway**: REST API and all endpoints
- ✅ **CloudFront Distribution**: CDN and cached content
- ✅ **IAM Roles & Policies**: All created roles and policies
- ✅ **Cognito Resources**: User pools, identity pools, and user data

### Cleanup Process

The script follows this safe deletion order:

1. **Discovery Phase**: Identifies all S3 buckets and resources
2. **S3 Preparation**: Empties buckets (required before stack deletion)
3. **Dependent Stack Deletion**: Removes Strands workflow stack first
4. **Base Stack Deletion**: Removes main infrastructure stack
5. **Final Cleanup**: Force-deletes any remaining S3 buckets
6. **Orphan Detection**: Reports any resources that need manual cleanup

### Manual Cleanup (if needed)

If the automated cleanup encounters issues, you may need to manually delete:

```bash
# Delete specific Lambda functions
aws lambda delete-function --function-name function-name --region us-east-1

# Delete specific DynamoDB tables
aws dynamodb delete-table --table-name table-name --region us-east-1

# Delete specific IAM roles
aws iam delete-role --role-name role-name

# Force delete S3 buckets
aws s3 rb s3://bucket-name --force --region us-east-1
```

### Verification

After cleanup, verify all resources are deleted:

```bash
# Check CloudFormation stacks
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE --region us-east-1

# Check S3 buckets
aws s3 ls | grep restaurant-kitchen-assistant

# Check Lambda functions
aws lambda list-functions --region us-east-1 | grep restaurant-kitchen-assistant

# Check DynamoDB tables
aws dynamodb list-tables --region us-east-1 | grep restaurant-kitchen-assistant
```

### Cost Considerations

Running the cleanup script helps avoid ongoing charges for:
- DynamoDB read/write capacity and storage
- S3 storage and requests
- CloudFront distribution and data transfer
- Lambda function invocations
- API Gateway requests
- Cognito active users

**Recommendation**: Always run cleanup when done testing or if you need to redeploy from scratch.

## Usage

### Starting the Restaurant Monitoring Agents

The restaurant monitoring agents are automatically deployed and begin monitoring equipment once the infrastructure is deployed. The system includes built-in equipment simulation for demonstration purposes.

### Accessing the Restaurant Monitoring Agent Dashboard

1. Navigate to the CloudFront URL provided in the deployment output
2. Sign up for a new account or sign in with existing credentials
3. View real-time restaurant status powered by monitoring agents
4. Interact directly with restaurant monitoring agents through the chat interface for intelligent assistance

### API Endpoints

The Restaurant Monitoring Agents system provides the following REST API endpoints:

- `GET /restaurants` - List all restaurant locations with agent-analyzed status
- `GET /equipment` - Get equipment readings processed by monitoring agents
- `GET /tickets` - Get maintenance tickets created by restaurant monitoring agents
- `POST /strands-agent-chat` - Direct interface to restaurant monitoring agents

### Geographic Coverage

The Restaurant Monitoring Agents system covers 10 Georgia restaurant locations:
- Atlanta (AFC-001), Savannah (AFC-002), Augusta (AFC-003)
- Macon (AFC-004), Athens (AFC-005), Columbus (AFC-006)
- Brunswick (AFC-007), Albany (AFC-008), Valdosta (AFC-009)
- Cumming (AFC-010)

Each location is monitored by dedicated restaurant monitoring agents that analyze equipment performance and operational status.


## API Reference

### Restaurant Status API

```http
GET /restaurants
```

Returns a list of all restaurant locations with current status.

**Response:**
```json
[
  {
    "id": "AFC-001",
    "name": "AnyCompany Atlanta",
    "location": "Atlanta, GA",
    "status": "operational",
    "manager": "John Smith"
  }
]
```

### Equipment Monitoring API

```http
GET /equipment
```

Returns current equipment readings across all locations.

**Response:**
```json
[
  {
    "restaurant_id": "AFC-001",
    "equipment_id": "freezer-001",
    "temperature": 32.5,
    "target_temperature": 32.0,
    "status": "operational",
    "timestamp": "2024-01-15T10:30:00Z"
  }
]
```

### Maintenance Tickets API

```http
GET /tickets
```

Returns all maintenance tickets with priority and status information.

### Restaurant Monitoring Agent Chat API

```http
POST /strands-agent-chat
```

**Request Body:**
```json
{
  "message": "What's the status of Atlanta kitchen?",
  "session_id": "optional-session-id"
}
```

**Response:**
```json
{
  "response": "The Atlanta restaurant monitoring agent reports all equipment is operational with normal temperature readings across all 10 appliances.",
  "session_id": "session_12345",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

## Configuration

### Environment Variables

The Restaurant Monitoring Agents system uses the following environment variables:

- `RESTAURANTS_TABLE` - DynamoDB table name for restaurant data processed by monitoring agents
- `EQUIPMENT_TABLE` - DynamoDB table name for equipment readings analyzed by agents
- `TICKETS_TABLE` - DynamoDB table name for maintenance tickets created by restaurant monitoring agents
- `CHAT_HISTORY_TABLE` - DynamoDB table name for restaurant monitoring agent conversation history
- `AWS_REGION` - AWS region for deployment (default: us-east-1)

### Cognito Configuration

Authentication is handled through AWS Cognito. The configuration is automatically updated during deployment in `static-website/auth.js`:

```javascript
const cognitoConfig = {
    region: 'us-east-1',
    userPoolId: 'us-east-1_XXXXXXXXX',
    userPoolWebClientId: 'XXXXXXXXXXXXXXXXXXXXXXXXXX',
    identityPoolId: 'us-east-1:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
};
```

### Restaurant Monitoring Agent Status Logic

Restaurant status is intelligently determined by restaurant monitoring agents based on ticket priorities:
- **Critical**: High/Critical priority tickets detected by monitoring agents (Red indicator)
- **Warning**: Medium/Warning priority tickets identified by monitoring agents (Yellow indicator)
- **Operational**: No active tickets - all systems normal per monitoring agents (Green indicator)

## Testing

### Running Tests

The project includes comprehensive testing capabilities for validating the restaurant monitoring agent functionality and infrastructure deployment.

### Test Coverage

- ✅ Restaurant monitoring agent infrastructure deployment and configuration
- ✅ Data population and equipment simulation for agent analysis
- ✅ Restaurant monitoring agent workflow integration
- ✅ API endpoint functionality with agent responses
- ✅ Restaurant monitoring agent chat interface responses
- ✅ Automated ticket creation by monitoring agents

## Troubleshooting

### Common Issues

**Issue: Deployment fails with S3 bucket conflicts**
```bash
# Solution: Clean up existing buckets
aws s3 rm s3://your-bucket-name --recursive
aws s3api delete-bucket --bucket your-bucket-name
```

**Issue: Restaurant monitoring agents not creating tickets**
```bash
# Solution: Check data format and restaurant monitoring agent Lambda logs
aws logs tail /aws/lambda/restaurant-monitoring-agents-workflow-production
```

**Issue: Dashboard not loading**
```bash
# Solution: Verify CloudFront distribution and S3 sync
./utils/refresh-website.sh
```

### Monitoring and Debugging

- **CloudWatch Logs**: Monitor Lambda function execution
- **DynamoDB Metrics**: Track read/write capacity and throttling
- **API Gateway Metrics**: Monitor request rates and error rates
- **CloudFront Metrics**: Track cache hit rates and origin requests

### Support

For technical support and questions:
- Review the [Project Requirements Matrix](docs/PROJECT_REQUIREMENTS_MATRIX.md)
- Monitor CloudWatch logs for detailed error information
- Check AWS CloudFormation stack events for deployment issues

## Security

This implementation follows AWS security best practices with comprehensive security controls:

### Infrastructure Security
- **Encryption**: All DynamoDB tables and S3 buckets use server-side encryption (AES256)
- **Access Logging**: S3 access logs and CloudFront logs enabled for audit trails
- **IAM Security**: Least privilege roles with account/region conditions
- **WAF Protection**: CloudFront protected by AWS WAF with managed rule sets
- **Security Headers**: CSP, X-Frame-Options, and other security headers implemented

### Application Security
- **Authentication**: Cognito provides secure user management with strong password policies
- **Authorization**: IAM roles with scoped permissions to specific resources
- **Network Security**: CloudFront with HTTPS enforcement and security headers
- **Input Validation**: Secure coding practices with proper input sanitization
- **Secrets Management**: No hardcoded secrets, uses AWS services for credential management

### Code Security
- **Secure Random**: Uses cryptographically secure random number generation
- **Safe Subprocess**: Prevents shell injection with safe command execution
- **Web Security**: Content Security Policy and XSS protection headers
- **Data Protection**: S3 bucket policies and public access blocks

### Security Scanning
- Automated security scanning with AWS Automated Security Helper (ASH)
- Security baseline configuration to manage false positives
- Regular security validation as part of deployment process

## Contributing

We welcome contributions to improve the Restaurant Monitoring Agents on AWS guidance. Please follow these guidelines:

1. **Fork the repository** and create a feature branch
2. **Follow coding standards** and include appropriate tests
3. **Update documentation** for any new features or changes
4. **Submit a pull request** with a clear description of changes

### Development Setup

1. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

2. Set up AWS credentials and configure the CLI

3. Validate changes by deploying to a test environment and verifying functionality

## Technologies

- **AWS Services**: DynamoDB, API Gateway, Lambda, Cognito, S3, CloudFront, Bedrock
- **Frontend**: HTML5, CSS3, JavaScript, Three.js (3D visualization)
- **Backend**: Python 3.9, Boto3, Claude AI via Bedrock for restaurant monitoring agents
- **Infrastructure**: CloudFormation, Bash deployment scripts
- **Agent Orchestration**: Restaurant monitoring agent workflow orchestration with conversation context

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Project Status

**Status**: Production Ready (93% complete)

The Restaurant Monitoring Agents on AWS guidance is ready for production deployment with comprehensive agent-based monitoring, automated ticket creation by intelligent agents, and real-time dashboard functionality. The only remaining feature is the complete implementation of the conversational restaurant monitoring agent interface, which can be added post-deployment without affecting core agent operations.

### Roadmap

- [ ] Complete conversational restaurant monitoring agent interface implementation
- [ ] Enhanced predictive analytics capabilities for restaurant monitoring agents
- [ ] Mobile application integration with restaurant monitoring agents
- [ ] Integration with external maintenance management systems via restaurant monitoring agents
- [ ] Advanced reporting and analytics dashboard powered by restaurant monitoring agents
