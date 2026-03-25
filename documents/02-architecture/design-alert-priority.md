# Thiết kế: Hệ thống Alert theo Priority

## Vấn đề

Tất cả Telegram notifications hiện tại đều giống nhau - không phân biệt urgent vs routine. User bỏ sót alerts quan trọng vì quá nhiều notification.

## Giải pháp: 3 mức priority

### FLASH (Khẩn cấp)

- Ollama/PostgreSQL/Redis down
- Security issue detected
- Workflow failure rate >50%
- Gửi ngay + repeat mỗi 5 phút cho đến khi acknowledged

### PRIORITY (Quan trọng)

- Content ready for review
- Batch generation complete
- Quiz answer due
- Gửi ngay, không repeat

### ROUTINE (Thường xuyên)

- Daily digest
- Healthcheck OK
- Stats update
- Gom thành 1 digest, gửi 2 lần/ngày (9AM + 6PM)

## Implementation

### Notification Helper

Code snippet dùng chung cho tất cả workflows:

```javascript
function sendAlert(level, title, body, chatId) {
  const prefixes = {
    'FLASH': '🔴🔴🔴 *FLASH ALERT*',
    'PRIORITY': '🟡 *PRIORITY*',
    'ROUTINE': '🟢'
  };
  return `${prefixes[level]}\n\n${title}\n\n${body}`;
}
```

### Changes needed in existing workflows

| Workflow | Khi nào | Level |
|----------|---------|-------|
| WF5 Healthcheck | Service unhealthy | FLASH |
| WF5 Healthcheck | All services healthy | ROUTINE |
| WF3 Daily Digest | Daily summary | ROUTINE |
| WF2 Batch | Generation complete | PRIORITY |
| WF6 Telegram Bot | Generate results | PRIORITY |
| WF12 Auto-Comment | Comment posted | ROUTINE |

### Database

```sql
CREATE TABLE IF NOT EXISTS alert_log (
    id SERIAL PRIMARY KEY,
    level VARCHAR(10) CHECK (level IN ('FLASH', 'PRIORITY', 'ROUTINE')),
    source VARCHAR(50),
    title VARCHAR(255),
    message TEXT,
    acknowledged BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Routine Digest Collector (n8n sub-workflow)

- Collect ROUTINE alerts trong ngày vào bảng `alert_log`
- Combine thành single digest lúc 9AM và 6PM
- Giảm notification noise đáng kể
- Chỉ gửi FLASH và PRIORITY ngay lập tức

### Flow xử lý

```
Alert phát sinh
  ├── FLASH   → Gửi Telegram ngay → Log DB → Schedule repeat 5 phút
  ├── PRIORITY → Gửi Telegram ngay → Log DB
  └── ROUTINE  → Log DB → Chờ digest (9AM / 6PM)
```

## Lợi ích

1. Giảm notification fatigue - chỉ bị ping khi thực sự cần
2. Không bỏ sót FLASH alerts nhờ repeat mechanism
3. ROUTINE alerts gom lại giúp review dễ hơn
4. Alert log trong DB giúp audit và debug
