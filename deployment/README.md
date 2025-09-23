# Deployment

This folder contains the AWS CloudFormation templates and deployment scripts for the Restaurant Monitoring Agents guidance.

## Files

- `restaurant-monitoring-base-template.yaml` - Main infrastructure template
- `strands-agent-chat-workflow.yaml` - Agent workflow Lambda functions
- `deploy.sh` - Automated deployment script

## Usage

Run the deployment script:
```bash
./deploy.sh
```

Or deploy manually using AWS CLI:
```bash
aws cloudformation deploy --template-file restaurant-monitoring-base-template.yaml --stack-name restaurant-monitoring-base --capabilities CAPABILITY_IAM
```
