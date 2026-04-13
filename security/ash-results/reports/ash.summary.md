# ASH Security Scan Report

- **Report generated**: 2026-03-10T20:47:19+00:00
- **Time since scan**: 1 minute

## Scan Metadata

- **Project**: ASH
- **Scan executed**: 2026-03-10T20:46:16+00:00
- **ASH version**: 3.2.3

## Summary

### Scanner Results

The table below shows findings by scanner, with status based on severity thresholds and dependencies:

- **Severity levels**:
  - **Suppressed (S)**: Findings that have been explicitly suppressed and don't affect scanner status
  - **Critical (C)**: Highest severity findings that require immediate attention
  - **High (H)**: Serious findings that should be addressed soon
  - **Medium (M)**: Moderate risk findings
  - **Low (L)**: Lower risk findings
  - **Info (I)**: Informational findings with minimal risk
- **Duration (Time)**: Time taken by the scanner to complete its execution
- **Actionable**: Number of findings at or above the threshold severity level that require attention
- **Result**:
  - **PASSED** = No findings at or above threshold
  - **FAILED** = Findings at or above threshold
  - **MISSING** = Required dependencies not available
  - **SKIPPED** = Scanner explicitly disabled
  - **ERROR** = Scanner execution error
- **Threshold**: The minimum severity level that will cause a scanner to fail
  - Thresholds: ALL, LOW, MEDIUM, HIGH, CRITICAL
  - Source: Values in parentheses indicate where the threshold is set:
    - `global` (global_settings section in the ASH_CONFIG used)
    - `config` (scanner config section in the ASH_CONFIG used)
    - `scanner` (default configuration in the plugin, if explicitly set)
- **Statistics calculation**:
  - All statistics are calculated from the final aggregated SARIF report
  - Suppressed findings are counted separately and do not contribute to actionable findings
  - Scanner status is determined by comparing actionable findings to the threshold

| Scanner | Suppressed | Critical | High | Medium | Low | Info | Actionable | Result | Threshold |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| bandit | 0 | 0 | 0 | 0 | 4 | 0 | 0 | PASSED | MEDIUM (global) |
| cdk-nag | 0 | 19 | 0 | 1 | 0 | 46 | 20 | FAILED | MEDIUM (global) |
| cfn-nag | 0 | 0 | 0 | 0 | 0 | 0 | 0 | MISSING | MEDIUM (global) |
| checkov | 0 | 6 | 0 | 0 | 0 | 0 | 6 | FAILED | MEDIUM (global) |
| detect-secrets | 0 | 4 | 0 | 0 | 0 | 0 | 4 | FAILED | MEDIUM (global) |
| grype | 0 | 0 | 0 | 0 | 0 | 0 | 0 | MISSING | MEDIUM (global) |
| npm-audit | 0 | 0 | 0 | 0 | 0 | 0 | 0 | PASSED | MEDIUM (global) |
| opengrep | 0 | 0 | 0 | 0 | 0 | 0 | 0 | MISSING | MEDIUM (global) |
| semgrep | 0 | 3 | 0 | 0 | 0 | 0 | 3 | FAILED | MEDIUM (global) |
| syft | 0 | 0 | 0 | 0 | 0 | 0 | 0 | MISSING | MEDIUM (global) |

### Top 6 Hotspots

Files with the highest number of security findings:

| Finding Count | File Location |
| ---: | --- |
| 20 | deployment/restaurant-monitoring-base-template.yaml |
| 7 | deployment/chat-endpoint.yaml |
| 2 | frontend/3d-twin.html |
| 2 | frontend/shared.js |
| 1 | frontend/login.html |
| 1 | frontend/api.js |

<h2>Detailed Findings</h2>

<details>
<summary>Show 20 of 33 actionable findings</summary>

### Finding 1: SECRET-BASE64-HIGH-ENTROPY-STRING

- **Severity**: HIGH
- **Scanner**: detect-secrets
- **Rule ID**: SECRET-BASE64-HIGH-ENTROPY-STRING
- **Location**: frontend/login.html:7

**Description**:
Secret of type 'Base64 High Entropy String' detected in file 'frontend/login.html' at line 7

**Code Snippet**:
```
Secret of type Base64 High Entropy String detected
```

---

### Finding 2: SECRET-SECRET-KEYWORD

