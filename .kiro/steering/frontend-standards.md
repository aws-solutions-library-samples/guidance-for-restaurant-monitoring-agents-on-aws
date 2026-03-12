---
inclusion: fileMatch
fileMatchPattern: "**/*.html,**/*.js,**/frontend/**"
---

# Frontend Development Standards

## File Organization

⚠️ **IMPORTANT**: All backup copies and reference files MUST be saved to `temp/` folder.

```
temp/source-backup/    # Backup copies of frontend files
```

Production frontend files go in `frontend/`.

## Authentication with Cognito

```javascript
// Initialize Cognito
const poolData = {
    UserPoolId: 'us-east-1_XXXXXX',
    ClientId: 'your-client-id'
};
const userPool = new AmazonCognitoIdentity.CognitoUserPool(poolData);

// Get current user token
async function getAuthToken() {
    return new Promise((resolve, reject) => {
        const cognitoUser = userPool.getCurrentUser();
        if (!cognitoUser) {
            reject(new Error('No user logged in'));
            return;
        }
        cognitoUser.getSession((err, session) => {
            if (err) reject(err);
            else resolve(session.getIdToken().getJwtToken());
        });
    });
}
```

## API Calls

```javascript
async function callApi(endpoint, method = 'GET', body = null) {
    try {
        showLoading(true);
        const token = await getAuthToken();
        const response = await fetch(`${API_URL}/${endpoint}`, {
            method,
            headers: {
                'Authorization': token,
                'Content-Type': 'application/json'
            },
            body: body ? JSON.stringify(body) : null
        });
        
        if (!response.ok) {
            throw new Error(`API error: ${response.status}`);
        }
        return await response.json();
    } catch (error) {
        showError('Failed to load data. Please try again.');
        console.error(error);
    } finally {
        showLoading(false);
    }
}
```

## UI Patterns

### Loading States
```javascript
function showLoading(show) {
    document.getElementById('loading').style.display = show ? 'block' : 'none';
}
```

### Error Messages
```javascript
function showError(message) {
    const errorDiv = document.getElementById('error');
    errorDiv.textContent = message;
    errorDiv.style.display = 'block';
    setTimeout(() => errorDiv.style.display = 'none', 5000);
}
```

## Chat Interface

```javascript
async function sendChatMessage(message) {
    const response = await fetch(`${API_URL}/chat-stream`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': await getAuthToken()
        },
        body: JSON.stringify({ prompt: message })
    });
    
    // Handle streaming response
    const reader = response.body.getReader();
    const decoder = new TextDecoder();
    
    while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        appendToChat(decoder.decode(value));
    }
}
```

## Security Rules

1. Never store tokens in localStorage - use sessionStorage or memory
2. Always validate user input before sending to API
3. Sanitize any HTML content before rendering
4. Use HTTPS for all API calls
5. Implement session timeout handling

## Frontend Deployment (S3 + CloudFront)

⚠️ **IMPORTANT**: After ANY frontend code changes, you MUST sync to S3 and invalidate CloudFront cache.

### Quick Deployment Commands

```bash
# Get S3 bucket name
S3_BUCKET=$(aws cloudformation describe-stacks \
    --stack-name restaurant-agent-infrastructure-prod \
    --query 'Stacks[0].Outputs[?OutputKey==`BucketName`].OutputValue' \
    --output text)

# Sync frontend files to S3
aws s3 sync frontend/ s3://$S3_BUCKET/ --delete

# Get CloudFront distribution ID
CLOUDFRONT_ID=$(aws cloudformation describe-stacks \
    --stack-name restaurant-agent-infrastructure-prod \
    --query 'Stacks[0].Outputs[?OutputKey==`DistributionId`].OutputValue' \
    --output text)

# Invalidate CloudFront cache (REQUIRED for changes to appear)
aws cloudfront create-invalidation --distribution-id $CLOUDFRONT_ID --paths "/*"
```

### Using Utility Script

```bash
./deployment/utils/invalidate-frontend-cache.sh
```

### Deployment Checklist

After editing frontend files:
- [ ] Test changes locally (open HTML files in browser)
- [ ] Sync to S3: `aws s3 sync frontend/ s3://$S3_BUCKET/ --delete`
- [ ] Invalidate CloudFront: `aws cloudfront create-invalidation --distribution-id $CLOUDFRONT_ID --paths "/*"`
- [ ] Verify changes at CloudFront URL
- [ ] Cache invalidation takes 1-2 minutes to propagate

### Full Deployment (includes frontend)

```bash
./deployment/deploy-all.sh
```

This script automatically:
1. Updates API URLs in frontend files
2. Syncs to S3
3. Invalidates CloudFront cache
