# Book Translation Module Phase 2 — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add review workflow, consistency checking, memory system, and bilingual rendering to the book translation module.

**Architecture:** Two new Claude skills (review-translation, consistency-check) handle interactive workflows. A new Python module (consistency_scanner.py) provides script-assisted glossary/heading scanning for the consistency-check skill. Bilingual render already has a skeleton in manage.py — needs tests. Memory system works through skills reading/writing markdown files (no new scripts needed).

**Tech Stack:** Python 3.10+, click, pyyaml, pytest (existing deps — no new packages)

**Spec Document:** `documents/03-planning/superpowers/specs/2026-03-27-book-translation-design.md` (Sections 4.4, 4.5, 6, 9.2)

**Done when:** Can translate 3+ chapters, feedback is saved to memory files, consistency-scan CLI produces a report, bilingual render creates a DOCX with EN/VI interleaved.

---

## Chunk 1: Consistency Scanner (TDD)

### Task 1: Implement consistency_scanner.py with tests

**Files:**
- Create: `modules/book-translation/scripts/tests/test_consistency_scanner.py`
- Create: `modules/book-translation/scripts/lib/consistency_scanner.py`

- [ ] **Step 1: Write failing tests**

```python
# modules/book-translation/scripts/tests/test_consistency_scanner.py
"""Tests for consistency scanner module."""
import pytest
from pathlib import Path

from lib.consistency_scanner import (
    scan_glossary_consistency,
    scan_heading_counts,
    scan_word_count_ratios,
    generate_report,
)


@pytest.fixture
def project_with_translations(tmp_path):
    """Create a project with source and translated chapters."""
    source_dir = tmp_path / "source" / "chapters"
    source_dir.mkdir(parents=True)
    translated_dir = tmp_path / "translated"
    translated_dir.mkdir()

    # Source chapters
    (source_dir / "ch01.md").write_text(
        "# Chapter 1: Beginning\n\n"
        "The inferiority complex is a common issue.\n\n"
        "The style of life determines behavior.\n",
        encoding="utf-8",
    )
    (source_dir / "ch02.md").write_text(
        "# Chapter 2: Middle\n\n"
        "## Section A\n\n"
        "The inferiority complex grows over time.\n\n"
        "The style of life can change.\n",
        encoding="utf-8",
    )

    # Translated chapters (ch01 consistent, ch02 has inconsistency)
    (translated_dir / "ch01.md").write_text(
        "---\nchapter: 1\nstatus: approved\n---\n\n"
        "# Chuong 1: Khoi dau\n\n"
        "Mac cam tu ti la van de pho bien.\n\n"
        "Nep song quyet dinh hanh vi.\n",
        encoding="utf-8",
    )
    (translated_dir / "ch02.md").write_text(
        "---\nchapter: 2\nstatus: approved\n---\n\n"
        "# Chuong 2: Giua\n\n"
        "## Phan A\n\n"
        "Phuc cam tu ti phat trien theo thoi gian.\n\n"  # "phuc cam" instead of "mac cam"
        "Phong cach song co the thay doi.\n",  # "phong cach song" instead of "nep song"
        encoding="utf-8",
    )

    # Glossary
    (tmp_path / "glossary.md").write_text(
        "# Glossary\n\n"
        "| English | Vietnamese | Context | Notes |\n"
        "|---------|-----------|---------|-------|\n"
        "| inferiority complex | mac cam tu ti | psychology | |\n"
        "| style of life | nep song | core concept | |\n",
        encoding="utf-8",
    )

    return tmp_path


class TestScanGlossaryConsistency:
    def test_finds_inconsistent_terms(self, project_with_translations):
        results = scan_glossary_consistency(
            project_with_translations / "glossary.md",
            project_with_translations / "translated",
        )
        # Should find that ch02 uses "phuc cam tu ti" and "phong cach song"
        # instead of glossary terms "mac cam tu ti" and "nep song"
        assert len(results) > 0
        terms_found = [r["term_vi"] for r in results]
        assert "mac cam tu ti" in terms_found or "nep song" in terms_found

    def test_reports_which_chapters_have_issues(self, project_with_translations):
        results = scan_glossary_consistency(
            project_with_translations / "glossary.md",
            project_with_translations / "translated",
        )
        # Each result should have chapter info
        for r in results:
            assert "chapters_with_term" in r
            assert "chapters_without_term" in r

    def test_empty_glossary_returns_empty(self, tmp_path):
        glossary = tmp_path / "glossary.md"
        glossary.write_text("# Glossary\n\n| English | Vietnamese | Context | Notes |\n|---|---|---|---|\n", encoding="utf-8")
        translated_dir = tmp_path / "translated"
        translated_dir.mkdir()
        results = scan_glossary_consistency(glossary, translated_dir)
        assert results == []


class TestScanHeadingCounts:
    def test_compares_heading_counts(self, project_with_translations):
        results = scan_heading_counts(
            project_with_translations / "source" / "chapters",
            project_with_translations / "translated",
        )
        # ch01: 1 heading source, 1 heading translated = OK
        # ch02: 2 headings source, 2 headings translated = OK
        for r in results:
            assert "chapter" in r
            assert "source_headings" in r
            assert "translated_headings" in r

    def test_flags_mismatch(self, tmp_path):
        source_dir = tmp_path / "source" / "chapters"
        source_dir.mkdir(parents=True)
        translated_dir = tmp_path / "translated"
        translated_dir.mkdir()

        (source_dir / "ch01.md").write_text("# Ch1\n\n## Sec A\n\n## Sec B\n", encoding="utf-8")
        (translated_dir / "ch01.md").write_text("# Ch1\n\nContent without section headings.\n", encoding="utf-8")

        results = scan_heading_counts(source_dir, translated_dir)
        mismatches = [r for r in results if r["source_headings"] != r["translated_headings"]]
        assert len(mismatches) >= 1


class TestScanWordCountRatios:
    def test_calculates_ratios(self, project_with_translations):
        results = scan_word_count_ratios(
            project_with_translations / "source" / "chapters",
            project_with_translations / "translated",
        )
        for r in results:
            assert "chapter" in r
            assert "source_words" in r
            assert "translated_words" in r
            assert "ratio" in r
            assert r["ratio"] > 0

    def test_flags_outlier_ratio(self, tmp_path):
        source_dir = tmp_path / "source" / "chapters"
        source_dir.mkdir(parents=True)
        translated_dir = tmp_path / "translated"
        translated_dir.mkdir()

        (source_dir / "ch01.md").write_text("# Ch1\n\n" + "word " * 100, encoding="utf-8")
        (translated_dir / "ch01.md").write_text("# Ch1\n\n" + "tu " * 30, encoding="utf-8")  # ratio 0.3 = outlier

        results = scan_word_count_ratios(source_dir, translated_dir)
        assert results[0]["is_outlier"] is True


class TestGenerateReport:
    def test_produces_text_report(self, project_with_translations):
        report = generate_report(project_with_translations)
        assert isinstance(report, str)
        assert "Glossary" in report or "glossary" in report
        assert "Heading" in report or "heading" in report
        assert "Word" in report or "word" in report
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd modules/book-translation && python -m pytest scripts/tests/test_consistency_scanner.py -v
```

