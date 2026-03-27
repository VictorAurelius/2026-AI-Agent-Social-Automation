# modules/book-translation/scripts/lib/validator.py
"""Comprehensive project validator.

Validates a book translation project directory for completeness and consistency.
Checks:
  - progress.yaml exists
  - All source chapters have a corresponding translated file
  - Translated files are non-empty
  - Heading counts match between source and translated chapters
  - Files are valid UTF-8 encoded
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import List


# ---------------------------------------------------------------------------
# Result dataclass
# ---------------------------------------------------------------------------


@dataclass
class ValidationResult:
    """Result of a project validation run."""
    errors: List[str] = field(default_factory=list)
    warnings: List[str] = field(default_factory=list)

    @property
    def is_valid(self) -> bool:
        """Return True only when there are no errors."""
        return len(self.errors) == 0


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


def validate_project(project_dir: Path) -> ValidationResult:
    """Validate the book translation project at *project_dir*.

    Args:
        project_dir: Path to the project root (contains source/, translated/,
                     progress.yaml).

    Returns:
        ValidationResult with accumulated errors and warnings.
    """
    result = ValidationResult()
    project_dir = Path(project_dir)

    # 1. Check progress.yaml exists
    progress_file = project_dir / "progress.yaml"
    if not progress_file.exists():
        result.errors.append(
            f"Missing progress.yaml in project directory: {project_dir}"
        )

    # 2. Locate source and translated directories
    # Support both project layouts:
    #   - Simple: project_dir/source/ch*.md
    #   - Managed: project_dir/source/chapters/ch*.md
    _source_base = project_dir / "source"
    if (_source_base / "chapters").exists():
        source_dir = _source_base / "chapters"
    else:
        source_dir = _source_base
    translated_dir = project_dir / "translated"

    if not source_dir.exists():
        result.errors.append(f"Missing source/ directory: {source_dir}")
        return result  # Cannot continue without source files

    if not translated_dir.exists():
        result.errors.append(f"Missing translated/ directory: {translated_dir}")
        return result

    source_files = sorted(source_dir.glob("ch*.md"))

    for src_file in source_files:
        chapter_name = src_file.name  # e.g. "ch01.md"
        tr_file = translated_dir / chapter_name

        # 3. Check translated file exists
        if not tr_file.exists():
            result.errors.append(
                f"Missing translated file for {chapter_name}: {tr_file}"
            )
            continue

        # 4. Check translated file is non-empty
        try:
            content = tr_file.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            result.errors.append(
                f"Encoding error (not valid UTF-8) in translated file: {tr_file}"
            )
            continue

        if not content.strip():
            result.errors.append(
                f"Empty translated file: {tr_file}"
            )
            continue

        # 5. UTF-8 check on source file too
        try:
            src_content = src_file.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            result.errors.append(
                f"Encoding error (not valid UTF-8) in source file: {src_file}"
            )
            continue

        # 6. Heading count comparison
        src_headings = _count_headings(src_content)
        tr_headings = _count_headings(_strip_frontmatter(content))
        if src_headings != tr_headings:
            result.warnings.append(
                f"Heading count mismatch in {chapter_name}: "
                f"source has {src_headings}, translated has {tr_headings}"
            )

    return result


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------


_HEADING_RE = re.compile(r"^#{1,6}\s+", re.MULTILINE)
_FRONTMATTER_RE = re.compile(r"^---\n.*?\n---\n", re.DOTALL)


def _count_headings(text: str) -> int:
    """Count ATX-style markdown headings in *text*."""
    return len(_HEADING_RE.findall(text))


def _strip_frontmatter(text: str) -> str:
    """Remove YAML frontmatter (--- ... ---) from the beginning of *text*."""
    return _FRONTMATTER_RE.sub("", text, count=1)