- **Severity**: HIGH
- **Scanner**: detect-secrets
- **Rule ID**: SECRET-SECRET-KEYWORD
- **Location**: deployment/restaurant-monitoring-base-template.yaml:1059

**Description**:
Secret of type 'Secret Keyword' detected in file 'deployment/restaurant-monitoring-base-template.yaml' at line 1059

**Code Snippet**:
```
Secret of type Secret Keyword detected
```

---

### Finding 3: SECRET-BASE64-HIGH-ENTROPY-STRING

- **Severity**: HIGH
- **Scanner**: detect-secrets
- **Rule ID**: SECRET-BASE64-HIGH-ENTROPY-STRING
- **Location**: frontend/3d-twin.html:12

**Description**:
Secret of type 'Base64 High Entropy String' detected in file 'frontend/3d-twin.html' at line 12

**Code Snippet**:
```
Secret of type Base64 High Entropy String detected
```

---

### Finding 4: SECRET-BASE64-HIGH-ENTROPY-STRING

- **Severity**: HIGH
- **Scanner**: detect-secrets
- **Rule ID**: SECRET-BASE64-HIGH-ENTROPY-STRING
- **Location**: frontend/3d-twin.html:13

**Description**:
Secret of type 'Base64 High Entropy String' detected in file 'frontend/3d-twin.html' at line 13

**Code Snippet**:
```
Secret of type Base64 High Entropy String detected
```

---

### Finding 5: AwsSolutions-SQS3

- **Severity**: HIGH
- **Scanner**: cdk-nag
- **Rule ID**: AwsSolutions-SQS3
- **Location**: deployment/chat-endpoint.yaml:46

**Description**:
The SQS queue is not used as a dead-letter queue (DLQ) and does not have a DLQ enabled.

Exception Reason: N/A

**Code Snippet**:
```
Resources:
  ChatLambdaDLQ:
    Properties:
      MessageRetentionPeriod: 1209600
      QueueName: RestaurantAgent-Chat-DLQ
      SqsManagedSseEnabled: true
    Type: AWS::SQS::Queue
```

---

### Finding 6: AwsSolutions-IAM4

- **Severity**: HIGH
- **Scanner**: cdk-nag
- **Rule ID**: AwsSolutions-IAM4
- **Location**: deployment/chat-endpoint.yaml:69

**Description**:
The IAM user, role, or group uses AWS managed policies.

Exception Reason: N/A

**Code Snippet**:
```
Resources:
  ChatLambdaRole:
    Properties:
      AssumeRolePolicyDocument:
        Statement:
          - Action: sts:AssumeRole
            Effect: Allow
            Principal:
              Service: lambda.amazonaws.com
        Version: '2012-10-17'
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
      Policies:
        - PolicyDocument:
            Statement:
              - Action:
                  - bedrock-agentcore:InvokeAgentRuntime
                  - bedrock-agentcore:Invoke
                Effect: Allow
                Resource: '*'
              - Action:
                  - sqs:SendMessage
                Effect: Allow
                Resource:
                  Fn::GetAtt:
                    - ChatLambdaDLQ
                    - Arn
            Version: '2012-10-17'
          PolicyName: InvokeAgentCore
      RoleName: RestaurantAgent-ChatLambda-Role
    Type: AWS::IAM::Role
```

---

### Finding 7: AwsSolutions-IAM5

- **Severity**: HIGH
- **Scanner**: cdk-nag
- **Rule ID**: AwsSolutions-IAM5
- **Location**: deployment/chat-endpoint.yaml:69

**Description**:
The IAM entity contains wildcard permissions and does not have a cdk-nag rule suppression with evidence for those permission.

Exception Reason: N/A

**Code Snippet**:
```
Resources:
  ChatLambdaRole:
    Properties:
      AssumeRolePolicyDocument:
        Statement:
          - Action: sts:AssumeRole
            Effect: Allow
            Principal:
              Service: lambda.amazonaws.com
        Version: '2012-10-17'
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
      Policies:
        - PolicyDocument:
            Statement:
              - Action:
                  - bedrock-agentcore:InvokeAgentRuntime
                  - bedrock-agentcore:Invoke
                Effect: Allow
                Resource: '*'
              - Action:
                  - sqs:SendMessage
                Effect: Allow
                Resource:
                  Fn::GetAtt:
                    - ChatLambdaDLQ
                    - Arn
            Version: '2012-10-17'
          PolicyName: InvokeAgentCore
      RoleName: RestaurantAgent-ChatLambda-Role
    Type: AWS::IAM::Role
```

