# Chinese Novel Translation - Dich truyen Trung -> Viet

> Workflow tu dong dich truyen tieng Trung sang tieng Viet qua Telegram Bot.
> Su dung Qwen2 7B (local LLM) cho chat luong dich Chinese tot nhat.

**Status:** In Development
**Scope:** Tach rieng khoi AI Agent Personal project

---

## Cach dung

```
/translate 阵问长生 1      -> Dich chuong 1 truyen Tran Van Truong Sinh
/translate 阵问长生 1-5    -> Dich chuong 1 den 5
/novel_list                -> Xem danh sach truyen da dang ky
/novel_add <ten> <url>     -> Them truyen moi
```

## Kien truc

```
Telegram Bot
     |
     v
n8n Workflow
     |
     +-- Lookup novel in DB -> Get chapter URL
     +-- WebFetch chapter text (Chinese)
     +-- Split into chunks (~1500 chars each)
     +-- Translate each chunk (Qwen2 7B)
     +-- Combine translated chunks
     +-- Send to Telegram (split if >4096 chars)
```

## Yeu cau

- Docker environment dang chay (n8n, PostgreSQL, Ollama)
- Pull Qwen2 model: `docker exec ollama ollama pull qwen2:7b`
- Import workflow vao n8n
- Chay SQL de tao tables

## Setup

1. Pull Qwen2 model:
   ```bash
   docker exec ollama ollama pull qwen2:7b
   ```

2. Chay SQL schema:
   ```bash
   docker exec -i postgres psql -U postgres -d agent_personal < modules/novel/sql/01-novel-schema.sql
   ```

3. Import workflow vao n8n:
   - Mo http://localhost:5678
   - Workflows -> Import -> `modules/novel/workflows/novel-translate.json`
   - Activate workflow

4. Test:
   - Gui `/translate 阵问长生 1` cho Telegram bot

## Source sites ho tro

| Site | URL Pattern | Status |
|------|-------------|--------|
| Shuhaige | `m.shuhaige.net/{novel_id}/{chapter_id}.html` | Tested |
| Qidian | `qidian.com/book/{id}/` | Can test |

## Glossary tu tien

Xem `glossary/glossary-xianxia.md` cho bang thuat ngu dich chuan.
