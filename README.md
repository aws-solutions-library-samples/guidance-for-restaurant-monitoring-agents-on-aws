# Guidance for Restaurant Monitoring Agents on AWS

## Table of Contents

1. [Overview](#overview)
   - [Cost](#cost)
2. [Prerequisites](#prerequisites)
   - [Operating System](#operating-system)
3. [Deployment Steps](#deployment-steps)
4. [Deployment Validation](#deployment-validation)
5. [Running the Guidance](#running-the-guidance)
6. [Next Steps](#next-steps)
7. [Cleanup](#cleanup)
8. [Notices](#notices)
9. [Authors](#authors)

## Overview

⚠️ **SECURITY WARNING**: This guidance has been assessed and contains significant security vulnerabilities. **DO NOT deploy to production** without addressing the critical security issues identified in the security assessment reports. See `security-remediation-summary.md` for details.

This guidance demonstrates how to build an AI-powered restaurant monitoring system using AWS services. The solution uses intelligent agents to monitor restaurant equipment across 10 Georgia locations with real-time anomaly detection, automated ticket creation, and conversational AI interfaces for restaurant operations management.

![Architecture Diagram](assets/architecture-diagram.png)

The system provides:
- **Intelligent Monitoring Agents**: AI-powered agents that analyze equipment data and detect anomalies
- **Real-time Equipment Monitoring**: Track temperature data across 10 appliances per location
- **Automated Ticket Creation**: Agents automatically create maintenance tickets for equipment issues
- **Interactive Dashboard**: 3D visualization with live data and agent chat interface
- **Secure Authentication**: Cognito-based user management with self-registration

**Security Status**: 🔴 **CRITICAL ISSUES IDENTIFIED** - 32 critical security vulnerabilities across Lambda, IAM, S3, and DynamoDB services require immediate remediation before production use.

### Cost

You are responsible for the cost of the AWS services used while running this Guidance. As of October 2025, the cost for running this Guidance with the default settings in the US East (Ohio) Region is approximately $2,482.41 per month for processing 10 restaurant locations with 70 equipment sensors and AI-powered monitoring agents.

We recommend creating a [Budget](https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html) through [AWS Cost Explorer](https://aws.amazon.com/aws-cost-management/aws-cost-explorer/) to help manage costs. Prices are subject to change. For full details, refer to the pricing webpage for each AWS service used in this Guidance.

The following table provides a sample cost breakdown for deploying this Guidance with the default parameters in the US East (Ohio) Region for one month.

| AWS service  | Dimensions | Cost [USD] |
| ----------- | ------------ | ------------ |
| Amazon DynamoDB (on-demand) | Standard table class, 1 KB average item size | $0.12 |
| Amazon DynamoDB (provisioned) | Standard table class, 14 KB average item size, 1 GB storage, reserved capacity | $18.86 |
| AWS Lambda | 864,000 requests per month, x86 architecture, 512 MB ephemeral storage | $29.33 |
| Amazon S3 | 5 GB storage, 10,000 PUT requests, 50,000 GET requests per month | $0.18 |
| Amazon CloudFront | 20 GB data transfer out per month | $1.70 |
| Amazon Cognito | 200 monthly active users with advanced security features | $10.00 |
| Amazon Bedrock (Workload 1) | 60 requests/min, 8 hours/day, 1000 input tokens, 500 output tokens per request | $2,419.20 |
| Amazon API Gateway | 864,000 REST API requests per month, 34 KB average request size | $3.02 |
| **Total monthly cost** | | **$2,482.41** |

## Prerequisites

### Operating System

These deployment instructions are optimized to best work on **Amazon Linux 2 AMI**. Deployment in another OS may require additional steps.

Before deploying this solution, ensure you have:

- AWS CLI configured with appropriate permissions
- AWS account with access to the required services
- Python 3.9 or later
- Bash shell (for deployment scripts)

### AWS account requirements

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

1. Clone the repository using command:
   ```bash
   git clone https://github.com/aws-solutions-library-samples/guidance-for-restaurant-monitoring-agents-on-aws.git
   ```

2. Change to the repository folder:
   ```bash
   cd guidance-for-restaurant-monitoring-agents-on-aws
   ```

3. Run the automated deployment script for complete setup:
   ```bash
   ./deployment/deploy.sh
   ```

This script will:
- Deploy Restaurant Monitoring Agent Base Infrastructure
- Deploy Restaurant Monitoring Agent Workflow Lambda functions  
- Deploy website content and load initial data

4. For clean deployment (recommended), run:
   ```bash
   ./deployment/reset-source-to-placeholders.sh
   ./deployment/deploy.sh
   ```

5. Capture the CloudFront URL from the deployment output:
   ```bash
   aws cloudformation describe-stacks --stack-name restaurant-monitoring-agents-base-infrastructure-production --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontURL`].OutputValue' --output text
   ```

## Deployment Validation

After deployment, verify the following resources were created:

- Open CloudFormation console and verify the status of the templates with names starting with `restaurant-monitoring-agents`
- If deployment is successful, you should see active DynamoDB tables with names starting with `restaurant-kitchen-assistant` in the DynamoDB console
- Run the following CLI command to validate the deployment:
  ```bash
  aws cloudformation describe-stacks --stack-name restaurant-monitoring-agents-base-infrastructure-production
  ```
- Verify API Gateway endpoints are responding:
  ```bash
  # Test API endpoints (replace with your actual API URL)
  curl "https://YOUR-API-URL/restaurants"
  curl "https://YOUR-API-URL/tickets"
  curl "https://YOUR-API-URL/equipment"
  ```

## Running the Guidance

### Accessing the Dashboard

1. Navigate to the CloudFront URL provided in the deployment output
2. Sign up for a new account or sign in with existing credentials
3. View real-time restaurant status powered by monitoring agents by navigating across the table Dashboard, 3D Digital Twin and Tickets. 
4. Click on each restaurant under 3D Digital Twin tab to see a 3D view of the store and its appliance status.
4. Interact with Gen AI chat interface on the bottom right to know the status of the restaurants in natural language format.

### Expected Output

The dashboard provides:
- **Real-time Status**: View all 10 Georgia locations with color-coded status
- **3D Digital Twin**: Interactive 3D visualization of restaurant equipment
- **Equipment Monitoring**: Live temperature data from 7 appliances per location
- **Automated Ticketing**: Strands agents automatically create tickets for anomalies
- **AI Chat Interface**: Conversational AI for restaurant operations queries

### API Endpoints

The system provides the following REST API endpoints:
- `GET /restaurants` - List all restaurant locations with agent-analyzed status
- `GET /equipment` - Get equipment readings processed by monitoring agents  
- `GET /tickets` - Get maintenance tickets created by restaurant monitoring agents
- `POST /strands-agent-chat` - Direct interface to restaurant monitoring agents

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

Customers are responsible for making their own independent assessment of the information in this Guidance. This Guidance: (a) is for informational purposes only, (b) represents AWS current product offerings and practices, which are subject to change without notice, and (c) does not create any commitments or assurances from AWS and its affiliates, suppliers or licensors. AWS products or services are provided "as is" without warranties, representations, or conditions of any kind, whether express or implied. AWS responsibilities and liabilities to its customers are controlled by AWS agreements, and this Guidance is not part of, nor does it modify, any agreement between AWS and its customers.

## Authors

This guidance was created by the AWS Solutions Library team.

## Notices

Customers are responsible for making their own independent assessment of the information in this Guidance. This Guidance: (a) is for informational purposes only, (b) represents AWS current product offerings and practices, which are subject to change without notice, and (c) does not create any commitments or assurances from AWS and its affiliates, suppliers or licensors. AWS products or services are provided "as is" without warranties, representations, or conditions of any kind, whether express or implied. AWS responsibilities and liabilities to its customers are controlled by AWS agreements, and this Guidance is not part of, nor does it modify, any agreement between AWS and its customers.

## Authors

This guidance was created by the AWS Solutions Library team.
