# Book Translation Module Phase 3 — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add EPUB extraction, enhanced rendering (footnotes, multi-line blockquotes, TOC), comprehensive validation, and state repair to complete the book translation pipeline.

**Architecture:** Extend existing extractor.py with EPUB support (ebooklib + BeautifulSoup). Enhance renderer.py with footnote and multi-line blockquote parsing. Create validator.py for comprehensive pre-render checks. Add repair command to manage.py for state recovery.

**Tech Stack:** Python 3.10+, ebooklib, beautifulsoup4, python-docx, pymupdf, pytest (ebooklib + bs4 already in requirements.txt)

**Spec Document:** `documents/03-planning/superpowers/specs/2026-03-27-book-translation-design.md` (Section 12, Phase 3)

**Done when:** Full pipeline PDF/EPUB → extract → translate → review → consistency → render DOCX works end-to-end.

---

## Chunk 1: EPUB Extraction

### Task 1: Add EPUB extraction to extractor.py with tests (TDD)

**Files:**
- Create: `modules/book-translation/scripts/tests/fixtures/sample.epub`
- Modify: `modules/book-translation/scripts/tests/test_extractor.py`
- Modify: `modules/book-translation/scripts/lib/extractor.py`

- [ ] **Step 1: Create EPUB test fixture generator**

Add to `modules/book-translation/scripts/tests/create_fixtures.py`:

```python
def create_sample_epub():
    """Create a small EPUB with 2 chapters for testing."""
    from ebooklib import epub

    book = epub.EpubBook()
    book.set_identifier("test-book-001")
    book.set_title("Test Book")
    book.set_language("en")
    book.add_author("Test Author")

    # Chapter 1
    ch1 = epub.EpubHtml(title="Chapter 1: The Start", file_name="ch1.xhtml", lang="en")
    ch1.content = (
        "<h1>Chapter 1: The Start</h1>"
        "<p>This is the <strong>first</strong> paragraph.</p>"
        "<p>This has <em>italic</em> text.</p>"
        "<blockquote><p>A quoted passage here.</p></blockquote>"
    )
    book.add_item(ch1)

    # Chapter 2
    ch2 = epub.EpubHtml(title="Chapter 2: The End", file_name="ch2.xhtml", lang="en")
    ch2.content = (
        "<h1>Chapter 2: The End</h1>"
        "<p>The final chapter wraps up.</p>"
        "<p>It has a footnote reference<sup>1</sup>.</p>"
    )
    book.add_item(ch2)

    # Table of contents and spine
    book.toc = [epub.Link("ch1.xhtml", "Chapter 1: The Start", "ch1"),
                epub.Link("ch2.xhtml", "Chapter 2: The End", "ch2")]
    book.add_item(epub.EpubNcx())
    book.add_item(epub.EpubNav())
    book.spine = ["nav", ch1, ch2]

    epub.write_epub(str(FIXTURES_DIR / "sample.epub"), book)
    print(f"Created {FIXTURES_DIR / 'sample.epub'}")
```

Add call in `if __name__ == "__main__"`:
```python
if __name__ == "__main__":
    create_sample_pdf()
    create_sample_epub()
```

Run: `cd modules/book-translation && python scripts/tests/create_fixtures.py`

- [ ] **Step 2: Write failing tests for EPUB extraction**

Add to `test_extractor.py`:

