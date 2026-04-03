# Book Translation Module

Công cụ tự động hóa dịch sách từ PDF/EPUB sang DOCX với hỗ trợ glossary, style feedback, và translation patterns.

## Quick Start

```bash
# 1. Install dependencies
pip install -r scripts/requirements.txt

# 2. Place your source file in the input/ staging area
cp /path/to/book.pdf input/

# 3. Initialize a translation project
python scripts/manage.py init "My Book" --author "Author Name" --source input/book.pdf

# 4. Extract chapters from source file
python scripts/manage.py extract my-book

# 5. Check extracted chapters
python scripts/manage.py status my-book

# 6. Translate sections (one chapter at a time with Claude)
# Use the translate-section skill in Claude Code

# 7. Render final output
python scripts/manage.py render my-book --full
```

> **Note:** Files in `input/` are git-ignored (copyright). The `init` command copies
> your file into `projects/{slug}/source/original.{ext}` automatically.

## Skills

| Skill | Purpose |
|-------|---------|
| `init-project` | Initialize new translation project with source file |
| `define-style` | Define translation style and tone for consistency |
| `translate-section` | Translate single section with memory integration |

## Scripts

| Script | Purpose |
|--------|---------|
| `manage.py` | Main CLI for project management and translation |
| `lib/config_loader.py` | Load and validate project configuration |
| `lib/extractor.py` | Extract text from PDF/EPUB files |
| `lib/merger.py` | Merge translated sections into DOCX |
| `lib/renderer.py` | Render final formatted output |

## Memory

- `glossary-global.md` — Global terminology dictionary
- `style-feedback.md` — Common style issues and solutions
- `translation-patterns.md` — Recurring translation patterns

## Project Structure

```
book-translation/
├── input/                       # Staging area — place source files here before init
│   └── .gitkeep                 # (contents are git-ignored)
└── projects/
    └── my-book/
        ├── config.yaml          # Project configuration
        ├── progress.yaml        # Translation progress tracker
        ├── glossary.md          # Project-specific glossary
        ├── style-guide.md       # Translation style guide
        ├── source/
        │   ├── original.pdf     # Copied from input/ by init command
        │   └── chapters/        # Extracted by extract command
        │       ├── ch01.md
        │       ├── ch02.md
        │       └── ...
        ├── translated/          # Translated chapter files
        │   ├── ch01.md
        │   └── ...
        └── output/              # Rendered DOCX output
            └── my-book-final.docx
```
