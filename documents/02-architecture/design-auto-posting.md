# Thiết kế: Workflows Đăng bài Tự động

## Tổng quan

Hiện tại hệ thống chỉ TẠO nội dung, chưa có workflow ĐĂNG BÀI. Document này thiết kế workflows đăng bài cho LinkedIn và Facebook.

## Phân tích từng Platform

### Facebook (Meta Graph API) - Dễ nhất

- API: `POST https://graph.facebook.com/v18.0/{page-id}/feed`
- Cần: Page Access Token (long-lived, 60 ngày)
- Hỗ trợ: Text, image, link, scheduled post
- Rate limit: 50 posts/day/page
- Setup: Tạo Facebook App → Get Page Token

### LinkedIn - Phức tạp hơn

- API: Posts API v2
- Cần: Apply Marketing Developer Platform (chờ approve vài tuần)
- Thay thế tạm: Manual posting qua Telegram Bot
- Rate limit: 500 requests/day

### Chiến lược triển khai

| Giai đoạn | Platform | Phương pháp |
|-----------|----------|-------------|
| Phase 1 | Facebook | Auto-post qua Meta Graph API |
| Phase 2 | LinkedIn | Manual (copy từ Telegram Bot) |
| Phase 3 | LinkedIn | API (khi được approve) |

## WF7: Facebook Auto-Post

### Sơ đồ luồng

```
[Manual/Cron Trigger]
       │
       ▼
[Get Approved Content] ── SELECT WHERE status='approved' AND platform LIKE 'facebook%'
       │
       ▼
[Has Content?]
       │
       ├── YES ──► [Post to Facebook] ── POST Meta Graph API
       │                  │
       │                  ├── Success ──► [Update status='published'] → [Telegram: "Đã đăng!"]
       │                  └── Error ──► [Log Error] → [Telegram: "Lỗi đăng bài!"]
       │
       └── NO ──► [Telegram: "Không có bài approved"]
```

### Yêu cầu setup

1. Tạo Facebook App tại developers.facebook.com
2. Thêm product "Facebook Login"
3. Lấy Page Access Token (long-lived)
4. Thêm vào infrastructure/docker/.env:
   ```
   FACEBOOK_PAGE_ID=your_page_id
   FACEBOOK_PAGE_TOKEN=your_long_lived_token
   ```
5. Recreate n8n container: `docker-compose up -d --force-recreate n8n`

### Security
- Token PHẢI lưu trong .env, KHÔNG commit vào git
- Page tokens cần renew mỗi 60 ngày
- Rate limiting: Không đăng quá 5 bài/ngày/page

## WF8: LinkedIn Post Helper

### Sơ đồ luồng

```
[Manual Trigger hoặc Telegram /post_linkedin]
       │
       ▼
[Get Approved LinkedIn Content]
       │
       ▼
[Has Content?]
       │
       ├── YES ──► [Format for LinkedIn] → [Send to Telegram]
       │              Gửi nội dung + hướng dẫn:
       │              "1. Copy nội dung trên
       │               2. Mở LinkedIn → Create a post
       │               3. Paste và đăng
       │               4. Dùng /published <id> <url>"
       │
       └── NO ──► [Telegram: "Không có bài LinkedIn approved"]
```

### Lý do dùng manual posting

- LinkedIn API cần approval process (vài tuần)
- Personal profile posting giới hạn hơn Page posting
- Manual posting an toàn hơn, tránh bị flag spam
- Có thể chuyển sang API sau khi được approve

## Kế hoạch triển khai

### Week 1: Facebook Auto-Post
- [ ] Tạo Facebook App
- [ ] Lấy Page Access Token
- [ ] Import WF7 vào n8n
- [ ] Test với draft post
- [ ] Enable auto-posting

### Week 2: LinkedIn Helper
- [ ] Import WF8 vào n8n
- [ ] Test manual posting flow
- [ ] Apply LinkedIn Marketing API (for future)

### Week 3: Monitoring
- [ ] Theo dõi posting success rate
- [ ] Monitor engagement
- [ ] Optimize timing