---

### Finding 8: AwsSolutions-L1

- **Severity**: HIGH
- **Scanner**: cdk-nag
- **Rule ID**: AwsSolutions-L1
- **Location**: deployment/chat-endpoint.yaml:22

**Description**:
The non-container Lambda function is not configured to use the latest runtime version.

Exception Reason: N/A

**Code Snippet**:
```
Resources:
  ChatLambda:
    Properties:
      Code:
        ZipFile: "import json\nimport boto3\nimport os\n\ndef handler(event, context):\n    try:\n        body = json.loads(event.get('body',\
          \ '{}'))\n        prompt = body.get('prompt', '')\n        session_id = body.get('sessionId', f\"session-{context.aws_request_id}\"\
          )\n        \n        if not prompt:\n            return {\n                'statusCode': 400,\n                'headers':\
          \ cors_headers(),\n                'body': json.dumps({'error': 'prompt required'})\n            }\n        \n \
          \       # Invoke AgentCore\n        client = boto3.client('bedrock-agentcore')\n        agent_arn = os.environ['AGENT_RUNTIME_ARN']\n\
          \        \n        response = client.invoke_agent_runtime(\n            agentRuntimeArn=agent_arn,\n           \
          \ payload=json.dumps({\n                'prompt': prompt,\n                'sessionId': session_id\n           \
          \ }).encode('utf-8')\n        )\n        \n        # Read response\n        response_body = response['response'].read().decode('utf-8')\n\
          \        result = json.loads(response_body)\n        \n        return {\n            'statusCode': 200,\n      \
          \      'headers': cors_headers(),\n            'body': json.dumps({\n                'result': result.get('result',\
          \ ''),\n                'sessionId': session_id\n            })\n        }\n    except Exception as e:\n       \
          \ print(f\"Error: {str(e)}\")\n        return {\n            'statusCode': 500,\n            'headers': cors_headers(),\n\
          \            'body': json.dumps({'error': str(e)})\n        }\n\ndef cors_headers():\n    return {\n        'Content-Type':\
          \ 'application/json',\n        'Access-Control-Allow-Origin': '*',\n        'Access-Control-Allow-Headers': 'Content-Type',\n\
          \        'Access-Control-Allow-Methods': 'POST,OPTIONS'\n    }\n"
      DeadLetterConfig:
        TargetArn:
          Fn::GetAtt:
            - ChatLambdaDLQ
            - Arn
      Environment:
        Variables:
          AGENT_RUNTIME_ARN:
            Ref: AgentRuntimeArn
      FunctionName: RestaurantAgent-Chat
      Handler: index.handler
      KmsKeyArn:
        Fn::GetAtt:
          - ChatLambdaEnvEncryptionKey
          - Arn
      MemorySize: 512
      ReservedConcurrentExecutions: 10
      Role:
        Fn::GetAtt:
          - ChatLambdaRole
          - Arn
      Runtime: python3.13
      Timeout: 300
    Type: AWS::Lambda::Function
```

---

### Finding 9: AwsSolutions-APIG4

- **Severity**: HIGH
- **Scanner**: cdk-nag
- **Rule ID**: AwsSolutions-APIG4
- **Location**: deployment/chat-endpoint.yaml:203

**Description**:
The API does not implement authorization.

Exception Reason: N/A

**Code Snippet**:
```
Resources:
  ChatOptionsMethod:
    Properties:
      AuthorizationType: NONE
      HttpMethod: OPTIONS
      Integration:
        IntegrationResponses:
          - ResponseParameters:
              method.response.header.Access-Control-Allow-Headers: '''Content-Type'''
              method.response.header.Access-Control-Allow-Methods: '''POST,OPTIONS'''
              method.response.header.Access-Control-Allow-Origin: '''*'''
            StatusCode: 200
        RequestTemplates:
          application/json: '{"statusCode": 200}'
        Type: MOCK
      MethodResponses:
        - ResponseParameters:
            method.response.header.Access-Control-Allow-Headers: true
            method.response.header.Access-Control-Allow-Methods: true
            method.response.header.Access-Control-Allow-Origin: true
          StatusCode: 200
      ResourceId:
        Ref: ChatResource
      RestApiId:
        Ref: RestApiId
    Type: AWS::ApiGateway::Method
```

