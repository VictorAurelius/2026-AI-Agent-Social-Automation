# Book Translation Module - Design Spec

**Created:** 2026-03-27
**Status:** Proposed
**Goal:** He thong dich sach tieng Anh chuyen sau voi Claude lam translator, quy trinh review co cau truc, memory tich luy, scripts Python render DOCX
**Prerequisites:** Claude Code Max plan active, Python 3.10+

---

## 1. Van de

### 1.1 Context
User da co kinh nghiem dich sach (du an Alfred Adler "What Life Should Mean to You") voi 2 prompt dich chi tiet (DICH_PROMPT_1.txt, DICH_PROMPT_2.txt). Quy trinh cu thieu:
- Khong co state tracking (khong biet dich den dau)
- Khong luu feedback (moi lan phai nhac lai)
- Khong co glossary management tu dong
- Khong co pipeline extract input → render output

### 1.2 Yeu cau
- Dich chuyen sau, it cuon nhung chat luong van chuong cao
- Claude Code lam translator truc tiep ($0/month)
- Quy trinh review cuc bo (per-chapter) + toan phan (full book)
- Memory tich luy glossary + style feedback + translation patterns qua cac sach
- Scripts Python: extract PDF/EPUB → markdown, render markdown → DOCX mirror format goc

### 1.3 Approach da chon
**Approach B: Skills + State Management** — Skills huong dan Claude dich, file-based state tracking, scripts Python lo extract/render. Khong dung n8n/DB/API (khac voi module novel).

---

## 2. Kien truc tong the

### 2.1 Data Flow

```
[1] INIT        User cung cap PDF/EPUB/Text
                    |
[2] EXTRACT     scripts/extract.py → source/chapters/ch*.md + format-map.yaml
                    |
[3] STYLE       Claude brainstorm style guide → style-guide.md
                    |
[4] TRANSLATE   Claude dich tung section (3-pass: Translate → Reflect → Improve)
                → translated/ch*.md
                    |
[5] REVIEW      User review → feedback loi hoac edit file
                Claude hoc feedback → memory/ + glossary
                    |
[6] CONSISTENCY Claude kiem tra toan sach → sua inconsistencies
                    |
[7] RENDER      scripts/render.py → output/{book}-final.docx
                (mirror format goc: heading, bold, italic, footnote...)
```

### 2.2 Skills Placement

Skills duoc dat trong `.claude/skills/book-translation/` (KHONG phai trong modules/). Ly do: Claude Code chi auto-discover skills trong `.claude/skills/`. Module `modules/book-translation/` chi chua scripts, memory, projects.

```
.claude/skills/book-translation/
├── init-project.md
├── translate-section.md
├── review-translation.md
├── consistency-check.md
└── define-style.md
```

User trigger skills bang cach noi tu nhien ("dich chapter 3", "tiep tuc dich", "review ban dich") hoac goi ten skill truc tiep. Claude match intent → load skill tuong ung.

### 2.3 Version Control Policy

```
Git TRACK (text files):
  ├── config.yaml, progress.yaml, style-guide.md, glossary.md
  ├── source/chapters/*.md        (extracted text)
  ├── translated/*.md             (translated text)
  └── memory/*.md                 (cross-book memory)

Git IGNORE (.gitignore):
  ├── source/original.*           (PDF/EPUB goc — qua lon)
  ├── output/*.docx               (generated output)
  └── scripts/__pycache__/
```

Loi ich: git diff de thay thay doi qua review iterations. git log de track lich su dich.

### 2.4 Module Structure

