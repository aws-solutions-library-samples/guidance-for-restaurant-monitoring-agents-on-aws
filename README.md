# Guidance for Restaurant Monitoring Agents on AWS

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Deployment Steps](#deployment-steps)
- [Post-deployment Steps](#post-deployment-steps)
- [Usage](#usage)
- [Next Steps](#next-steps)
- [Cleanup](#cleanup)
- [Notices](#notices)
- [Authors](#authors)
- [Security](#security)
- [Cost](#cost)
- [License](#license)

## Overview

This guidance demonstrates how to build an AI-powered restaurant monitoring system using AWS services. The solution uses intelligent agents to monitor restaurant equipment across 10 Georgia locations with real-time anomaly detection, automated ticket creation, and conversational AI interfaces for restaurant operations management.

### Key Features

- **Intelligent Monitoring Agents**: AI-powered agents that analyze equipment data and detect anomalies
- **Real-time Equipment Monitoring**: Track temperature data across 10 appliances per location
- **Automated Ticket Creation**: Agents automatically create maintenance tickets for equipment issues
- **Interactive Dashboard**: 3D visualization with live data and agent chat interface
- **Secure Authentication**: Cognito-based user management with self-registration

### Target Audience

This guidance is designed for:
- Solution architects looking to implement AI-powered monitoring systems
- Developers building restaurant or facility management applications
- Operations teams seeking automated monitoring and alerting solutions

## Architecture

![Architecture Diagram](assets/architecture-diagram.png)

### Core Components

- **Restaurant Monitoring Agents**: AI-powered agents using Amazon Bedrock for intelligent analysis
- **Equipment Data Simulator**: Generates realistic temperature data across 10 Georgia restaurant locations
- **DynamoDB Tables**: Stores restaurant data, equipment readings, maintenance tickets, and agent conversation history
- **API Gateway**: RESTful endpoints for dashboard data and agent interactions
- **Agent Workflow Engine**: Lambda functions orchestrating monitoring agents with conversation history
- **Monitoring Dashboard**: HTML/CSS/JS frontend with 3D visualization and agent chat interface
- **Amazon Cognito**: Secure user management with self-registration and session handling

### AWS Services Used

- Amazon DynamoDB
- Amazon API Gateway
- AWS Lambda
- Amazon S3
- Amazon CloudFront
- Amazon Cognito
- Amazon Bedrock
- AWS CloudFormation

## Prerequisites

Before deploying this solution, ensure you have:

- AWS CLI configured with appropriate permissions
- AWS account with access to the required services
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

## Deployment Steps

### Quick Deployment

Use the automated deployment script for complete setup:

```bash
./deployment/deploy.sh
```

This script will:
1. Deploy Restaurant Monitoring Agent Base Infrastructure
2. Deploy Restaurant Monitoring Agent Workflow Lambda functions
3. Deploy website content and load initial data using `deploy-loaddata.sh`

### Clean Deployment System

The system now uses a clean deployment approach with placeholder-based configuration:

```bash
# For clean deployment (recommended):
./deployment/reset-source-to-placeholders.sh
./deployment/deploy.sh

# Or direct deployment:
./deployment/deploy.sh
```

The deployment system automatically:
- Replaces all placeholders with actual AWS resource IDs
- Ensures no hardcoded values remain in source files
- Provides consistent, repeatable deployments

### Manual Deployment Steps

If you prefer manual deployment or need to customize the deployment:

1. **Deploy base infrastructure**
   ```bash
   aws cloudformation deploy \
     --template-file deployment/restaurant-monitoring-base-template.yaml \
     --stack-name restaurant-monitoring-agents-base-infrastructure-production \
     --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
     --region us-east-1
   ```

2. **Deploy agent workflows**
   ```bash
   aws cloudformation deploy \
     --template-file deployment/strands-agent-chat-workflow.yaml \
     --stack-name restaurant-monitoring-agents-workflow-production \
     --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
     --region us-east-1
   ```

3. **Deploy website content and load initial data**
   ```bash
   ./deployment/deploy-loaddata.sh
   ```

### Deployment Scripts

The deployment system includes several automated scripts:

- **`deploy.sh`** - Complete system deployment
- **`deploy-loaddata.sh`** - Website deployment and data population  
- **`reset-source-to-placeholders.sh`** - Reset source files to clean state
- **`cleanup.sh`** - Complete system cleanup and resource removal
- **`simple_simulator.py`** - Equipment data simulation and Strands agent triggering

### File Structure

```
├── deployment/
│   ├── deploy.sh                           # Main deployment script
│   ├── deploy-loaddata.sh                  # Website and data deployment
│   ├── reset-source-to-placeholders.sh    # Source file reset utility
│   ├── cleanup.sh                          # Complete cleanup script
│   ├── simple_simulator.py                # Data simulator
│   ├── restaurant-monitoring-base-template.yaml  # Infrastructure template
│   └── strands-agent-chat-workflow.yaml   # Agent workflow template
├── source/                                 # Website source files (with placeholders)
│   ├── index.html                         # Main dashboard
│   ├── 3d-twin.html                      # 3D visualization
│   ├── tickets.html                      # Tickets management
│   ├── login.html                        # Authentication
│   └── auth.js                           # Authentication logic
└── assets/                                # Documentation assets
```

### Deployment Validation

After deployment, verify the following resources were created:
- CloudFormation stacks in `CREATE_COMPLETE` status
- DynamoDB tables with proper encryption and data
- API Gateway with correct endpoints returning data
- S3 bucket with website content and proper configuration
- CloudFront distribution with valid domain and cache invalidation
- Cognito User Pool and Identity Pool with proper configuration
- Lambda functions for Strands agent workflows

## Post-deployment Steps

After successful deployment, complete these steps to initialize the system:

1. **Access the dashboard** using the CloudFront URL from deployment output

2. **Verify data population** - The deployment automatically:
   - Populates 10 Georgia restaurant locations
   - Creates 70 equipment readings (7 per location)
   - Generates equipment anomalies and tickets via Strands agents
   - Configures all API endpoints with correct URLs

3. **Create user account** through the self-registration interface

4. **Test the system**:
   - Verify dashboard loads restaurant data
   - Check that equipment anomalies show critical/warning status
   - Test the AI chat interface with Strands agents
   - Confirm tickets are automatically created for equipment issues

### Verification Commands

```bash
# Test API endpoints
curl "https://YOUR-API-URL/restaurants"
curl "https://YOUR-API-URL/tickets"
curl "https://YOUR-API-URL/equipment"

# Check DynamoDB data
aws dynamodb scan --table-name restaurant-kitchen-assistant-restaurants-production --select COUNT
aws dynamodb scan --table-name restaurant-kitchen-assistant-tickets-production --select COUNT
```

## Usage

### Accessing the Dashboard

1. Navigate to the CloudFront URL provided in the deployment output
2. Sign up for a new account or sign in with existing credentials
3. View real-time restaurant status powered by monitoring agents
4. Interact with restaurant monitoring agents through the chat interface

### API Endpoints

The system provides the following REST API endpoints:

- `GET /restaurants` - List all restaurant locations with agent-analyzed status
- `GET /equipment` - Get equipment readings processed by monitoring agents  
- `GET /tickets` - Get maintenance tickets created by restaurant monitoring agents
- `POST /strands-agent-chat` - Direct interface to restaurant monitoring agents

### Dashboard Features

- **Real-time Status**: View all 10 Georgia locations with color-coded status
- **3D Digital Twin**: Interactive 3D visualization of restaurant equipment
- **Equipment Monitoring**: Live temperature data from 7 appliances per location
- **Automated Ticketing**: Strands agents automatically create tickets for anomalies
- **AI Chat Interface**: Conversational AI for restaurant operations queries
- **Secure Authentication**: Cognito-based user registration and management

### Geographic Coverage

The system covers 10 Georgia restaurant locations with full equipment monitoring:

| Location | ID | Equipment Count | Monitoring |
|----------|----|-----------------|-----------| 
| Atlanta Kitchen | AFC-001 | 7 appliances | ✅ Active |
| Savannah Kitchen | AFC-002 | 7 appliances | ✅ Active |
| Augusta Kitchen | AFC-003 | 7 appliances | ✅ Active |
| Macon Kitchen | AFC-004 | 7 appliances | ✅ Active |
| Athens Kitchen | AFC-005 | 7 appliances | ✅ Active |
| Columbus Kitchen | AFC-006 | 7 appliances | ✅ Active |
| Brunswick Kitchen | AFC-007 | 7 appliances | ✅ Active |
| Albany Kitchen | AFC-008 | 7 appliances | ✅ Active |
| Valdosta Kitchen | AFC-009 | 7 appliances | ✅ Active |
| Cumming Kitchen | AFC-010 | 7 appliances | ✅ Active |

**Equipment Types Monitored:**
- Walk-in Cooler (38°F target)
- Beverage Cooler (35°F target)  
- Freezer Unit (-5°F target)
- Burger Grill (450°F target)
- French Fry Station (375°F target)
- Chicken Fryer (375°F target)
- Ice Cream Freezer (-10°F target)

## Next Steps

After deploying this guidance, consider these enhancements:

### Extend Monitoring Capabilities
- Add more equipment types (HVAC, lighting, security systems)
- Integrate with IoT sensors for real-time data collection
- Implement predictive maintenance using historical data
- Add mobile app support for field technicians

### Enhance AI Capabilities
- Train custom models on restaurant-specific data
- Implement advanced anomaly detection algorithms
- Add natural language processing for maintenance reports
- Integrate with external maintenance management systems

### Scale the Solution
- Deploy across multiple regions
- Add support for different restaurant chains
- Implement multi-tenant architecture
- Add advanced analytics and reporting dashboards

### Current System Status

✅ **Fully Deployed and Operational**
- 10 Georgia restaurant locations monitored
- 70 equipment sensors providing real-time data
- Strands agents actively creating maintenance tickets
- Interactive dashboard with 3D visualization
- AI chat interface for operations support
- Secure user authentication and session management

## Cleanup

To remove all deployed resources and avoid ongoing charges:

```bash
./deployment/cleanup.sh
```

**⚠️ WARNING: This will permanently delete ALL resources and data!**

The cleanup script will:
1. Empty S3 buckets
2. Delete CloudFormation stacks
3. Clean up orphaned resources
4. Provide cleanup summary

## Notices

This guidance is provided as sample code and is intended for educational and demonstration purposes. Before using in production:

- Review and customize security settings for your environment
- Implement proper monitoring and alerting
- Conduct thorough testing with your data and use cases
- Follow your organization's deployment and security policies

### Third-party Dependencies

This solution uses the following third-party libraries:
- Python standard libraries (included with Python)
- AWS SDK for Python (Boto3)
- HTML/CSS/JavaScript for frontend

### Data Privacy

This guidance processes simulated restaurant equipment data. When implementing with real data:
- Ensure compliance with applicable data protection regulations
- Implement appropriate data retention policies
- Consider data residency requirements
- Review and configure encryption settings

## Authors

This guidance was created by the AWS Solutions Library team.

For questions or feedback, please open an issue in this repository.



## Security

This implementation follows AWS security best practices:

### Infrastructure Security
- **Encryption**: All DynamoDB tables and S3 buckets use server-side encryption
- **Access Logging**: S3 access logs and CloudFront logs enabled
- **IAM Security**: Least privilege roles with account/region conditions
- **WAF Protection**: CloudFront protected by AWS WAF with managed rule sets

### Application Security
- **Authentication**: Cognito provides secure user management
- **Authorization**: IAM roles with scoped permissions
- **Network Security**: CloudFront with HTTPS enforcement
- **Input Validation**: Secure coding practices with proper input sanitization

## Cost

This guidance uses the following billable AWS services with cost for two months in the US East (N. Virginia) Region. We recommend creating a [Budget](https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html) through [AWS Cost Management](https://aws.amazon.com/aws-cost-management/) to help manage costs. Prices are subject to change. For full details, refer to the pricing webpage for each AWS service used in this guidance.

### Cost table

The following table provides a sample cost breakdown for deploying this guidance with the default parameters in the US East (N. Virginia) Region for two months.

| AWS service  | Dimensions | Cost [USD] |
| ----------- | ------------ | ------------ |
| Amazon DynamoDB | 4 tables, on-demand pricing, 20,000 read/write requests per month | $5.00 |
| Amazon API Gateway | 60,000 REST API requests per month | $0.21 |
| AWS Lambda | 2,000 invocations per month, 512 MB memory, 5-second average duration | $0.83 |
| Amazon S3 | 5 GB storage, 10,000 PUT requests, 50,000 GET requests per month | $0.46 |
| Amazon CloudFront | 20 GB data transfer out per month | $1.70 |
| Amazon Cognito | 200 monthly active users | $1.10 |
| Amazon Bedrock | 100,000 input tokens, 50,000 output tokens per month (Claude 3 Haiku) | $1.50 |
| **Total two-month cost** | | **$10.80** |
| **Monthly cost** | | **$5.40** |

The costs above are estimates based on the following assumptions:
- 10 restaurant locations with 7 equipment readings per location daily
- 100 monthly active users accessing the dashboard
- 1,000 API calls per day for monitoring and chat interactions
- Moderate usage of AI agents for anomaly detection and chat responses

### Cost optimization

You can optimize costs by implementing the following:

- **Use DynamoDB provisioned capacity** for predictable workloads instead of on-demand pricing
- **Enable CloudFront caching** to reduce API Gateway and Lambda invocations
- **Optimize Lambda functions** by right-sizing memory allocation and reducing execution time
- **Implement S3 lifecycle policies** to automatically transition logs to cheaper storage classes
- **Cache AI responses** to reduce Amazon Bedrock token consumption for common queries
- **Use AWS Free Tier** benefits where applicable (Lambda, DynamoDB, S3, CloudFront)

For cost estimation based on your specific usage patterns, use the [AWS Pricing Calculator](https://calculator.aws).

## License

This library is licensed under the MIT-0 License. See the [LICENSE](LICENSE) file for details.

## Contributing

See [CONTRIBUTING](CONTRIBUTING.md) for more information.

## Additional Resources

- [AWS Solutions Library](https://aws.amazon.com/solutions/)
- [Amazon Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

---

© 2024 Amazon Web Services, Inc. or its affiliates. All Rights Reserved.
