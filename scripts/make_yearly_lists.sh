#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# photo-yearly-archive
# make_yearly_lists.sh
#
# Generate yearly RAW / JPG / Video file lists
# using paths RELATIVE TO $HOME.
#
# Example list entry:
#   Pictures/2012/xxx.CR2
#
# ============================================================

# ------------------------------------------------------------
# Fixed layout
# ------------------------------------------------------------

HOME_ROOT="$HOME"
PICTURE_ROOT="$HOME_ROOT/Pictures"
VIDEO_ROOT="$HOME_ROOT/Videos"
ARCHIVE_ROOT="$HOME_ROOT/Documents/MediaArchive"

YEAR="${1:-}"

# ------------------------------------------------------------
# Validation
# ------------------------------------------------------------

if [[ -z "$YEAR" ]]; then
  echo "Usage: $0 <YEAR>"
  exit 1
fi

PICTURE_YEAR_DIR="$PICTURE_ROOT/$YEAR"
VIDEO_YEAR_DIR="$VIDEO_ROOT/$YEAR"

YEAR_DIR="$ARCHIVE_ROOT/$YEAR"
LIST_DIR="$YEAR_DIR/_lists"

if [[ ! -d "$PICTURE_YEAR_DIR" ]]; then
  echo "ERROR: Pictures directory not found: $PICTURE_YEAR_DIR"
  exit 1
fi

if [[ ! -d "$VIDEO_YEAR_DIR" ]]; then
  echo "Notice: Video directory not found: $VIDEO_YEAR_DIR"
fi

mkdir -p "$LIST_DIR"

# ------------------------------------------------------------
# Centralized extension definitions
# ------------------------------------------------------------

RAW_EXT=(arw cr3 nef raf dng)
JPG_EXT=(jpg jpeg)
VIDEO_EXT=(mp4 mov mxf)

# ------------------------------------------------------------
# Helper functions
# ------------------------------------------------------------

build_find_expr() {
  local exts=("$@")
  local expr=""
  for ext in "${exts[@]}"; do
    expr+=" -iname \"*.${ext}\" -o"
  done
  echo "${expr% -o}"
}

# ------------------------------------------------------------
# Generate file lists (RELATIVE paths)
# ------------------------------------------------------------

echo "Scanning year: ${YEAR}"
echo "Pictures root: $PICTURE_ROOT"
echo "Videos root  : $VIDEO_ROOT"
echo "Archive root : $ARCHIVE_ROOT"
echo "List paths   : relative to \$HOME"

RAW_EXPR=$(build_find_expr "${RAW_EXT[@]}")
JPG_EXPR=$(build_find_expr "${JPG_EXT[@]}")
VIDEO_EXPR=$(build_find_expr "${VIDEO_EXT[@]}")

# RAW and JPG from Pictures
eval "find \"$PICTURE_YEAR_DIR\" -type f \\( ${RAW_EXPR} \\)" |
  sed "s,^${HOME_ROOT}/,," |
  sort >"$LIST_DIR/RAW.list"

eval "find \"$PICTURE_YEAR_DIR\" -type f \\( ${JPG_EXPR} \\)" |
  sed "s,^${HOME_ROOT}/,," |
  sort >"$LIST_DIR/JPG.list"

# Video from Videos
if [[ -d "$VIDEO_YEAR_DIR" ]]; then
  eval "find \"$VIDEO_YEAR_DIR\" -type f \\( ${VIDEO_EXPR} \\)" |
    sed "s,^${HOME_ROOT}/,," |
    sort >"$LIST_DIR/Video.list"
else
  : >"$LIST_DIR/Video.list"
fi

# ------------------------------------------------------------
# Build ALL_MEDIA list (authoritative union)
# ------------------------------------------------------------

cat "$LIST_DIR/RAW.list" \
  "$LIST_DIR/JPG.list" \
  "$LIST_DIR/Video.list" |
  sort >"$LIST_DIR/ALL_MEDIA.list"

# ------------------------------------------------------------
# Completeness check
# ------------------------------------------------------------

echo "Running completeness check ..."

if ! diff -q \
  <(cat "$LIST_DIR/RAW.list" "$LIST_DIR/JPG.list" "$LIST_DIR/Video.list" | sort) \
  "$LIST_DIR/ALL_MEDIA.list" \
  >/dev/null; then
  echo "ERROR: File list mismatch detected."
  exit 1
fi

echo "Check passed. No missing or unknown media files."

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

echo
echo "Summary for year ${YEAR}:"
echo "RAW files   : $(wc -l <"$LIST_DIR/RAW.list")"
echo "JPG files   : $(wc -l <"$LIST_DIR/JPG.list")"
echo "Video files : $(wc -l <"$LIST_DIR/Video.list")"
echo
echo "Lists written to: $LIST_DIR"
