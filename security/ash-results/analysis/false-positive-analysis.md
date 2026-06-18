# ASH Scan False Positive Analysis

**Scan Date:** 2026-06-17  
**ASH Version:** 3.2.3  
**Total Actionable Findings:** 56 (2 checkov + 54 detect-secrets)

---

## Checkov Findings (2 Critical) — FALSE POSITIVES

Both checkov findings are scanning **old CDK Nag output artifacts** in `solution-guidance-docs-July2026/ash-results/`, not actual deployment source code.

### Finding 1: CKV_AWS_27 — SQS Queue Encryption

| Field | Value |
|-------|-------|
| Rule | CKV_AWS_27 |
| Severity | Critical |
| Message | Ensure all data stored in the SQS queue is encrypted |
| File | `solution-guidance-docs-July2026/ash-results/scanners/cdk-nag/source/deployment--chat-endpoint--yaml/ASHCDKNagScanner.template.json` |
| Status | **FALSE POSITIVE** |

**Reason:** This file is a previously generated CDK Nag synthesized template artifact, not actual deployment infrastructure. The actual source template (`deployment/chat-endpoint.yaml`) uses `SqsManagedSseEnabled: true` which provides SSE-SQS encryption. Checkov's rule expects KMS CMK encryption, but SSE-SQS is an acceptable encryption method for a Dead Letter Queue.

### Finding 2: CKV_AWS_21 — S3 Bucket Versioning

| Field | Value |
|-------|-------|
| Rule | CKV_AWS_21 |
| Severity | Critical |
| Message | Ensure the S3 bucket has versioning enabled |
| File | `solution-guidance-docs-July2026/ash-results/scanners/cdk-nag/source/deployment--knowledge-base--yaml/ASHCDKNagScanner.template.json` |
| Status | **FALSE POSITIVE** |

**Reason:** This file is a previously generated CDK Nag synthesized template artifact, not actual deployment infrastructure. The bucket in question (`KBAccessLogsBucket`) is an access logging bucket with a 90-day lifecycle expiration policy. Versioning is intentionally disabled on access log buckets to avoid storing redundant log versions that increase cost without security benefit.

---

## Detect-Secrets Findings (54 Critical) — FALSE POSITIVES

All 54 detect-secrets findings are false positives caused by:

### Category 1: `.secrets.baseline` file (16 findings)

The `.secrets.baseline` file is detect-secrets' own tracking file. It contains hashed representations of known non-secret patterns. Scanning this file produces self-referential false positives.

### Category 2: Frontend CDN Integrity Hashes (32 findings)

Files affected:
- `frontend/index.html` (8)
- `frontend/3d-twin.html` (6)
- `frontend/inventory.html` (4)
- `frontend/staffing.html` (4)
- `frontend/tickets.html` (4)
- `frontend/login.html` (2)
- `frontend/agent-dashboard.html` (4)

These are Subresource Integrity (SRI) hashes in `<script>` and `<link>` tags (e.g., `integrity="sha384-..."`). SRI hashes are a **security best practice** (not secrets) that verify CDN-loaded resources haven't been tampered with.

### Category 3: Old Scan Artifact Files (6 findings)

Files in `solution-guidance-docs-July2026/ash-results/` are previously generated scan results being re-scanned, producing false positives.

---

## Scanner Results Summary

| Scanner | Result | Actionable | Notes |
|---------|--------|------------|-------|
| bandit | PASSED | 0 | 4 Low findings (below threshold) |
| cdk-nag | PASSED | 0 | 10 Info only — suppressions working correctly |
| checkov | FAILED | 2 | Both are false positives (scanning old artifacts) |
| detect-secrets | FAILED | 54 | All false positives (baseline file, SRI hashes, old artifacts) |
| npm-audit | PASSED | 0 | Clean |
| semgrep | PASSED | 0 | Clean |

---

## Recommendation

1. **Exclude `solution-guidance-docs-July2026/` from ASH scans** — this folder contains documentation artifacts that should not be scanned as source code.
2. **Update `.secrets.baseline`** to acknowledge the SRI integrity hashes as non-secrets.
3. **No code changes required** — the actual deployment templates pass security validation.

---

## Conclusion

All 56 actionable findings are confirmed false positives. The actual deployment source code (`deployment/` folder) passes security scanning with no critical, high, or medium findings. The `cdk_nag` suppression for `AwsSolutions-IAM5` on the ChatLambdaRole is properly documented and justified.
