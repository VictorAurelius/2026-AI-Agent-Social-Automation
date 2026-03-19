# Thiết kế: Telegram Bot Tương tác

## Tổng quan

Nâng cấp Telegram Bot từ **chỉ thông báo** thành **tương tác 2 chiều**, cho phép user điều khiển hệ thống qua lệnh Telegram.

## Kiến trúc hiện tại vs Đề xuất

```
HIỆN TẠI (1 chiều):
  n8n Workflow → Telegram Bot → User (chỉ nhận thông báo)

ĐỀ XUẤT (2 chiều):
  User ←→ Telegram Bot ←→ n8n ←→ Ollama/PostgreSQL

  User gửi lệnh → Bot nhận → n8n xử lý → Bot trả kết quả
```

## Danh sách lệnh

### Lệnh tạo nội dung
| Lệnh | Mô tả | Ví dụ |
|-------|--------|-------|
| `/generate <topic>` | Tạo 1 bài viết LinkedIn | `/generate AI tools cho developers` |
| `/generate_fb <topic>` | Tạo bài Facebook Tech | `/generate_fb Docker containers explained` |
| `/batch` | Trigger batch generate ngay | `/batch` |

### Lệnh quản lý nội dung
| Lệnh | Mô tả | Ví dụ |
|-------|--------|-------|
| `/status` | Xem thống kê content queue | `/status` |
| `/pending` | Liệt kê bài chờ review | `/pending` |
| `/view <id>` | Xem nội dung đầy đủ | `/view 15` |
| `/approve <id>` | Duyệt bài viết | `/approve 15` |
| `/reject <id> <lý do>` | Từ chối bài viết | `/reject 15 cần thêm ví dụ` |

### Lệnh quản lý topics
| Lệnh | Mô tả | Ví dụ |
|-------|--------|-------|
| `/topics` | Xem topics chưa dùng | `/topics` |
| `/addtopic <topic>\|<pillar>\|<priority>` | Thêm topic mới | `/addtopic AI trends\|tech_insights\|3` |

### Lệnh hệ thống
| Lệnh | Mô tả |
|-------|--------|
| `/health` | Kiểm tra sức khỏe hệ thống |
| `/help` | Hiển thị danh sách lệnh |

## Workflow mới: WF6 Telegram Bot

### Sơ đồ

```
[Telegram Trigger] ── Nhận message từ user
       │
       ▼
[Extract Command] ── Parse lệnh và tham số
       │
       ▼
[Switch/Router] ── Phân loại lệnh
       │
       ├── /generate → [Get Prompt] → [Ollama] → [Save DB] → [Reply]
       ├── /status → [Query Stats] → [Format] → [Reply]
       ├── /pending → [Query Pending] → [Format] → [Reply]
       ├── /view → [Query Content] → [Format] → [Reply]
       ├── /approve → [Update Status] → [Reply]
       ├── /reject → [Update Status] → [Reply]
       ├── /topics → [Query Topics] → [Format] → [Reply]
       ├── /addtopic → [Insert Topic] → [Reply]
       ├── /health → [Check Services] → [Reply]
       └── /help → [Reply Help Text]
```

### Chi tiết kỹ thuật

#### Telegram Trigger Node
- Type: `n8n-nodes-base.telegramTrigger`
- Updates: `message`
- Nhận mọi tin nhắn gửi đến bot

#### Extract Command (Code Node)
```javascript
const message = $json.message.text || '';
const parts = message.split(' ');
const command = parts[0].toLowerCase();
const args = parts.slice(1).join(' ');
const chatId = $json.message.chat.id;

return { command, args, chatId, rawMessage: message };
```

#### Switch Node
- Route theo giá trị `command`
- Mỗi route xử lý 1 lệnh cụ thể

#### Response Format
Tất cả response dùng Markdown, gửi về cùng chat_id

### Ví dụ Response

#### `/generate AI tools`
```
🤖 Đang tạo nội dung...

📝 *Kết quả:*

[Nội dung bài viết đầy đủ ở đây]

---
📋 ID: #23
📌 Platform: LinkedIn
🏷️ Pillar: tech_insights
⏳ Status: pending_review

Dùng `/approve 23` để duyệt hoặc `/reject 23 <lý do>` để từ chối.
```

#### `/status`
```
📊 *Content Queue Status*

• Draft: 2
• ⏳ Pending Review: 5
• ✅ Approved: 3
• 📅 Scheduled: 1
• 🚀 Published: 12
• ❌ Rejected: 2

📝 Unused Topics: 7

Dùng `/pending` để xem chi tiết bài chờ review.
```

#### `/view 15`
```
📄 *Content #15*

*Title:* AI đang thay đổi cách developers làm việc
*Platform:* LinkedIn
*Pillar:* tech_insights
*Status:* pending_review
*Created:* 2026-03-19 08:30

---

[Nội dung đầy đủ bài viết]

---

✅ `/approve 15` | ❌ `/reject 15 <lý do>`
```

## Yêu cầu kỹ thuật

### n8n Configuration
- Cần Telegram Trigger node (khác với Telegram Send node)
- Bot phải được set commands qua BotFather: `/setcommands`
- Workflow phải luôn ACTIVE để nhận messages

### BotFather Commands Setup
```
generate - Tạo bài viết LinkedIn từ chủ đề
generate_fb - Tạo bài viết Facebook từ chủ đề
batch - Chạy batch generate ngay
status - Xem thống kê content queue
pending - Liệt kê bài chờ review
view - Xem nội dung đầy đủ (dùng: /view ID)
approve - Duyệt bài viết (dùng: /approve ID)
reject - Từ chối bài (dùng: /reject ID lý do)
topics - Xem danh sách topics chưa dùng
addtopic - Thêm topic mới
health - Kiểm tra sức khỏe hệ thống
help - Hiển thị trợ giúp
```

### Security
- Chỉ cho phép chat_id của owner tương tác
- Reject mọi message từ chat_id khác
- Log tất cả commands vào workflow_logs

## Ưu tiên triển khai

### Phase 1 (MVP):
- `/generate`, `/status`, `/pending`, `/help`

### Phase 2:
- `/view`, `/approve`, `/reject`

### Phase 3:
- `/topics`, `/addtopic`, `/health`, `/batch`
