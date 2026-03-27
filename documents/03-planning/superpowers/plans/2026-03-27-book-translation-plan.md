# Book Translation Module - Implementation Plan (Phase 1: MVP)

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a book translation module where Claude Code translates English books with structured review workflow, file-based state tracking, and Python scripts for PDF extraction and DOCX rendering.

**Architecture:** Claude Code skills drive the translation workflow. Python scripts handle extraction (PDF→MD) and rendering (MD→DOCX). YAML files track state. Markdown files store glossary, style guide, and translation memory.

**Tech Stack:** Python 3.10+, pymupdf, python-docx, click, pyyaml, chardet, pytest

**Spec Document:** `documents/03-planning/superpowers/specs/2026-03-27-book-translation-design.md`

**Phase 1 scope (MVP):** Folder structure, config/progress YAML, extract.py (PDF→markdown), render.py (MD→DOCX), manage.py CLI, 3 skills (init-project, define-style, translate-section), unit tests.

**Done when:** Can extract chapters from a PDF, translate 1 chapter with Claude, and render the result to DOCX.

---

## Chunk 1: Project Scaffold & Config Loader

### Task 1: Create module folder structure and .gitignore

**Files:**
- Create: `modules/book-translation/README.md`
- Create: `modules/book-translation/scripts/requirements.txt`
- Create: `modules/book-translation/scripts/lib/__init__.py`
- Create: `modules/book-translation/scripts/templates/.gitkeep`
- Create: `modules/book-translation/memory/glossary-global.md`
- Create: `modules/book-translation/memory/style-feedback.md`
- Create: `modules/book-translation/memory/translation-patterns.md`
- Create: `modules/book-translation/.gitignore`

- [ ] **Step 1: Create directory structure**

```bash
mkdir -p modules/book-translation/scripts/lib
mkdir -p modules/book-translation/scripts/tests/fixtures
mkdir -p modules/book-translation/scripts/templates
mkdir -p modules/book-translation/memory
mkdir -p modules/book-translation/projects
```

- [ ] **Step 2: Create requirements.txt**

```
# modules/book-translation/scripts/requirements.txt
pymupdf>=1.24.0
python-docx>=1.1.0
pyyaml>=6.0
click>=8.1
chardet>=5.0
markdown>=3.6
pytest>=8.0
```

- [ ] **Step 3: Create .gitignore**

```gitignore
# modules/book-translation/.gitignore
# Source files (too large for git)
projects/*/source/original.*
projects/*/source/*.pdf
projects/*/source/*.epub

# Generated output
projects/*/output/*.docx

# Python
scripts/__pycache__/
scripts/lib/__pycache__/
scripts/tests/__pycache__/
*.pyc
```

- [ ] **Step 4: Create lib/__init__.py**

```python
# modules/book-translation/scripts/lib/__init__.py
"""Book translation scripts library."""
```

- [ ] **Step 5: Create memory template files**

```markdown
# modules/book-translation/memory/glossary-global.md
# Global Glossary

Accumulated terminology from all translation projects.

| English | Vietnamese | Source Book | Notes |
|---------|-----------|-------------|-------|
```

```markdown
# modules/book-translation/memory/style-feedback.md
# Style Feedback

Translation style rules confirmed across projects.

## Confirmed Rules

## Rejected Approaches
```

```markdown
# modules/book-translation/memory/translation-patterns.md
# Translation Patterns

Approved translation examples for reference.
```

- [ ] **Step 6: Create README.md**

```markdown
# modules/book-translation/README.md
# Book Translation Module

Dich sach tieng Anh chuyen sau voi Claude Code lam translator.

## Quick Start

1. Install dependencies: `pip install -r scripts/requirements.txt`
2. Init project: `python scripts/manage.py init "Book Title" --author "Author" --source path/to/book.pdf`
3. Ask Claude: "dich chapter 1" or "tiep tuc dich"
4. Review and approve translations
5. Render: `python scripts/manage.py render {book-slug} --full`

## Skills (in .claude/skills/book-translation/)

| Skill | Trigger |
|-------|---------|
| init-project | "dich sach moi", provide PDF/EPUB |
| define-style | "dinh nghia van phong", after init |
| translate-section | "dich chapter X", "tiep tuc dich" |
| review-translation | "review ban dich", provide feedback |
| consistency-check | "kiem tra nhat quan", after all chapters approved |

## Scripts

| Command | Purpose |
|---------|---------|
| `manage.py init` | Create new book project |
| `manage.py status` | Show translation progress |
| `manage.py extract` | Extract PDF/EPUB to markdown |
| `manage.py validate` | Validate before rendering |
| `manage.py render` | Render markdown to DOCX |
```

- [ ] **Step 7: Commit**

```bash
git add modules/book-translation/
git commit -m "feat(book-translation): scaffold module folder structure"
```

---

### Task 2: Create conftest.py for test path setup

**Files:**
- Create: `modules/book-translation/scripts/tests/__init__.py`
- Create: `modules/book-translation/scripts/tests/conftest.py`

- [ ] **Step 1: Create conftest.py**

```python
# modules/book-translation/scripts/tests/__init__.py
```

```python
# modules/book-translation/scripts/tests/conftest.py
"""Shared test configuration — adds scripts/ to sys.path."""
import sys
from pathlib import Path

# Add scripts dir to path so tests can import from lib/
sys.path.insert(0, str(Path(__file__).parent.parent))
```

- [ ] **Step 2: Commit**

```bash
git add modules/book-translation/scripts/tests/__init__.py modules/book-translation/scripts/tests/conftest.py
git commit -m "feat(book-translation): add test conftest.py for path setup"
```

---

### Task 3: Implement config_loader.py with tests (TDD)

**Files:**
- Create: `modules/book-translation/scripts/tests/test_config_loader.py`
- Create: `modules/book-translation/scripts/lib/config_loader.py`

- [ ] **Step 1: Write failing tests for config_loader**

```python
# modules/book-translation/scripts/tests/test_config_loader.py
"""Tests for config_loader module."""
import os
import pytest
import yaml
from pathlib import Path

from lib.config_loader import (
    load_config,
    load_progress,
    save_progress,
    init_config,
    init_progress,
    get_project_path,
    get_next_chapter,
    VALID_STATUSES,
)


@pytest.fixture
def tmp_project(tmp_path):
    """Create a temporary project directory with basic structure."""
    project_dir = tmp_path / "test-book"
    project_dir.mkdir()
    (project_dir / "source" / "chapters").mkdir(parents=True)
    (project_dir / "translated").mkdir()
    (project_dir / "output").mkdir()
    return project_dir


class TestInitConfig:
    def test_creates_config_yaml(self, tmp_project):
        config = init_config(
            project_dir=tmp_project,
            title="Test Book",
            author="Test Author",
            source_format="pdf",
            source_file="source/original.pdf",
        )
        config_path = tmp_project / "config.yaml"
        assert config_path.exists()
        assert config["book"]["title"] == "Test Book"
        assert config["book"]["author"] == "Test Author"
        assert config["book"]["slug"] == "test-book"
        assert config["source"]["format"] == "pdf"
        assert config["chunking"]["max_section_words"] == 3000

    def test_generates_slug_from_title(self, tmp_project):
        config = init_config(
            project_dir=tmp_project,
            title="What Life Should Mean to You",
            author="Alfred Adler",
            source_format="pdf",
            source_file="source/original.pdf",
        )
        assert config["book"]["slug"] == "what-life-should-mean-to-you"


class TestInitProgress:
    def test_creates_progress_yaml(self, tmp_project):
        chapters = [
            {"id": "ch01", "title": "Chapter One", "word_count": 2000},
            {"id": "ch02", "title": "Chapter Two", "word_count": 5000},
        ]
        progress = init_progress(tmp_project, chapters)
        progress_path = tmp_project / "progress.yaml"
        assert progress_path.exists()
        assert progress["status"] == "extracting"
        assert len(progress["chapters"]) == 2
        assert progress["chapters"][0]["status"] == "extracted"
        assert progress["chapters"][1]["sections"] == 1

    def test_auto_sections_for_long_chapters(self, tmp_project):
        chapters = [
            {"id": "ch01", "title": "Long Chapter", "word_count": 9200},
        ]
        progress = init_progress(tmp_project, chapters, max_section_words=3000)
        ch = progress["chapters"][0]
        assert ch["sections"] == 4  # ceil(9200/3000) = 4


class TestLoadConfig:
    def test_loads_existing_config(self, tmp_project):
        config_data = {
            "book": {"title": "Test", "author": "Author", "slug": "test"},
            "source": {"format": "pdf", "file": "source/original.pdf"},
            "chunking": {"strategy": "flexible", "max_section_words": 3000},
            "output": {"format": "docx", "mirror_source_format": True},
        }
        with open(tmp_project / "config.yaml", "w", encoding="utf-8") as f:
            yaml.dump(config_data, f, allow_unicode=True)
        loaded = load_config(tmp_project)
        assert loaded["book"]["title"] == "Test"

    def test_raises_on_missing_config(self, tmp_project):
        with pytest.raises(FileNotFoundError):
            load_config(tmp_project)


class TestLoadProgress:
    def test_loads_existing_progress(self, tmp_project):
        progress_data = {
            "status": "translating",
            "chapters": [
                {"id": "ch01", "title": "Ch 1", "status": "approved", "sections": 1}
            ],
        }
        with open(tmp_project / "progress.yaml", "w", encoding="utf-8") as f:
            yaml.dump(progress_data, f, allow_unicode=True)
        loaded = load_progress(tmp_project)
        assert loaded["status"] == "translating"

    def test_raises_on_missing_progress(self, tmp_project):
        with pytest.raises(FileNotFoundError):
            load_progress(tmp_project)


class TestSaveProgress:
    def test_saves_and_updates_timestamp(self, tmp_project):
        progress = {
            "status": "translating",
            "chapters": [
                {"id": "ch01", "status": "draft", "sections": 1}
            ],
        }
        save_progress(tmp_project, progress)
        loaded = load_progress(tmp_project)
        assert loaded["status"] == "translating"


class TestGetNextChapter:
    def test_returns_first_extracted_chapter(self, tmp_project):
        progress = {
            "status": "translating",
            "chapters": [
                {"id": "ch01", "status": "approved", "sections": 1},
                {"id": "ch02", "status": "extracted", "sections": 1},
                {"id": "ch03", "status": "extracted", "sections": 1},
            ],
        }
        next_ch = get_next_chapter(progress)
        assert next_ch["id"] == "ch02"

    def test_returns_none_when_all_approved(self, tmp_project):
        progress = {
            "status": "translating",
            "chapters": [
                {"id": "ch01", "status": "approved", "sections": 1},
            ],
        }
        assert get_next_chapter(progress) is None
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd modules/book-translation && python -m pytest scripts/tests/test_config_loader.py -v
```

