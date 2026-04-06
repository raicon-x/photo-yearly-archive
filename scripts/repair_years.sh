#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# repair_years.sh
#
# Verify and repair archives for a range of years using PAR2.
#
# Usage:
#   ./repair_years.sh <START_YEAR> <END_YEAR> [ARCHIVE_ROOT]
#
# Defaults:
#   ARCHIVE_ROOT : ~/Documents/MediaArchive
#
# Example:
#   ./repair_years.sh 2018 2023
#   ./repair_years.sh 2018 2023 /Volumes/ColdBackup/MediaArchive
# ============================================================

START_YEAR="${1:-}"
END_YEAR="${2:-}"
ARCHIVE_ROOT="${3:-$HOME/Documents/MediaArchive}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPAIR_SCRIPT="$SCRIPT_DIR/repair_year.sh"

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

if [[ ! -x "$REPAIR_SCRIPT" ]]; then
  echo "ERROR: repair_year.sh not found or not executable."
  exit 1
fi

echo "Repairing archives for years ${START_YEAR} - ${END_YEAR}"
echo "Archive root : $ARCHIVE_ROOT"

# ------------------------------------------------------------
# Main loop
# ------------------------------------------------------------

FAILED_YEARS=()

for (( year = START_YEAR; year <= END_YEAR; year++ )); do
  echo
  echo "=============================="
  echo " Repairing year: ${year}"
  echo "=============================="

  if "$REPAIR_SCRIPT" "$year" "$ARCHIVE_ROOT"; then
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
echo " Repair summary"
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
echo "All years repaired successfully."
