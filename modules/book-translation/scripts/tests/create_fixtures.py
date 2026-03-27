"""Generate test fixture files for unit tests."""
import fitz  # pymupdf
from pathlib import Path

FIXTURES_DIR = Path(__file__).parent / "fixtures"
FIXTURES_DIR.mkdir(exist_ok=True)


def create_sample_pdf():
    """Create a small PDF with 3 chapters for testing."""
    doc = fitz.open()

    # Page 1 - Chapter 1
    page = doc.new_page()
    # Insert heading with larger font using text insertion
    page.insert_text((72, 72), "Chapter 1: The Beginning", fontsize=18)
    page.insert_text((72, 110), "This is the first paragraph of chapter one.", fontsize=12)
    page.insert_text((72, 130), "It contains some basic text for testing extraction.", fontsize=12)
    page.insert_text((72, 160), "Second paragraph with important concepts.", fontsize=12)

    # Page 2 - Chapter 2
    page2 = doc.new_page()
    page2.insert_text((72, 72), "Chapter 2: The Middle", fontsize=18)
    page2.insert_text((72, 110), "This chapter discusses the middle part of our story.", fontsize=12)
    page2.insert_text((72, 130), "It has emphasis on certain words.", fontsize=12)
    page2.insert_text((72, 160), "And continues with more content for testing.", fontsize=12)

    # Page 3 - Chapter 3
    page3 = doc.new_page()
    page3.insert_text((72, 72), "Chapter 3: The End", fontsize=18)
    page3.insert_text((72, 110), "The final chapter wraps everything up.", fontsize=12)
    page3.insert_text((72, 130), "It provides a conclusion to the narrative.", fontsize=12)

    doc.save(str(FIXTURES_DIR / "sample.pdf"))
    doc.close()
    print(f"Created {FIXTURES_DIR / 'sample.pdf'}")


def create_sample_epub():
    """Create a small EPUB with 2 chapters for testing.

    Chapter 1: includes bold and italic text.
    Chapter 2: includes a blockquote.
    """
    from ebooklib import epub

    book = epub.EpubBook()
    book.set_identifier("sample-epub-001")
    book.set_title("Sample Test Book")
    book.set_language("en")
    book.add_author("Test Author")

    # Chapter 1 HTML content with bold, italic
    c1 = epub.EpubHtml(title="Chapter 1: The Beginning", file_name="chap_01.xhtml", lang="en")
    c1.content = (
        b"<html><body>"
        b"<h1>Chapter 1: The Beginning</h1>"
        b"<p>This is the first paragraph of chapter one.</p>"
        b"<p>It contains <strong>bold text</strong> for testing.</p>"
        b"<p>It also has <em>italic text</em> for emphasis.</p>"
        b"</body></html>"
    )

    # Chapter 2 HTML content with blockquote
    c2 = epub.EpubHtml(title="Chapter 2: The Middle", file_name="chap_02.xhtml", lang="en")
    c2.content = (
        b"<html><body>"
        b"<h1>Chapter 2: The Middle</h1>"
        b"<p>This chapter discusses the middle part.</p>"
        b"<blockquote><p>A wise man once said something profound.</p></blockquote>"
        b"<p>And continues with more content for testing.</p>"
        b"</body></html>"
    )

    book.add_item(c1)
    book.add_item(c2)

    # Table of contents
    book.toc = (epub.Link("chap_01.xhtml", "Chapter 1", "chap01"),
                epub.Link("chap_02.xhtml", "Chapter 2", "chap02"))

    # Required navigation items
    book.add_item(epub.EpubNcx())
    book.add_item(epub.EpubNav())

    # Define spine (reading order)
    book.spine = [c1, c2]

    epub.write_epub(str(FIXTURES_DIR / "sample.epub"), book, {})
    print(f"Created {FIXTURES_DIR / 'sample.epub'}")


if __name__ == "__main__":
    create_sample_pdf()
    create_sample_epub()