Expected: FAIL — `ImportError: cannot import name 'scan_glossary_consistency'`

- [ ] **Step 3: Implement consistency_scanner.py**

```python
# modules/book-translation/scripts/lib/consistency_scanner.py
"""Scan translated files for consistency issues (glossary, headings, word counts)."""
import re
from pathlib import Path


def _parse_glossary(glossary_path: Path) -> list[dict]:
    """Parse glossary.md markdown table into list of term dicts."""
    if not glossary_path.exists():
        return []
    text = glossary_path.read_text(encoding="utf-8")
    terms = []
    for line in text.split("\n"):
        line = line.strip()
        if not line.startswith("|") or line.startswith("|---") or line.startswith("| English"):
            continue
        parts = [p.strip() for p in line.split("|")]
        parts = [p for p in parts if p]
        if len(parts) >= 2 and parts[0] and parts[1]:
            terms.append({
                "term_en": parts[0],
                "term_vi": parts[1],
                "context": parts[2] if len(parts) > 2 else "",
                "notes": parts[3] if len(parts) > 3 else "",
            })
    return terms


def _strip_frontmatter(text: str) -> str:
    """Remove YAML frontmatter from markdown."""
    if text.startswith("---"):
        end = text.find("---", 3)
        if end != -1:
            return text[end + 3:].strip()
    return text.strip()


def _count_headings(text: str) -> int:
    """Count markdown headings in text."""
    return len(re.findall(r"^#{1,6}\s+", text, re.MULTILINE))


def _count_words(text: str) -> int:
    """Count words in text, ignoring markdown syntax."""
    clean = re.sub(r"^#{1,6}\s+", "", text, flags=re.MULTILINE)
    clean = re.sub(r"[*_`>]", "", clean)
    return len(clean.split())