```
modules/book-translation/
├── scripts/
│   ├── extract.py                   # PDF/EPUB → markdown chapters
│   ├── render.py                    # Markdown chapters → DOCX
│   ├── manage.py                    # CLI: init, status, validate, render
│   ├── lib/
│   │   ├── __init__.py
│   │   ├── extractor.py            # PDF/EPUB parsing logic
│   │   ├── renderer.py             # MD → DOCX voi format preservation
│   │   ├── merger.py               # Gop chapters
│   │   ├── formatter.py            # Preserve formatting: bold, italic, footnote
│   │   ├── validator.py            # Validate structure & completeness
│   │   └── config_loader.py        # Load config.yaml + progress.yaml
│   ├── tests/                       # pytest unit + integration tests
│   │   ├── test_extractor.py
│   │   ├── test_renderer.py
│   │   ├── test_merger.py
│   │   └── fixtures/               # Sample PDF, EPUB, MD cho tests
│   ├── templates/
│   │   └── default-template.docx   # Reference DOCX template
│   └── requirements.txt            # python-docx, pymupdf, ebooklib, pyyaml
├── memory/                          # Tich luy xuyen sach
│   ├── glossary-global.md          # Thuat ngu chung da hoc
│   ├── style-feedback.md           # Feedback van phong chung
│   └── translation-patterns.md    # Pattern dich hay da approve
└── README.md
```

### 2.5 Per-book Project Structure

```
modules/book-translation/projects/{book-slug}/
├── config.yaml                      # Metadata + settings
├── style-guide.md                   # Van phong rieng (brainstorm voi Claude)
├── glossary.md                      # Thuat ngu rieng cho sach
├── progress.yaml                    # Tracking trang thai tung chapter/section
├── source/
│   ├── original.pdf                 # File goc
│   └── chapters/
│       ├── ch01.md                  # Chapter 1 extracted (EN)
│       └── ...
├── translated/
│   ├── ch01.md                      # Chapter 1 translated (VI)
│   └── ...
└── output/
    └── {book-slug}-final.docx       # Output cuoi cung
```

---

## 3. State Machine & Conventions

### 3.1 Chapter Status Transitions

```
extracted ──→ translating ──→ draft ──→ reviewing ──→ approved
                  ↑              ↑          │
                  │              └──────────┘
                  │            (feedback/edit)
                  │
            (resume after pause)
```

- `extracted`: source text da co, chua dich
- `translating`: Claude dang dich (trong session)
- `draft`: ban dich xong 3-pass, cho user review
- `reviewing`: user dang review / da gui feedback, Claude dang sua
- `approved`: user da approve, san sang render

Book-level status: `init | extracting | translating | reviewing | consistency_check | done`

### 3.2 Section Naming Convention

Khi chapter > `max_section_words` (default 3000):
- extract.py tu dong chia tai **paragraph break gan nhat** voi word boundary
- User confirm truoc khi finalize

```
Chapter ngan (<=3000 words):
  source/chapters/ch03.md          → 1 file
  translated/ch03.md               → 1 file
  progress.yaml: sections: 1

Chapter dai (>3000 words, vd 9200 words → 3 sections):
  source/chapters/ch05.md          → 1 file (giu nguyen)
  source/chapters/ch05-s1.md       → section 1 (extracted)
  source/chapters/ch05-s2.md       → section 2
  source/chapters/ch05-s3.md       → section 3
  translated/ch05-s1.md            → section 1 (translated)
  translated/ch05-s2.md            → section 2
  translated/ch05-s3.md            → section 3
  progress.yaml: sections: 3, section_status: [s1: draft, s2: extracted, ...]

Render merge: merger.py doc ch05-s1 + ch05-s2 + ch05-s3 theo thu tu → ch05 hoan chinh
```

Sach co Parts (Part I, Part II...): naming convention `pt01-ch01.md`, `pt01-ch02.md`, `pt02-ch01.md`...

### 3.3 Glossary Format

```markdown
# Glossary — {Book Title}

| English | Vietnamese | Context | Notes |
|---------|-----------|---------|-------|
| inferiority feelings | cam giac tu ti | Adler psychology | KHONG dung "mac cam" |
| style of life | nep song | core concept | KHONG dung "phong cach song" |
| neurotic | nguoi mang lech lac tam ly | clinical term | KHONG dung "than kinh" |
```

Glossary phai parseable boi ca Claude (doc markdown) va scripts (validate glossary terms trong translated files).

---

## 4. Skills System

### 4.1 Skill: init-project.md

**Trigger:** User noi "dich sach moi" hoac cung cap file PDF/EPUB

