#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# restore_years.sh
#
# Restore a range of yearly archives.
#
# Usage:
#   ./restore_years.sh <START_YEAR> <END_YEAR> [DEST_ROOT] [ARCHIVE_ROOT]
#
# Defaults:
#   DEST_ROOT    : $HOME  (RAW/JPG -> ~/Pictures, Video -> ~/Videos)
#   ARCHIVE_ROOT : ~/Documents/MediaArchive
#
# Example:
#   ./restore_years.sh 2018 2023
#   ./restore_years.sh 2018 2023 /Volumes/Restore
#   ./restore_years.sh 2018 2023 /Volumes/Restore /Volumes/ColdBackup/MediaArchive
# ============================================================

START_YEAR="${1:-}"
END_YEAR="${2:-}"
DEST_ROOT="${3:-$HOME}"
ARCHIVE_ROOT="${4:-$HOME/Documents/MediaArchive}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESTORE_SCRIPT="$SCRIPT_DIR/restore_year.sh"

# ------------------------------------------------------------
# Validation
# ------------------------------------------------------------

if [[ -z "$START_YEAR" || -z "$END_YEAR" ]]; then
  echo "Usage: $0 <START_YEAR> <END_YEAR> [DEST_ROOT] [ARCHIVE_ROOT]"
  exit 1
fi

if [[ ! "$START_YEAR" =~ ^[0-9]{4}$ || ! "$END_YEAR" =~ ^[0-9]{4}$ ]]; then
  echo "ERROR: START_YEAR and END_YEAR must be 4-digit years."
  exit 1
fi

if (( START_YEAR > END_YEAR )); then
  echo "ERROR: START_YEAR ($START_YEAR) must be <= END_YEAR ($END_YEAR)."
  exit 1
fi

if [[ ! -x "$RESTORE_SCRIPT" ]]; then
  echo "ERROR: restore_year.sh not found or not executable."
  exit 1
fi

echo "Restoring years ${START_YEAR} - ${END_YEAR}"
echo "Archive root : $ARCHIVE_ROOT"
echo "Destination  : $DEST_ROOT"
echo "  (RAW/JPG -> $DEST_ROOT/Pictures, Video -> $DEST_ROOT/Videos)"

# ------------------------------------------------------------
# Main loop
# ------------------------------------------------------------

FAILED_YEARS=()

for (( year = START_YEAR; year <= END_YEAR; year++ )); do
  echo
  echo "=============================="
  echo " Restoring year: ${year}"
  echo "=============================="

  if "$RESTORE_SCRIPT" "$year" "$DEST_ROOT" "$ARCHIVE_ROOT"; then
    echo "Year ${year}: OK"
  else
    echo "Year ${year}: FAILED"
    FAILED_YEARS+=("$year")
  fi
done

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

echo
echo "=============================="
echo " Restore summary"
echo "=============================="
TOTAL=$(( END_YEAR - START_YEAR + 1 ))
FAILED=${#FAILED_YEARS[@]}
OK=$(( TOTAL - FAILED ))

echo "  Total years : $TOTAL"
echo "  Succeeded   : $OK"
echo "  Failed      : $FAILED"

if (( FAILED > 0 )); then
  echo
  echo "Failed years:"
  for y in "${FAILED_YEARS[@]}"; do
    echo "  - $y"
  done
  exit 1
fi

echo
echo "All years restored successfully to:"
echo "  $DEST_ROOT"