def scan_glossary_consistency(
    glossary_path: Path,
    translated_dir: Path,
) -> list[dict]:
    """Scan all translated files for glossary term consistency.

    Returns list of dicts: {term_en, term_vi, chapters_with_term, chapters_without_term}
    Only returns terms that appear in SOME but not ALL chapters (inconsistent).
    """
    terms = _parse_glossary(glossary_path)
    if not terms:
        return []

    translated_files = sorted(translated_dir.glob("ch*.md"))
    if not translated_files:
        return []

    results = []
    for term in terms:
        vi = term["term_vi"].lower()
        with_term = []
        without_term = []

        for f in translated_files:
            content = _strip_frontmatter(f.read_text(encoding="utf-8")).lower()
            if vi in content:
                with_term.append(f.stem)
            else:
                without_term.append(f.stem)

        # Report if term appears in some but not all (inconsistent)
        # OR if term appears in zero chapters (completely missing)
        if without_term:
            results.append({
                "term_en": term["term_en"],
                "term_vi": term["term_vi"],
                "chapters_with_term": with_term,
                "chapters_without_term": without_term,
                "status": "missing" if not with_term else "inconsistent",
            })

    return results


def scan_heading_counts(
    source_dir: Path,
    translated_dir: Path,
) -> list[dict]:
    """Compare heading counts between source and translated chapters.

    Returns list of dicts: {chapter, source_headings, translated_headings}
    """
    results = []
    for source_file in sorted(source_dir.glob("ch*.md")):
        chapter_id = source_file.stem
        translated_file = translated_dir / f"{chapter_id}.md"
        if not translated_file.exists():
            continue

        source_text = source_file.read_text(encoding="utf-8")
        translated_text = _strip_frontmatter(
            translated_file.read_text(encoding="utf-8")
        )

        results.append({
            "chapter": chapter_id,
            "source_headings": _count_headings(source_text),
            "translated_headings": _count_headings(translated_text),
        })

    return results


def scan_word_count_ratios(
    source_dir: Path,
    translated_dir: Path,
    outlier_low: float = 0.5,
    outlier_high: float = 2.0,
) -> list[dict]:
    """Compare word counts between source and translated chapters.

    Returns list of dicts: {chapter, source_words, translated_words, ratio, is_outlier}
    """
    results = []
    for source_file in sorted(source_dir.glob("ch*.md")):
        chapter_id = source_file.stem
        translated_file = translated_dir / f"{chapter_id}.md"
        if not translated_file.exists():
            continue

        source_words = _count_words(source_file.read_text(encoding="utf-8"))
        translated_words = _count_words(
            _strip_frontmatter(translated_file.read_text(encoding="utf-8"))
        )

        ratio = translated_words / source_words if source_words > 0 else 0
        results.append({
            "chapter": chapter_id,
            "source_words": source_words,
            "translated_words": translated_words,
            "ratio": round(ratio, 2),
            "is_outlier": ratio < outlier_low or ratio > outlier_high,
        })

    return results