**Flow:**
1. Tao folder `projects/{book-slug}/` voi cau truc chuan
2. Chay `scripts/extract.py` de tach chapters → `source/chapters/`
3. User review ket qua extract (so chapter, format dung khong)
4. Generate `config.yaml` tu metadata sach
5. Init `progress.yaml` voi tat ca chapters o trang thai `extracted`
6. Chuyen sang skill `define-style`

### 4.2 Skill: define-style.md

**Trigger:** Sau init, hoac khi user muon dieu chinh style

**Flow:**
1. Claude doc 2-3 doan mau tu sach goc
2. Phan tich: the loai, giong van tac gia, doi tuong doc gia, muc do hoc thuat
3. Hoi user cac cau hoi then chot (1 cau/lan):
   - Doi tuong doc ban dich la ai?
   - Muc do Han-Viet mong muon?
   - Giong van uu tien?
   - Xung ho?
   - Xu ly thuat ngu chuyen nganh?
4. Doc `memory/style-feedback.md` de apply feedback chung tu sach truoc (neu co)
5. Claude de xuat style guide draft
6. User approve → ghi vao `style-guide.md`

**Output style-guide.md mau:**
```markdown
# Style Guide — {Book Title}

## Giong van
[Mo ta giong van cu the]

## Xung ho
[Quy tac xung ho]

## Thuat ngu
- Quy tac chung ve thuat ngu
- Xem glossary.md cho danh sach cu the

## Quy tac
- Khong lap tu trong 3 cau lien tiep
- Khong dich word-by-word
- Chia cau dai phuc thanh cau ngan hon neu can
- Giu nguyen cau truc doan van goc

## Anti-patterns
- KHONG dung gach dau dong/so thu tu trong van xuoi
- KHONG chen tom tat y chinh dau/cuoi doan
- KHONG them chu thich ca nhan
```

### 4.3 Skill: translate-section.md (Core)

**Trigger:** User noi "dich chapter X" hoac "tiep tuc dich"

**3-pass workflow (Translate → Reflect → Improve):**

```
Pass 1: TRANSLATE
  - Doc source section
  - Doc style-guide.md + glossary.md
  - Doc memory/translation-patterns.md (patterns da approve)
  - Doc 1-2 section da dich truoc (neu co) de giu giong van
  - Dich toan bo section

Pass 2: REFLECT
  - Tu doi chieu voi source: co bo sot y khong?
  - Check glossary consistency
  - Check anti-patterns (lap tu, word-by-word, formatting sai)
  - Check QC 3 lop: logic → tham my → ngu phap

Pass 3: IMPROVE
  - Apply cac diem tu reflection
  - Doc lai mach van lien mach
  - Output ban dich final cua section
```

**Sau khi dich:**
- Ghi ket qua vao `translated/chXX.md` (hoac `chXX-s1.md` neu chia section)
- Cap nhat `progress.yaml`: status → `draft`
- Thong bao user kem thong ke: word count, glossary terms applied, sentences split

**Translated file format:**
```markdown
---
chapter: 3
section: 1
source: "source/chapters/ch03.md"
status: draft
translated_at: "2026-03-27"
pass: 3
---

[Noi dung dich]
```

### 4.4 Skill: review-translation.md

**Trigger:** User review ban dich (feedback loi hoac edit file)

**3 cach xu ly:**

**Cach A — Feedback bang loi (van de lon):**
1. Claude nhan feedback
2. Claude sua lai section
3. Phan loai feedback:
   - Rieng sach nay → cap nhat style-guide.md hoac glossary.md
   - Chung cho moi sach → cap nhat memory/style-feedback.md
   - Pattern dich hay → luu vi du vao memory/translation-patterns.md
4. Cap nhat progress.yaml: status → reviewing

**Cach B — User edit file truc tiep (chinh sua nho):**
1. Claude diff file translated voi version truoc
2. Phan tich: user thay doi gi? tai sao?
3. Hoi user neu can: "Thay doi nay ap dung chung hay chi cho doan nay?"
4. Luu vao memory tuong ung

