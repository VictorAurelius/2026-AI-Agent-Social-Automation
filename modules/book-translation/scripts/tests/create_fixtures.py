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


if __name__ == "__main__":
    create_sample_pdf()