---

### Finding 10: AwsSolutions-SQS3

- **Severity**: HIGH
- **Scanner**: cdk-nag
- **Rule ID**: AwsSolutions-SQS3
- **Location**: deployment/restaurant-monitoring-base-template.yaml:65

**Description**:
The SQS queue is not used as a dead-letter queue (DLQ) and does not have a DLQ enabled.

Exception Reason: N/A

**Code Snippet**:
```
Resources:
  ApiLambdaDLQ:
    Properties:
      MessageRetentionPeriod: 1209600
      QueueName:
        Fn::Sub: ${ProjectName}-api-dlq-${Environment}
      SqsManagedSseEnabled: true
    Type: AWS::SQS::Queue
```

---

### Finding 11: AwsSolutions-IAM4

- **Severity**: HIGH
- **Scanner**: cdk-nag
- **Rule ID**: AwsSolutions-IAM4
- **Location**: deployment/restaurant-monitoring-base-template.yaml:245

**Description**:
The IAM user, role, or group uses AWS managed policies.

Exception Reason: N/A

**Code Snippet**:
```
Resources:
  ApiLambdaRole:
    Properties:
      AssumeRolePolicyDocument:
        Statement:
          - Action: sts:AssumeRole
            Condition:
              StringEquals:
                aws:SourceAccount:
                  Ref: AWS::AccountId
            Effect: Allow
            Principal:
              Service: lambda.amazonaws.com
        Version: '2012-10-17'
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
      Policies:
        - PolicyDocument:
            Statement:
              - Action:
                  - dynamodb:GetItem
                  - dynamodb:Query
                  - dynamodb:Scan
                Condition:
                  StringEquals:
                    aws:RequestedRegion:
                      Ref: AWS::Region
                Effect: Allow
                Resource:
                  - Fn::GetAtt:
                      - RestaurantDataTable
                      - Arn
                  - Fn::GetAtt:
                      - EquipmentReadingsTable
                      - Arn
                  - Fn::GetAtt:
                      - TicketsTable
                      - Arn
                  - Fn::GetAtt:
                      - InventoryItemsTable
                      - Arn
                  - Fn::GetAtt:
                      - StaffingRequirementsTable
                      - Arn
              - Action:
                  - bedrock-agentcore:InvokeAgentRuntime
                  - bedrock-agentcore:InvokeAgentRuntimeWithWebSocketStream
                Effect: Allow
                Resource: '*'
              - Action:
                  - sqs:SendMessage
                Effect: Allow
                Resource:
                  Fn::GetAtt:
                    - ApiLambdaDLQ
                    - Arn
            Version: '2012-10-17'
          PolicyName: DynamoDBAccess
      RoleName:
        Fn::Sub: ${ProjectName}-api-lambda-role-${Environment}
    Type: AWS::IAM::Role
```

---

### Finding 12: AwsSolutions-IAM5

- **Severity**: HIGH
- **Scanner**: cdk-nag
- **Rule ID**: AwsSolutions-IAM5
- **Location**: deployment/restaurant-monitoring-base-template.yaml:245

**Description**:
The IAM entity contains wildcard permissions and does not have a cdk-nag rule suppression with evidence for those permission.

Exception Reason: N/A

**Code Snippet**:
```
Resources:
  ApiLambdaRole:
    Properties:
      AssumeRolePolicyDocument:
        Statement:
          - Action: sts:AssumeRole
            Condition:
              StringEquals:
                aws:SourceAccount:
                  Ref: AWS::AccountId
            Effect: Allow
            Principal:
              Service: lambda.amazonaws.com
        Version: '2012-10-17'
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
      Policies:
        - PolicyDocument:
            Statement:
              - Action:
                  - dynamodb:GetItem
                  - dynamodb:Query
                  - dynamodb:Scan
                Condition:
                  StringEquals:
                    aws:RequestedRegion:
                      Ref: AWS::Region
                Effect: Allow
                Resource:
                  - Fn::GetAtt:
                      - RestaurantDataTable
                      - Arn
                  - Fn::GetAtt:
                      - EquipmentReadingsTable
                      - Arn
                  - Fn::GetAtt:
                      - TicketsTable
                      - Arn
                  - Fn::GetAtt:
                      - InventoryItemsTable
                      - Arn
                  - Fn::GetAtt:
                      - StaffingRequirementsTable
                      - Arn
              - Action:
                  - bedrock-agentcore:InvokeAgentRuntime
                  - bedrock-agentcore:InvokeAgentRuntimeWithWebSocketStream
                Effect: Allow
                Resource: '*'
              - Action:
                  - sqs:SendMessage
                Effect: Allow
                Resource:
                  Fn::GetAtt:
                    - ApiLambdaDLQ
                    - Arn
            Version: '2012-10-17'
          PolicyName: DynamoDBAccess
      RoleName:
        Fn::Sub: ${ProjectName}-api-lambda-role-${Environment}
    Type: AWS::IAM::Role
```