```python
class TestExtractEpub:
    @pytest.fixture
    def sample_epub(self):
        path = FIXTURES_DIR / "sample.epub"
        if not path.exists():
            pytest.skip("sample.epub fixture not created yet")
        return path

    def test_extracts_chapters(self, sample_epub):
        from lib.extractor import extract_epub
        chapters = extract_epub(sample_epub)
        assert len(chapters) >= 2
        assert chapters[0]["id"] == "ch01"
        assert "The Start" in chapters[0]["title"]

    def test_preserves_bold_as_markdown(self, sample_epub):
        from lib.extractor import extract_epub
        chapters = extract_epub(sample_epub)
        assert "**" in chapters[0]["content"]  # bold preserved as **text**

    def test_preserves_italic_as_markdown(self, sample_epub):
        from lib.extractor import extract_epub
        chapters = extract_epub(sample_epub)
        assert "*" in chapters[0]["content"]  # italic preserved as *text*

    def test_preserves_blockquote(self, sample_epub):
        from lib.extractor import extract_epub
        chapters = extract_epub(sample_epub)
        assert "> " in chapters[0]["content"]  # blockquote preserved


class TestExtractToChaptersEpub:
    def test_epub_writes_chapter_files(self, tmp_path):
        sample_epub = FIXTURES_DIR / "sample.epub"
        if not sample_epub.exists():
            pytest.skip("sample.epub fixture not created yet")
        output_dir = tmp_path / "chapters"
        output_dir.mkdir()
        chapters = extract_to_chapters(sample_epub, output_dir)
        assert len(chapters) >= 2
        md_files = list(output_dir.glob("ch*.md"))
        assert len(md_files) >= 2
```

- [ ] **Step 3: Run tests to verify they fail**

```bash
cd modules/book-translation && python -m pytest scripts/tests/test_extractor.py::TestExtractEpub -v
```

Expected: FAIL — `ImportError: cannot import name 'extract_epub'`

- [ ] **Step 4: Implement EPUB extraction in extractor.py**

Add these functions to `extractor.py`:

```python
# Add imports at top of file
from bs4 import BeautifulSoup

def extract_epub(epub_path: Path) -> list[dict[str, Any]]:
    """Extract chapters from an EPUB file to structured chapter data.

    Uses ebooklib to read EPUB structure and BeautifulSoup to parse HTML content.
    Converts HTML formatting to markdown (bold, italic, blockquote).

    Returns:
        List of chapter dicts: {id, title, content, page}
    """
    import ebooklib
    from ebooklib import epub

    book = epub.read_epub(str(epub_path), options={"ignore_ncx": True})
    chapters = []
    seq = 0

    for item in book.get_items_of_type(ebooklib.ITEM_DOCUMENT):
        content = item.get_content().decode("utf-8", errors="replace")
        soup = BeautifulSoup(content, "html.parser")

        # Skip nav/toc pages
        body = soup.find("body") or soup
        text = body.get_text(strip=True)
        if not text or len(text) < 20:
            continue

        seq += 1
        # Extract title from first heading
        heading = body.find(re.compile(r"^h[1-3]$"))
        title = heading.get_text(strip=True) if heading else f"Chapter {seq}"

        # Convert HTML to markdown
        md_content = _html_to_markdown(body, skip_first_heading=True)

        chapters.append({
            "id": f"ch{seq:02d}",
            "title": title,
            "content": md_content,
            "page": 0,
        })

    return chapters


def _html_to_markdown(element, skip_first_heading: bool = False) -> str:
    """Convert an HTML element tree to markdown text.

    Handles: p, strong/b, em/i, blockquote, h1-h6, br, sup (footnotes).
    """
    parts = []
    first_heading_skipped = False

    for child in element.children:
        if not hasattr(child, "name"):
            # NavigableString (text node)
            text = str(child).strip()
            if text:
                parts.append(text)
            continue

        tag = child.name

        if tag in ("h1", "h2", "h3", "h4", "h5", "h6"):
            if skip_first_heading and not first_heading_skipped:
                first_heading_skipped = True
                continue
            level = int(tag[1])
            parts.append(f"\n{'#' * level} {child.get_text(strip=True)}\n")

        elif tag == "p":
            para_text = _inline_to_markdown(child)
            if para_text.strip():
                parts.append(f"\n{para_text}\n")

        elif tag == "blockquote":
            quote_text = child.get_text(strip=True)
            parts.append(f"\n> {quote_text}\n")

        elif tag == "br":
            parts.append("\n")

        elif tag in ("div", "section", "article"):
            # Recurse into container elements
            inner = _html_to_markdown(child, skip_first_heading=False)
            if inner.strip():
                parts.append(inner)

    return "\n".join(parts).strip()


def _inline_to_markdown(element) -> str:
    """Convert inline HTML elements to markdown text."""
    result = []
    for child in element.children:
        if not hasattr(child, "name"):
            result.append(str(child))
            continue
        tag = child.name
        text = child.get_text()
        if tag in ("strong", "b"):
            result.append(f"**{text}**")
        elif tag in ("em", "i"):
            result.append(f"*{text}*")
        elif tag == "sup":
            result.append(f"[^{text}]")
        else:
            result.append(text)
    return "".join(result)
```

