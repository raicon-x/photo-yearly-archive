#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# make_years.sh
#
# Create yearly archives for a range of years.
#
# Usage:
#   ./make_years.sh <START_YEAR> <END_YEAR> [ARCHIVE_ROOT]
#
# Defaults:
#   ARCHIVE_ROOT : ~/Documents/MediaArchive
#
# Example:
#   ./make_years.sh 2018 2023
#   ./make_years.sh 2018 2023 /Volumes/ColdBackup/MediaArchive
# ============================================================

START_YEAR="${1:-}"
END_YEAR="${2:-}"
ARCHIVE_ROOT="${3:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAKE_SCRIPT="$SCRIPT_DIR/make_yearly_archive.sh"

# ------------------------------------------------------------
# Validation
# ------------------------------------------------------------

if [[ -z "$START_YEAR" || -z "$END_YEAR" ]]; then
  echo "Usage: $0 <START_YEAR> <END_YEAR> [ARCHIVE_ROOT]"
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

if [[ ! -x "$MAKE_SCRIPT" ]]; then
  echo "ERROR: make_yearly_archive.sh not found or not executable."
  exit 1
fi

echo "Creating archives for years ${START_YEAR} - ${END_YEAR}"
[[ -n "$ARCHIVE_ROOT" ]] && echo "Archive root : $ARCHIVE_ROOT"

# ------------------------------------------------------------
# Main loop
# ------------------------------------------------------------

FAILED_YEARS=()

for (( year = START_YEAR; year <= END_YEAR; year++ )); do
  echo
  echo "=============================="
  echo " Archiving year: ${year}"
  echo "=============================="

  # Pass ARCHIVE_ROOT only if explicitly set, so make_yearly_archive.sh
  # can keep its own default.
  if [[ -n "$ARCHIVE_ROOT" ]]; then
    ARCHIVE_ROOT="$ARCHIVE_ROOT" "$MAKE_SCRIPT" "$year"
  else
    "$MAKE_SCRIPT" "$year"
  fi && echo "Year ${year}: OK" || {
    echo "Year ${year}: FAILED"
    FAILED_YEARS+=("$year")
  }
done

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

echo
echo "=============================="
echo " Archive summary"
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
echo "All years archived successfully."
