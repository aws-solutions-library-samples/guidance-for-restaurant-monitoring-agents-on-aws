---
inclusion: always
---

# Security Requirements

## File Organization

⚠️ **IMPORTANT**: All security scan results, reports, and working documents MUST be saved to appropriate folders:

```
security/                  # Security reports and scan results
temp/                      # Working documents and drafts
```

**DO NOT** create security reports or summaries in the project root.

## Critical Security Rules

⚠️ **DO NOT deploy to production** without addressing these security issues.

### Authentication & Authorization

1. **API Gateway**: Must use Cognito authorizer - never `AuthorizationType: NONE` for protected endpoints
2. **MFA**: Enable multi-factor authentication for all Cognito users
3. **Password Policy**: Require symbols in addition to current requirements
4. **Session Management**: Implement token refresh and automatic logout after inactivity

### Network Security

1. **CORS**: Restrict to CloudFront domain only - never use `Access-Control-Allow-Origin: *`
2. **Rate Limiting**: Add API Gateway throttling to prevent DDoS
3. **CSP Headers**: Add Content Security Policy to prevent XSS attacks

### Data Protection

1. **Encryption**: Use KMS customer managed keys for sensitive data
2. **No Hardcoded Secrets**: Use environment variables or AWS Secrets Manager
3. **Data Classification**: Tag sensitive data appropriately

### Monitoring & Logging

1. **CloudTrail**: Must be enabled for all API call auditing
2. **CloudWatch Alarms**: Set up for Lambda errors, API 4xx/5xx, DynamoDB throttling
3. **AWS Config**: Enable for configuration drift detection

### Code Security Checklist

When writing code, verify:
- [ ] No hardcoded API keys, tokens, or credentials
- [ ] No hardcoded passwords or secrets
- [ ] No hardcoded internal URLs or IP addresses
- [ ] No embedded private keys or certificates
- [ ] No database connection strings with credentials
- [ ] Environment variables used for all sensitive configuration
- [ ] Input validation on all user inputs
- [ ] Error messages don't expose sensitive information
