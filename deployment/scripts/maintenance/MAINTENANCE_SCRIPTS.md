# Maintenance Scripts

## Overview
Maintenance scripts for updating deployed components without full redeployment.

## Available Scripts

### update-frontend.sh
**Purpose**: Update frontend files (HTML/CSS/JS) without redeploying infrastructure

**Usage**:
```bash
./scripts/maintenance/update-frontend.sh
```

**What it does**:
1. Syncs all frontend files to S3 bucket
2. Invalidates CloudFront cache for immediate updates
3. Displays CloudFront URL for verification

**When to use**:
- After modifying HTML/CSS/JavaScript files
- After updating chat interface or dashboard
- After fixing frontend bugs

**Stack reference**: `rest-monitor-complete-infrastructure-prod`

## Removed Scripts (Moved to temp/)

The following scripts were removed as they reference old deployment patterns:
- `update-agent-with-inventory.sh` - Old AgentCore pattern
- `update-agentcore-inventory.sh` - Old AgentCore pattern
- `add-inventory-to-agentcore.sh` - Old AgentCore pattern
- `update-agent-memory.sh` - Old Docker build pattern
- `fix-and-deploy-agentcore.sh` - Old AgentCore pattern
- `update-agentcore.sh` - Old AgentCore pattern

These scripts referenced separate base-infra/inventory-infra/staffing-infra stacks that have been consolidated into `complete-infrastructure.yaml`.

## Status: ✅ CLEANED UP
- 1 useful script (update-frontend.sh)
- 6 obsolete scripts moved to temp/
- All references updated to consolidated stack name