Update `extract_to_chapters` to handle EPUB:

```python
# Replace the epub ValueError block in extract_to_chapters:
    elif fmt == "epub":
        chapters = extract_epub(source_path)
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
cd modules/book-translation && python -m pytest scripts/tests/test_extractor.py -v
```

Expected: All tests PASS.

- [ ] **Step 6: Commit**

```bash
git add modules/book-translation/scripts/lib/extractor.py modules/book-translation/scripts/tests/test_extractor.py modules/book-translation/scripts/tests/create_fixtures.py
git commit -m "feat(book-translation): add EPUB extraction support"
```

---

## Chunk 2: Enhanced Renderer

### Task 2: Add footnote and multi-line blockquote support to renderer.py (TDD)

**Files:**
- Modify: `modules/book-translation/scripts/tests/test_renderer.py`
- Modify: `modules/book-translation/scripts/lib/renderer.py`

- [ ] **Step 1: Write failing tests**

Add to `test_renderer.py`:

```python
class TestFootnoteRendering:
    def test_parses_footnote_reference(self):
        elements = parse_markdown_elements("Text with a footnote[^1] here.\n")
        assert elements[0]["type"] == "paragraph"
        runs = elements[0]["runs"]
        assert any("[^1]" in r["text"] for r in runs)

    def test_parses_footnote_definition(self):
        elements = parse_markdown_elements("[^1]: This is the footnote text.\n")
        assert elements[0]["type"] == "footnote_def"
        assert elements[0]["id"] == "1"
        assert elements[0]["text"] == "This is the footnote text."


class TestMultiLineBlockquote:
    def test_parses_consecutive_blockquote_lines(self):
        md = "> Line one of quote.\n> Line two of quote.\n"
        elements = parse_markdown_elements(md)
        # Should merge into single blockquote
        blockquotes = [e for e in elements if e["type"] == "blockquote"]
        assert len(blockquotes) == 1
        assert "Line one" in blockquotes[0]["text"]
        assert "Line two" in blockquotes[0]["text"]


class TestDocxFootnotes:
    def test_renders_footnote_definition(self, tmp_path):
        md = "Main text[^1] here.\n\n[^1]: Footnote content.\n"
        output = tmp_path / "test.docx"
        render_markdown_to_docx(md, output)
        doc = Document(str(output))
        # Footnote should appear as small text at end or inline
        all_text = " ".join(p.text for p in doc.paragraphs)
        assert "Footnote content" in all_text
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd modules/book-translation && python -m pytest scripts/tests/test_renderer.py::TestFootnoteRendering -v
```

Expected: FAIL — `footnote_def` type not recognized.

- [ ] **Step 3: Update parse_markdown_elements in renderer.py**

Replace `parse_markdown_elements` with enhanced version:

