---
inclusion: fileMatch
fileMatchPattern: "**/*.yaml,**/*.yml"
---

# CloudFormation Standards

## File Organization

⚠️ **IMPORTANT**: All draft templates and reference infrastructure files MUST be saved to `temp/` folder.

```
temp/infrastructure/cloudformation/    # Reference/draft templates
temp/deployment-legacy/                # Deprecated templates
```

Production templates go in `deployment/templates/`.

## Template Structure

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: Brief description of what this template deploys

Parameters:
  Environment:
    Type: String
    Default: prod
    AllowedValues: [dev, staging, prod]

Resources:
  # Resources here

Outputs:
  # Outputs here
```

## Naming Conventions

- Stack names: `restaurant-agent-{component}-{environment}`
- Resource names: `restaurant-kitchen-assistant-{resource}-{environment}`
- Use `!Sub` for dynamic naming: `!Sub 'restaurant-agent-${Environment}'`

## DynamoDB Tables

```yaml
MyTable:
  Type: AWS::DynamoDB::Table
  DeletionPolicy: Retain
  Properties:
    TableName: !Sub 'restaurant-kitchen-assistant-${TableName}-${Environment}'
    BillingMode: PAY_PER_REQUEST
    SSESpecification:
      SSEEnabled: true
    PointInTimeRecoverySpecification:
      PointInTimeRecoveryEnabled: true
```

## IAM Policies - Least Privilege

```yaml
LambdaRole:
  Type: AWS::IAM::Role
  Properties:
    Policies:
      - PolicyName: DynamoDBAccess
        PolicyDocument:
          Statement:
            - Effect: Allow
              Action:
                - dynamodb:GetItem
                - dynamodb:PutItem
                - dynamodb:Query
                - dynamodb:Scan
              Resource: !GetAtt MyTable.Arn
```

## API Gateway with Cognito Auth

```yaml
ApiMethod:
  Type: AWS::ApiGateway::Method
  Properties:
    AuthorizationType: COGNITO_USER_POOLS
    AuthorizerId: !Ref CognitoAuthorizer
```

## S3 Buckets

```yaml
S3Bucket:
  Type: AWS::S3::Bucket
  Properties:
    BucketEncryption:
      ServerSideEncryptionConfiguration:
        - ServerSideEncryptionByDefault:
            SSEAlgorithm: AES256
    PublicAccessBlockConfiguration:
      BlockPublicAcls: true
      BlockPublicPolicy: true
      IgnorePublicAcls: true
      RestrictPublicBuckets: true
```

## Required Tags

All resources should include:
```yaml
Tags:
  - Key: Project
    Value: restaurant-monitoring
  - Key: Environment
    Value: !Ref Environment
  - Key: ManagedBy
    Value: CloudFormation
```
