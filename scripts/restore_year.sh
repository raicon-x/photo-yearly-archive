#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# restore_year.sh
#
# Restore a yearly archive:
#   verify -> repair (if needed) -> verify -> extract
#
# Usage:
#   ./restore_year.sh <YEAR> <DEST_DIR> [ARCHIVE_ROOT]
#
# ============================================================

YEAR="${1:-}"
DEST_DIR="${2:-}"
ARCHIVE_ROOT="${3:-$HOME/Documents/MediaArchive}"

# ------------------------------------------------------------
# Validation
# ------------------------------------------------------------

if [[ -z "$YEAR" || -z "$DEST_DIR" ]]; then
  echo "Usage: $0 <YEAR> <DEST_DIR> [ARCHIVE_ROOT]"
  exit 1
fi

YEAR_DIR="$ARCHIVE_ROOT/$YEAR"
PAR2_DIR="$YEAR_DIR/_par2"

if [[ ! -d "$YEAR_DIR" ]]; then
  echo "ERROR: Year directory not found:"
  echo "  $YEAR_DIR"
  exit 1
fi

if [[ ! -d "$PAR2_DIR" ]]; then
  echo "ERROR: _par2 directory not found:"
  echo "  $PAR2_DIR"
  exit 1
fi

if ! command -v par2 >/dev/null 2>&1; then
  echo "ERROR: par2 not found. Install with: brew install par2"
  exit 1
fi

if ! command -v tar >/dev/null 2>&1; then
  echo "ERROR: tar not found."
  exit 1
fi

mkdir -p "$DEST_DIR"

echo "Restoring year: $YEAR"
echo "Archive root : $ARCHIVE_ROOT"
echo "Destination  : $DEST_DIR"

# ------------------------------------------------------------
# Helper: verify + repair for one archive
# ------------------------------------------------------------

restore_one() {
  local label="$1"
  local tar_file="${YEAR}_${label}.tar"
  local par2_file="_par2/${YEAR}_${label}.par2"

  if [[ ! -f "$YEAR_DIR/$par2_file" ]]; then
    echo
    echo "Skipping ${label}: PAR2 file not found."
    return
  fi

  if [[ ! -f "$YEAR_DIR/$tar_file" ]]; then
    echo
    echo "ERROR: TAR file missing:"
    echo "  $YEAR_DIR/$tar_file"
    exit 1
  fi

  echo
  echo "Processing ${label} ..."

  # Verify
  if (
    cd "$YEAR_DIR" || exit 1
    par2 verify -B . "$par2_file" >/dev/null
  ); then
    echo "  OK: ${label} verified."
  else
    echo "  Integrity issues detected in ${label}."
    echo "  Attempting repair ..."

    if (
      cd "$YEAR_DIR" || exit 1
      par2 repair -B . "$par2_file"
    ); then
      echo "  Repair completed. Re-verifying ..."

      if (
        cd "$YEAR_DIR" || exit 1
        par2 verify -B . "$par2_file" >/dev/null
      ); then
        echo "  OK: ${label} repaired and verified."
      else
        echo "  ERROR: ${label} verification failed after repair."
        exit 1
      fi
    else
      echo "  ERROR: ${label} repair failed."
      exit 1
    fi
  fi

  # Extract
  echo "  Extracting ${label} to $DEST_DIR ..."
  tar -xf "$YEAR_DIR/$tar_file" -C "$DEST_DIR"
}

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------

restore_one "RAW"
restore_one "JPG"
restore_one "Video"

echo
echo "Restore completed successfully for year ${YEAR}."
echo "Files restored to:"
echo "  $DEST_DIR"
