# Thiet ke: Workflow Dich Truyen Trung -> Viet

**Created:** 2026-03-19
**Status:** Proposed
**Goal:** Tu dong dich truyen tieng Trung sang tieng Viet qua Telegram Bot

---

## 1. Tong quan

### Use case
User gui lenh `/translate 阵问长生 1` -> Bot tu dong:
1. Tim truyen trong database
2. Fetch noi dung chuong tu web
3. Dich Trung -> Viet bang Qwen2 7B
4. Gui ket qua qua Telegram

### Tai sao Qwen2 7B?
- Duoc train nhieu du lieu Chinese hon Llama
- Hieu ngu canh van hoc Chinese tot hon
- Ho tro ca simplified va traditional Chinese
- Kich thuoc tuong duong Llama 8B (~4.4GB)

## 2. Database Design

### Bang novel_registry
Luu thong tin truyen da dang ky.

```sql
CREATE TABLE novel_registry (
    id SERIAL PRIMARY KEY,
    title_cn VARCHAR(255) NOT NULL,      -- 阵问长生
    title_vn VARCHAR(255),               -- Tran Van Truong Sinh
    author VARCHAR(100),                 -- 观虚
    source_site VARCHAR(50),             -- shuhaige
    base_url VARCHAR(500),               -- https://m.shuhaige.net/230050/
    chapter_list_url VARCHAR(500),       -- URL to chapter list page
    total_chapters INTEGER,
    genre VARCHAR(50),                   -- xianxia, wuxia, etc.
    glossary_id INTEGER,                 -- link to custom glossary
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Bang translation_history
Luu lich su dich de khong dich lai.

```sql
CREATE TABLE translation_history (
    id SERIAL PRIMARY KEY,
    novel_id INTEGER REFERENCES novel_registry(id),
    chapter_number INTEGER NOT NULL,
    chapter_title VARCHAR(255),
    source_url VARCHAR(500),
    original_text TEXT,
    translated_text TEXT,
    model_used VARCHAR(50) DEFAULT 'qwen2:7b',
    translation_time_ms INTEGER,
    char_count INTEGER,
    status VARCHAR(20) DEFAULT 'completed',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(novel_id, chapter_number)
);
```

### Bang translation_glossary
Bang thuat ngu tuy chinh theo the loai.

```sql
CREATE TABLE translation_glossary (
    id SERIAL PRIMARY KEY,
    genre VARCHAR(50),           -- xianxia, wuxia, modern
    term_cn VARCHAR(100),        -- 金丹
    term_vn VARCHAR(100),        -- Kim Dan
    pinyin VARCHAR(100),         -- jin dan
    category VARCHAR(50),        -- cultivation, weapon, title
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## 3. Source Site Scraping

### Shuhaige.net (da test thanh cong)

**Chapter list:**
```
GET https://m.shuhaige.net/{novel_id}/
-> Parse HTML -> Extract chapter links
-> Pattern: /230050/{chapter_id}.html
```

**Chapter content:**
```
GET https://m.shuhaige.net/{novel_id}/{chapter_id}.html
-> Extract text between content markers
-> Clean: remove ads, navigation, scripts
```

### URL Resolution Flow

```
Input: novel_name="阵问长生", chapter=1
    |
    v
Query novel_registry WHERE title_cn = '阵问长生'
    |
    v
Got base_url = "https://m.shuhaige.net/230050/"
    |
    v
Fetch chapter list page -> Parse -> Get chapter 1 URL
    |
    v
Got: https://m.shuhaige.net/230050/85312323.html
    |
    v
Fetch chapter content -> Clean -> Return text
```

## 4. Translation Strategy

### System Prompt

```
你是一位专业的中越文学翻译家，专注于仙侠/玄幻小说翻译。

翻译要求：
1. 保持原文的文学风格和韵味
2. 人称代词统一：他->han（男主/反派）, 她->nang（女性）, 它->no
3. 使用下方术语表翻译专有名词
4. 保留原文的段落结构
5. 不添加任何解释或注释
6. 翻译成自然流畅的越南语

术语表：
修炼 -> tu luyen
真气 -> chan khi
灵石 -> linh thach
丹田 -> dan dien
金丹 -> Kim Dan
元婴 -> Nguyen Anh
化神 -> Hoa Than
渡劫 -> Do Kiep
筑基 -> Truc Co
炼气 -> Luyen Khi
功法 -> cong phap
法器 -> phap khi
阵法 -> tran phap
灵根 -> linh can
经脉 -> kinh mach
[...more terms loaded from glossary DB]
```

### Chunking Strategy

```
Chapter text (~3000-5000 Chinese chars)
    |
    v
Split by paragraphs (\n\n)
    |
    v
Combine paragraphs into chunks of ~1500 chars
(never split mid-paragraph)
    |
    v
Translate each chunk separately
    |
    v
Combine translated chunks
```

### 2-Pass Translation (Optional, higher quality)

```
Pass 1: Direct translation (Qwen2)
    -> Ban dich tho, dung nghia

Pass 2: Polish (Qwen2 hoac Llama)
    -> Input: ban dich tho + original
    -> Prompt: "Chinh sua ban dich cho tu nhien hon, giu nguyen nghia"
    -> Output: Ban dich polish
```

## 5. Telegram Integration

### Commands

| Lenh | Mo ta | Vi du |
|------|-------|-------|
| `/translate <ten> <chuong>` | Dich 1 chuong | `/translate 阵问长生 1` |
| `/translate <ten> <from>-<to>` | Dich nhieu chuong | `/translate 阵问长生 1-5` |
| `/novel_list` | Danh sach truyen | |
| `/novel_add <ten_cn> <url>` | Dang ky truyen moi | `/novel_add 阵问长生 https://m.shuhaige.net/230050/` |
| `/novel_info <ten>` | Thong tin truyen | `/novel_info 阵问长生` |
| `/glossary <ten> <cn> <vn>` | Them thuat ngu | `/glossary xianxia 金丹 Kim Dan` |
| `/history <ten>` | Xem chuong da dich | `/history 阵问长生` |

### Output Format

```
*阵问长生 - Tran Van Truong Sinh*
*Chuong 1: Mac Hoa*
Tac gia: Quan Hu (观虚)

---

Dao lich hai van khong tram hai muoi hai nam, thang chin mung muoi.
Thong Tien Thanh, ngoai son Thong Tien Mon.

Mac Hoa muoi tuoi mac dao bao de tu ngoai mon gian di,
chan nan ngoi xom sau mot tang da lon duoi chan nui,
tay cam re co, cui dau ve nhung duong van phuc tap tren mat dat.

[... tiep tuc ...]

---
3,200 chu | 45 giay | Qwen2 7B
```

**Telegram limit:** Neu >4096 chars, chia thanh messages:
- Message 1: Header + phan 1
- Message 2-N: Tiep theo
- Message cuoi: Footer voi stats

## 6. Caching

Chuong da dich luu trong `translation_history` -> khong dich lai.
```
/translate 阵问长生 1
    -> Check DB: da dich chua?
    -> YES: Tra ve tu cache (instant)
    -> NO: Fetch + Translate + Save + Reply
```

## 7. Performance Estimate

| Metric | Gia tri |
|--------|---------|
| Thoi gian dich 1 chuong | 30-60 giay |
| Thoi gian fetch | 2-3 giay |
| RAM can them (Qwen2) | ~4-5GB |
| Total RAM (Llama + Qwen2) | ~13-15GB |
| Telegram response | 5-10 giay (tu cache) |

## 8. Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Site thay doi structure | High | Ho tro multiple sources |
| Site block scraping | Medium | User-Agent rotation, rate limit |
| Qwen2 + Llama cung luc OOM | High | Chi load 1 model tai 1 thoi diem |
| Dich sai thuat ngu | Medium | Glossary + human review |
| Chuong qua dai | Low | Chunking strategy |

## 9. Ke hoach trien khai

### Phase 1: MVP (Week 1)
- DB schema + glossary xianxia
- Workflow: fetch + translate + reply
- Telegram: /translate command
- Test voi 阵问长生 chuong 1-5

### Phase 2: Features (Week 2)
- Multi-chapter: /translate 1-10
- Caching (khong dich lai)
- /novel_add, /novel_list
- 2-pass translation

### Phase 3: Polish (Week 3)
- Multiple source sites
- Custom glossary per novel
- Translation quality scoring
- Batch download (save as TXT)
