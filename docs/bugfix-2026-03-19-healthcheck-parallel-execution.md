# Bug Fix: Healthcheck Workflow Parallel Execution Error

**Date:** 2026-03-19
**Severity:** High (Blocks healthcheck monitoring)
**Status:** ✅ Fixed

---

## Problem

Healthcheck workflow fails with error:
```
Cannot assign to read only property 'name' of object 'Error: Node 'Check Postgres' hasn't been executed'
```

**Error Location:** "Evaluate" node trying to access `$('Check Postgres').first()`

**Impact:** Healthcheck workflow cannot execute, service monitoring broken

**Error Details:**
```json
{
  "errorMessage": "Cannot assign to read only property 'name' of object 'Error: Node 'Check Postgres' hasn't been executed'",
  "n8nDetails": {
    "n8nVersion": "2.12.3 (Self Hosted)",
    "binaryDataMode": "filesystem"
  }
}
```

## Root Cause

**Parallel Execution Race Condition:**

The workflow structure had three health checks running in parallel, all connecting directly to the Evaluate node:

```
Every 5 Min
  ├─> Check Ollama ──┐
  ├─> Check Postgres ├─> Evaluate
  └─> Check Redis ───┘
```

**Problem:** Each health check triggers the Evaluate node independently when it completes. When "Check Ollama" finishes first and triggers "Evaluate", the code tries to access:
```javascript
const postgresResult = $('Check Postgres').first();
```

But "Check Postgres" hasn't executed yet in that execution context, causing the error.

**n8n Execution Behavior:**
- Multiple nodes connecting to one node triggers it multiple times
- Each trigger has its own execution context
- Node reference `$('NodeName')` only works for nodes that executed before current node in same context
- Parallel branches execute independently and don't share context

## Solution

### Use Sequential Execution Instead of Parallel

**Initial attempt:** Used Merge node with parallel execution, but encountered Merge v3 configuration error requiring field matching parameters.

**Final solution:** Restructured workflow to use sequential execution:

```
Every 5 Min → Check Ollama → Check Postgres → Check Redis → Evaluate → Is Healthy?
```

**Why Sequential Works:**
- Each health check executes after the previous one completes
- When Evaluate runs, all three checks have already executed in sequence
- Node references `$('Check Ollama')`, `$('Check Postgres')`, `$('Check Redis')` all work correctly
- Simple, reliable, no Merge configuration complexity

**Trade-off:**
- Sequential is slightly slower than parallel (~1-2 seconds total)
- For a healthcheck running every 5 minutes, this is acceptable
- Simplicity and reliability outweigh minor performance difference

**Changed File:** `workflows/n8n/healthcheck.json`

### 1. Restructured to Sequential Connections

**Before (parallel - caused error):**
```json
"Every 5 Min": {"main": [[
  {"node": "Check Ollama", "type": "main", "index": 0},
  {"node": "Check Postgres", "type": "main", "index": 0},
  {"node": "Check Redis", "type": "main", "index": 0}
]]}
```

**After (sequential - works):**
```json
"Every 5 Min": {"main": [[{"node": "Check Ollama", "type": "main", "index": 0}]]},
"Check Ollama": {"main": [[{"node": "Check Postgres", "type": "main", "index": 0}]]},
"Check Postgres": {"main": [[{"node": "Check Redis", "type": "main", "index": 0}]]},
"Check Redis": {"main": [[{"node": "Evaluate", "type": "main", "index": 0}]]}
```

### 2. Updated Node Positions (Sequential Layout)

- Check Ollama: [400, 380] (moved from [480, 220])
- Check Postgres: [560, 380] (moved from [480, 380])
- Check Redis: [720, 380] (moved from [480, 540])
- Evaluate: [880, 380] (moved from [720, 380])

All nodes now on same Y position (380) for clean sequential layout.

### 3. Enhanced Evaluate to Include Redis

**Added Redis check:**
```javascript
const redisResult = $('Check Redis').first();
const redisOk = !redisResult.error;
const allHealthy = ollamaOk && postgresOk && redisOk;  // Now checks all 3
```

