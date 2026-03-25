# Bug Fix: Container Recreate Required for Environment Variables

**Date:** 2026-03-19
**Severity:** Medium (Operational Knowledge)
**Status:** ✅ Resolved

---

## Problem

After adding `N8N_BLOCK_ENV_ACCESS_IN_NODE=false` to docker-compose.yml and restarting n8n, the error persisted:
```
access to env vars denied
```

**Root Cause:**
Docker container restart (`docker-compose restart`) does NOT reload environment variables from docker-compose.yml. It only restarts the existing container with its original configuration.

## Why Restart Doesn't Work

**Docker Container Lifecycle:**
1. **Create:** Container created with environment variables from compose file
2. **Start:** Container starts with stored configuration
3. **Stop:** Container stops but keeps configuration
4. **Restart:** Container starts again with SAME configuration (no reload from compose file)

**To apply new environment variables, container must be recreated:**
1. Stop container
2. **Remove container** (removes old configuration)
3. Create NEW container (reads updated compose file)
4. Start new container (with new environment variables)

## Solution

### Option A: Recreate Specific Service ✅ CHOSEN

Created `scripts/recreate-service.sh` to recreate individual services:

```bash
bash scripts/recreate-service.sh n8n
```

**What it does:**
1. `docker-compose stop n8n` - Stop container
2. `docker-compose rm -f n8n` - Remove container
3. `docker-compose up -d n8n` - Create and start new container

**Pros:**
- Precise: Only recreates specified service
- Fast: Other services keep running
- Safe: Data persists in volumes

### Option B: Recreate All Services

```bash
cd docker
docker-compose down
docker-compose up -d
```

**Pros:**
- Ensures all services have latest config

**Cons:**
- Slower: Stops and recreates all services
- Overkill: Not needed for single service change

## Files Changed

### 1. scripts/recreate-service.sh (NEW)

**Purpose:** Recreate Docker service with updated environment variables

**Usage:**
```bash
bash scripts/recreate-service.sh <service_name>
```

**Features:**
- Validates service name parameter
- Shows warning about recreation
- Stops, removes, and recreates container
- Provides status check instructions

**Example:**
```bash
bash scripts/recreate-service.sh n8n
# Recreates n8n container with updated env vars
```

## Verification

### Before Fix:
```bash
# Restart doesn't load new env vars
bash scripts/restart-services.sh n8n
docker exec n8n env | grep N8N_BLOCK_ENV_ACCESS_IN_NODE
# Output: (nothing) - env var not loaded
```

### After Fix:
```bash
# Recreate loads new env vars
bash scripts/recreate-service.sh n8n
docker exec n8n env | grep N8N_BLOCK_ENV_ACCESS_IN_NODE
# Output: N8N_BLOCK_ENV_ACCESS_IN_NODE=false ✅
```

## When to Use Each Script

### restart-services.sh
Use when:
- Service crashed and needs restart
- Config file changes (workflow imports, credentials)
- Quick restart without env var changes

### recreate-service.sh
Use when:
- Environment variables changed in docker-compose.yml
- Docker image updated (need to pull new image)
- Container configuration changed (ports, volumes, etc.)
- Service behaving unexpectedly (fresh start)

## Lesson Learned

**Key Insight:**
> Docker restart ≠ Docker recreate

**Remember:**
- Restart: Quick, keeps config
- Recreate: Reloads config from compose file

**General Rule:**
- Changed code/data: restart is enough
- Changed docker-compose.yml: recreate required

## Related

- Original issue: `bugfix-2026-03-19-n8n-env-access.md`
- PR #3: Added N8N_BLOCK_ENV_ACCESS_IN_NODE=false
- This fix: Made env var actually take effect

---

**Fix completed:** 2026-03-19
**Workflow should now work:** Test Telegram notifications