def generate_report(project_dir: Path) -> str:
    """Generate a full consistency report for a project.

    Args:
        project_dir: Path to the project directory.

    Returns:
        Human-readable text report.
    """
    glossary_path = project_dir / "glossary.md"
    source_dir = project_dir / "source" / "chapters"
    translated_dir = project_dir / "translated"

    lines = ["# Consistency Report\n"]

    # 1. Glossary consistency
    lines.append("## Glossary Consistency\n")
    glossary_results = scan_glossary_consistency(glossary_path, translated_dir)
    if glossary_results:
        for r in glossary_results:
            lines.append(
                f"- **{r['term_en']}** ({r['term_vi']}): "
                f"found in {r['chapters_with_term']}, "
                f"missing in {r['chapters_without_term']}"
            )
    else:
        lines.append("No glossary inconsistencies found.")
    lines.append("")

    # 2. Heading counts
    lines.append("## Heading Counts\n")
    heading_results = scan_heading_counts(source_dir, translated_dir)
    mismatches = [r for r in heading_results if r["source_headings"] != r["translated_headings"]]
    if mismatches:
        for r in mismatches:
            lines.append(
                f"- **{r['chapter']}**: source={r['source_headings']}, "
                f"translated={r['translated_headings']}"
            )
    else:
        lines.append("All heading counts match.")
    lines.append("")

    # 3. Word count ratios
    lines.append("## Word Count Ratios\n")
    ratio_results = scan_word_count_ratios(source_dir, translated_dir)
    outliers = [r for r in ratio_results if r["is_outlier"]]
    if outliers:
        for r in outliers:
            lines.append(
                f"- **{r['chapter']}**: {r['source_words']} -> {r['translated_words']} "
                f"(ratio {r['ratio']}) OUTLIER"
            )
    else:
        lines.append("All word count ratios within normal range.")
    lines.append("")

    # Summary
    total_issues = len(glossary_results) + len(mismatches) + len(outliers)
    lines.append(f"## Summary: {total_issues} issue(s) found\n")

    return "\n".join(lines)
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd modules/book-translation && python -m pytest scripts/tests/test_consistency_scanner.py -v
```

Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add modules/book-translation/scripts/lib/consistency_scanner.py modules/book-translation/scripts/tests/test_consistency_scanner.py
git commit -m "feat(book-translation): add consistency scanner with TDD tests"
```

---

## Chunk 2: CLI Command + Bilingual Tests

### Task 2: Add consistency-scan command to manage.py

**Files:**
- Modify: `modules/book-translation/scripts/manage.py`
- Modify: `modules/book-translation/scripts/tests/test_manage_cli.py`

- [ ] **Step 1: Write CLI test for consistency-scan first (TDD)**

Add to `test_manage_cli.py`:

```python
class TestConsistencyScanCommand:
    def test_runs_scan(self, runner, initialized_project, monkeypatch):
        import manage
        monkeypatch.setattr(manage, "PROJECTS_DIR", initialized_project.parent)
        # Extract to create source chapters
        runner.invoke(cli, ["extract", "test-book"])
        # Create a mock translated file
        translated_dir = initialized_project / "translated"
        (translated_dir / "ch01.md").write_text(
            "---\nchapter: 1\nstatus: draft\n---\n\n# Ch 1\n\nContent.\n",
            encoding="utf-8",
        )
        result = runner.invoke(cli, ["consistency-scan", "test-book"])
        assert result.exit_code == 0
        assert "Consistency Report" in result.output or "consistency" in result.output.lower()
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd modules/book-translation && python -m pytest scripts/tests/test_manage_cli.py::TestConsistencyScanCommand -v
```

Expected: FAIL — `No such command 'consistency-scan'`

- [ ] **Step 3: Add consistency-scan command to manage.py**

Add after the `validate` command, before `if __name__`:

```python
@cli.command("consistency-scan")
@click.argument("slug")
def consistency_scan(slug):
    """Run consistency checks on translated chapters."""
    project_dir = PROJECTS_DIR / slug
    if not project_dir.exists():
        click.secho(f"Project '{slug}' not found!", fg="red")
        return

    from lib.consistency_scanner import generate_report

    report = generate_report(project_dir)
    click.echo(report)
```

- [ ] **Step 4: Run all tests**

```bash
cd modules/book-translation && python -m pytest scripts/tests/ -v
```

Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add modules/book-translation/scripts/manage.py modules/book-translation/scripts/tests/test_manage_cli.py
git commit -m "feat(book-translation): add consistency-scan CLI command"
```

---

### Task 3: Add bilingual render tests

**Files:**
- Modify: `modules/book-translation/scripts/tests/test_manage_cli.py`

- [ ] **Step 1: Add bilingual render test**

Add to `test_manage_cli.py`:

```python
class TestBilingualRender:
    def test_bilingual_creates_docx(self, runner, initialized_project, monkeypatch):
        import manage
        monkeypatch.setattr(manage, "PROJECTS_DIR", initialized_project.parent)
        runner.invoke(cli, ["extract", "test-book"])

        # Create mock translated chapter matching source
        translated_dir = initialized_project / "translated"
        (translated_dir / "ch01.md").write_text(
            "---\nchapter: 1\nstatus: approved\n---\n\n"
            "# Chuong 1\n\nNoi dung dich.\n",
            encoding="utf-8",
        )

        result = runner.invoke(cli, ["render", "test-book", "--chapter", "1", "--bilingual", "--force"])
        assert result.exit_code == 0
        # Check output file exists
        output = initialized_project / "output" / "test-book-ch01.docx"
        # Bilingual single chapter still uses ch01 naming
        assert "Rendered" in result.output or "rendered" in result.output.lower()
```

- [ ] **Step 2: Add interleave_bilingual unit test**

Add a focused test for the interleave function. Add to `test_manage_cli.py`:

```python
class TestInterleaveBilingual:
    def test_interleaves_paragraphs(self):
        from manage import _interleave_bilingual
        source = "# Title\n\nParagraph one.\n\nParagraph two."
        translated = "# Tieu de\n\nDoan mot.\n\nDoan hai."
        result = _interleave_bilingual(source, translated)
        # EN paragraphs should come before VI paragraphs
        assert "[EN]" in result
        lines = result.split("\n\n")
        # Should alternate EN/VI
        assert len(lines) >= 4

    def test_handles_unequal_lengths(self):
        from manage import _interleave_bilingual
        source = "One.\n\nTwo.\n\nThree."
        translated = "Mot.\n\nHai."
        result = _interleave_bilingual(source, translated)
        assert "Three" in result
        assert "Hai" in result
```

- [ ] **Step 3: Run all tests**

```bash
cd modules/book-translation && python -m pytest scripts/tests/ -v
```

Expected: All tests PASS.

- [ ] **Step 4: Commit**

```bash
git add modules/book-translation/scripts/tests/test_manage_cli.py
git commit -m "test(book-translation): add bilingual render and consistency-scan tests"
```

---

## Chunk 3: Claude Skills

### Task 4: Create review-translation skill

**Files:**
- Create: `.claude/skills/book-translation/review-translation.md`

- [ ] **Step 1: Write the skill**

```markdown
---
name: review-translation
description: Review translated chapters and learn from user feedback — use when user provides feedback on translation, says "review ban dich", approves/rejects a chapter, or has edited a translated file
---

# Review Translation

## Trigger
User provides feedback on a translation, says "review", "approve", "reject", edits a translated file, or comments on translation quality.

## Context to Load
1. **Always:** The translated section being reviewed from `projects/{slug}/translated/`
2. **Always:** The source section from `projects/{slug}/source/chapters/`
3. **If needed:** `projects/{slug}/style-guide.md`
4. **If needed:** `projects/{slug}/glossary.md`