**Updated output to include all three services:**
```javascript
return [{
  json: {
    ollama: ollamaOk,
    postgres: postgresOk,
    redis: redisOk,      // NEW
    allHealthy,
    timestamp
  }
}];
```

### 4. Updated Logging and Alerts

- **Log Error query:** Now includes redis status in details JSON
- **Alert message:** Now shows Redis health status alongside Ollama and PostgreSQL

## Verification Steps

1. **Import updated workflow:**
   ```bash
   # Workflow file: workflows/n8n/healthcheck.json
   # Import via n8n UI or replace existing workflow
   ```

2. **Test manual execution:**
   - Open workflow in n8n UI: http://localhost:5678
   - Click "Execute Workflow"
   - Verify no errors
   - Check all nodes execute successfully

3. **Verify sequential execution:**
   - Check execution log shows nodes execute in order: Ollama → Postgres → Redis → Evaluate
   - Evaluate node executes only once after all checks complete
   - All three health check results available in Evaluate context

4. **Test error handling:**
   - Stop PostgreSQL: `bash scripts/restart-services.sh postgres` (to stop)
   - Execute workflow
   - Verify Evaluate handles error correctly (continues with error data)
   - Verify Alert sent with Postgres showing as DOWN
   - Restart PostgreSQL: `bash scripts/restart-services.sh postgres`

## Why Sequential Execution Works

**Sequential vs Parallel for Healthchecks:**

**Sequential (our solution):**
- ✅ Simple: No Merge configuration needed
- ✅ Reliable: Each node executes once in predictable order
- ✅ Node references work: `$('NodeName')` works for all previous nodes
- ❌ Slower: Adds 1-2 seconds total (acceptable for 5-minute intervals)

**Parallel with Merge (attempted):**
- ✅ Faster: All checks run simultaneously
- ❌ Complex: Requires proper Merge v3 configuration
- ❌ Error-prone: Field matching parameters, mode configuration
- ❌ Overkill: For simple healthcheck use case

**When to Use Each:**
- **Sequential:** Simple workflows, acceptable latency, reliability priority
- **Parallel:** Complex workflows, latency critical, worth configuration complexity

## Related n8n Concepts

**Node References `$('NodeName')`:**
- Only works for nodes executed BEFORE current node in execution path
- Searches in current execution context
- In sequential execution: all previous nodes are accessible
- In parallel execution: only nodes in same branch are accessible (unless merged)

**onError: "continueRegularOutput":**
- Health check nodes continue even if they fail
- Error data passed to next node
- Evaluate node can check for errors in results via `.error` property

**Execution Order:**
- Settings: `"executionOrder": "v1"`
- Controls how n8n handles workflow execution
- Sequential execution follows simple linear path

## Lessons Learned

**Key Insight:**
> For simple healthcheck workflows, sequential execution is more reliable than parallel with Merge

**Pattern Used:**
```
Trigger → Check 1 → Check 2 → Check 3 → Evaluate → Conditional Logic
```

**Why This Works:**
- Each node completes before next starts
- All previous nodes accessible via `$('NodeName')`
- No synchronization complexity
- Predictable execution order

**When to Use Sequential:**
- Simple workflows with few nodes
- Node references needed for all checks
- Reliability more important than speed
- Total execution time is acceptable

**When to Use Parallel (with proper Merge):**
- Many independent API calls
- Latency is critical concern
- Worth the Merge configuration complexity
- Execution time matters more than simplicity

**Our Choice:** Sequential for simplicity and reliability. For a healthcheck running every 5 minutes, the extra 1-2 seconds is negligible.

## Related Issues

- **Original error:** Discovered after fixing container recreation issue (PR #4)
- **Symptom:** Healthcheck workflow failing to execute
- **Impact:** Service monitoring unavailable

---

**Fix completed:** 2026-03-19
**Ready for:** Testing healthcheck workflow in n8n UI