```python
def parse_markdown_elements(markdown: str) -> list[dict]:
    """Parse markdown text into structured elements.

    Supported types: heading, paragraph, page_break, blockquote, footnote_def
    """
    elements = []
    lines = markdown.split("\n")
    i = 0
    while i < len(lines):
        line = lines[i].rstrip()
        if not line:
            i += 1
            continue

        # Page break
        if re.match(r"^-{3,}$", line):
            elements.append({"type": "page_break"})
            i += 1
            continue

        # Heading
        heading_match = re.match(r"^(#{1,6})\s+(.+)$", line)
        if heading_match:
            level = len(heading_match.group(1))
            text = heading_match.group(2).strip()
            elements.append({"type": "heading", "level": level, "text": text})
            i += 1
            continue

        # Footnote definition: [^1]: text
        fn_match = re.match(r"^\[\^(\w+)\]:\s*(.+)$", line)
        if fn_match:
            elements.append({
                "type": "footnote_def",
                "id": fn_match.group(1),
                "text": fn_match.group(2).strip(),
            })
            i += 1
            continue

        # Blockquote (merge consecutive > lines)
        if line.startswith("> "):
            quote_lines = []
            while i < len(lines) and lines[i].rstrip().startswith("> "):
                quote_lines.append(lines[i].rstrip()[2:].strip())
                i += 1
            elements.append({"type": "blockquote", "text": " ".join(quote_lines)})
            continue

        # Regular paragraph
        runs = _parse_inline_formatting(line)
        elements.append({"type": "paragraph", "text": line, "runs": runs})
        i += 1

    return elements
```

Update `render_markdown_to_docx` to handle `footnote_def`:

Add after the blockquote elif block:

```python
        elif elem["type"] == "footnote_def":
            para = doc.add_paragraph()
            para.paragraph_format.line_spacing = 1.0
            run = para.add_run(f"[{elem['id']}] {elem['text']}")
            run.font.name = font_name
            run.font.size = Pt(font_size - 2)  # smaller font for footnotes
            run.italic = True
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd modules/book-translation && python -m pytest scripts/tests/test_renderer.py -v
```

Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add modules/book-translation/scripts/lib/renderer.py modules/book-translation/scripts/tests/test_renderer.py
git commit -m "feat(book-translation): add footnote and multi-line blockquote to renderer"
```

---

## Chunk 3: Validator & Repair

### Task 3: Create comprehensive validator.py with tests (TDD)

**Files:**
- Create: `modules/book-translation/scripts/tests/test_validator.py`
- Create: `modules/book-translation/scripts/lib/validator.py`

- [ ] **Step 1: Write failing tests**

```python
# modules/book-translation/scripts/tests/test_validator.py
"""Tests for comprehensive project validator."""
import pytest
from pathlib import Path
from lib.validator import validate_project, ValidationResult


@pytest.fixture
def valid_project(tmp_path):
    """Create a minimal valid project."""
    (tmp_path / "config.yaml").write_text("book:\n  title: Test\n  slug: test\n", encoding="utf-8")
    source_dir = tmp_path / "source" / "chapters"
    source_dir.mkdir(parents=True)
    (source_dir / "ch01.md").write_text("# Ch 1\n\nContent.\n", encoding="utf-8")
    translated_dir = tmp_path / "translated"
    translated_dir.mkdir()
    (translated_dir / "ch01.md").write_text(
        "---\nchapter: 1\nstatus: draft\n---\n\n# Ch 1\n\nNoi dung.\n", encoding="utf-8")
    progress = "status: translating\nchapters:\n  - id: ch01\n    title: Ch 1\n    sections: 1\n    status: draft\n    word_count_source: 10\n"
    (tmp_path / "progress.yaml").write_text(progress, encoding="utf-8")
    (tmp_path / "glossary.md").write_text("# Glossary\n\n| English | Vietnamese | Context | Notes |\n|---|---|---|---|\n", encoding="utf-8")
    return tmp_path