**Cach C — Ket hop A + B**

**Approve flow:**
- User approve → progress.yaml status → `approved`
- Chuyen sang section/chapter tiep theo

### 4.5 Skill: consistency-check.md

**Trigger:** Tat ca chapters approved, hoac sau moi 3-5 chapters

**5 buoc kiem tra:**
1. **Glossary audit** — Moi term dich nhat quan xuyen suot?
2. **Name audit** — Ten rieng (nguoi, dia danh) spelling nhat quan?
3. **Style drift check** — Giong van chapter dau vs chapter cuoi co drift?
4. **Completeness check** — So heading source vs translated khop? Word count ratio co outlier?
5. **Final read** — Doc luot toan bo, phat hien doan "ky" khi doc lien mach

**Output:** Report voi danh sach inconsistencies, user quyet dinh sua cai nao.

**Sau review toan phan → merge memory:**
- Glossary terms → memory/glossary-global.md
- Style rules moi → memory/style-feedback.md
- Pattern dich hay → memory/translation-patterns.md
- progress.yaml → status: done

---

## 5. Scripts Python

### 5.1 CLI: manage.py

manage.py la utility ma skills goi internally. User interact voi Claude (trigger skill), Claude goi manage.py. User cung co the chay manage.py truc tiep cho non-interactive tasks (status, validate, render).

```bash
# Khoi tao project moi
python manage.py init "Book Title" --author "Author" --source original.pdf

# Xem tien do
python manage.py status {book-slug}

# Extract PDF → chapters markdown
python manage.py extract {book-slug}

# Validate truoc khi render
python manage.py validate {book-slug}

# Render 1 chapter
python manage.py render {book-slug} --chapter 3

# Render toan bo sach
python manage.py render {book-slug} --full

# Render bilingual (EN/VI doi chieu)
python manage.py render {book-slug} --bilingual
```

### 5.2 Extract Pipeline (extract.py)

**Ho tro 3 input formats:**

| Format | Library | Kha nang |
|--------|---------|----------|
| PDF | pymupdf (fitz) | Text + basic formatting. Limitation: multi-column/scanned PDF can detect & warn |
| EPUB | ebooklib + BeautifulSoup | HTML chapters → markdown |
| Markdown/Text | Copy truc tiep | Chi split chapters |

**Pipeline:**
1. Detect format (pdf/epub/md)
2. Extract raw content voi font metadata
3. Detect chapter boundaries (heading patterns, font size jumps, HTML tags)
4. Convert to markdown (heading levels, bold, italic, footnotes, blockquotes, lists)
5. Write chapter files: `source/chapters/ch01.md, ch02.md, ...`
6. Generate `format-map.yaml`

**format-map.yaml** — Ban do format goc o structure-level (KHONG dung character offsets vi offsets se sai khi dich sang ngon ngu khac do dai khac):
```yaml
chapters:
  ch01:
    title: "The Meaning of Life"
    source_pages: [1, 15]
    elements:
      - type: heading
        level: 1
      - type: paragraph
      - type: paragraph
        has_bold: true
        has_italic: true
      - type: blockquote
      - type: footnote
        id: 1
      - type: paragraph
        has_footnote_ref: 1
```

Formatting chi tiet (bold, italic) duoc giu trong markdown syntax cua translated files (**bold**, *italic*). format-map.yaml chi luu structure: thu tu element types, heading levels, footnote positions, page breaks. Render.py parse markdown formatting + structure tu format-map de tao DOCX.

**Limitation:** format-map la best-effort. PDF phuc tap (multi-column, text boxes) co the extract khong chinh xac. User PHAI review source/chapters/ sau extract.

### 5.3 Render Pipeline (render.py)

**Pipeline:**
1. Load config.yaml + progress.yaml + format-map.yaml
2. Validate: tat ca chapters co status approved (hoac --force cho draft)
3. Merge chapters: doc translated/ch*.md theo thu tu, resolve sections
4. Parse markdown: heading, paragraph, bold, italic, footnote, blockquote, list
5. Apply format-map: doi chieu voi format-map.yaml → giu formatting goc
6. Create DOCX: python-docx (Document → add_heading → add_paragraph → add_run)
7. Apply styles: Font (Times New Roman/Noto Serif), size, margins, line spacing, page break
8. Output: `output/{book-slug}-final.docx`

