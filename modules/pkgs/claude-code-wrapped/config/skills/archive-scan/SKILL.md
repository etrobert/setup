---
name: archive-scan
description:
  Triage a scanned document (typically a PDF from the iPhone Notes app), decide
  whether it is worth keeping, and if so OCR + compress it and file it into
  ~/sync/doc/mail/ with the repo's naming convention. Use whenever Étienne hands
  over a scanned letter/PDF and asks to archive, file, keep, or throw it away.
---

# Archive a scanned document

Étienne scans postal mail with the **iPhone Notes app** and hands the exported
PDF over for filing. Notes produces good, legible scans but the PDFs are
**huge** (~26 MB for a one-page letter, pages at ~3× A4 dimensions) and have
**no searchable text layer**. This skill triages, OCRs, compresses, and files
them.

## 1. Identify the document

The scans are image-only, so `pdftotext` returns nothing. Render a page and read
it visually:

```bash
nix shell nixpkgs#poppler-utils -c pdfinfo "<file>" | grep -E "Pages|Page size"
nix shell nixpkgs#poppler-utils -c pdftoppm -png -r 100 "<file>" /tmp/scan-page
# Crop/zoom a region at higher res for legibility, then Read the PNG:
nix shell nixpkgs#imagemagick -c magick /tmp/scan-page-1.png \
  -resize 2000x -gravity North -crop 2000x1400+0+0 +repage /tmp/scan-z1.png
```

Read the resulting PNG with the Read tool. Identify sender, date, subject, and
any reference/case number. Clean up `/tmp/scan-*.png` afterwards.

## 2. Decide: archive or discard

Use judgment about **record value**, and explain the reasoning to Étienne:

- **Archive** official correspondence with legal/financial/administrative weight
  or future usefulness — e.g. government agencies (Agentur für Arbeit,
  Amtsanwaltschaft, Finanzamt), insurers, anything usable as proof for an
  insurance claim, anything with a case number that could resurface.
- **Discard** (recommend, don't auto-delete) low-value items with no obligation
  or consequence — e.g. voluntary survey/study invitations, marketing.

Never delete the original from `~/Downloads`/Notes without explicit
confirmation. When archiving, **copy** the file in (leave the original in
place).

## 3. OCR + compress, then file

OCR is the expensive part and **does not work natively on this Mac**:
`nix run nixpkgs#ocrmypdf` fails on Darwin — the tesseract subprocess can't read
ocrmypdf's intermediate PNG (`image file not found: …/000001_ocr.png`),
reproducibly, with and without the Claude Code sandbox. Plain `tesseract` on a
PNG works locally, but ocrmypdf's orchestration is broken. So **route OCR
through `tower`** (Linux, reachable over Tailscale; the pipeline works there
first try). If tower is down, fall back to compression-only locally (step 3b)
and note that the text layer is missing until tower is back.

### 3a. Full pipeline (preferred — via tower)

```bash
scp "<input.pdf>" tower:/tmp/in.pdf
ssh tower '
  set -e
  cd /tmp
  # OCR: add a searchable German+English text layer (does not shrink the file)
  nix run nixpkgs#ocrmypdf -- -l deu+eng --skip-text /tmp/in.pdf /tmp/ocr.pdf
  # Compress: downsample to 150 dpi; preserves the OCR text layer
  nix shell nixpkgs#ghostscript -c gs -sDEVICE=pdfwrite \
    -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dQUIET -dBATCH \
    -sOutputFile=/tmp/final.pdf /tmp/ocr.pdf
'
scp tower:/tmp/final.pdf "<archive-destination.pdf>"
ssh tower 'rm -f /tmp/in.pdf /tmp/ocr.pdf /tmp/final.pdf'
```

Validated result: 26 MB → ~2.4 MB (≈11×), full German text layer with umlauts
intact, no visible loss of legibility. `-dPDFSETTINGS=/ebook` is 150 dpi; bump
to `/printer` (300 dpi) if Étienne wants higher fidelity at a larger size.

Verify before reporting done: `pdftotext <final> - | grep <known phrase>` should
return real body text, and the file size should have dropped.

### 3b. Fallback (tower unreachable — compression only, no OCR)

```bash
nix shell nixpkgs#ghostscript -c gs -sDEVICE=pdfwrite \
  -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dQUIET -dBATCH \
  -sOutputFile="<out.pdf>" "<input.pdf>"
```

## 4. Naming convention (mail/)

File into `~/sync/doc/mail/` as:

```
YYYY-MM-DD_sender_topic_reference.pdf
```

- **Date** = the document's own date, not the scan date.
- Underscores between fields, hyphens within a field.
- Prefer **English** terms (Étienne's preference), even for German senders —
  e.g. `employment-agency` (Agentur für Arbeit), `berlin-prosecutor`
  (Amtsanwaltschaft Berlin), `follow-up-invitation` (Folgeeinladung).
- **reference** = the most identifying number (Kundennummer, Geschäftszeichen,
  tracking number).

Examples already in the folder:

- `2025-01-29_employment-agency_follow-up-invitation_022H525328.pdf`
- `2024-12-06_berlin-prosecutor_theft-case-closed_3004-UJs-24354-24-A.pdf`

`mail/` naming is specific to that folder; see `~/sync/doc/CLAUDE.md` for the
repo's full conventions.
