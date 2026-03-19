# Thiết kế: Chiến lược Test Automation

**Created:** 2026-03-19
**Status:** Proposed
**Goal:** Chuyển từ reactive (deploy → bug → fix) sang proactive (test → validate → deploy)

---

## 1. Vấn đề hiện tại

### Approach cũ: Reactive
```
Code → Deploy → Phát hiện lỗi → Fix → Deploy lại
```

**Hậu quả đã gặp (PRs #1-#6):**
- PR #2: SQL injection trong content insert (security)
- PR #3: n8n không truy cập env vars (configuration)
- PR #5→#6: Healthcheck parallel execution fail (logic)
- PR #1: Commit trực tiếp lên main (process)

### Approach mới: Proactive
```
Code → Validate → Test → Review → Deploy
```

## 2. Các layer cần test

### Layer 1: Workflow JSON Validation
**Mục đích:** Đảm bảo workflow JSON hợp lệ trước khi import vào n8n

Kiểm tra:
- JSON syntax valid
- Tất cả nodes có `id`, `name`, `type`
- Tất cả connections trỏ đến nodes tồn tại
- Credentials referenced đúng format
- Không có nodes orphan (không connected)

### Layer 2: SQL Validation
**Mục đích:** Đảm bảo SQL scripts chạy không lỗi

Kiểm tra:
- SQL syntax valid
- Tables/columns exist trước khi ALTER
- INSERT không duplicate (ON CONFLICT handling)
- Foreign key constraints satisfied
- Indexes không trùng

### Layer 3: Prompt Quality Test
**Mục đích:** Đảm bảo Ollama prompts tạo output chất lượng

Kiểm tra:
- Prompt tạo được response (không timeout)
- Response đúng format (JSON nếu required)
- Response đúng ngôn ngữ (Vietnamese)
- Response đủ dài (không quá ngắn/dài)
- Không có AI artifacts ("As an AI...")

### Layer 4: Integration Test
**Mục đích:** Test end-to-end flow

Kiểm tra:
- n8n → Ollama API connectivity
- n8n → PostgreSQL connectivity
- Content generation → DB insert → query
- Telegram notification delivery

### Layer 5: Security Test
**Mục đích:** Đảm bảo không có lỗ hổng bảo mật

Kiểm tra:
- SQL injection trong tất cả user inputs
- Environment variables không bị leak
- API tokens không hardcode
- Telegram bot chỉ respond owner

## 3. Test Scripts

### Script 1: validate-workflows.sh
Validate tất cả workflow JSON files.

### Script 2: validate-sql.sh
Validate tất cả SQL init scripts.

### Script 3: test-prompts.sh
Test prompt quality với Ollama (cần Docker).

### Script 4: test-integration.sh
Test end-to-end connectivity (cần Docker).

### Script 5: test-security.sh
Scan cho SQL injection patterns.

## 4. CI Pipeline (Future)

```
git push → GitHub Actions:
  1. validate-workflows.sh (no Docker needed)
  2. validate-sql.sh (no Docker needed)
  3. test-security.sh (no Docker needed)
  4. test-prompts.sh (needs Docker - optional)
  5. test-integration.sh (needs Docker - optional)
```

## 5. Khi nào chạy tests

| Event | Tests |
|-------|-------|
| Trước mỗi commit | validate-workflows, validate-sql |
| Trước mỗi PR | Tất cả validation tests |
| Sau mỗi deploy | test-integration |
| Hàng tuần | test-prompts (quality check) |

## 6. Kế hoạch triển khai

### Phase 1: Validation Scripts (ngay)
- validate-workflows.sh
- validate-sql.sh
- test-security.sh

### Phase 2: Integration Tests (khi có Docker)
- test-prompts.sh
- test-integration.sh

### Phase 3: CI/CD (future)
- GitHub Actions workflow
- Auto-run on PR
