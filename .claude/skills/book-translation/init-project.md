---
name: init-project
description: Initialize a new book translation project — use when user says "dich sach moi" or provides a PDF/EPUB file for translation
---

# Init Book Translation Project

## Trigger
User says "dich sach moi", "translate a new book", or provides a PDF/EPUB file.

## Steps

### 0. Git Setup
Create an isolated branch for this translation project:
```bash
git checkout main && git pull
git checkout -b translate/{slug}
git push -u origin translate/{slug}
```
Branch naming: `translate/{slug}` (e.g. `translate/dao-duc-kinh`).

> **Important:** Book content (projects/{slug}/) stays on this branch permanently — it is
> NEVER merged to main. Only cross-book data (memory/) and tooling fixes flow back to main
> via separate PRs. See the Git Workflow section in README for details.

### 1. Gather info
Ask user (if not already provided):
- Book title
- Author name
- Source file path (PDF, EPUB, or text)

### 2. Create project
Run the CLI to scaffold the project:
```bash
cd modules/book-translation
python scripts/manage.py init "{title}" --author "{author}" --source "{path}"
```

### 3. Extract chapters
```bash
python scripts/manage.py extract {slug}
```

### 4. Clean extracted chapters
PDF extraction produces artifacts. Claude MUST review and fix each chapter file:

**Character fixes:**
- Replace `�` with proper quotes (`"` or `'`)
- Fix curly quote mojibake (`\x93`/`\x94` → `"`/`"`)
- Fix broken dashes (`\x96`/`\x97` → `–`/`—`)

**Split word fixes:**
- Single uppercase + space + lowercase: `T hese` → `These`, `W hen` → `When`
- Short fragment + space + fragment: `th at` → `that`, `the n` → `then`
- Use context to determine if a space is a real word boundary or PDF artifact

**Paragraph structure (compare with PDF):**
- PDF pages create artificial paragraph breaks mid-sentence — merge these
- BUT preserve intentional paragraph breaks the author used to separate ideas
- **MUST compare each chapter with the original PDF** to distinguish:
  - Page break artifact (mid-sentence split) → merge ✓
  - Author's paragraph break (topic shift, new idea) → keep ✓
- The MD file IS the source of truth for DOCX rendering — each `\n\n` = new paragraph

**Process:** Read each `source/chapters/chXX.md`, compare with original PDF, apply fixes, overwrite.

### 4b. Create front matter
Create `source/chapters/front-matter.md` with translated content for everything before chapter 1:
```markdown
# {Tên sách tiếng Việt}

**Tác giả:** {Author}
**Dịch giả:** {Translator}

---

## Mục Lục

1. {Chapter 1 title in Vietnamese}
2. {Chapter 2 title in Vietnamese}
...
```
This file is rendered BEFORE ch01 in the final DOCX.
Also translate any preface notes, copyright attributions, etc. that appear before the main content.

### 5. User reviews extraction & paragraph structure
Show the user:
- Number of chapters detected
- Word count per chapter
- Ask them to review `projects/{slug}/source/chapters/` for accuracy

If chapter detection is wrong, user can:
- Edit the markdown files manually
- Re-run with a custom chapter pattern in config.yaml

### 6. Show status
```bash
python scripts/manage.py status {slug}
```

### 7. Transition
Once user confirms extraction looks good, invoke **define-style** skill to brainstorm the style guide for this book.
