"""PDF/text extractor module.

Extracts content from PDF, markdown, and text files into structured chapter data.
Supports:
  - PDF via pymupdf (fitz)
  - Markdown / plain text via chardet encoding detection
  - EPUB via ebooklib + BeautifulSoup (Phase 3)
"""

from __future__ import annotations

import re
import statistics
from pathlib import Path
from typing import Any

import chardet
import fitz  # pymupdf
from bs4 import BeautifulSoup

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

# Regex to detect chapter/part/section headings (case insensitive)
_CHAPTER_PATTERN = re.compile(
    r"^(chapter|part|section)\s+\d+", re.IGNORECASE
)

# Minimum character count on a page to consider it as having real text
_MIN_TEXT_CHARS = 50

# Fraction of pages that must have text to consider the PDF non-scanned
_TEXT_PAGES_THRESHOLD = 0.10

# How many points above the median font size a block must be to count as heading
_HEADING_SIZE_MARGIN = 2.0

# Maximum word count for a block to be considered a heading candidate
_MAX_HEADING_WORDS = 12

# Fraction of pages a block text must appear on to be considered boilerplate
_BOILERPLATE_PAGE_THRESHOLD = 0.25


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


def detect_format(file_path: Path) -> str:
    """Return format string for the given file path based on extension.

    Returns:
        "pdf", "epub", or "markdown"

    Raises:
        ValueError: if the extension is not supported.
    """
    suffix = file_path.suffix.lower()
    if suffix == ".pdf":
        return "pdf"
    if suffix == ".epub":
        return "epub"
    if suffix in {".md", ".txt"}:
        return "markdown"
    raise ValueError(f"Unsupported file extension: '{suffix}' for file '{file_path}'")


def is_scanned_pdf(pdf_path: Path) -> bool:
    """Return True if the PDF appears to be image-based (scanned).

    Detection heuristic: a PDF is considered scanned when fewer than
    _TEXT_PAGES_THRESHOLD (10%) of its pages contain more than
    _MIN_TEXT_CHARS (50) characters of extractable text.
    """
    doc = fitz.open(str(pdf_path))
    total_pages = len(doc)
    if total_pages == 0:
        doc.close()
        return True

    text_pages = sum(
        1
        for page in doc
        if len(page.get_text("text").strip()) > _MIN_TEXT_CHARS
    )
    doc.close()
    return (text_pages / total_pages) < _TEXT_PAGES_THRESHOLD


def extract_pdf(pdf_path: Path) -> list[dict[str, Any]]:
    """Extract text blocks from a PDF with font metadata.

    Each block dict contains:
        text       (str)   — block text content
        page       (int)   — 0-based page number
        font_size  (float) — dominant font size in the block
        is_heading (bool)  — True if font_size is significantly larger than median
        is_bold    (bool)  — True if the block's dominant font is bold
        is_italic  (bool)  — True if the block's dominant font is italic

    Strategy:
        1. Collect all spans from all pages.
        2. Compute median font size across the document.
        3. Mark blocks whose font_size > median + _HEADING_SIZE_MARGIN as headings.
    """
    doc = fitz.open(str(pdf_path))
    raw_blocks: list[dict[str, Any]] = []

    for page_num, page in enumerate(doc):
        # get_text("dict") returns structured block/line/span data
        page_dict = page.get_text("dict")
        for block in page_dict.get("blocks", []):
            if block.get("type") != 0:  # type 0 = text block
                continue
            spans = []
            for line in block.get("lines", []):
                for span in line.get("spans", []):
                    spans.append(span)

            if not spans:
                continue

            # Aggregate text from all spans in the block
            block_text = " ".join(s["text"].strip() for s in spans if s["text"].strip())
            if not block_text:
                continue

            # Dominant font size: use the span with most characters
            dominant_span = max(spans, key=lambda s: len(s["text"]))
            font_size = dominant_span["size"]
            font_flags = dominant_span.get("flags", 0)

            # fitz font flags: bit 4 = italic (16), bit 1 = bold (2^4? actually:
            # flags & 2**4 == bold in some versions; safer to check font name)
            font_name: str = dominant_span.get("font", "").lower()
            is_bold = bool(font_flags & (1 << 4)) or "bold" in font_name or "helvb" in font_name
            is_italic = bool(font_flags & (1 << 1)) or "italic" in font_name or "helvi" in font_name

            raw_blocks.append(
                {
                    "text": block_text,
                    "page": page_num,
                    "font_size": font_size,
                    "is_bold": is_bold,
                    "is_italic": is_italic,
                    # placeholder — will be computed after collecting all blocks
                    "is_heading": False,
                }
            )

    total_pages = len(doc)
    doc.close()

    if not raw_blocks:
        return raw_blocks

    # --- Filter boilerplate (text repeated on many pages) ---
    raw_blocks = _remove_boilerplate(raw_blocks, total_pages)

    if not raw_blocks:
        return raw_blocks

    # --- Heading detection ---
    # Compute median using character-weighted font sizes (body text dominates)
    char_sizes: list[tuple[float, int]] = [
        (b["font_size"], len(b["text"])) for b in raw_blocks
    ]
    total_chars = sum(c for _, c in char_sizes)
    # Find the font size that covers the majority of text (body size)
    size_char_counts: dict[float, int] = {}
    for size, chars in char_sizes:
        rounded = round(size, 1)
        size_char_counts[rounded] = size_char_counts.get(rounded, 0) + chars
    body_size = max(size_char_counts, key=size_char_counts.get)
    body_char_fraction = size_char_counts[body_size] / total_chars if total_chars else 0

    if body_char_fraction > 0.8:
        # Most text is the same size — font-based heading detection won't work.
        # Fall back to short-block heuristic: a heading is a short block
        # whose text is <=_MAX_HEADING_WORDS and appears near page start.
        for block in raw_blocks:
            word_count = len(block["text"].split())
            block["is_heading"] = word_count <= _MAX_HEADING_WORDS
    else:
        # Normal case: headings are larger than body text
        heading_threshold = body_size + _HEADING_SIZE_MARGIN
        for block in raw_blocks:
            block["is_heading"] = block["font_size"] >= heading_threshold

    return raw_blocks