---

### Finding 13: AwsSolutions-L1

- **Severity**: HIGH
- **Scanner**: cdk-nag
- **Rule ID**: AwsSolutions-L1
- **Location**: deployment/restaurant-monitoring-base-template.yaml:291

**Description**:
The non-container Lambda function is not configured to use the latest runtime version.

Exception Reason: N/A

**Code Snippet**:
```
Resources:
  ApiLambdaFunction:
    Properties:
      Code:
        ZipFile: "import json\nimport boto3\nimport os\nfrom decimal import Decimal\n\ndynamodb = boto3.resource('dynamodb')\n\
          \ndef decimal_default(obj):\n    if isinstance(obj, Decimal):\n        return float(obj)\n    raise TypeError\n\n\
          def lambda_handler(event, context):\n    try:\n        path = event.get('path', '')\n        method = event.get('httpMethod',\
          \ 'GET')\n        \n        # Security headers\n        headers = {\n            'Content-Type': 'application/json',\n\
          \            'Access-Control-Allow-Origin': '*',\n            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',\n\
          \            'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',\n            'Strict-Transport-Security': 'max-age=31536000;\
          \ includeSubDomains',\n            'X-Content-Type-Options': 'nosniff',\n            'X-Frame-Options': 'DENY',\n\
          \            'X-XSS-Protection': '1; mode=block'\n        }\n        \n        if method == 'OPTIONS':\n       \
          \     return {\n                'statusCode': 200,\n                'headers': headers,\n                'body':\
          \ ''\n            }\n        \n        # Input validation\n        if not path or len(path) > 100:\n           \
          \ return {\n                'statusCode': 400,\n                'headers': headers,\n                'body': json.dumps({'error':\
          \ 'Invalid path'})\n            }\n        \n        if path == '/restaurants':\n            table = dynamodb.Table(os.environ['RESTAURANTS_TABLE'])\n\
          \            response = table.scan()\n            return {\n                'statusCode': 200,\n               \
          \ 'headers': headers,\n                'body': json.dumps(response['Items'], default=decimal_default)\n        \
          \    }\n        \n        elif path == '/tickets':\n            table = dynamodb.Table(os.environ['TICKETS_TABLE'])\n\
          \            response = table.scan()\n            return {\n                'statusCode': 200,\n               \
          \ 'headers': headers,\n                'body': json.dumps(response['Items'], default=decimal_default)\n        \
          \    }\n        \n        elif path == '/equipment':\n            table = dynamodb.Table(os.environ['EQUIPMENT_TABLE'])\n\
          \            response = table.scan()\n            return {\n                'statusCode': 200,\n               \
          \ 'headers': headers,\n                'body': json.dumps(response['Items'], default=decimal_default)\n        \
          \    }\n        \n        elif path == '/inventory':\n            table = dynamodb.Table(os.environ['INVENTORY_TABLE'])\n\
          \            response = table.scan()\n            return {\n                'statusCode': 200,\n               \
          \ 'headers': headers,\n                'body': json.dumps({'inventory': response['Items']}, default=decimal_default)\n\
          \            }\n        \n        elif path == '/staffing':\n            table = dynamodb.Table(os.environ['STAFFING_TABLE'])\n\
          \            response = table.scan()\n            return {\n                'statusCode': 200,\n               \
          \ 'headers': headers,\n                'body': json.dumps({'staffing': response['Items']}, default=decimal_default)\n\
          \            }\n        \n        elif path == '/voice-token':\n            from urllib.parse import quote as url_quote\n\
          \            from botocore.auth import SigV4QueryAuth\n            from botocore.awsrequest import AWSRequest\n\
          \            from botocore.session import Session as BotoSession\n            \n            agent_arn = os.environ.get('AGENT_RUNTIME_ARN',\
          \ '')\n            if not agent_arn:\n                return {'statusCode': 500, 'headers': headers, 'body': json.dumps({'error':\
          \ 'AGENT_RUNTIME_ARN not set'})}\n            \n            rgn = os.environ.get('AWS_REGION', 'us-east-1')\n  \
          \          host = f'bedrock-agentcore.{rgn}.amazonaws.com'\n            encoded_arn = url_quote(agent_arn, safe='')\n\
          \            url = f'https://{host}/runtimes/{encoded_arn}/ws'\n            \n            bsession = BotoSession()\n\
          \            creds = bsession.get_credentials().get_frozen_credentials()\n            request = AWSRequest(method='GET',\
          \ url=url, headers={'host': host})\n            signer = SigV4QueryAuth(creds, 'bedrock-agentcore', rgn, expires=300)\n\
          \            signer.add_auth(request)\n            ws_url = request.url.replace('https://', 'wss://')\n        \
          \    \n            return {\n                'statusCode': 200,\n                'headers': headers,\n         \
          \       'body': json.dumps({'wsUrl': ws_url})\n            }\n        \n        return {\n            'statusCode':\
          \ 404,\n            'headers': headers,\n            'body': json.dumps({'error': 'Not found'})\n        }\n   \
          \     \n    except Exception as e:\n        return {\n            'statusCode': 500,\n            'headers': headers,\n\
          \            'body': json.dumps({'error': 'Internal server error'})\n        }\n"
      DeadLetterConfig:
        TargetArn:
          Fn::GetAtt:
            - ApiLambdaDLQ
            - Arn
      Environment:
        Variables:
          AGENT_RUNTIME_ARN:
            Fn::Sub: arn:aws:bedrock-agentcore:${AWS::Region}:${AWS::AccountId}:runtime/restaurant_agent
          EQUIPMENT_TABLE:
            Ref: EquipmentReadingsTable
          INVENTORY_TABLE:
            Ref: InventoryItemsTable
          RESTAURANTS_TABLE:
            Ref: RestaurantDataTable
          STAFFING_TABLE:
            Ref: StaffingRequirementsTable
          TICKETS_TABLE:
            Ref: TicketsTable
      FunctionName:
        Fn::Sub: ${ProjectName}-api-${Environment}
      Handler: index.lambda_handler
      KmsKeyArn:
        Fn::GetAtt:
          - LambdaEnvEncryptionKey
          - Arn
      MemorySize: 256
      ReservedConcurrentExecutions: 10
      Role:
        Fn::GetAtt:
          - ApiLambdaRole
          - Arn
      Runtime: python3.13
      Tags:
        - Key: Environment
          Value:
            Ref: Environment
        - Key: Project
          Value:
            Ref: ProjectName
      Timeout: 30
    Type: AWS::Lambda::Function
```

