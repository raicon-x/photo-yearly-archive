#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# photo-yearly-archive
# make_yearly_archive.sh
#
# Create transport-friendly yearly archives:
#   tar (no compression) + par2
#
# Assumptions:
# - make_yearly_lists.sh outputs paths RELATIVE to $HOME
#   (e.g. Pictures/2012/xxx.CR2)
#
# Output layout:
#   <YEAR>_RAW.tar
#   <YEAR>_JPG.tar
#   <YEAR>_Video.tar
#   _par2/
#     *.par2, *.vol*.par2
#
# macOS / BSD tar compatible
# ============================================================

ARCHIVE_ROOT="$HOME/Documents/MediaArchive"
HOME_ROOT="$HOME"
YEAR="${1:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIST_SCRIPT="$SCRIPT_DIR/make_yearly_lists.sh"

# ------------------------------------------------------------
# Validation
# ------------------------------------------------------------

if [[ -z "$YEAR" ]]; then
  echo "Usage: $0 <YEAR>"
  exit 1
fi

if [[ ! -x "$LIST_SCRIPT" ]]; then
  echo "ERROR: make_yearly_lists.sh not found or not executable."
  exit 1
fi

if ! command -v tar >/dev/null 2>&1; then
  echo "ERROR: tar not found."
  exit 1
fi

if ! command -v par2 >/dev/null 2>&1; then
  echo "ERROR: par2 not found."
  echo "Install with: brew install par2"
  exit 1
fi

# ------------------------------------------------------------
# Step 1: Generate relative-path file lists
# ------------------------------------------------------------

echo "Step 1: Generating file lists for year ${YEAR}"
"$LIST_SCRIPT" "$YEAR"

YEAR_DIR="$ARCHIVE_ROOT/$YEAR"
LIST_DIR="$YEAR_DIR/_lists"
PAR2_DIR="$YEAR_DIR/_par2"

if [[ ! -d "$LIST_DIR" ]]; then
  echo "ERROR: List directory not found: $LIST_DIR"
  exit 1
fi

mkdir -p "$YEAR_DIR" "$PAR2_DIR"

# ------------------------------------------------------------
# PAR2 redundancy policy
# ------------------------------------------------------------

RAW_REDUNDANCY=10
JPG_REDUNDANCY=5
VIDEO_REDUNDANCY=3

# ------------------------------------------------------------
# Helper: tar + par2
# ------------------------------------------------------------

archive_and_par2() {
  local label="$1"
  local list_file="$2"
  local redundancy="$3"

  if [[ ! -s "$list_file" ]]; then
    echo "Skipping ${label}: list empty."
    return
  fi

  local tar_file="$YEAR_DIR/${YEAR}_${label}.tar"
  local par2_base="$PAR2_DIR/${YEAR}_${label}.par2"

  echo
  echo "Creating TAR for ${label}"

  (
    cd "$HOME_ROOT" || exit 1
    tar -cf "$tar_file" -T "$list_file"
  )

  echo "Creating PAR2 for ${label} (${redundancy}% redundancy)"

  par2 create \
    -B "$YEAR_DIR" \
    -r"${redundancy}" \
    "$par2_base" \
    "$tar_file"
}

# ------------------------------------------------------------
# Step 2: Create archives
# ------------------------------------------------------------

archive_and_par2 "RAW" "$LIST_DIR/RAW.list" "$RAW_REDUNDANCY"
archive_and_par2 "JPG" "$LIST_DIR/JPG.list" "$JPG_REDUNDANCY"
archive_and_par2 "Video" "$LIST_DIR/Video.list" "$VIDEO_REDUNDANCY"

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

echo
echo "Yearly transport archive completed: ${YEAR}"
echo "Location: $YEAR_DIR"
