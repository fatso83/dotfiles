#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./compress-pdf-images.sh INPUT.pdf [OUTPUT.pdf]

Environment overrides:
  PDF_DPI=150          Downsample color/grayscale images to this DPI
  PDF_MONO_DPI=300     Downsample monochrome images to this DPI
  PDF_JPEG_Q=75        JPEG quality, 1-100
  PDF_COMPAT=1.6       Output PDF compatibility level

Examples:
  ./compress-pdf-images.sh big.pdf
  PDF_DPI=120 PDF_JPEG_Q=70 ./compress-pdf-images.sh big.pdf smaller.pdf

Install tools on macOS:
  brew install ghostscript qpdf poppler
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || $# -lt 1 ]]; then
  usage
  exit 0
fi

if ! command -v gs >/dev/null 2>&1; then
  echo "Missing dependency: ghostscript (gs)" >&2
  echo "Install on macOS: brew install ghostscript qpdf poppler" >&2
  exit 1
fi

input=$1
if [[ ! -f "$input" ]]; then
  echo "Input file not found: $input" >&2
  exit 1
fi

output=${2:-"${input%.pdf}.compressed.pdf"}
tmp_output="${output}.tmp.pdf"
optimized_tmp="${output}.optimized.tmp.pdf"

dpi=${PDF_DPI:-150}
mono_dpi=${PDF_MONO_DPI:-300}
jpeg_q=${PDF_JPEG_Q:-75}
compat=${PDF_COMPAT:-1.6}

rm -f "$tmp_output" "$optimized_tmp"

gs \
  -sDEVICE=pdfwrite \
  -dCompatibilityLevel="$compat" \
  -dPDFSETTINGS=/ebook \
  -dNOPAUSE \
  -dQUIET \
  -dBATCH \
  -dDetectDuplicateImages=true \
  -dCompressFonts=true \
  -dSubsetFonts=true \
  -dAutoRotatePages=/None \
  -dColorImageDownsampleType=/Bicubic \
  -dColorImageResolution="$dpi" \
  -dGrayImageDownsampleType=/Bicubic \
  -dGrayImageResolution="$dpi" \
  -dMonoImageDownsampleType=/Subsample \
  -dMonoImageResolution="$mono_dpi" \
  -dAutoFilterColorImages=false \
  -dColorImageFilter=/DCTEncode \
  -dAutoFilterGrayImages=false \
  -dGrayImageFilter=/DCTEncode \
  -dJPEGQ="$jpeg_q" \
  -sOutputFile="$tmp_output" \
  "$input"

if command -v qpdf >/dev/null 2>&1; then
  qpdf --linearize "$tmp_output" "$optimized_tmp"
  mv "$optimized_tmp" "$output"
  rm -f "$tmp_output"
else
  mv "$tmp_output" "$output"
fi

in_size=$(wc -c < "$input" | tr -d ' ')
out_size=$(wc -c < "$output" | tr -d ' ')

awk -v in_size="$in_size" -v out_size="$out_size" -v input="$input" -v output="$output" '
  BEGIN {
    saved = in_size - out_size
    pct = in_size ? (saved / in_size) * 100 : 0
    printf("Input:  %s (%.1f MB)\n", input, in_size / 1000000)
    printf("Output: %s (%.1f MB)\n", output, out_size / 1000000)
    printf("Saved:  %.1f MB (%.1f%%)\n", saved / 1000000, pct)
  }
'