---

### Finding 14: AwsSolutions-APIG4

- **Severity**: HIGH
- **Scanner**: cdk-nag
- **Rule ID**: AwsSolutions-APIG4
- **Location**: deployment/restaurant-monitoring-base-template.yaml:482

**Description**:
The API does not implement authorization.

Exception Reason: N/A

**Code Snippet**:
```
Resources:
  RestaurantsOptionsMethod:
    Properties:
      AuthorizationType: NONE
      HttpMethod: OPTIONS
      Integration:
        IntegrationResponses:
          - ResponseParameters:
              method.response.header.Access-Control-Allow-Headers: '''Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'''
              method.response.header.Access-Control-Allow-Methods: '''GET,OPTIONS'''
              method.response.header.Access-Control-Allow-Origin: '''*'''
            ResponseTemplates:
              application/json: ''
            StatusCode: 200
        PassthroughBehavior: WHEN_NO_MATCH
        RequestTemplates:
          application/json: '{"statusCode": 200}'
        Type: MOCK
      MethodResponses:
        - ResponseModels:
            application/json: Empty
          ResponseParameters:
            method.response.header.Access-Control-Allow-Headers: true
            method.response.header.Access-Control-Allow-Methods: true
            method.response.header.Access-Control-Allow-Origin: true
          StatusCode: 200
      ResourceId:
        Ref: RestaurantsResource
      RestApiId:
        Ref: RestApi
    Type: AWS::ApiGateway::Method
```