**Bilingual mode:**
- Tung doan EN/VI xen ke
- EN: italic + gray style
- VI: normal + black style
- Phuc vu bien tap doi chieu

### 5.4 Validator (validator.py)

**Checklist tu dong:**
- Tat ca chapters co file trong translated/
- Khong co chapter trong hoac placeholder
- So luong headings trong translated ~ source (+-10%)
- Khong co markdown syntax loi
- Glossary terms xuat hien nhat quan
- Encoding UTF-8 dung (dau tieng Viet)
- format-map.yaml ton tai va khop voi chapters

### 5.5 Dependencies (requirements.txt)

```
pymupdf>=1.24.0        # PDF extraction
ebooklib>=0.18          # EPUB extraction
beautifulsoup4>=4.12    # HTML parsing (EPUB)
python-docx>=1.1.0      # DOCX generation
pyyaml>=6.0             # Config/progress files
markdown>=3.6           # MD parsing
click>=8.1              # CLI framework
chardet>=5.0            # Encoding detection
pytest>=8.0             # Testing (dev dependency)
```

---

## 6. Memory System

### 6.1 Ba tang memory

**Tang 1: Per-book** (trong projects/{book}/)
- `glossary.md` — thuat ngu rieng cho sach
- `style-guide.md` — van phong rieng cho sach

**Tang 2: Cross-book** (trong memory/)
- `glossary-global.md` — thuat ngu da hoc tu tat ca sach
- `style-feedback.md` — feedback van phong chung (da confirm + da reject)
- `translation-patterns.md` — vi du dich hay da approve (an du, cau phuc, thuat ngu trong ngu canh)

**Tang 3: Claude memory** (~/.claude/projects/.../memory/)
- Preferences ca nhan cua user (khong nam trong file project)
- Feedback loai feedback_*.md va user_*.md

### 6.2 Flow tich luy

```
Sach 1 dich xong → merge vao memory/ (user chon terms/rules nao giu)
    |
    v
Sach 2 khoi dau da co:
    - Glossary chung san
    - Style rules da validate
    - Pattern dich hay lam reference
    → Chat luong tot hon tu chapter 1
```

### 6.3 Glossary conflict resolution
Khi sach moi co term trung nhung nghia khac:
- Flag cho user: "Term X da dich la Y trong sach truoc. Giu hay doi?"
- User quyet dinh → ghi vao glossary.md per-book
- Khong overwrite glossary-global

---

## 7. Config Files

### 7.1 config.yaml

```yaml
book:
  title: "What Life Should Mean to You"
  author: "Alfred Adler"
  slug: "adler-what-life"
  language:
    source: en
    target: vi

source:
  format: pdf
  file: "source/original.pdf"

chunking:
  strategy: flexible
  max_section_words: 3000

output:
  format: docx
  mirror_source_format: true
  template: null
```

### 7.2 progress.yaml

```yaml
status: in_progress
chapters:
  - id: ch01
    title: "The Meaning of Life"
    sections: 1
    status: approved
    word_count_source: 2100
    last_updated: "2026-03-27"
  - id: ch02
    title: "Mind and Body"
    sections: 3
    section_status:
      - s1: approved
      - s2: reviewing
      - s3: draft
    status: reviewing
    word_count_source: 8500
    last_updated: "2026-03-27"
```

---

## 8. Constraints & Boundaries

### 8.1 Module nay KHONG lam

| Khong lam | Ly do |
|-----------|-------|
| Dich tu dong khong can review | Trai voi muc tieu chat luong van chuong |
| Tich hop n8n/Telegram | Khong phai workflow tu dong |
| Dung Ollama/API tra phi | Claude Code subscription = $0 them |
| OCR sach scan/anh | Ngoai scope, dung tool OCR rieng truoc |
| Dich song song nhieu sach | Chuyen sau tung cuon |
| Publish/distribute sach | Chi den buoc output DOCX |

