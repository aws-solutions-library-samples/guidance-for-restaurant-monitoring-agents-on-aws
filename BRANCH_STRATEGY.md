# Git Branch Strategy

## Current Branch Structure

```
main (57588e5)
├── backup-before-direct-code-deploy (0815932) ✅ BACKUP
└── feature-direct-code-deploy (57588e5) 🚧 WORK IN PROGRESS
```

## Branch Descriptions

### `backup-before-direct-code-deploy` ✅
**Purpose**: Preserve working container deployment state

**Contains**:
- ✅ Complete infrastructure (complete-infrastructure.yaml)
- ✅ Container-based AgentCore deployment (working)
- ✅ Data loading scripts (7 files, merged and minimized)
- ✅ Frontend with tabbed interface (5 pages)
- ✅ Maintenance scripts (1 useful script)
- ✅ All documentation

**Status**: STABLE, WORKING, DO NOT MODIFY

**Restore Command**:
```bash
git checkout backup-before-direct-code-deploy
```

### `feature-direct-code-deploy` 🚧
**Purpose**: Migrate from container to direct code deploy

**Work To Do**:
1. ⏳ Setup virtual environment for Bedrock AgentCore CLI
2. ⏳ Test minimal agent with direct code deploy
3. ⏳ Convert full agent (inventory + staffing tools)
4. ⏳ Update frontend with new AgentCore URL
5. ⏳ Delete old CloudFormation stack
6. ⏳ Verify all functionality works

**Status**: IN PROGRESS

**Current Command**:
```bash
git checkout feature-direct-code-deploy
```

### `main`
**Purpose**: Production-ready code

**Status**: Currently at old state (57588e5)

**Will Update**: After feature-direct-code-deploy is tested and verified

## Migration Workflow

### Phase 1: Backup (COMPLETE ✅)
```bash
git checkout -b backup-before-direct-code-deploy
git add -A
git commit -m "Backup: Container deployment working state"
```

### Phase 2: Development (IN PROGRESS 🚧)
```bash
git checkout -b feature-direct-code-deploy
# Make changes for direct code deploy
# Test thoroughly
git add -A
git commit -m "Feature: Direct code deploy migration"
```

### Phase 3: Merge (PENDING ⏳)
```bash
# After testing succeeds
git checkout main
git merge feature-direct-code-deploy
git push origin main
```

### Phase 4: Cleanup (PENDING ⏳)
```bash
# Keep backup branch for safety
# Delete feature branch after merge
git branch -d feature-direct-code-deploy
```

## Rollback Strategy

### If Direct Code Deploy Fails
```bash
# Restore working container deployment
git checkout backup-before-direct-code-deploy

# Deploy from backup
cd deployment
./deploy.sh
```

### If Need to Abandon Migration
```bash
# Switch back to main
git checkout main

# Delete feature branch
git branch -D feature-direct-code-deploy

# Merge backup to main if needed
git merge backup-before-direct-code-deploy
```

## Safety Notes

1. **NEVER delete backup-before-direct-code-deploy branch**
2. **Test feature-direct-code-deploy thoroughly before merging**
3. **Keep backup branch for at least 30 days after migration**
4. **Document any issues in feature branch commits**

## Current Status

- ✅ Backup created: `backup-before-direct-code-deploy`
- 🚧 Feature branch created: `feature-direct-code-deploy`
- ⏳ Migration in progress
- ⏳ Testing pending
- ⏳ Merge to main pending

## Next Steps

1. Setup virtual environment in `feature-direct-code-deploy`
2. Install Bedrock AgentCore CLI
3. Test minimal agent deployment
4. Convert full agent if test succeeds
5. Update documentation
6. Merge to main after verification

## Branch Comparison

| Feature | backup-before-direct-code-deploy | feature-direct-code-deploy |
|---------|----------------------------------|----------------------------|
| Deployment Method | Container (Docker) | Direct Code (ZIP) |
| Deployment Time | 15-20 minutes | 3-4 minutes (target) |
| Docker Required | Yes | No |
| Status | ✅ Working | 🚧 In Progress |
| Risk | None (backup) | Testing required |