---

### Finding 15: AwsSolutions-APIG4

- **Severity**: HIGH
- **Scanner**: cdk-nag
- **Rule ID**: AwsSolutions-APIG4
- **Location**: deployment/restaurant-monitoring-base-template.yaml:484

**Description**:
The API does not implement authorization.

Exception Reason: N/A

**Code Snippet**:
```
Resources:
  TicketsOptionsMethod:
    Properties:
      AuthorizationType: NONE
      HttpMethod: OPTIONS
      Integration:
        IntegrationResponses:
          - ResponseParameters:
              method.response.header.Access-Control-Allow-Headers: '''Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'''
              method.response.header.Access-Control-Allow-Methods: '''GET,OPTIONS'''
              method.response.header.Access-Control-Allow-Origin: '''*'''
            ResponseTemplates:
              application/json: ''
            StatusCode: 200
        PassthroughBehavior: WHEN_NO_MATCH
        RequestTemplates:
          application/json: '{"statusCode": 200}'
        Type: MOCK
      MethodResponses:
        - ResponseModels:
            application/json: Empty
          ResponseParameters:
            method.response.header.Access-Control-Allow-Headers: true
            method.response.header.Access-Control-Allow-Methods: true
            method.response.header.Access-Control-Allow-Origin: true
          StatusCode: 200
      ResourceId:
        Ref: TicketsResource
      RestApiId:
        Ref: RestApi
    Type: AWS::ApiGateway::Method
```

---

### Finding 16: AwsSolutions-APIG4

- **Severity**: HIGH
- **Scanner**: cdk-nag
- **Rule ID**: AwsSolutions-APIG4
- **Location**: deployment/restaurant-monitoring-base-template.yaml:486

**Description**:
The API does not implement authorization.

Exception Reason: N/A

**Code Snippet**:
```
Resources:
  EquipmentOptionsMethod:
    Properties:
      AuthorizationType: NONE
      HttpMethod: OPTIONS
      Integration:
        IntegrationResponses:
          - ResponseParameters:
              method.response.header.Access-Control-Allow-Headers: '''Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'''
              method.response.header.Access-Control-Allow-Methods: '''GET,OPTIONS'''
              method.response.header.Access-Control-Allow-Origin: '''*'''
            ResponseTemplates:
              application/json: ''
            StatusCode: 200
        PassthroughBehavior: WHEN_NO_MATCH
        RequestTemplates:
          application/json: '{"statusCode": 200}'
        Type: MOCK
      MethodResponses:
        - ResponseModels:
            application/json: Empty
          ResponseParameters:
            method.response.header.Access-Control-Allow-Headers: true
            method.response.header.Access-Control-Allow-Methods: true
            method.response.header.Access-Control-Allow-Origin: true
          StatusCode: 200
      ResourceId:
        Ref: EquipmentResource
      RestApiId:
        Ref: RestApi
    Type: AWS::ApiGateway::Method
```

---

### Finding 17: AwsSolutions-APIG4

- **Severity**: HIGH
- **Scanner**: cdk-nag
- **Rule ID**: AwsSolutions-APIG4
- **Location**: deployment/restaurant-monitoring-base-template.yaml:488

**Description**:
The API does not implement authorization.

Exception Reason: N/A

**Code Snippet**:
```
Resources:
  InventoryOptionsMethod:
    Properties:
      AuthorizationType: NONE
      HttpMethod: OPTIONS
      Integration:
        IntegrationResponses:
          - ResponseParameters:
              method.response.header.Access-Control-Allow-Headers: '''Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'''
              method.response.header.Access-Control-Allow-Methods: '''GET,OPTIONS'''
              method.response.header.Access-Control-Allow-Origin: '''*'''
            ResponseTemplates:
              application/json: ''
            StatusCode: 200
        PassthroughBehavior: WHEN_NO_MATCH
        RequestTemplates:
          application/json: '{"statusCode": 200}'
        Type: MOCK
      MethodResponses:
        - ResponseModels:
            application/json: Empty
          ResponseParameters:
            method.response.header.Access-Control-Allow-Headers: true
            method.response.header.Access-Control-Allow-Methods: true
            method.response.header.Access-Control-Allow-Origin: true
          StatusCode: 200
      ResourceId:
        Ref: InventoryResource
      RestApiId:
        Ref: RestApi
    Type: AWS::ApiGateway::Method
```