Expected: FAIL — `ImportError: cannot import name 'load_config' from 'lib.config_loader'`

- [ ] **Step 3: Implement config_loader.py**

```python
# modules/book-translation/scripts/lib/config_loader.py
"""Load and manage config.yaml and progress.yaml for book translation projects."""
import math
import re
from datetime import date
from pathlib import Path

import yaml

VALID_STATUSES = ("extracted", "translating", "draft", "reviewing", "approved")
VALID_BOOK_STATUSES = (
    "init", "extracting", "translating", "reviewing", "consistency_check", "done"
)

PROJECTS_DIR = Path(__file__).parent.parent.parent / "projects"


def slugify(title: str) -> str:
    """Convert book title to URL-friendly slug."""
    slug = title.lower().strip()
    slug = re.sub(r"[^\w\s-]", "", slug)
    slug = re.sub(r"[\s_]+", "-", slug)
    slug = re.sub(r"-+", "-", slug)
    return slug.strip("-")


def get_project_path(slug: str) -> Path:
    """Get the project directory path for a given book slug."""
    return PROJECTS_DIR / slug


def init_config(
    project_dir: Path,
    title: str,
    author: str,
    source_format: str,
    source_file: str,
    source_lang: str = "en",
    target_lang: str = "vi",
) -> dict:
    """Create config.yaml for a new book project."""
    slug = slugify(title)
    config = {
        "book": {
            "title": title,
            "author": author,
            "slug": slug,
            "language": {"source": source_lang, "target": target_lang},
        },
        "source": {
            "format": source_format,
            "file": source_file,
        },
        "chunking": {
            "strategy": "flexible",
            "max_section_words": 3000,
        },
        "output": {
            "format": "docx",
            "mirror_source_format": True,
            "template": None,
        },
    }
    config_path = project_dir / "config.yaml"
    with open(config_path, "w", encoding="utf-8") as f:
        yaml.dump(config, f, default_flow_style=False, allow_unicode=True, sort_keys=False)
    return config


def init_progress(
    project_dir: Path,
    chapters: list[dict],
    max_section_words: int = 3000,
) -> dict:
    """Create progress.yaml for a new book project.

    Args:
        project_dir: Path to the project directory.
        chapters: List of dicts with keys: id, title, word_count.
        max_section_words: Max words per section before splitting.
    """
    progress_chapters = []
    for ch in chapters:
        word_count = ch.get("word_count", 0)
        sections = max(1, math.ceil(word_count / max_section_words)) if word_count > max_section_words else 1
        chapter_entry = {
            "id": ch["id"],
            "title": ch["title"],
            "sections": sections,
            "status": "extracted",
            "word_count_source": word_count,
            "last_updated": str(date.today()),
        }
        if sections > 1:
            chapter_entry["section_status"] = [
                {f"s{i+1}": "extracted"} for i in range(sections)
            ]
        progress_chapters.append(chapter_entry)

    progress = {
        "status": "extracting",
        "chapters": progress_chapters,
    }
    progress_path = project_dir / "progress.yaml"
    with open(progress_path, "w", encoding="utf-8") as f:
        yaml.dump(progress, f, default_flow_style=False, allow_unicode=True, sort_keys=False)
    return progress


def load_config(project_dir: Path) -> dict:
    """Load config.yaml from project directory."""
    config_path = project_dir / "config.yaml"
    if not config_path.exists():
        raise FileNotFoundError(f"Config not found: {config_path}")
    with open(config_path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def load_progress(project_dir: Path) -> dict:
    """Load progress.yaml from project directory."""
    progress_path = project_dir / "progress.yaml"
    if not progress_path.exists():
        raise FileNotFoundError(f"Progress not found: {progress_path}")
    with open(progress_path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def save_progress(project_dir: Path, progress: dict) -> None:
    """Save progress.yaml to project directory."""
    progress_path = project_dir / "progress.yaml"
    with open(progress_path, "w", encoding="utf-8") as f:
        yaml.dump(progress, f, default_flow_style=False, allow_unicode=True, sort_keys=False)


def get_next_chapter(progress: dict) -> dict | None:
    """Find the next chapter to translate (first non-approved chapter)."""
    for ch in progress.get("chapters", []):
        if ch["status"] in ("extracted", "translating", "draft", "reviewing"):
            return ch
    return None
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd modules/book-translation && python -m pytest scripts/tests/test_config_loader.py -v
```

Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add modules/book-translation/scripts/lib/config_loader.py modules/book-translation/scripts/tests/test_config_loader.py
git commit -m "feat(book-translation): add config_loader with TDD tests"
```

---

## Chunk 2: PDF Extractor & Merger

### Task 4: Implement extractor.py with tests (TDD)

**Files:**
- Create: `modules/book-translation/scripts/tests/fixtures/sample.pdf`
- Create: `modules/book-translation/scripts/tests/test_extractor.py`
- Create: `modules/book-translation/scripts/lib/extractor.py`

- [ ] **Step 1: Create sample PDF test fixture**

```python
# Run this once to generate the test fixture:
# modules/book-translation/scripts/tests/create_fixtures.py
"""Generate test fixture files for unit tests."""
import fitz  # pymupdf
from pathlib import Path

FIXTURES_DIR = Path(__file__).parent / "fixtures"
FIXTURES_DIR.mkdir(exist_ok=True)


def create_sample_pdf():
    """Create a small PDF with 3 chapters for testing."""
    doc = fitz.open()

    # Chapter 1 (short - no splitting needed)
    page = doc.new_page()
    # Title
    page.insert_text((72, 72), "Chapter 1: The Beginning", fontsize=18, fontname="helv")
    page.insert_text((72, 110), "This is the first paragraph of chapter one.", fontsize=12, fontname="helv")
    page.insert_text((72, 130), "It contains some basic text for testing extraction.", fontsize=12, fontname="helv")
    page.insert_text((72, 160), "Second paragraph with bold concepts.", fontsize=12, fontname="helvB")

    # Chapter 2 (medium)
    page2 = doc.new_page()
    page2.insert_text((72, 72), "Chapter 2: The Middle", fontsize=18, fontname="helv")
    page2.insert_text((72, 110), "This chapter discusses the middle part of our story.", fontsize=12, fontname="helv")
    page2.insert_text((72, 130), "It has italic emphasis on certain words.", fontsize=12, fontname="helvI")
    page2.insert_text((72, 160), "And continues with more content for testing.", fontsize=12, fontname="helv")

    # Chapter 3
    page3 = doc.new_page()
    page3.insert_text((72, 72), "Chapter 3: The End", fontsize=18, fontname="helv")
    page3.insert_text((72, 110), "The final chapter wraps everything up.", fontsize=12, fontname="helv")
    page3.insert_text((72, 130), "It provides a conclusion to the narrative.", fontsize=12, fontname="helv")

    doc.save(str(FIXTURES_DIR / "sample.pdf"))
    doc.close()
    print(f"Created {FIXTURES_DIR / 'sample.pdf'}")