### 8.2 Edge Cases

| Case | Xu ly |
|------|-------|
| Chapter qua dai (>8000 tu) | Auto-suggest chia sections, user confirm |
| Chapter qua ngan (<500 tu) | Giu nguyen, dich nguyen chapter |
| PDF extract loi | Flag cho user review source/ truoc khi dich |
| Sach co hinh anh/bang/cong thuc | Placeholder [IMAGE], markdown table, giu nguyen cong thuc |
| User bo do giua chung | progress.yaml luu trang thai, "tiep tuc dich" → resume |
| User thay doi style guide giua chung | Hoi retroactive hay chi tu chapter tiep |
| Glossary conflict giua cac sach | Per-book override, khong overwrite global |
| Sach co nhieu parts (Part I, II...) | Naming: pt01-ch01.md, pt01-ch02.md |
| Encoding sai tu PDF extract | Detect encoding voi chardet, convert ve UTF-8 |
| Scanned PDF (image-based) | Detect va warn user, khong tu OCR |

### 8.3 Constraints ky thuat

| Constraint | Giai phap |
|-----------|-----------|
| Claude context window | Dich tung section, khong load toan bo sach |
| python-docx khong ho tro TOC native | Insert TOC field code, Word tu generate |
| PDF extract khong hoan hao 100% | User review bat buoc sau extract |
| Footnote mapping phuc tap | format-map.yaml + best-effort mapping |
| Concurrent editing | Chi 1 session dich tai 1 thoi diem. File-based, khong co locking |

---

## 9. Context Management

### 9.1 Context Budget per Skill

Claude context window co gioi han. Moi skill co context loading priority:

| Skill | Luon load | Load neu co | Khong load |
|-------|-----------|-------------|------------|
| translate-section | style-guide.md, glossary.md, source section | 1 translated section truoc, memory/translation-patterns.md (top 10) | Tat ca chapters khac |
| review-translation | translated section hien tai, source section | style-guide.md, glossary.md | Chapters khac |
| consistency-check | glossary.md, style-guide.md | Sampling 3-5 paragraphs random/chapter | KHONG doc toan bo sach |

### 9.2 Consistency Check — Sampling Strategy

Thay vi doc toan bo sach (bat kha thi voi sach 80,000+ words), dung targeted scanning:

1. **Glossary scan:** Grep tung glossary term trong tat ca translated files → bao cao inconsistencies (script-assisted, khong can load full text)
2. **Name scan:** Grep ten rieng → kiem tra spelling variants
3. **Style drift:** Doc paragraph dau + paragraph cuoi cua moi chapter (sampling) → so sanh tone
4. **Completeness:** So sanh heading count source vs translated (script-assisted)
5. **Final read:** Doc toan bo 1-2 chapters ngau nhien de spot-check

manage.py co the ho tro: `python manage.py consistency-scan {book-slug}` → output report text ma Claude doc.

---

## 10. Error Handling & Recovery

### 10.1 Extract errors

| Loi | Xu ly |
|-----|-------|
| PDF khong doc duoc (encrypted/corrupted) | Exit voi error message ro rang, huong dan user |
| Encoding sai | Detect voi chardet, auto-convert UTF-8, warn user |
| Chapter detection sai (qua it/nhieu chapters) | User review, co the override bang config.yaml `chapter_pattern` regex |
| Extract bi gian doan | Partial output van giu, chay lai extract se overwrite |

### 10.2 Render errors

| Loi | Xu ly |
|-----|-------|
| Missing chapters (chua dich het) | Exit voi list chapters thieu, hoac --force de render nhung gi co |
| Markdown syntax loi | Warning + best-effort render, log vi tri loi |
| Template DOCX loi | Fallback ve default styles (no template) |
| Output file bi lock (Word dang mo) | Error message ro rang |

### 10.3 State recovery

- progress.yaml la source of truth. Neu bi corrupt → user co the re-init tu translated/ files hien co
- Moi translated file co YAML frontmatter (chapter, section, status) → co the rebuild progress.yaml tu files
- manage.py co the co lenh `python manage.py repair {book-slug}` de rebuild state tu files

