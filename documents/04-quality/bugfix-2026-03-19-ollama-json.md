# Bug Fix: Ollama JSON Body Invalid Expression

**Date:** 2026-03-19
**Severity:** High (blocks content generation)
**Status:** Fixed

---

## Problem

Workflows `content-generate` and `batch-generate` failed with error:
```
JSON parameter needs to be valid JSON
```

**Error Location:** Node "Call Ollama" → HTTP Request → JSON Body

**Root Cause:**
Incorrect n8n expression syntax in jsonBody. Used template strings `{{ $json.field }}` inside JSON which is invalid when using `=` prefix.

**Incorrect Code (line 64 in content-generate.json):**
```json
"jsonBody": "={
  \"model\": \"llama3.1:8b\",
  \"messages\": [
    {\"role\": \"system\", \"content\": \"{{ $json.system_prompt }}\"},
    {\"role\": \"user\", \"content\": \"{{ $json.user_prompt }}\"}
  ],
  \"stream\": false
}"
```

## Solution

**Correct n8n expression syntax:** When using `=` prefix, expressions should be direct JavaScript, not template strings.

**Fixed Code:**
```json
"jsonBody": "={{ {
  \"model\": \"llama3.1:8b\",
  \"messages\": [
    {\"role\": \"system\", \"content\": $json.system_prompt},
    {\"role\": \"user\", \"content\": $json.user_prompt}
  ],
  \"stream\": false
} }}"
```

**Changes:**
- Wrap entire JSON in `{{ }}`
- Remove quotes around `$json.field` expressions
- Remove `{{ }}` inside field values

## Files Changed

1. `modules/social/workflows/content-generate.json` - Line 64
2. `modules/social/workflows/batch-generate.json` - Line 73

## Verification Steps

1. Re-import workflows to n8n
2. Execute "WF1: Content Generate" workflow
3. Verify:
   - No JSON errors
   - Ollama receives valid request
   - Content is generated successfully
   - Database insert succeeds

## Testing

**Test Command:**
```bash
# After re-importing workflow in n8n UI
# Execute workflow and check output
bash scripts/healthcheck.sh
```

**Expected Result:**
- Workflow executes without errors
- Content appears in database with status "pending_review"
- Telegram notification sent (if configured)

## Prevention

- Use n8n expression editor to validate JSON syntax
- Test with manual trigger before activating cron workflows
- Reference: n8n docs on expressions vs template strings