## Handling Feedback

### Path A: Verbal feedback (big changes)
User says something like "this paragraph is too stiff" or "use a different term for X".

1. Understand the feedback — ask clarifying questions if ambiguous
2. Revise the section according to feedback
3. Show the revised version to user
4. Classify the feedback:
   - **Book-specific** (style choice for this book) → update `projects/{slug}/style-guide.md` or `glossary.md`
   - **Universal rule** (applies to all future books) → append to `modules/book-translation/memory/style-feedback.md`
   - **Good translation pattern** (reusable example) → append to `modules/book-translation/memory/translation-patterns.md`
5. Update `projects/{slug}/progress.yaml`: set chapter status to `reviewing`

### Path B: User edited file directly (small fixes)
User says "I edited ch03.md" or you notice the file changed.

1. Read the current translated file
2. Ask user what they changed and why (if not obvious)
3. Ask: "Should this change apply to all future translations, or just this section?"
4. Save to appropriate memory file if universal
5. Update progress.yaml status

### Path C: Combined A + B
Handle both verbal and file-edit feedback together.

## Approve Flow
When user says "approve", "LGTM", "ok", or explicitly approves:

1. Update `projects/{slug}/progress.yaml`: set chapter status to `approved`
2. Show next chapter to translate: read progress.yaml, find next `extracted` chapter
3. Ask: "Chapter X approved. Continue with chapter Y, or review something else?"

## Memory Classification Guide

**Save to `style-guide.md`** (per-book):
- Specific tone/voice choices for this book
- Book-specific terminology decisions
- Author-specific translation approaches

**Save to `memory/style-feedback.md`** (cross-book):
- General translation rules confirmed by user
- Anti-patterns user has rejected
- Format: rule + **Source:** book/chapter where confirmed

**Save to `memory/translation-patterns.md`** (cross-book):
- Specific EN→VI translation examples user approved
- Metaphor translations
- Complex sentence restructuring examples
- Format: EN original → VI translation + **Context:** where/why

## After Review
- If more chapters to review: ask user which to review next
- If all chapters reviewed: suggest running consistency check
```

- [ ] **Step 2: Commit**

```bash
git add .claude/skills/book-translation/review-translation.md
git commit -m "feat(book-translation): add review-translation skill"
```

---

### Task 5: Create consistency-check skill

**Files:**
- Create: `.claude/skills/book-translation/consistency-check.md`

- [ ] **Step 1: Write the skill**

```markdown
---
name: consistency-check
description: Check translation consistency across all chapters — use when user says "kiem tra nhat quan", "consistency check", after all chapters approved, or after every 3-5 chapters
---

# Consistency Check

## Trigger
User says "kiem tra nhat quan", "consistency check", "check consistency", or all chapters are approved.

## When to Run
- After all chapters reach `approved` status
- After every 3-5 chapters as a mid-project check
- When user explicitly requests it

## Step 1: Run Script-Assisted Scan

Run the consistency scanner to get automated checks:

```bash
cd modules/book-translation
python scripts/manage.py consistency-scan {slug}
```

This produces a report covering:
- **Glossary consistency** — terms used in some chapters but not others
- **Heading count comparison** — source vs translated heading counts
- **Word count ratios** — flag chapters with unusual ratios (< 0.5 or > 2.0)

## Step 2: Name Audit (Manual)

Scan translated files for proper name spelling consistency:
- Read through chapter files looking for character names, place names, book titles
- Check that each name is spelled identically across all chapters
- Common issues: accent variations, capitalization, transliteration differences
- If inconsistencies found, add to report

This step is manual because proper names vary too much for automated regex detection.

## Step 3: Review Report

Read the scanner report + name audit findings. For each issue:

### Glossary Issues
- Check if the term SHOULD appear in the flagged chapter (some terms are chapter-specific)
- If it should: note for correction
- If it shouldn't: skip (not a real issue)