class TestValidateProject:
    def test_valid_project_no_errors(self, valid_project):
        result = validate_project(valid_project)
        assert isinstance(result, ValidationResult)
        assert len(result.errors) == 0

    def test_missing_translated_file(self, valid_project):
        (valid_project / "translated" / "ch01.md").unlink()
        result = validate_project(valid_project)
        assert len(result.errors) >= 1
        assert any("missing" in e.lower() or "ch01" in e.lower() for e in result.errors)

    def test_empty_translated_file(self, valid_project):
        (valid_project / "translated" / "ch01.md").write_text("", encoding="utf-8")
        result = validate_project(valid_project)
        assert len(result.warnings) >= 1

    def test_heading_count_mismatch(self, valid_project):
        (valid_project / "source" / "chapters" / "ch01.md").write_text(
            "# Ch 1\n\n## Sec A\n\n## Sec B\n\nContent.\n", encoding="utf-8")
        result = validate_project(valid_project)
        assert len(result.warnings) >= 1

    def test_encoding_check(self, valid_project):
        # Write valid UTF-8 with Vietnamese characters
        (valid_project / "translated" / "ch01.md").write_text(
            "---\nchapter: 1\nstatus: draft\n---\n\n# Ch 1\n\nNoi dung tieng Viet co dau.\n",
            encoding="utf-8")
        result = validate_project(valid_project)
        assert len(result.errors) == 0

    def test_missing_progress_yaml(self, valid_project):
        (valid_project / "progress.yaml").unlink()
        result = validate_project(valid_project)
        assert len(result.errors) >= 1
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd modules/book-translation && python -m pytest scripts/tests/test_validator.py -v
```

Expected: FAIL — `ImportError`

- [ ] **Step 3: Implement validator.py**

```python
# modules/book-translation/scripts/lib/validator.py
"""Comprehensive project validation before rendering."""
import re
from dataclasses import dataclass, field
from pathlib import Path

import yaml


@dataclass
class ValidationResult:
    """Result of project validation."""
    errors: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)

    @property
    def is_valid(self) -> bool:
        return len(self.errors) == 0


def validate_project(project_dir: Path) -> ValidationResult:
    """Run all validation checks on a project.

    Checks:
    - progress.yaml exists and is valid
    - All translated files exist and are non-empty
    - Heading counts match between source and translated (warning)
    - UTF-8 encoding valid
    """
    result = ValidationResult()

    # Check progress.yaml
    progress_path = project_dir / "progress.yaml"
    if not progress_path.exists():
        result.errors.append("Missing progress.yaml")
        return result

    try:
        with open(progress_path, "r", encoding="utf-8") as f:
            progress = yaml.safe_load(f)
    except yaml.YAMLError as e:
        result.errors.append(f"Invalid progress.yaml: {e}")
        return result

    if not progress or "chapters" not in progress:
        result.errors.append("progress.yaml has no chapters")
        return result

    translated_dir = project_dir / "translated"
    source_dir = project_dir / "source" / "chapters"

    for ch in progress["chapters"]:
        ch_id = ch["id"]
        sections = ch.get("sections", 1)

        # Check translated files exist
        if sections <= 1:
            _check_file(translated_dir / f"{ch_id}.md", ch_id, result)
        else:
            for s in range(1, sections + 1):
                _check_file(translated_dir / f"{ch_id}-s{s}.md", f"{ch_id}-s{s}", result)

        # Check heading counts (source vs translated)
        source_file = source_dir / f"{ch_id}.md"
        translated_file = translated_dir / f"{ch_id}.md"
        if source_file.exists() and translated_file.exists():
            _check_headings(source_file, translated_file, ch_id, result)

    return result


def _check_file(file_path: Path, label: str, result: ValidationResult) -> None:
    """Check a single translated file exists and is non-empty."""
    if not file_path.exists():
        result.errors.append(f"Missing translated file: {label}")
        return

    try:
        content = file_path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        result.errors.append(f"Encoding error in {label} (not valid UTF-8)")
        return

    if len(content.strip()) < 10:
        result.warnings.append(f"Nearly empty file: {label}")


