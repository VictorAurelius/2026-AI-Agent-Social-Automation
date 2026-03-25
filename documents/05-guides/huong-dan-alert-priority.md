# Hướng dẫn: Hệ thống Alert Priority

## Tổng quan

Hệ thống chia notifications thành 3 mức độ ưu tiên để giảm notification noise và đảm bảo không bỏ sót alerts quan trọng.

## 3 mức Priority

### FLASH - Khẩn cấp

**Khi nào:** Hệ thống gặp sự cố nghiêm trọng cần xử lý ngay.

- Ollama, PostgreSQL, hoặc Redis bị down
- Phát hiện security issue
- Workflow failure rate vượt 50%

**Cách hoạt động:**
- Gửi Telegram notification ngay lập tức
- Tự động repeat mỗi 5 phút cho đến khi được acknowledged
- Format: `🔴🔴🔴 FLASH ALERT` + nội dung

**Cách acknowledge:**
- Reply `/ack` trong Telegram bot
- Hoặc update trực tiếp trong DB: `UPDATE alert_log SET acknowledged = true, acknowledged_at = NOW() WHERE id = <alert_id>;`

### PRIORITY - Quan trọng

**Khi nào:** Có kết quả hoặc action cần review, nhưng không khẩn cấp.

- Content batch generation hoàn tất
- Content sẵn sàng để review
- Quiz có câu trả lời mới cần duyệt

**Cách hoạt động:**
- Gửi Telegram notification ngay lập tức
- Không repeat - chỉ gửi 1 lần
- Format: `🟡 PRIORITY` + nội dung

### ROUTINE - Thường xuyên

**Khi nào:** Thông tin cập nhật định kỳ, không cần xử lý ngay.

- Daily digest / báo cáo hàng ngày
- Healthcheck OK
- Stats update
- Auto-comment đã post xong

**Cách hoạt động:**
- Không gửi ngay - lưu vào DB
- Gom tất cả thành 1 digest, gửi 2 lần/ngày:
  - 9:00 AM - digest buổi sáng
  - 6:00 PM - digest buổi chiều
- Format: `🟢` + danh sách tổng hợp

## Mapping với Workflows hiện tại

| Workflow | Tình huống | Level |
|----------|-----------|-------|
| WF5 Healthcheck | Service down | FLASH |
| WF5 Healthcheck | All OK | ROUTINE |
| WF3 Daily Digest | Báo cáo ngày | ROUTINE |
| WF2 Batch Generation | Xong batch | PRIORITY |
| WF6 Telegram Bot | Kết quả generate | PRIORITY |
| WF12 Auto-Comment | Đã comment | ROUTINE |

## Cấu hình

### Thay đổi thời gian digest

Mặc định digest gửi lúc 9AM và 6PM. Để thay đổi, chỉnh cron schedule trong sub-workflow "Routine Digest Collector":

- 9AM: `0 9 * * *`
- 6PM: `0 18 * * *`

### Thay đổi FLASH repeat interval

Mặc định repeat mỗi 5 phút. Chỉnh trong workflow WF5 Healthcheck node "FLASH Repeat Timer".

### Thêm alert mới

Khi thêm alert mới vào bất kỳ workflow nào, sử dụng helper function:

```javascript
// Trong n8n Code node
const level = 'PRIORITY'; // FLASH | PRIORITY | ROUTINE
const title = 'Tiêu đề alert';
const body = 'Chi tiết alert';

// Insert vào alert_log
const query = `
  INSERT INTO alert_log (level, source, title, message)
  VALUES ($1, $2, $3, $4)
`;
await $runQuery(query, [level, 'workflow-name', title, body]);
```

## Troubleshooting

**Q: Không nhận được FLASH alert?**
- Kiểm tra Telegram bot token còn hoạt động
- Kiểm tra chat_id đúng chưa
- Xem logs trong n8n execution history

**Q: Digest không gửi đúng giờ?**
- Kiểm tra timezone của n8n container (phải là Asia/Ho_Chi_Minh)
- Kiểm tra cron trigger đang active

**Q: Muốn tắt repeat cho FLASH?**
- Set acknowledged = true trong DB cho alert đó
- Hoặc reply `/ack` trong Telegram
