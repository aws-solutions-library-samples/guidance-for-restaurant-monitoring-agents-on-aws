# Security Documentation

This folder contains all security-related documentation and tools for the Restaurant Monitoring System.

## Files

### 📋 Reports

- **`SECURITY_REPORT.md`** - Comprehensive security analysis with recommendations
- **`security-scan-results.txt`** - Latest scan results from AWS infrastructure

### 🔧 Tools

- **`security-scan.sh`** - Automated security scanner for AWS resources

## Running Security Scan

To generate a fresh security report:

```bash
cd security
bash security-scan.sh
```

This will:
1. Validate CloudFormation templates
2. Scan deployed AWS resources (IAM, S3, DynamoDB, Lambda, API Gateway, CloudFront, Cognito)
3. Check for security misconfigurations
4. Generate updated reports

## Requirements

- AWS CLI configured with valid credentials
- Access to `rest-monitor-base-infrastructure-prod` stack
- Region: `us-east-1`

## Reports Generated

After running the scan:
- `SECURITY_REPORT.md` - Updated with latest findings
- `security-scan-results.txt` - Console output saved

## Last Scan

**Date:** October 12, 2025  
**Security Score:** 6/10  
**Critical Issues:** 6 found

See `SECURITY_REPORT.md` for details.
