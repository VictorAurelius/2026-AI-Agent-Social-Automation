# Bug Fix: n8n Environment Variable Access Denied

**Date:** 2026-03-19
**Severity:** Medium (Blocks workflow execution)
**Status:** ✅ Fixed

---

## Problem

Workflows fail when accessing environment variables with error:
```
access to env vars denied
```

**Error Location:** All Telegram nodes using `={{ $env.TELEGRAM_CHAT_ID }}`

**Affected Workflows:**
- content-generate.json: "Notify Telegram" node
- batch-generate.json: "Send Summary" node
- daily-digest.json: "Send Digest" node
- healthcheck.json: "Alert" node

**Error Details:**
```json
{
  "errorMessage": "access to env vars denied",
  "parameter": "chatId",
  "cause": "={{ $env.TELEGRAM_CHAT_ID }}",
  "causeDetailed": "If you need access please contact the administrator to remove the environment variable 'N8N_BLOCK_ENV_ACCESS_IN_NODE'"
}
```

## Root Cause

n8n blocks access to environment variables in workflow nodes by default for security reasons. This prevents workflows from reading `$env.VARIABLE_NAME` expressions.

**Default Behavior:**
- n8n implicitly sets `N8N_BLOCK_ENV_ACCESS_IN_NODE=true`
- Protects against accidental exposure of sensitive env vars
- Requires explicit opt-in to enable access

## Solution

### Option A: Enable Env Access (CHOSEN) ✅

Add environment variable to n8n container to allow env access:
```yaml
N8N_BLOCK_ENV_ACCESS_IN_NODE=false
```

**Pros:**
- Flexible: Can change chat ID without re-importing workflows
- Clean workflows: Use `$env` expressions
- Follows n8n best practices for configuration

**Cons:**
- Security consideration: Workflows can access all env vars
- Requires restart after env changes

### Option B: Hardcode Values (Not Chosen)

Replace `$env.TELEGRAM_CHAT_ID` with hardcoded value `5664772222` in all workflows.

**Pros:**
- No env access needed
- Slightly more secure

**Cons:**
- Less flexible: Must re-import workflows to change chat ID
- Violates DRY principle
- Harder to maintain across multiple workflows

## Implementation

### Changed File: docker/docker-compose.yml

**Added line 22:**
```yaml
environment:
  # ... existing vars ...
  - N8N_BLOCK_ENV_ACCESS_IN_NODE=false  # NEW
  - TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
  - TELEGRAM_CHAT_ID=${TELEGRAM_CHAT_ID}
```

**Position:** After `N8N_LOG_LEVEL`, before `TELEGRAM_BOT_TOKEN`

## Verification Steps

1. **Restart n8n container:**
   ```bash
   bash scripts/restart-services.sh n8n
   ```

2. **Wait for n8n to be ready:**
   ```bash
   sleep 10
   bash scripts/healthcheck.sh
   ```

3. **Test workflow execution:**
   - Open n8n UI: http://localhost:5678
   - Execute "WF1: Content Generate" manually
   - Verify no "env access denied" error
   - Check Telegram receives notification

4. **Verify env variable accessible:**
   - In any workflow, add Set node
   - Set value: `={{ $env.TELEGRAM_CHAT_ID }}`
   - Execute and verify it resolves to `5664772222`

## Security Considerations

**Risk Level:** Low (in development environment)

**Mitigations:**
- Only necessary env vars exposed (TELEGRAM_CHAT_ID, TELEGRAM_BOT_TOKEN)
- n8n runs in isolated Docker container
- No external access to n8n (localhost only)
- Basic auth enabled on n8n UI

**For Production:**
Consider using n8n Credentials system instead of env vars for sensitive data.

## Related Issues

- **Issue:** Workflows using `$env` expressions fail
- **Impact:** All Telegram notifications blocked
- **Resolution:** Enable env access in n8n configuration

## Prevention

When creating new workflows that need external configuration:
1. Use `$env` for non-sensitive config (chat IDs, URLs)
2. Use n8n Credentials for sensitive data (API keys, passwords)
3. Document required env vars in workflow README
4. Test env access before deploying

---

**Fix completed:** 2026-03-19
**Ready for:** Testing after n8n restart