if __name__ == "__main__":
    create_sample_pdf()
```

Run: `cd modules/book-translation && python scripts/tests/create_fixtures.py`

- [ ] **Step 2: Write failing tests for extractor**

```python
# modules/book-translation/scripts/tests/test_extractor.py
"""Tests for PDF/text extractor module."""
import pytest
from pathlib import Path

from lib.extractor import (
    detect_format,
    extract_pdf,
    detect_chapters,
    is_scanned_pdf,
    extract_to_chapters,
)


FIXTURES_DIR = Path(__file__).parent / "fixtures"


class TestDetectFormat:
    def test_pdf_extension(self):
        assert detect_format(Path("book.pdf")) == "pdf"

    def test_epub_extension(self):
        assert detect_format(Path("book.epub")) == "epub"

    def test_md_extension(self):
        assert detect_format(Path("book.md")) == "markdown"

    def test_txt_extension(self):
        assert detect_format(Path("book.txt")) == "markdown"

    def test_unknown_raises(self):
        with pytest.raises(ValueError, match="Unsupported"):
            detect_format(Path("book.docx"))


class TestIsScannedPdf:
    def test_text_pdf_is_not_scanned(self):
        pdf_path = FIXTURES_DIR / "sample.pdf"
        if not pdf_path.exists():
            pytest.skip("sample.pdf fixture not created yet")
        assert is_scanned_pdf(pdf_path) is False


class TestExtractPdf:
    @pytest.fixture
    def sample_pdf(self):
        path = FIXTURES_DIR / "sample.pdf"
        if not path.exists():
            pytest.skip("sample.pdf fixture not created yet")
        return path

    def test_extracts_text_blocks(self, sample_pdf):
        blocks = extract_pdf(sample_pdf)
        assert len(blocks) > 0
        # Each block should have text, page, font_size
        assert "text" in blocks[0]
        assert "page" in blocks[0]
        assert "font_size" in blocks[0]

    def test_detects_headings_by_font_size(self, sample_pdf):
        blocks = extract_pdf(sample_pdf)
        headings = [b for b in blocks if b["is_heading"]]
        assert len(headings) >= 3  # 3 chapters


class TestDetectChapters:
    def test_splits_by_heading_pattern(self):
        blocks = [
            {"text": "Chapter 1: The Beginning", "is_heading": True, "page": 0, "font_size": 18},
            {"text": "Some content here.", "is_heading": False, "page": 0, "font_size": 12},
            {"text": "Chapter 2: The Middle", "is_heading": True, "page": 1, "font_size": 18},
            {"text": "More content.", "is_heading": False, "page": 1, "font_size": 12},
        ]
        chapters = detect_chapters(blocks)
        assert len(chapters) == 2
        assert chapters[0]["id"] == "ch01"
        assert chapters[0]["title"] == "Chapter 1: The Beginning"
        assert "Some content here." in chapters[0]["content"]

    def test_handles_no_chapter_pattern(self):
        """When no heading matches chapter pattern, treat whole text as ch01."""
        blocks = [
            {"text": "Introduction", "is_heading": True, "page": 0, "font_size": 18},
            {"text": "Some text.", "is_heading": False, "page": 0, "font_size": 12},
        ]
        chapters = detect_chapters(blocks)
        assert len(chapters) == 1
        assert chapters[0]["id"] == "ch01"


class TestExtractToChapters:
    def test_writes_chapter_files(self, tmp_path):
        sample_pdf = FIXTURES_DIR / "sample.pdf"
        if not sample_pdf.exists():
            pytest.skip("sample.pdf fixture not created yet")
        output_dir = tmp_path / "chapters"
        output_dir.mkdir()
        chapters = extract_to_chapters(sample_pdf, output_dir)
        assert len(chapters) >= 1
        # Check files created
        md_files = list(output_dir.glob("ch*.md"))
        assert len(md_files) >= 1
        # Check content is not empty
        content = md_files[0].read_text(encoding="utf-8")
        assert len(content) > 0
```

- [ ] **Step 3: Run tests to verify they fail**

```bash
cd modules/book-translation && python -m pytest scripts/tests/test_extractor.py -v
```

Expected: FAIL — `ImportError: cannot import name 'detect_format' from 'lib.extractor'`

- [ ] **Step 4: Implement extractor.py**

```python
# modules/book-translation/scripts/lib/extractor.py
"""Extract text from PDF/EPUB/text files into markdown chapter files."""
import re
from pathlib import Path

import chardet
import fitz  # pymupdf


def detect_format(file_path: Path) -> str:
    """Detect input file format from extension."""
    ext = file_path.suffix.lower()
    format_map = {
        ".pdf": "pdf",
        ".epub": "epub",
        ".md": "markdown",
        ".txt": "markdown",
        ".text": "markdown",
    }
    if ext not in format_map:
        raise ValueError(f"Unsupported format: {ext}. Use PDF, EPUB, MD, or TXT.")
    return format_map[ext]


def is_scanned_pdf(pdf_path: Path) -> bool:
    """Detect if PDF is scanned (image-based) by checking text content.

    Returns True if fewer than 10% of pages have extractable text.
    """
    doc = fitz.open(str(pdf_path))
    pages_with_text = 0
    total_pages = len(doc)
    for page in doc:
        text = page.get_text().strip()
        if len(text) > 50:  # meaningful text threshold
            pages_with_text += 1
    doc.close()
    return pages_with_text < (total_pages * 0.1)


