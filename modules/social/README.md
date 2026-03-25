# Social Automation Module

Module tu dong hoa noi dung social media cho 3 platforms.

## Platforms
- LinkedIn
- Facebook Tech
- Facebook Chinese

## Workflows (8)
| File | Trigger | Purpose |
|------|---------|---------|
| content-generate.json | Manual | Tao 1 bai |
| batch-generate.json | Cron Mon/Wed/Fri 8AM | Batch 5 bai |
| facebook-post.json | Manual | Dang FB |
| linkedin-post-helper.json | Manual | Gui LI content qua Telegram |
| quiz-generator.json | Manual | Tao quiz |
| auto-comment.json | Cron 30min | Auto-comment dap an |
| data-collector.json | Cron 6AM | Thu thap RSS |
| trending-detector.json | Cron 7AM | Phat hien trending |

## Prompts
Trong `prompts/` directory.
