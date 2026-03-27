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
    click.secho(f"Rendered to {output}", fg="green")


if __name__ == "__main__":
    main()
