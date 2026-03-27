# modules/book-translation/scripts/extract.py
"""Standalone script for extracting PDF/EPUB to markdown chapters."""
import sys
from pathlib import Path
import click

sys.path.insert(0, str(Path(__file__).parent))
from lib.extractor import extract_to_chapters, detect_format


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
    click.secho(f"{len(chapters)} chapters extracted to {out}", fg="green")
    for ch in chapters:
        click.echo(f"  {ch['id']}: {ch['title']} ({ch['word_count']} words)")


if __name__ == "__main__":
    main()