def _check_headings(source: Path, translated: Path, ch_id: str, result: ValidationResult) -> None:
    """Compare heading counts between source and translated."""
    source_text = source.read_text(encoding="utf-8")
    translated_text = translated.read_text(encoding="utf-8")

    # Strip frontmatter from translated
    if translated_text.startswith("---"):
        end = translated_text.find("---", 3)
        if end != -1:
            translated_text = translated_text[end + 3:]

    source_headings = len(re.findall(r"^#{1,6}\s+", source_text, re.MULTILINE))
    translated_headings = len(re.findall(r"^#{1,6}\s+", translated_text, re.MULTILINE))

    if source_headings != translated_headings:
        result.warnings.append(
            f"Heading count mismatch in {ch_id}: source={source_headings}, translated={translated_headings}"
        )
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd modules/book-translation && python -m pytest scripts/tests/test_validator.py -v
```

Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add modules/book-translation/scripts/lib/validator.py modules/book-translation/scripts/tests/test_validator.py
git commit -m "feat(book-translation): add comprehensive project validator"
```

---

### Task 4: Add repair command and update validate in manage.py

**Files:**
- Modify: `modules/book-translation/scripts/manage.py`
- Modify: `modules/book-translation/scripts/tests/test_manage_cli.py`

- [ ] **Step 1: Write test for repair command first (TDD)**

Add to `test_manage_cli.py`:

```python
class TestRepairCommand:
    def test_rebuilds_progress(self, runner, initialized_project, monkeypatch):
        import manage
        monkeypatch.setattr(manage, "PROJECTS_DIR", initialized_project.parent)
        runner.invoke(cli, ["extract", "test-book"])
        # Create a translated file with frontmatter
        translated_dir = initialized_project / "translated"
        (translated_dir / "ch01.md").write_text(
            "---\nchapter: 1\nstatus: approved\n---\n\n# Ch 1\n\nContent.\n",
            encoding="utf-8")
        # Delete progress.yaml
        (initialized_project / "progress.yaml").unlink()
        # Repair should rebuild it
        result = runner.invoke(cli, ["repair", "test-book"])
        assert result.exit_code == 0
        assert "Repaired" in result.output or "repaired" in result.output.lower() or "rebuilt" in result.output.lower()
        assert (initialized_project / "progress.yaml").exists()


class TestValidateWithValidator:
    def test_uses_comprehensive_validator(self, runner, initialized_project, monkeypatch):
        import manage
        monkeypatch.setattr(manage, "PROJECTS_DIR", initialized_project.parent)
        runner.invoke(cli, ["extract", "test-book"])
        result = runner.invoke(cli, ["validate", "test-book"])
        assert result.exit_code == 0
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd modules/book-translation && python -m pytest scripts/tests/test_manage_cli.py::TestRepairCommand -v
```

Expected: FAIL — `No such command 'repair'`

- [ ] **Step 3: Add repair command and update validate in manage.py**

Add repair command:

