---
name: scientific-documents
description: Inspect local scientific PDFs, slides, scans, and figures. Use for metadata, text extraction, page rendering, OCR, and Typst note conversion.
compatibility: Uses Poppler tools, Tesseract, ImageMagick, Pandoc, and Pi image reading when available.
---

# Scientific Document Workflow

## Preserve the Source

Treat supplied books, papers, slides, and scans as immutable source material. Write extraction, rendered pages, and OCR output to `/tmp` or another ignored working directory. Do not commit copyrighted documents or bulk extracted text.

Record the exact source path/version and state which pages or sections were inspected.

## Identify the Document

Start with metadata and file type:

```bash
file document.pdf
pdfinfo document.pdf
pdffonts document.pdf
```

The presence of fonts/text suggests direct extraction may work; image-only pages may require rendering and OCR.

## Text Extraction

For searchable prose:

```bash
pdftotext -layout document.pdf /tmp/document.txt
rg -n "keyword|Definition|Theorem|Algorithm" /tmp/document.txt
```

Extraction is an index, not ground truth. Multi-column order, symbols, equations, footnotes, and tables can be corrupted. Verify important claims against the rendered page and cite page/section identifiers.

## Render Relevant Pages

Render only the needed page range at adequate resolution:

```bash
mkdir -p /tmp/document-pages
pdftoppm -f 12 -l 14 -r 180 -png document.pdf /tmp/document-pages/page
```

Use Pi's image reading on the resulting PNGs when equations, diagrams, or layout matter. Avoid rendering an entire long book unless necessary.

## OCR for Scans

For an image-only page:

```bash
tesseract /tmp/document-pages/page-12.png stdout --psm 6 > /tmp/page-12.txt
```

Choose segmentation mode based on layout and visually verify equations and special symbols. OCR output must not be treated as exact mathematical notation.

## Figures and Images

Use `pdfimages -list` to inspect embedded assets before extracting. Prefer page rendering when labels and surrounding captions matter. Preserve aspect ratio; do not infer quantitative values from a plot without checking axes, units, and uncertainty.

## Conversion to Notes

Do not blindly convert an entire PDF or LaTeX-like extraction into Typst. Instead:

1. extract the relevant claims and notation
2. verify against pages
3. reconstruct the mathematical content in Typst-native syntax
4. distinguish source content from added explanation
5. compile and inspect the resulting `.typ` artifact

When quoting or citing, retain page/section provenance and obey the document's license and course rules.