---

## 11. Testing Strategy

### 11.1 Unit Tests (pytest)

```
scripts/tests/
├── test_extractor.py       # Test PDF/EPUB extraction voi sample files
├── test_renderer.py        # Test MD → DOCX conversion
├── test_merger.py          # Test chapter merging + section resolution
├── test_formatter.py       # Test format preservation (bold, italic, footnote)
├── test_validator.py       # Test validation checks
├── test_config_loader.py   # Test YAML loading + edge cases
└── fixtures/
    ├── sample.pdf          # Small PDF (3 pages) cho test
    ├── sample.epub         # Small EPUB (2 chapters) cho test
    ├── sample-chapter.md   # Sample extracted chapter
    ├── sample-translated.md # Sample translated chapter
    └── sample-template.docx # Sample DOCX template
```

### 11.2 Test Coverage

| Module | Test Focus |
|--------|-----------|
| extractor.py | PDF → MD formatting correct, chapter detection, encoding handling |
| renderer.py | MD → DOCX styles correct, bold/italic/heading rendered, page breaks |
| merger.py | Section ordering, missing section detection, part+chapter naming |
| formatter.py | Format-map parsing, element type mapping |
| validator.py | Missing files detection, heading count comparison, UTF-8 check |
| config_loader.py | Valid/invalid YAML, missing fields, default values |

### 11.3 Integration Tests

- End-to-end: sample.pdf → extract → (mock translate) → render → verify DOCX output
- CLI tests: manage.py init/status/validate/render voi fixture data

### 11.4 Skill Testing

Skills khong co automated tests (chung la markdown instructions cho Claude). Validate bang:
- Manual walkthrough moi skill voi 1 chapter mau
- Check skill references dung file paths
- Check skill flow khong co dead ends

---

## 12. Implementation Phases

### Phase 1: Foundation (MVP)
- Folder structure + config/progress YAML
- extract.py (PDF → markdown, basic formatting, scanned PDF detection)
- Skills: init-project, define-style, translate-section
- render.py (MD → DOCX: heading + paragraph + bold/italic + page breaks)
- manage.py (init, status, extract, render)
- Unit tests cho extractor, renderer, config_loader
- **Done khi:** Co the dich 1 chapter tu PDF → review → render DOCX thanh cong

### Phase 2: Review & Memory
- Skill: review-translation (feedback loop)
- Skill: consistency-check (voi sampling strategy)
- Memory system (3 tang)
- render.py bilingual mode
- manage.py consistency-scan command
- **Done khi:** Co the dich 3+ chapters, feedback duoc luu, consistency check chay duoc

### Phase 3: Polish
- EPUB extraction support
- format-map.yaml (structure-level formatting preservation)
- render.py advanced (footnote, blockquote, TOC field code)
- validator.py comprehensive checks
- Merge memory workflow (per-book → global)
- manage.py repair command
- **Done khi:** Full pipeline PDF/EPUB → extract → dich → review → consistency → render DOCX hoan chinh

---

## 13. Ke thua tu Prompt dich cu

Cac yeu to tu DICH_PROMPT_1.txt va DICH_PROMPT_2.txt duoc tich hop:

| Yeu to | Prompt cu | Module moi |
|--------|-----------|------------|
| Quy trinh 5 buoc | Doc → Nam y → Dien dat → So sanh → Hieu dinh | → 3-pass: Translate → Reflect → Improve |
| QC 3 lop | Logic → tham my → ngu phap | → Tich hop trong Reflect pass |
| Anti-patterns | Khong word-by-word, khong lap tu 3 cau | → Ghi vao style-guide.md moi sach |
| Glossary | Hardcode trong prompt | → Tach file glossary.md, inject tu dong |
| Format preservation | "Giu dung hinh thuc trinh bay" | → format-map.yaml + render mirror |
| Feedback luu tru | Khong co | → 3 tang memory system |

---

**Author:** VictorAurelius
**Created:** 2026-03-27