---

### Finding 18: AwsSolutions-APIG4

- **Severity**: HIGH
- **Scanner**: cdk-nag
- **Rule ID**: AwsSolutions-APIG4
- **Location**: deployment/restaurant-monitoring-base-template.yaml:490

**Description**:
The API does not implement authorization.

Exception Reason: N/A

**Code Snippet**:
```
Resources:
  StaffingOptionsMethod:
    Properties:
      AuthorizationType: NONE
      HttpMethod: OPTIONS
      Integration:
        IntegrationResponses:
          - ResponseParameters:
              method.response.header.Access-Control-Allow-Headers: '''Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'''
              method.response.header.Access-Control-Allow-Methods: '''GET,OPTIONS'''
              method.response.header.Access-Control-Allow-Origin: '''*'''
            ResponseTemplates:
              application/json: ''
            StatusCode: 200
        PassthroughBehavior: WHEN_NO_MATCH
        RequestTemplates:
          application/json: '{"statusCode": 200}'
        Type: MOCK
      MethodResponses:
        - ResponseModels:
            application/json: Empty
          ResponseParameters:
            method.response.header.Access-Control-Allow-Headers: true
            method.response.header.Access-Control-Allow-Methods: true
            method.response.header.Access-Control-Allow-Origin: true
          StatusCode: 200
      ResourceId:
        Ref: StaffingResource
      RestApiId:
        Ref: RestApi
    Type: AWS::ApiGateway::Method
```

---

### Finding 19: AwsSolutions-APIG4

- **Severity**: HIGH
- **Scanner**: cdk-nag
- **Rule ID**: AwsSolutions-APIG4
- **Location**: deployment/restaurant-monitoring-base-template.yaml:492

**Description**:
The API does not implement authorization.

Exception Reason: N/A

**Code Snippet**:
```
Resources:
  VoiceTokenOptionsMethod:
    Properties:
      AuthorizationType: NONE
      HttpMethod: OPTIONS
      Integration:
        IntegrationResponses:
          - ResponseParameters:
              method.response.header.Access-Control-Allow-Headers: '''Content-Type'''
              method.response.header.Access-Control-Allow-Methods: '''GET,OPTIONS'''
              method.response.header.Access-Control-Allow-Origin: '''*'''
            StatusCode: 200
        RequestTemplates:
          application/json: '{"statusCode": 200}'
        Type: MOCK
      MethodResponses:
        - ResponseParameters:
            method.response.header.Access-Control-Allow-Headers: true
            method.response.header.Access-Control-Allow-Methods: true
            method.response.header.Access-Control-Allow-Origin: true
          StatusCode: 200
      ResourceId:
        Ref: VoiceTokenResource
      RestApiId:
        Ref: RestApi
    Type: AWS::ApiGateway::Method
```

---

### Finding 20: AwsSolutions-S5

- **Severity**: HIGH
- **Scanner**: cdk-nag
- **Rule ID**: AwsSolutions-S5
- **Location**: deployment/restaurant-monitoring-base-template.yaml:795

**Description**:
The S3 static website bucket either has an open world bucket policy or does not use a CloudFront Origin Access Identity (OAI) in the bucket policy for limited getObject and/or putObject permissions.

Exception Reason: N/A

**Code Snippet**:
```
Resources:
  DashboardBucket:
    DeletionPolicy: Retain
    Properties:
      BucketEncryption:
        ServerSideEncryptionConfiguration:
          - BucketKeyEnabled: true
            ServerSideEncryptionByDefault:
              SSEAlgorithm: AES256
      LoggingConfiguration:
        DestinationBucketName:
          Ref: AccessLogsBucket
        LogFilePrefix: dashboard-access-logs/
      PublicAccessBlockConfiguration:
        BlockPublicAcls: true
        BlockPublicPolicy: true
        IgnorePublicAcls: true
        RestrictPublicBuckets: true
      VersioningConfiguration:
        Status: Enabled
      WebsiteConfiguration:
        ErrorDocument: error.html
        IndexDocument: index.html
    Type: AWS::S3::Bucket
```


> Note: Showing 20 of 33 total actionable findings. Configure `max_detailed_findings` to adjust this limit.

</details>

---

*Report generated by [Automated Security Helper (ASH)](https://github.com/awslabs/automated-security-helper) at 2026-03-10T20:47:19+00:00*