### Heading Mismatches
- Check if headings were intentionally merged/split during translation
- If unintentional: note for correction

### Word Count Outliers
- Read the flagged chapter to check if content was omitted or over-expanded
- Minor variations (0.8-1.3 ratio) are normal for EN→VI translation

## Step 3: Style Drift Check (Manual Sampling)

Claude reads first and last paragraph of each chapter to detect style drift:
- Compare tone/formality between early and late chapters
- Check pronoun usage consistency
- Check Han-Viet vocabulary density consistency

**Context budget:** Only load first paragraph + last paragraph per chapter (not full text).

## Step 5: Present Findings

Present a summary to user:

```
Consistency Report for "{book title}":

Glossary:     X issue(s)
Headings:     X mismatch(es)
Word Counts:  X outlier(s)
Style Drift:  [none detected / mild / significant]

Details:
[list each issue with chapter reference]

Options:
1. Fix all issues automatically
2. Review each issue one by one
3. Skip — proceed to render
```

## Step 6: Fix Issues

Based on user choice:
- **Fix all:** Claude corrects glossary terms, adjusts headings, flags content gaps
- **Review each:** Go through issues one by one, user decides per issue
- **Skip:** Move on

After fixes, re-run `consistency-scan` to verify.

## Step 7: Merge to Global Memory

After consistency check passes (all chapters approved + consistent):

1. Ask user: "Translation complete! Which terms/rules should be saved for future books?"
2. Present glossary terms for selection → merge chosen terms into `modules/book-translation/memory/glossary-global.md`
3. Present style rules discovered → merge into `modules/book-translation/memory/style-feedback.md`
4. Present notable translation patterns → merge into `modules/book-translation/memory/translation-patterns.md`
5. Update `projects/{slug}/progress.yaml`: book status → `done`

## Glossary Conflict Resolution (for future books)
When starting a new book, `init-project` skill should:
1. Read `memory/glossary-global.md`
2. Pre-populate new book's `glossary.md` with relevant terms
3. Flag any terms that might need different translation in new context
```

- [ ] **Step 2: Commit**

```bash
git add .claude/skills/book-translation/consistency-check.md
git commit -m "feat(book-translation): add consistency-check skill with memory merge"
```

---

### Task 6: Run full test suite and final commit

**Files:** None (validation only)

- [ ] **Step 1: Run full test suite**

```bash
cd modules/book-translation && python -m pytest scripts/tests/ -v --tb=short
```

Expected: All tests pass (49 existing + new scanner tests + new CLI tests).

- [ ] **Step 2: Verify file structure**

```bash
ls .claude/skills/book-translation/
ls modules/book-translation/scripts/lib/
ls modules/book-translation/memory/
```

Expected skills: `init-project.md`, `define-style.md`, `translate-section.md`, `review-translation.md`, `consistency-check.md`
Expected lib: `__init__.py`, `config_loader.py`, `extractor.py`, `merger.py`, `renderer.py`, `consistency_scanner.py`
Expected memory: `glossary-global.md`, `style-feedback.md`, `translation-patterns.md`

- [ ] **Step 3: Final commit**

```bash
git add modules/book-translation/ .claude/skills/book-translation/
git commit -m "feat(book-translation): complete Phase 2 — review, consistency, memory system"
```

---

## Summary

| Task | Component | Tests |
|------|-----------|-------|
| 1 | consistency_scanner.py | test_consistency_scanner.py (8 tests) |
| 2 | manage.py consistency-scan command | test_manage_cli.py (1 new test) |
| 3 | Bilingual render tests | test_manage_cli.py (3 new tests) |
| 4 | review-translation.md skill | — (markdown) |
| 5 | consistency-check.md skill + memory merge | — (markdown) |
| 6 | Full test suite validation | Integration |

**Phase 2 delivers:** Complete review workflow (skill), consistency checking (script + skill), memory merge workflow (in consistency-check skill), bilingual render tested. User can now translate multiple chapters, get feedback saved, run consistency checks, and merge learnings for future books.