def _remove_boilerplate(
    blocks: list[dict[str, Any]], total_pages: int
) -> list[dict[str, Any]]:
    """Remove blocks whose text appears on too many pages (headers/footers/watermarks)."""
    if total_pages < 4:
        return blocks

    # Count on how many distinct pages each normalized text appears
    text_page_sets: dict[str, set[int]] = {}
    for b in blocks:
        normalized = b["text"].strip().lower()
        if normalized not in text_page_sets:
            text_page_sets[normalized] = set()
        text_page_sets[normalized].add(b["page"])

    min_pages = max(3, int(total_pages * _BOILERPLATE_PAGE_THRESHOLD))
    boilerplate_texts = {
        text for text, pages in text_page_sets.items() if len(pages) >= min_pages
    }

    if not boilerplate_texts:
        return blocks

    return [b for b in blocks if b["text"].strip().lower() not in boilerplate_texts]


def detect_chapters(blocks: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Detect chapter boundaries in a list of text blocks.

    Detection priority:
      1. Heading blocks matching _CHAPTER_PATTERN ("Chapter N", "Part N", etc.)
      2. Fallback: heading blocks that are short (<= _MAX_HEADING_WORDS) and
         followed by longer body text (title-based chapters).
      3. Last resort: all content as a single chapter.

    Returns:
        List of chapter dicts:
            id      (str) — "ch01", "ch02", …
            title   (str) — heading text
            content (str) — joined body text
            page    (int) — start page number
    """
    # Priority 1: explicit chapter pattern
    chapter_indices: list[int] = [
        i
        for i, b in enumerate(blocks)
        if b["is_heading"] and _CHAPTER_PATTERN.match(b["text"].strip())
    ]

    # Priority 2: heading blocks that look like chapter titles
    if not chapter_indices:
        chapter_indices = _detect_title_based_chapters(blocks)

    # Priority 3: single chapter fallback
    if not chapter_indices:
        title = next(
            (b["text"] for b in blocks if b["is_heading"]),
            blocks[0]["text"] if blocks else "Chapter 1",
        )
        body_texts = [
            b["text"] for b in blocks if not b["is_heading"]
        ]
        return [
            {
                "id": "ch01",
                "title": title,
                "content": "\n\n".join(body_texts),
                "page": blocks[0]["page"] if blocks else 0,
            }
        ]

    chapters: list[dict[str, Any]] = []
    for seq, start_idx in enumerate(chapter_indices, start=1):
        end_idx = (
            chapter_indices[seq]  # next chapter starts here
            if seq < len(chapter_indices)
            else len(blocks)
        )
        heading_block = blocks[start_idx]
        body_blocks = [b for b in blocks[start_idx + 1 : end_idx] if not b["is_heading"]]
        chapters.append(
            {
                "id": f"ch{seq:02d}",
                "title": heading_block["text"],
                "content": "\n\n".join(b["text"] for b in body_blocks),
                "page": heading_block["page"],
            }
        )

    return chapters


def _detect_title_based_chapters(blocks: list[dict[str, Any]]) -> list[int]:
    """Find chapter boundaries using short heading blocks followed by body text.

    A heading block is a chapter title candidate if:
      - is_heading is True
      - word count <= _MAX_HEADING_WORDS
      - no dot leaders (TOC entries like "Chapter 1.......3")
      - followed by substantial body text (>= 100 words before next heading)
    """
    _TOC_DOTS = re.compile(r"\.{3,}")
    _MIN_BODY_WORDS = 100

    candidates: list[int] = []
    for i, b in enumerate(blocks):
        if not b["is_heading"]:
            continue
        word_count = len(b["text"].split())
        if word_count > _MAX_HEADING_WORDS:
            continue
        # Skip TOC entries with dot leaders
        if _TOC_DOTS.search(b["text"]):
            continue
        # Count body words until next heading candidate
        body_words = 0
        for j in range(i + 1, len(blocks)):
            if blocks[j]["is_heading"] and len(blocks[j]["text"].split()) <= _MAX_HEADING_WORDS:
                break
            body_words += len(blocks[j]["text"].split())
        if body_words >= _MIN_BODY_WORDS:
            candidates.append(i)

    # Need at least 2 chapters to consider this a valid detection
    if len(candidates) < 2:
        return []

    return candidates


def extract_to_chapters(source_path: Path, output_dir: Path) -> list[dict[str, Any]]:
    """Full extraction pipeline: detect format → extract → detect chapters → write files.

    Writes one Markdown file per chapter to output_dir (ch01.md, ch02.md, …).

    Returns:
        List of chapter dicts (same structure as detect_chapters output).

    Raises:
        ValueError: for unsupported formats.
        FileNotFoundError: if source_path does not exist.
    """
    if not source_path.exists():
        raise FileNotFoundError(f"Source file not found: {source_path}")

    fmt = detect_format(source_path)

    if fmt == "pdf":
        blocks = extract_pdf(source_path)
        chapters = detect_chapters(blocks)
    elif fmt == "markdown":
        text = _read_text_file(source_path)
        chapters = _split_text_chapters(text)
    elif fmt == "epub":
        chapters = extract_epub(source_path)
    else:
        raise ValueError(f"Unhandled format: {fmt}")

    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    for chapter in chapters:
        ch_file = output_dir / f"{chapter['id']}.md"
        md_content = f"# {chapter['title']}\n\n{chapter['content']}\n"
        ch_file.write_text(md_content, encoding="utf-8")

    return chapters


# ---------------------------------------------------------------------------
# EPUB extraction
# ---------------------------------------------------------------------------


def extract_epub(epub_path: Path) -> list[dict[str, Any]]:
    """Extract chapters from an EPUB file.

    Uses ebooklib to read the EPUB and BeautifulSoup to parse the HTML content.
    Converts HTML to markdown-like text preserving bold, italic, and blockquotes.

    Returns:
        List of chapter dicts (same structure as detect_chapters output):
            id      (str) — "ch01", "ch02", …
            title   (str) — heading text from first <h1>/<h2> in the chapter
            content (str) — body text converted to markdown
            page    (int) — always 0 for EPUB (no page numbers)
    """
    import ebooklib
    from ebooklib import epub

    book = epub.read_epub(str(epub_path), options={"ignore_ncx": True})

    chapters: list[dict[str, Any]] = []
    seq = 1

    for item in book.get_items():
        if item.get_type() != ebooklib.ITEM_DOCUMENT:
            continue

        # Skip nav documents
        if "nav" in item.get_name().lower():
            continue

        content_bytes = item.get_content()
        if not content_bytes:
            continue

        soup = BeautifulSoup(content_bytes, "html.parser")
        body = soup.find("body")
        if body is None:
            body = soup

        # Extract title from first heading
        heading = body.find(["h1", "h2", "h3"])
        title = heading.get_text(strip=True) if heading else f"Chapter {seq}"

        # Convert body to markdown
        content = _html_to_markdown(body)

        chapters.append(
            {
                "id": f"ch{seq:02d}",
                "title": title,
                "content": content,
                "page": 0,
            }
        )
        seq += 1

    return chapters


def _html_to_markdown(element) -> str:
    """Convert a BeautifulSoup element tree to markdown text.

    Handles:
      - <h1>-<h6>  → # heading
      - <p>         → paragraph with inline formatting
      - <blockquote> → > quoted text
      - <strong>/<b> → **bold**  (handled inline)
      - <em>/<i>    → *italic*   (handled inline)
    """
    lines: list[str] = []

    for tag in element.children:
        if not hasattr(tag, "name") or tag.name is None:
            # Plain text node at block level — skip (inline text is handled per-tag)
            continue

        if tag.name in ("h1", "h2", "h3", "h4", "h5", "h6"):
            level = int(tag.name[1])
            lines.append(f"{'#' * level} {tag.get_text(strip=True)}")
        elif tag.name == "p":
            inline_md = _inline_to_markdown(tag)
            if inline_md.strip():
                lines.append(inline_md.strip())
        elif tag.name == "blockquote":
            # Each paragraph inside blockquote becomes "> text"
            inner_lines: list[str] = []
            for child in tag.children:
                if hasattr(child, "name") and child.name == "p":
                    inner_lines.append(_inline_to_markdown(child).strip())
                elif hasattr(child, "name") and child.name is not None:
                    inner_lines.append(child.get_text(strip=True))
                else:
                    text = str(child).strip()
                    if text:
                        inner_lines.append(text)
            for inner in inner_lines:
                if inner:
                    lines.append(f"> {inner}")
        elif tag.name in ("div", "section", "article"):
            # Recurse into container elements
            nested = _html_to_markdown(tag)
            if nested.strip():
                lines.append(nested.strip())
        else:
            # Other tags — just get text
            text = tag.get_text(strip=True)
            if text:
                lines.append(text)

    return "\n\n".join(line for line in lines if line.strip())


def _inline_to_markdown(element) -> str:
    """Convert inline HTML elements within a paragraph to markdown.

    Processes children of a paragraph tag, converting:
      - <strong>/<b> → **text**
      - <em>/<i>     → *text*
      - Plain text nodes → as-is
    """
    parts: list[str] = []
    for child in element.children:
        if not hasattr(child, "name"):
            # NavigableString — plain text
            parts.append(str(child))
        elif child.name in ("strong", "b"):
            inner = child.get_text()
            parts.append(f"**{inner}**")
        elif child.name in ("em", "i"):
            inner = child.get_text()
            parts.append(f"*{inner}*")
        elif child.name == "a":
            inner = child.get_text()
            href = child.get("href", "")
            parts.append(f"[{inner}]({href})")
        else:
            # Other inline tags — just extract text
            parts.append(child.get_text())
    return "".join(parts)


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------


def _read_text_file(file_path: Path) -> str:
    """Read a text file using chardet for encoding detection."""
    raw_bytes = Path(file_path).read_bytes()
    detected = chardet.detect(raw_bytes)
    encoding = detected.get("encoding") or "utf-8"
    try:
        return raw_bytes.decode(encoding)
    except (UnicodeDecodeError, LookupError):
        return raw_bytes.decode("utf-8", errors="replace")


def _split_text_chapters(text: str) -> list[dict[str, Any]]:
    """Split a markdown/plain-text string into chapters by heading patterns.

    Recognises ATX headings (# … ) and the chapter/part/section pattern.
    Falls back to a single chapter if no boundaries are found.
    """
    # Split on ATX headings or chapter pattern at start of line
    heading_re = re.compile(
        r"^(?:#{1,3}\s+.+|(?:chapter|part|section)\s+\d+.*)",
        re.IGNORECASE | re.MULTILINE,
    )

    positions = [m.start() for m in heading_re.finditer(text)]

    if not positions:
        return [
            {
                "id": "ch01",
                "title": "Chapter 1",
                "content": text.strip(),
                "page": 0,
            }
        ]

    chapters: list[dict[str, Any]] = []
    for seq, start in enumerate(positions, start=1):
        end = positions[seq] if seq < len(positions) else len(text)
        chunk = text[start:end].strip()
        lines = chunk.splitlines()
        title = lines[0].lstrip("#").strip() if lines else f"Chapter {seq}"
        body = "\n".join(lines[1:]).strip()
        chapters.append(
            {
                "id": f"ch{seq:02d}",
                "title": title,
                "content": body,
                "page": 0,
            }
        )

    return chapters
