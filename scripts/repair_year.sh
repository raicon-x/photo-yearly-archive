#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# repair_year.sh
#
# Verify and repair a SINGLE year archive using PAR2.
#
# Usage:
#   ./repair_year.sh <YEAR> [ARCHIVE_ROOT]
#
# Example:
#   ./repair_year.sh 2012
#   ./repair_year.sh 2012 /Volumes/ColdBackup/MediaArchive
#
# IMPORTANT:
# - Must be run with par2cmdline available
# - Uses explicit cwd + -B . to avoid par2 path issues
# ============================================================

YEAR="${1:-}"
ARCHIVE_ROOT="${2:-$HOME/Documents/MediaArchive}"

# ------------------------------------------------------------
# Validation
# ------------------------------------------------------------

if [[ -z "$YEAR" ]]; then
  echo "Usage: $0 <YEAR> [ARCHIVE_ROOT]"
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

echo "Repairing archives for year: $YEAR"
echo "Archive root: $ARCHIVE_ROOT"

# ------------------------------------------------------------
# Helper: verify + repair for one label
# ------------------------------------------------------------

repair_one() {
  local label="$1"
  local par2_file="_par2/${YEAR}_${label}.par2"

  if [[ ! -f "$YEAR_DIR/$par2_file" ]]; then
    echo
    echo "Skipping ${label}: PAR2 file not found."
    return
  fi

  echo
  echo "Checking ${label} ..."

  # First verify
  if (
    cd "$YEAR_DIR" || exit 1
    par2 verify -B . "$par2_file" >/dev/null
  ); then
    echo "OK: ${label} archive is intact."
    return
  fi

  echo "Detected errors in ${label}. Repairing ..."

  # Repair
  if (
    cd "$YEAR_DIR" || exit 1
    par2 repair -B . "$par2_file"
  ); then
    echo "Repair completed for ${label}. Re-verifying ..."

    if (
      cd "$YEAR_DIR" || exit 1
      par2 verify -B . "$par2_file" >/dev/null
    ); then
      echo "OK: ${label} repaired successfully."
    else
      echo "ERROR: ${label} verification failed after repair."
      exit 1
    fi
  else
    echo "ERROR: ${label} repair failed. Data may be unrecoverable."
    exit 1
  fi
}

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------

repair_one "RAW"
repair_one "JPG"
repair_one "Video"

echo
echo "Repair process completed successfully for year ${YEAR}."