def extract_pdf(pdf_path: Path) -> list[dict]:
    """Extract text blocks from PDF with font metadata.

    Returns list of dicts: {text, page, font_size, font_name, is_heading, is_bold, is_italic}
    """
    doc = fitz.open(str(pdf_path))
    blocks = []
    font_sizes = []

    # First pass: collect all font sizes to detect heading threshold
    for page in doc:
        text_dict = page.get_text("dict")
        for block in text_dict.get("blocks", []):
            if block.get("type") != 0:  # skip image blocks
                continue
            for line in block.get("lines", []):
                for span in line.get("spans", []):
                    if span.get("text", "").strip():
                        font_sizes.append(span["size"])

    if not font_sizes:
        doc.close()
        return blocks

    # Determine heading threshold: text larger than median + 2pt
    sorted_sizes = sorted(font_sizes)
    median_size = sorted_sizes[len(sorted_sizes) // 2]
    heading_threshold = median_size + 2

    # Second pass: extract blocks with metadata
    for page_num, page in enumerate(doc):
        text_dict = page.get_text("dict")
        for block in text_dict.get("blocks", []):
            if block.get("type") != 0:
                continue
            # Merge spans within block into single text
            block_text_parts = []
            max_font_size = 0
            is_bold = False
            is_italic = False
            font_name = ""

            for line in block.get("lines", []):
                line_parts = []
                for span in line.get("spans", []):
                    text = span.get("text", "")
                    if not text.strip():
                        continue
                    line_parts.append(text)
                    size = span.get("size", 12)
                    if size > max_font_size:
                        max_font_size = size
                        font_name = span.get("font", "")
                    flags = span.get("flags", 0)
                    if flags & 2 ** 4:  # bold flag
                        is_bold = True
                    if flags & 2 ** 1:  # italic flag
                        is_italic = True
                if line_parts:
                    block_text_parts.append(" ".join(line_parts))

            full_text = "\n".join(block_text_parts).strip()
            if not full_text:
                continue

            blocks.append({
                "text": full_text,
                "page": page_num,
                "font_size": max_font_size,
                "font_name": font_name,
                "is_heading": max_font_size >= heading_threshold,
                "is_bold": is_bold,
                "is_italic": is_italic,
            })

    doc.close()
    return blocks


def detect_chapters(blocks: list[dict]) -> list[dict]:
    """Detect chapter boundaries from extracted text blocks.

    Returns list of chapters: {id, title, content, word_count, start_page}
    """
    chapter_pattern = re.compile(
        r"^(chapter|part|section)\s+\d+", re.IGNORECASE
    )

    # Find heading blocks that match chapter pattern
    chapter_starts = []
    for i, block in enumerate(blocks):
        if block["is_heading"] and chapter_pattern.search(block["text"]):
            chapter_starts.append(i)

    # If no chapter headings found, treat all content as single chapter
    if not chapter_starts:
        all_text = "\n\n".join(b["text"] for b in blocks)
        title = blocks[0]["text"] if blocks and blocks[0]["is_heading"] else "Untitled"
        return [{
            "id": "ch01",
            "title": title,
            "content": all_text,
            "word_count": len(all_text.split()),
            "start_page": blocks[0]["page"] if blocks else 0,
        }]

    # Split blocks into chapters
    chapters = []
    for idx, start in enumerate(chapter_starts):
        end = chapter_starts[idx + 1] if idx + 1 < len(chapter_starts) else len(blocks)
        title = blocks[start]["text"]
        content_blocks = blocks[start + 1 : end]
        content = "\n\n".join(b["text"] for b in content_blocks)

        chapter_num = idx + 1
        chapters.append({
            "id": f"ch{chapter_num:02d}",
            "title": title.strip(),
            "content": content,
            "word_count": len(content.split()),
            "start_page": blocks[start]["page"],
        })

    return chapters


def _blocks_to_markdown(blocks: list[dict], heading_blocks_indices: set = None) -> str:
    """Convert text blocks to markdown format."""
    lines = []
    for i, block in enumerate(blocks):
        text = block["text"].strip()
        if not text:
            continue
        if block.get("is_heading"):
            lines.append(f"# {text}")
        elif block.get("is_bold") and not block.get("is_italic"):
            lines.append(f"**{text}**")
        elif block.get("is_italic") and not block.get("is_bold"):
            lines.append(f"*{text}*")
        else:
            lines.append(text)
        lines.append("")  # blank line between blocks
    return "\n".join(lines).strip() + "\n"


def extract_to_chapters(
    source_path: Path,
    output_dir: Path,
    chapter_pattern: str | None = None,
) -> list[dict]:
    """Extract source file to chapter markdown files.

    Args:
        source_path: Path to PDF/EPUB/text file.
        output_dir: Directory to write ch01.md, ch02.md, etc.
        chapter_pattern: Optional regex to override chapter detection.

    Returns:
        List of chapter metadata dicts: {id, title, word_count, file_path}
    """
    fmt = detect_format(source_path)
    output_dir.mkdir(parents=True, exist_ok=True)

    if fmt == "pdf":
        if is_scanned_pdf(source_path):
            raise ValueError(
                f"PDF appears to be scanned (image-based): {source_path}. "
                "Please OCR the file first before using this tool."
            )
        blocks = extract_pdf(source_path)
        chapters = detect_chapters(blocks)
    elif fmt == "markdown":
        text = _read_text_file(source_path)
        chapters = _split_text_chapters(text)
    else:
        raise ValueError(f"Format '{fmt}' extraction not yet implemented. Phase 3 will add EPUB support.")

    result = []
    for ch in chapters:
        file_path = output_dir / f"{ch['id']}.md"
        content = f"# {ch['title']}\n\n{ch['content']}\n"
        file_path.write_text(content, encoding="utf-8")
        result.append({
            "id": ch["id"],
            "title": ch["title"],
            "word_count": ch["word_count"],
            "file_path": str(file_path),
        })

    return result


def _read_text_file(file_path: Path) -> str:
    """Read text file with encoding detection."""
    raw = file_path.read_bytes()
    detected = chardet.detect(raw)
    encoding = detected.get("encoding", "utf-8") or "utf-8"
    return raw.decode(encoding)


def _split_text_chapters(text: str) -> list[dict]:
    """Split plain text/markdown into chapters by heading patterns."""
    chapter_pattern = re.compile(r"^#+\s+.*(?:chapter|part)\s+\d+", re.IGNORECASE | re.MULTILINE)
    matches = list(chapter_pattern.finditer(text))

    if not matches:
        return [{
            "id": "ch01",
            "title": "Chapter 1",
            "content": text.strip(),
            "word_count": len(text.split()),
        }]

    chapters = []
    for idx, match in enumerate(matches):
        start = match.start()
        end = matches[idx + 1].start() if idx + 1 < len(matches) else len(text)
        title = match.group().lstrip("#").strip()
        content = text[match.end() : end].strip()
        chapters.append({
            "id": f"ch{idx + 1:02d}",
            "title": title,
            "content": content,
            "word_count": len(content.split()),
        })

    return chapters
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
cd modules/book-translation && python -m pytest scripts/tests/test_extractor.py -v
```

Expected: All tests PASS.

- [ ] **Step 6: Commit**

```bash
git add modules/book-translation/scripts/lib/extractor.py modules/book-translation/scripts/tests/test_extractor.py modules/book-translation/scripts/tests/create_fixtures.py
git commit -m "feat(book-translation): add PDF extractor with TDD tests"
```

---

## Chunk 3: DOCX Renderer & CLI

### Task 5: Implement merger.py with tests (TDD)

**Files:**
- Create: `modules/book-translation/scripts/tests/test_merger.py`
- Create: `modules/book-translation/scripts/lib/merger.py`

- [ ] **Step 1: Write failing tests for merger**

```python
# modules/book-translation/scripts/tests/test_merger.py
"""Tests for chapter merger module."""
import pytest
from pathlib import Path

from lib.merger import merge_chapters, resolve_sections


class TestResolveSections:
    def test_single_section_returns_file(self, tmp_path):
        ch1 = tmp_path / "ch01.md"
        ch1.write_text("# Chapter 1\n\nContent here.\n", encoding="utf-8")
        result = resolve_sections(tmp_path, "ch01", sections=1)
        assert len(result) == 1
        assert result[0] == ch1

    def test_multiple_sections_returns_ordered(self, tmp_path):
        for i in range(1, 4):
            f = tmp_path / f"ch02-s{i}.md"
            f.write_text(f"Section {i} content.\n", encoding="utf-8")
        result = resolve_sections(tmp_path, "ch02", sections=3)
        assert len(result) == 3
        assert result[0].name == "ch02-s1.md"
        assert result[2].name == "ch02-s3.md"

    def test_missing_section_raises(self, tmp_path):
        (tmp_path / "ch03-s1.md").write_text("s1", encoding="utf-8")
        # s2 missing
        (tmp_path / "ch03-s3.md").write_text("s3", encoding="utf-8")
        with pytest.raises(FileNotFoundError, match="ch03-s2"):
            resolve_sections(tmp_path, "ch03", sections=3)


class TestMergeChapters:
    def test_merges_single_file_chapters(self, tmp_path):
        (tmp_path / "ch01.md").write_text("# Ch 1\n\nContent 1.\n", encoding="utf-8")
        (tmp_path / "ch02.md").write_text("# Ch 2\n\nContent 2.\n", encoding="utf-8")
        progress_chapters = [
            {"id": "ch01", "sections": 1},
            {"id": "ch02", "sections": 1},
        ]
        result = merge_chapters(tmp_path, progress_chapters)
        assert "Content 1." in result
        assert "Content 2." in result
        assert result.index("Content 1.") < result.index("Content 2.")

    def test_merges_multi_section_chapters(self, tmp_path):
        (tmp_path / "ch01.md").write_text("# Ch 1\n\nSingle.\n", encoding="utf-8")
        (tmp_path / "ch02-s1.md").write_text("Section 1.\n", encoding="utf-8")
        (tmp_path / "ch02-s2.md").write_text("Section 2.\n", encoding="utf-8")
        progress_chapters = [
            {"id": "ch01", "sections": 1},
            {"id": "ch02", "sections": 2},
        ]
        result = merge_chapters(tmp_path, progress_chapters)
        assert "Single." in result
        assert "Section 1." in result
        assert "Section 2." in result
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd modules/book-translation && python -m pytest scripts/tests/test_merger.py -v
```

Expected: FAIL — `ImportError`

- [ ] **Step 3: Implement merger.py**

```python
# modules/book-translation/scripts/lib/merger.py
"""Merge translated chapter/section files into a single document."""
from pathlib import Path


def resolve_sections(translated_dir: Path, chapter_id: str, sections: int) -> list[Path]:
    """Resolve section files for a chapter.

    Args:
        translated_dir: Directory containing translated files.
        chapter_id: Chapter identifier (e.g., "ch02").
        sections: Number of sections.

    Returns:
        Ordered list of file paths for this chapter.
    """
    if sections <= 1:
        file_path = translated_dir / f"{chapter_id}.md"
        if not file_path.exists():
            raise FileNotFoundError(f"Missing translated file: {file_path}")
        return [file_path]

    files = []
    for i in range(1, sections + 1):
        file_path = translated_dir / f"{chapter_id}-s{i}.md"
        if not file_path.exists():
            raise FileNotFoundError(f"Missing section file: {file_path.name}")
        files.append(file_path)
    return files


def merge_chapters(translated_dir: Path, progress_chapters: list[dict]) -> str:
    """Merge all translated chapters into a single markdown string.

    Args:
        translated_dir: Directory containing translated .md files.
        progress_chapters: List of chapter dicts from progress.yaml (need id, sections).

    Returns:
        Merged markdown content with page breaks between chapters.
    """
    parts = []
    for ch in progress_chapters:
        chapter_id = ch["id"]
        sections = ch.get("sections", 1)
        files = resolve_sections(translated_dir, chapter_id, sections)
        chapter_content = "\n\n".join(
            _strip_frontmatter(f.read_text(encoding="utf-8")) for f in files
        )
        parts.append(chapter_content)

    return "\n\n---\n\n".join(parts)


def _strip_frontmatter(text: str) -> str:
    """Remove YAML frontmatter from markdown text."""
    if text.startswith("---"):
        end = text.find("---", 3)
        if end != -1:
            return text[end + 3:].strip()
    return text.strip()
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd modules/book-translation && python -m pytest scripts/tests/test_merger.py -v
```

Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add modules/book-translation/scripts/lib/merger.py modules/book-translation/scripts/tests/test_merger.py
git commit -m "feat(book-translation): add chapter merger with TDD tests"
```

---

### Task 6: Implement renderer.py with tests (TDD)

**Files:**
- Create: `modules/book-translation/scripts/tests/test_renderer.py`
- Create: `modules/book-translation/scripts/lib/renderer.py`

- [ ] **Step 1: Write failing tests for renderer**

```python
# modules/book-translation/scripts/tests/test_renderer.py
"""Tests for markdown-to-DOCX renderer module."""
import pytest
from pathlib import Path
from docx import Document

from lib.renderer import render_markdown_to_docx, parse_markdown_elements


class TestParseMarkdownElements:
    def test_heading_level_1(self):
        elements = parse_markdown_elements("# Chapter Title\n")
        assert elements[0]["type"] == "heading"
        assert elements[0]["level"] == 1
        assert elements[0]["text"] == "Chapter Title"

    def test_heading_level_2(self):
        elements = parse_markdown_elements("## Section Title\n")
        assert elements[0]["type"] == "heading"
        assert elements[0]["level"] == 2

    def test_paragraph(self):
        elements = parse_markdown_elements("A regular paragraph.\n")
        assert elements[0]["type"] == "paragraph"
        assert elements[0]["text"] == "A regular paragraph."

    def test_bold_text(self):
        elements = parse_markdown_elements("This has **bold** text.\n")
        assert elements[0]["type"] == "paragraph"
        runs = elements[0]["runs"]
        assert any(r["bold"] for r in runs)

    def test_italic_text(self):
        elements = parse_markdown_elements("This has *italic* text.\n")
        assert elements[0]["type"] == "paragraph"
        runs = elements[0]["runs"]
        assert any(r["italic"] for r in runs)

    def test_page_break(self):
        elements = parse_markdown_elements("---\n")
        assert elements[0]["type"] == "page_break"

    def test_blockquote(self):
        elements = parse_markdown_elements("> A quoted passage.\n")
        assert elements[0]["type"] == "blockquote"
        assert elements[0]["text"] == "A quoted passage."

    def test_mixed_content(self):
        md = "# Title\n\nParagraph one.\n\nParagraph two with **bold**.\n\n---\n\n# Next Chapter\n"
        elements = parse_markdown_elements(md)
        types = [e["type"] for e in elements]
        assert types[0] == "heading"
        assert "paragraph" in types
        assert "page_break" in types


class TestRenderMarkdownToDocx:
    def test_creates_docx_file(self, tmp_path):
        md = "# Chapter 1\n\nHello world.\n"
        output = tmp_path / "test.docx"
        render_markdown_to_docx(md, output)
        assert output.exists()

    def test_docx_has_heading(self, tmp_path):
        md = "# My Chapter\n\nContent here.\n"
        output = tmp_path / "test.docx"
        render_markdown_to_docx(md, output)
        doc = Document(str(output))
        headings = [p for p in doc.paragraphs if p.style.name.startswith("Heading")]
        assert len(headings) >= 1
        assert "My Chapter" in headings[0].text

    def test_docx_has_paragraphs(self, tmp_path):
        md = "# Title\n\nFirst paragraph.\n\nSecond paragraph.\n"
        output = tmp_path / "test.docx"
        render_markdown_to_docx(md, output)
        doc = Document(str(output))
        normal_paras = [p for p in doc.paragraphs if p.style.name == "Normal" and p.text]
        assert len(normal_paras) >= 2

    def test_docx_has_bold(self, tmp_path):
        md = "# Title\n\nThis is **bold text** here.\n"
        output = tmp_path / "test.docx"
        render_markdown_to_docx(md, output)
        doc = Document(str(output))
        bold_runs = [
            run for p in doc.paragraphs for run in p.runs if run.bold
        ]
        assert len(bold_runs) >= 1
        assert "bold text" in bold_runs[0].text

    def test_docx_font_settings(self, tmp_path):
        md = "# Title\n\nContent.\n"
        output = tmp_path / "test.docx"
        render_markdown_to_docx(md, output, font_name="Times New Roman", font_size=12)
        doc = Document(str(output))
        for p in doc.paragraphs:
            for run in p.runs:
                if run.font.name:
                    assert run.font.name == "Times New Roman"
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd modules/book-translation && python -m pytest scripts/tests/test_renderer.py -v
```

Expected: FAIL — `ImportError`

- [ ] **Step 3: Implement renderer.py**

```python
# modules/book-translation/scripts/lib/renderer.py
"""Render markdown content to DOCX with formatting preservation."""
import re
from pathlib import Path

from docx import Document
from docx.shared import Pt, Cm
from docx.enum.text import WD_ALIGN_PARAGRAPH


def parse_markdown_elements(markdown: str) -> list[dict]:
    """Parse markdown text into structured elements.

    Returns list of elements: {type, text, level, runs, ...}
    Supported types: heading, paragraph, page_break, blockquote
    """
    elements = []
    lines = markdown.split("\n")
    i = 0

    while i < len(lines):
        line = lines[i].rstrip()

        # Skip empty lines
        if not line:
            i += 1
            continue

        # Page break (---)
        if re.match(r"^-{3,}$", line):
            elements.append({"type": "page_break"})
            i += 1
            continue

        # Headings
        heading_match = re.match(r"^(#{1,6})\s+(.+)$", line)
        if heading_match:
            level = len(heading_match.group(1))
            text = heading_match.group(2).strip()
            elements.append({"type": "heading", "level": level, "text": text})
            i += 1
            continue

        # Blockquote
        if line.startswith("> "):
            text = line[2:].strip()
            elements.append({"type": "blockquote", "text": text})
            i += 1
            continue

        # Regular paragraph — collect runs for bold/italic
        runs = _parse_inline_formatting(line)
        elements.append({"type": "paragraph", "text": line, "runs": runs})
        i += 1

    return elements


def _parse_inline_formatting(text: str) -> list[dict]:
    """Parse inline markdown formatting into runs.

    Returns list of: {text, bold, italic}
    """
    runs = []
    # Pattern matches **bold**, *italic*, or plain text
    pattern = re.compile(r"(\*\*(.+?)\*\*|\*(.+?)\*|([^*]+))")

    for match in pattern.finditer(text):
        if match.group(2):  # **bold**
            runs.append({"text": match.group(2), "bold": True, "italic": False})
        elif match.group(3):  # *italic*
            runs.append({"text": match.group(3), "bold": False, "italic": True})
        elif match.group(4):  # plain
            runs.append({"text": match.group(4), "bold": False, "italic": False})

    return runs


def render_markdown_to_docx(
    markdown: str,
    output_path: Path,
    font_name: str = "Times New Roman",
    font_size: int = 12,
    heading1_size: int = 16,
    heading2_size: int = 14,
    heading3_size: int = 13,
    margin_top: float = 2.5,
    margin_bottom: float = 2.5,
    margin_left: float = 3.0,
    margin_right: float = 2.0,
    line_spacing: float = 1.5,
) -> None:
    """Render markdown string to DOCX file.

    Args:
        markdown: Markdown content to render.
        output_path: Path for output .docx file.
        font_name: Font family name.
        font_size: Body text size in points.
        heading1_size: H1 size in points.
        heading2_size: H2 size in points.
        heading3_size: H3 size in points.
        margin_*: Page margins in cm.
        line_spacing: Line spacing multiplier.
    """
    doc = Document()

    # Set page margins
    for section in doc.sections:
        section.top_margin = Cm(margin_top)
        section.bottom_margin = Cm(margin_bottom)
        section.left_margin = Cm(margin_left)
        section.right_margin = Cm(margin_right)

    heading_sizes = {1: heading1_size, 2: heading2_size, 3: heading3_size}
    elements = parse_markdown_elements(markdown)

    for elem in elements:
        if elem["type"] == "page_break":
            doc.add_page_break()

        elif elem["type"] == "heading":
            level = min(elem["level"], 3)
            para = doc.add_heading(elem["text"], level=level)
            for run in para.runs:
                run.font.name = font_name
                run.font.size = Pt(heading_sizes.get(level, heading3_size))

        elif elem["type"] == "blockquote":
            para = doc.add_paragraph()
            para.paragraph_format.left_indent = Cm(1.0)
            run = para.add_run(elem["text"])
            run.font.name = font_name
            run.font.size = Pt(font_size)
            run.italic = True

        elif elem["type"] == "paragraph":
            para = doc.add_paragraph()
            para.paragraph_format.line_spacing = line_spacing
            for run_data in elem.get("runs", []):
                run = para.add_run(run_data["text"])
                run.font.name = font_name
                run.font.size = Pt(font_size)
                run.bold = run_data.get("bold", False)
                run.italic = run_data.get("italic", False)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    doc.save(str(output_path))
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd modules/book-translation && python -m pytest scripts/tests/test_renderer.py -v
```

Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add modules/book-translation/scripts/lib/renderer.py modules/book-translation/scripts/tests/test_renderer.py
git commit -m "feat(book-translation): add DOCX renderer with TDD tests"
```

---

## Chunk 4: CLI Tests

### Task 7: Implement manage.py CLI

**Files:**
- Create: `modules/book-translation/scripts/manage.py`
- Create: `modules/book-translation/scripts/extract.py`
- Create: `modules/book-translation/scripts/render.py`

- [ ] **Step 1: Create manage.py CLI**

```python
# modules/book-translation/scripts/manage.py
"""CLI for book translation project management."""
import sys
from pathlib import Path

import click
import yaml

# Add scripts dir to path
sys.path.insert(0, str(Path(__file__).parent))

from lib.config_loader import (
    init_config,
    init_progress,
    load_config,
    load_progress,
    save_progress,
    get_next_chapter,
    slugify,
    VALID_STATUSES,
)
from lib.extractor import extract_to_chapters, detect_format, is_scanned_pdf
from lib.merger import merge_chapters
from lib.renderer import render_markdown_to_docx

PROJECTS_DIR = Path(__file__).parent.parent / "projects"

# Color helpers
GREEN = "green"
RED = "red"
YELLOW = "yellow"
BLUE = "blue"


@click.group()
def cli():
    """Book Translation Manager — manage translation projects."""
    pass


@cli.command()
@click.argument("title")
@click.option("--author", required=True, help="Book author name")
@click.option("--source", required=True, type=click.Path(exists=True), help="Path to source PDF/EPUB/text")
def init(title, author, source):
    """Initialize a new book translation project."""
    source_path = Path(source)
    fmt = detect_format(source_path)

    # Generate slug using shared function
    slug = slugify(title)

    project_dir = PROJECTS_DIR / slug
    if project_dir.exists():
        click.secho(f"Project '{slug}' already exists!", fg=RED)
        return

    # Create project structure
    project_dir.mkdir(parents=True)
    (project_dir / "source" / "chapters").mkdir(parents=True)
    (project_dir / "translated").mkdir()
    (project_dir / "output").mkdir()

    # Copy source file
    import shutil
    dest = project_dir / "source" / f"original{source_path.suffix}"
    shutil.copy2(source_path, dest)

    # Create config
    config = init_config(
        project_dir=project_dir,
        title=title,
        author=author,
        source_format=fmt,
        source_file=f"source/original{source_path.suffix}",
    )

    # Create empty glossary and style-guide
    (project_dir / "glossary.md").write_text(
        f"# Glossary — {title}\n\n"
        "| English | Vietnamese | Context | Notes |\n"
        "|---------|-----------|---------|-------|\n",
        encoding="utf-8",
    )
    (project_dir / "style-guide.md").write_text(
        f"# Style Guide — {title}\n\n"
        "(To be defined with Claude using define-style skill)\n",
        encoding="utf-8",
    )

    click.secho(f"✓ Project '{slug}' created at {project_dir}", fg=GREEN)
    click.secho(f"  Source: {fmt} ({source_path.name})", fg=BLUE)
    click.echo(f"  Next: run 'python manage.py extract {slug}'")


@cli.command()
@click.argument("slug")
def extract(slug):
    """Extract source file into chapter markdown files."""
    project_dir = PROJECTS_DIR / slug
    if not project_dir.exists():
        click.secho(f"Project '{slug}' not found!", fg=RED)
        return

    config = load_config(project_dir)
    source_file = project_dir / config["source"]["file"]
    chapters_dir = project_dir / "source" / "chapters"

    click.echo(f"Extracting {config['source']['format']}...")

    try:
        chapters = extract_to_chapters(source_file, chapters_dir)
    except ValueError as e:
        click.secho(f"Error: {e}", fg=RED)
        return

    # Init progress
    max_words = config.get("chunking", {}).get("max_section_words", 3000)
    progress = init_progress(project_dir, chapters, max_section_words=max_words)

    click.secho(f"✓ Extracted {len(chapters)} chapters:", fg=GREEN)
    for ch in chapters:
        click.echo(f"  {ch['id']}: {ch['title']} ({ch['word_count']} words)")

    click.echo(f"\nReview files in {chapters_dir}")
    click.echo("Then ask Claude: 'dinh nghia van phong cho sach nay'")


@cli.command()
@click.argument("slug")
def status(slug):
    """Show translation progress for a project."""
    project_dir = PROJECTS_DIR / slug
    if not project_dir.exists():
        click.secho(f"Project '{slug}' not found!", fg=RED)
        return

    config = load_config(project_dir)
    progress = load_progress(project_dir)

    title = config["book"]["title"]
    author = config["book"]["author"]
    book_status = progress["status"]

    click.secho(f"\n📖 {title} — {author}", fg=BLUE, bold=True)
    click.echo(f"   Status: {book_status}\n")

    status_icons = {
        "extracted": "⏳",
        "translating": "🔄",
        "draft": "📝",
        "reviewing": "🔍",
        "approved": "✅",
    }

    total = len(progress["chapters"])
    approved = sum(1 for ch in progress["chapters"] if ch["status"] == "approved")

    click.echo(f"   {'Chapter':<35} {'Words':>6}  Status")
    click.echo(f"   {'─' * 55}")
    for ch in progress["chapters"]:
        icon = status_icons.get(ch["status"], "❓")
        sections_info = ""
        if ch.get("sections", 1) > 1:
            section_statuses = ch.get("section_status", [])
            parts = []
            for ss in section_statuses:
                for k, v in ss.items():
                    parts.append(f"{k}:{status_icons.get(v, '❓')}")
            sections_info = f" ({' '.join(parts)})"
        click.echo(
            f"   {ch['id']}  {ch.get('title', ''):<30} "
            f"{ch.get('word_count_source', 0):>6}  {icon} {ch['status']}{sections_info}"
        )

    click.echo(f"   {'─' * 55}")
    click.echo(f"   Progress: {approved}/{total} approved")

    next_ch = get_next_chapter(progress)
    if next_ch:
        click.echo(f"\n   Next: {next_ch['id']} ({next_ch.get('title', '')})")


@cli.command()
@click.argument("slug")
@click.option("--chapter", type=int, default=None, help="Render single chapter")
@click.option("--full", is_flag=True, help="Render full book")
@click.option("--bilingual", is_flag=True, help="Render bilingual EN/VI")
@click.option("--force", is_flag=True, help="Render even if chapters not approved")
def render(slug, chapter, full, bilingual, force):
    """Render translated markdown to DOCX."""
    project_dir = PROJECTS_DIR / slug
    if not project_dir.exists():
        click.secho(f"Project '{slug}' not found!", fg=RED)
        return

    config = load_config(project_dir)
    progress = load_progress(project_dir)
    translated_dir = project_dir / "translated"
    output_dir = project_dir / "output"
    output_dir.mkdir(exist_ok=True)

    if chapter:
        # Single chapter render
        ch_id = f"ch{chapter:02d}"
        ch_data = next((c for c in progress["chapters"] if c["id"] == ch_id), None)
        if not ch_data:
            click.secho(f"Chapter {ch_id} not found!", fg=RED)
            return
        if ch_data["status"] not in ("draft", "reviewing", "approved") and not force:
            click.secho(f"Chapter {ch_id} not translated yet (status: {ch_data['status']})", fg=YELLOW)
            return
        chapters_to_render = [ch_data]
        output_file = output_dir / f"{slug}-{ch_id}.docx"
    elif full:
        if not force:
            not_approved = [c for c in progress["chapters"] if c["status"] != "approved"]
            if not_approved:
                click.secho(
                    f"{len(not_approved)} chapters not yet approved. Use --force to render anyway.",
                    fg=YELLOW,
                )
                return
        chapters_to_render = progress["chapters"]
        suffix = "-bilingual" if bilingual else "-final"
        output_file = output_dir / f"{slug}{suffix}.docx"
    else:
        click.echo("Specify --chapter N or --full")
        return

    click.echo(f"Rendering {len(chapters_to_render)} chapter(s)...")

    try:
        merged = merge_chapters(translated_dir, chapters_to_render)
    except FileNotFoundError as e:
        click.secho(f"Error: {e}", fg=RED)
        return

    if bilingual:
        source_dir = project_dir / "source" / "chapters"
        try:
            source_merged = merge_chapters(source_dir, chapters_to_render)
        except FileNotFoundError:
            click.secho("Source chapters not found for bilingual mode!", fg=RED)
            return
        merged = _interleave_bilingual(source_merged, merged)

    render_markdown_to_docx(merged, output_file)
    click.secho(f"✓ Rendered to {output_file}", fg=GREEN)


def _interleave_bilingual(source_md: str, translated_md: str) -> str:
    """Interleave source (EN) and translated (VI) paragraphs."""
    source_paras = [p for p in source_md.split("\n\n") if p.strip()]
    trans_paras = [p for p in translated_md.split("\n\n") if p.strip()]
    result = []
    max_len = max(len(source_paras), len(trans_paras))
    for i in range(max_len):
        if i < len(source_paras):
            result.append(f"*[EN] {source_paras[i]}*")
        if i < len(trans_paras):
            result.append(trans_paras[i])
    return "\n\n".join(result)


@cli.command()
@click.argument("slug")
def validate(slug):
    """Validate project before rendering."""
    project_dir = PROJECTS_DIR / slug
    if not project_dir.exists():
        click.secho(f"Project '{slug}' not found!", fg=RED)
        return

    progress = load_progress(project_dir)
    translated_dir = project_dir / "translated"
    source_dir = project_dir / "source" / "chapters"
    errors = []
    warnings = []

    for ch in progress["chapters"]:
        ch_id = ch["id"]
        sections = ch.get("sections", 1)
        if sections <= 1:
            f = translated_dir / f"{ch_id}.md"
            if not f.exists():
                errors.append(f"Missing: {f.name}")
            elif f.stat().st_size < 10:
                warnings.append(f"Nearly empty: {f.name}")
        else:
            for s in range(1, sections + 1):
                f = translated_dir / f"{ch_id}-s{s}.md"
                if not f.exists():
                    errors.append(f"Missing: {f.name}")

    if errors:
        click.secho(f"\n✗ {len(errors)} error(s):", fg=RED)
        for e in errors:
            click.echo(f"  - {e}")
    if warnings:
        click.secho(f"\n⚠ {len(warnings)} warning(s):", fg=YELLOW)
        for w in warnings:
            click.echo(f"  - {w}")
    if not errors and not warnings:
        click.secho("✓ All checks passed!", fg=GREEN)


if __name__ == "__main__":
    cli()
```

- [ ] **Step 2: Create extract.py entry script**

```python
# modules/book-translation/scripts/extract.py
"""Standalone script for extracting PDF/EPUB to markdown chapters."""
import sys
from pathlib import Path

import click

sys.path.insert(0, str(Path(__file__).parent))
from lib.extractor import extract_to_chapters, detect_format, is_scanned_pdf


@click.command()
@click.argument("source", type=click.Path(exists=True))
@click.argument("output_dir", type=click.Path())
def main(source, output_dir):
    """Extract PDF/EPUB/text to markdown chapter files."""
    source_path = Path(source)
    out = Path(output_dir)
    out.mkdir(parents=True, exist_ok=True)

    fmt = detect_format(source_path)
    click.echo(f"Extracting {fmt}: {source_path.name}")

    chapters = extract_to_chapters(source_path, out)
    click.secho(f"✓ {len(chapters)} chapters extracted to {out}", fg="green")
    for ch in chapters:
        click.echo(f"  {ch['id']}: {ch['title']} ({ch['word_count']} words)")


if __name__ == "__main__":
    main()
```

- [ ] **Step 3: Create render.py entry script**

```python
# modules/book-translation/scripts/render.py
"""Standalone script for rendering markdown to DOCX."""
import sys
from pathlib import Path

import click

sys.path.insert(0, str(Path(__file__).parent))
from lib.renderer import render_markdown_to_docx


@click.command()
@click.argument("input_file", type=click.Path(exists=True))
@click.argument("output_file", type=click.Path())
@click.option("--font", default="Times New Roman", help="Font name")
@click.option("--font-size", default=12, help="Body font size in pt")
def main(input_file, output_file, font, font_size):
    """Render a markdown file to DOCX."""
    md = Path(input_file).read_text(encoding="utf-8")
    output = Path(output_file)
    render_markdown_to_docx(md, output, font_name=font, font_size=font_size)
    click.secho(f"✓ Rendered to {output}", fg="green")


if __name__ == "__main__":
    main()
```

- [ ] **Step 4: Test CLI commands manually**

```bash
cd modules/book-translation
python scripts/manage.py --help
python scripts/manage.py init --help
python scripts/manage.py status --help
```

Expected: Help text displays correctly for all commands.

- [ ] **Step 5: Commit**

```bash
git add modules/book-translation/scripts/manage.py modules/book-translation/scripts/extract.py modules/book-translation/scripts/render.py
git commit -m "feat(book-translation): add manage.py CLI with init/extract/status/render/validate"
```

---

## Chunk 5: Claude Skills & Integration Test

### Task 8: Add CLI tests for manage.py

**Files:**
- Create: `modules/book-translation/scripts/tests/test_manage_cli.py`

- [ ] **Step 1: Write CLI tests using Click's CliRunner**

```python
# modules/book-translation/scripts/tests/test_manage_cli.py
"""Tests for manage.py CLI commands."""
import pytest
import shutil
from pathlib import Path
from click.testing import CliRunner

from lib.extractor import extract_to_chapters

# Import after conftest.py sets up path
import sys
sys.path.insert(0, str(Path(__file__).parent.parent))
from manage import cli


FIXTURES_DIR = Path(__file__).parent / "fixtures"


@pytest.fixture
def runner():
    return CliRunner()


@pytest.fixture
def sample_pdf():
    path = FIXTURES_DIR / "sample.pdf"
    if not path.exists():
        pytest.skip("sample.pdf fixture not created yet")
    return path


@pytest.fixture
def initialized_project(runner, sample_pdf, tmp_path, monkeypatch):
    """Create an initialized project for testing."""
    # Patch PROJECTS_DIR to use tmp_path
    import manage
    monkeypatch.setattr(manage, "PROJECTS_DIR", tmp_path)
    result = runner.invoke(cli, ["init", "Test Book", "--author", "Author", "--source", str(sample_pdf)])
    assert result.exit_code == 0
    return tmp_path / "test-book"


class TestInitCommand:
    def test_creates_project(self, runner, sample_pdf, tmp_path, monkeypatch):
        import manage
        monkeypatch.setattr(manage, "PROJECTS_DIR", tmp_path)
        result = runner.invoke(cli, ["init", "My Book", "--author", "Author", "--source", str(sample_pdf)])
        assert result.exit_code == 0
        assert "created" in result.output.lower()
        assert (tmp_path / "my-book").exists()

    def test_duplicate_project_fails(self, runner, sample_pdf, tmp_path, monkeypatch):
        import manage
        monkeypatch.setattr(manage, "PROJECTS_DIR", tmp_path)
        runner.invoke(cli, ["init", "My Book", "--author", "A", "--source", str(sample_pdf)])
        result = runner.invoke(cli, ["init", "My Book", "--author", "A", "--source", str(sample_pdf)])
        assert "already exists" in result.output.lower()


class TestStatusCommand:
    def test_shows_status(self, runner, initialized_project, monkeypatch):
        import manage
        monkeypatch.setattr(manage, "PROJECTS_DIR", initialized_project.parent)
        # Extract first to have chapters
        runner.invoke(cli, ["extract", "test-book"])
        result = runner.invoke(cli, ["status", "test-book"])
        assert result.exit_code == 0
        assert "Test Book" in result.output or "test-book" in result.output

    def test_missing_project(self, runner, tmp_path, monkeypatch):
        import manage
        monkeypatch.setattr(manage, "PROJECTS_DIR", tmp_path)
        result = runner.invoke(cli, ["status", "nonexistent"])
        assert "not found" in result.output.lower()


class TestValidateCommand:
    def test_validate_missing_translations(self, runner, initialized_project, monkeypatch):
        import manage
        monkeypatch.setattr(manage, "PROJECTS_DIR", initialized_project.parent)
        runner.invoke(cli, ["extract", "test-book"])
        result = runner.invoke(cli, ["validate", "test-book"])
        assert "error" in result.output.lower() or "missing" in result.output.lower()
```

- [ ] **Step 2: Run CLI tests**

```bash
cd modules/book-translation && python -m pytest scripts/tests/test_manage_cli.py -v
```

Expected: All tests PASS.

- [ ] **Step 3: Commit**

```bash
git add modules/book-translation/scripts/tests/test_manage_cli.py
git commit -m "test(book-translation): add CLI tests for manage.py"
```

---

### Task 9: Create init-project skill

**Files:**
- Create: `.claude/skills/book-translation/init-project.md`

- [ ] **Step 1: Write init-project skill**

```markdown
---
name: init-project
description: Initialize a new book translation project — use when user says "dich sach moi" or provides a PDF/EPUB file for translation
---

# Init Book Translation Project

## Trigger
User says "dich sach moi", "translate a new book", or provides a PDF/EPUB file.

## Steps

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

### 4. User reviews extraction
Show the user:
- Number of chapters detected
- Word count per chapter
- Ask them to review `projects/{slug}/source/chapters/` for accuracy

If chapter detection is wrong, user can:
- Edit the markdown files manually
- Re-run with a custom chapter pattern in config.yaml

### 5. Show status
```bash
python scripts/manage.py status {slug}
```

### 6. Transition
Once user confirms extraction looks good, invoke **define-style** skill to brainstorm the style guide for this book.
```

- [ ] **Step 2: Commit**

```bash
git add .claude/skills/book-translation/init-project.md
git commit -m "feat(book-translation): add init-project skill"
```

---

### Task 10: Create define-style skill

**Files:**
- Create: `.claude/skills/book-translation/define-style.md`

- [ ] **Step 1: Write define-style skill**

```markdown
---
name: define-style
description: Brainstorm and define the translation style guide for a book — use after init-project or when user wants to adjust style
---

# Define Translation Style Guide

## Trigger
After init-project completes, or user says "dinh nghia van phong", "adjust style guide".

## Context to Load
- Read 2-3 sample paragraphs from `projects/{slug}/source/chapters/ch01.md`
- Read `modules/book-translation/memory/style-feedback.md` (cross-book rules if any)

## Steps

### 1. Analyze source text
Read the first 2-3 paragraphs of chapter 1. Identify:
- Genre (philosophical, literary, technical, self-help, etc.)
- Author's voice (formal, conversational, academic, poetic)
- Target audience
- Complexity level

### 2. Ask clarifying questions (one at a time)
- **Target reader:** Who will read the translation? (general public / academics / students)
- **Han-Viet level:** How much Sino-Vietnamese vocabulary? (heavy / moderate / light)
- **Tone:** What feeling should the translation convey? (formal-elegant / accessible-warm / neutral)
- **Pronouns:** How should toi/ban or other forms be used?
- **Technical terms:** Translate fully / translate with EN in parentheses first time / keep EN?

### 3. Apply cross-book feedback
Check `modules/book-translation/memory/style-feedback.md` for rules from previous books.
Apply relevant rules, skip irrelevant ones.

### 4. Draft style guide
Write a complete style-guide.md based on answers. Include:
- Voice description
- Pronoun rules
- Terminology approach
- Translation rules (no word-by-word, no repetition in 3 sentences, etc.)
- Anti-patterns
- Reference: DICH_PROMPT_1.txt and DICH_PROMPT_2.txt patterns in `documents/07-archived/legacy/`

### 5. User approval
Present the draft. User approves or requests changes.
Save to `projects/{slug}/style-guide.md`.

### 6. Initialize glossary
If the book has specialized terms, start populating `projects/{slug}/glossary.md` with the first set of terms.

### 7. Transition
Tell user: "Style guide saved. You can now start translating with 'dich chapter 1' or 'tiep tuc dich'."
```

- [ ] **Step 2: Commit**

```bash
git add .claude/skills/book-translation/define-style.md
git commit -m "feat(book-translation): add define-style skill"
```

---

### Task 11: Create translate-section skill

**Files:**
- Create: `.claude/skills/book-translation/translate-section.md`

- [ ] **Step 1: Write translate-section skill**

```markdown
---
name: translate-section
description: Core translation skill — translate a chapter/section using 3-pass method (Translate, Reflect, Improve). Use when user says "dich chapter X", "tiep tuc dich", or "translate next"
---

# Translate Section

## Trigger
User says "dich chapter X", "tiep tuc dich", "translate next", or "dich tiep".

## Context to Load (Priority Order)
1. **Always:** `projects/{slug}/style-guide.md`
2. **Always:** `projects/{slug}/glossary.md`
3. **Always:** Source section from `projects/{slug}/source/chapters/{chapter}.md`
4. **If exists:** Last 1-2 translated sections (for voice consistency)
5. **If exists:** `modules/book-translation/memory/translation-patterns.md` (top 10 examples)

## Determine What to Translate

1. Read `projects/{slug}/progress.yaml`
2. If user specified a chapter: use that chapter
3. If user said "tiep tuc dich": find the next chapter with status `extracted` or `translating`
4. If chapter has multiple sections: translate the next untranslated section

## 3-Pass Translation

### Pass 1: TRANSLATE
- Read the source section completely
- Read style-guide.md rules
- Read glossary.md terms
- Translate the entire section following the style guide
- Preserve paragraph structure from source
- Apply glossary terms consistently
- Use Vietnamese idioms where appropriate

### Pass 2: REFLECT
Self-review checklist:
- [ ] No content omitted from source?
- [ ] All glossary terms used consistently?
- [ ] No word-by-word translation patterns?
- [ ] No word repetition within 3 consecutive sentences?
- [ ] Paragraph structure matches source?
- [ ] Formatting preserved (bold, italic, headings)?
- [ ] QC 3 layers: logic content → aesthetic style → grammar correctness

### Pass 3: IMPROVE
- Fix all issues found in reflection
- Read the full translation aloud (mentally) for flow
- Polish final version

## After Translation

1. **Write file:** Save to `projects/{slug}/translated/{chapter}.md` with frontmatter:
   ```yaml
   ---
   chapter: {N}
   section: {S or null}
   source: "source/chapters/{chapter}.md"
   status: draft
   translated_at: "{date}"
   pass: 3
   ---
   ```

2. **Update progress:** Edit `projects/{slug}/progress.yaml`:
   - Set chapter/section status to `draft`
   - Update `last_updated`

3. **Report to user:**
   - Word count (source vs translated, ratio)
   - Number of glossary terms applied
   - Any new terms encountered (suggest adding to glossary)
   - Any passages that were particularly challenging

4. **Ask:** "Ban muon review chapter nay, hay tiep tuc dich chapter tiep theo?"
```

- [ ] **Step 2: Commit**

```bash
git add .claude/skills/book-translation/translate-section.md
git commit -m "feat(book-translation): add translate-section skill (core 3-pass)"
```

---

### Task 12: Install dependencies and run full test suite

**Files:**
- None (validation only)

- [ ] **Step 1: Install Python dependencies**

```bash
cd modules/book-translation
pip install -r scripts/requirements.txt
```

- [ ] **Step 2: Generate test fixtures**

```bash
cd modules/book-translation
python scripts/tests/create_fixtures.py
```

- [ ] **Step 3: Run full test suite**

```bash
cd modules/book-translation
python -m pytest scripts/tests/ -v --tb=short
```

Expected: All tests pass.

- [ ] **Step 4: Test end-to-end with fixture PDF**

```bash
cd modules/book-translation
python scripts/manage.py init "Test Book" --author "Test Author" --source scripts/tests/fixtures/sample.pdf
python scripts/manage.py status test-book
python scripts/manage.py extract test-book
python scripts/manage.py status test-book
```

Expected: Project created, chapters extracted, status shows correctly.

- [ ] **Step 5: Create a mock translated chapter and test render**

```bash
# Create a mock translated file to test render
cat > projects/test-book/translated/ch01.md << 'ENDOFFILE'
---
chapter: 1
section: null
source: "source/chapters/ch01.md"
status: draft
translated_at: "2026-03-27"
pass: 3
---

# Chuong 1: Khoi Dau

Day la doan van dau tien cua chuong mot.

No chua mot so **noi dung co ban** de kiem tra viec trich xuat.

Doan van thu hai voi cac *khai niem in dam*.
ENDOFFILE
```

```bash
cd modules/book-translation
python scripts/manage.py render test-book --chapter 1 --force
ls projects/test-book/output/
```

Expected: `test-book-ch01.docx` created in output directory.

- [ ] **Step 6: Clean up test project**

```bash
rm -rf modules/book-translation/projects/test-book
```

- [ ] **Step 7: Final commit**

```bash
git add modules/book-translation/
git add .claude/skills/book-translation/
git commit -m "feat(book-translation): complete Phase 1 MVP — extract, translate, render pipeline"
```

---

## Summary

| Task | Component | Tests |
|------|-----------|-------|
| 1 | Module scaffold, .gitignore, README, memory templates | — |
| 2 | conftest.py for test path setup | — |
| 3 | config_loader.py | test_config_loader.py (10 tests) |
| 4 | extractor.py (PDF→MD) | test_extractor.py (8 tests) |
| 5 | merger.py | test_merger.py (5 tests) |
| 6 | renderer.py (MD→DOCX) | test_renderer.py (8 tests) |
| 7 | manage.py CLI + extract.py + render.py entry scripts | — |
| 8 | CLI tests for manage.py | test_manage_cli.py (5 tests) |
| 9 | init-project.md skill | — |
| 10 | define-style.md skill | — |
| 11 | translate-section.md skill | — |
| 12 | Install deps, full test suite, end-to-end validation | Integration test |

**Phase 1 delivers:** Working pipeline from PDF → extract chapters → Claude translates (via skill) → render DOCX. User can init a project, extract, translate chapter by chapter, and render output.

**Phase 2 will add:** review-translation skill, consistency-check skill, memory system, bilingual render mode.