```python
@cli.command()
@click.argument("slug")
def repair(slug):
    """Rebuild progress.yaml from translated file frontmatter."""
    project_dir = PROJECTS_DIR / slug
    if not project_dir.exists():
        click.secho(f"Project '{slug}' not found!", fg="red")
        return

    config = load_config(project_dir)
    source_dir = project_dir / "source" / "chapters"
    translated_dir = project_dir / "translated"

    # Scan source chapters
    chapters = []
    for f in sorted(source_dir.glob("ch*.md")):
        content = f.read_text(encoding="utf-8")
        lines = content.split("\n")
        title = lines[0].lstrip("# ").strip() if lines else f.stem
        word_count = len(content.split())

        # Check if translated version exists and read its status
        translated_file = translated_dir / f.name
        status = "extracted"
        if translated_file.exists():
            t_content = translated_file.read_text(encoding="utf-8")
            # Parse frontmatter for status
            if t_content.startswith("---"):
                end = t_content.find("---", 3)
                if end != -1:
                    import yaml as _yaml
                    try:
                        fm = _yaml.safe_load(t_content[3:end])
                        status = fm.get("status", "draft")
                    except Exception:
                        status = "draft"

        chapters.append({
            "id": f.stem,
            "title": title,
            "word_count": word_count,
        })

    if not chapters:
        click.secho("No source chapters found!", fg="red")
        return

    max_words = config.get("chunking", {}).get("max_section_words", 3000)
    init_progress(project_dir, chapters, max_section_words=max_words)

    # Update statuses from translated files
    progress = load_progress(project_dir)
    for ch in progress["chapters"]:
        translated_file = translated_dir / f"{ch['id']}.md"
        if translated_file.exists():
            t_content = translated_file.read_text(encoding="utf-8")
            if t_content.startswith("---"):
                end = t_content.find("---", 3)
                if end != -1:
                    import yaml as _yaml
                    try:
                        fm = _yaml.safe_load(t_content[3:end])
                        ch["status"] = fm.get("status", "draft")
                    except Exception:
                        ch["status"] = "draft"
    save_progress(project_dir, progress)

    click.secho(f"Repaired progress.yaml ({len(chapters)} chapters)", fg="green")
```

Update existing `validate` command to use validator.py:

Replace the `validate` function body with:

```python
@cli.command()
@click.argument("slug")
def validate(slug):
    """Validate project before rendering."""
    project_dir = PROJECTS_DIR / slug
    if not project_dir.exists():
        click.secho(f"Project '{slug}' not found!", fg="red")
        return

    from lib.validator import validate_project

    result = validate_project(project_dir)

    if result.errors:
        click.secho(f"\n{len(result.errors)} error(s):", fg="red")
        for e in result.errors:
            click.echo(f"  - {e}")
    if result.warnings:
        click.secho(f"\n{len(result.warnings)} warning(s):", fg="yellow")
        for w in result.warnings:
            click.echo(f"  - {w}")
    if result.is_valid and not result.warnings:
        click.secho("All checks passed!", fg="green")
    elif result.is_valid:
        click.secho("Valid with warnings.", fg="yellow")
```

- [ ] **Step 4: Run all tests**

```bash
cd modules/book-translation && python -m pytest scripts/tests/ -v --tb=short
```

Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add modules/book-translation/scripts/manage.py modules/book-translation/scripts/tests/test_manage_cli.py
git commit -m "feat(book-translation): add repair command and comprehensive validate"
```

---

### Task 5: Run full test suite and final commit

- [ ] **Step 1: Run full test suite**

```bash
cd modules/book-translation && python -m pytest scripts/tests/ -v --tb=short
```

Expected: All tests pass.

- [ ] **Step 2: Verify module structure**

```bash
ls modules/book-translation/scripts/lib/
```

Expected: `__init__.py`, `config_loader.py`, `consistency_scanner.py`, `extractor.py`, `merger.py`, `renderer.py`, `validator.py`

- [ ] **Step 3: Final commit**

```bash
git add modules/book-translation/
git commit -m "feat(book-translation): complete Phase 3 -- EPUB, footnotes, validator, repair"
```

---

## Summary

| Task | Component | Tests |
|------|-----------|-------|
| 1 | EPUB extraction (extractor.py) | test_extractor.py (+5 new tests) |
| 2 | Footnote + multi-line blockquote (renderer.py) | test_renderer.py (+4 new tests) |
| 3 | validator.py (comprehensive checks) | test_validator.py (6 new tests) |
| 4 | manage.py repair + updated validate | test_manage_cli.py (+3 new tests) |
| 5 | Full suite validation | Integration |

**Phase 3 delivers:** EPUB extraction support, footnote/blockquote rendering, comprehensive validation, state repair. Full pipeline: PDF/EPUB → extract → translate → review → consistency → render DOCX.
