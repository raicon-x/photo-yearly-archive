#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# verify_years.sh
#
# Verify archives for a range of years using PAR2.
#
# Usage:
#   ./verify_years.sh <START_YEAR> <END_YEAR> [ARCHIVE_ROOT]
#
# Defaults:
#   ARCHIVE_ROOT : ~/Documents/MediaArchive
#
# Example:
#   ./verify_years.sh 2018 2023
#   ./verify_years.sh 2018 2023 /Volumes/ColdBackup/MediaArchive
# ============================================================

START_YEAR="${1:-}"
END_YEAR="${2:-}"
ARCHIVE_ROOT="${3:-$HOME/Documents/MediaArchive}"

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

if [[ ! -d "$ARCHIVE_ROOT" ]]; then
  echo "ERROR: Archive root not found:"
  echo "  $ARCHIVE_ROOT"
  exit 1
fi

if ! command -v par2 >/dev/null 2>&1; then
  echo "ERROR: par2 not found. Install with: brew install par2"
  exit 1
fi

echo "Verifying years ${START_YEAR} - ${END_YEAR}"
echo "Archive root : $ARCHIVE_ROOT"

# ------------------------------------------------------------
# Helper: verify one label for a given year
# ------------------------------------------------------------

verify_one() {
  local year_dir="$1"
  local year="$2"
  local label="$3"
  local par2_file="_par2/${year}_${label}.par2"

  if [[ ! -f "$year_dir/$par2_file" ]]; then
    echo "  Skipping ${label}: PAR2 not found."
    return
  fi

  echo "  Verifying ${label} ..."

  if (
    cd "$year_dir" || exit 1
    par2 verify -B . "$par2_file" >/dev/null
  ); then
    echo "  OK: ${label}"
  else
    echo "  ERROR: ${label} verification failed."
    echo "  --- par2 diagnostic output ---"
    (
      cd "$year_dir" || exit 1
      par2 verify -B . -v "$par2_file"
    )
    echo "  --- end of diagnostic ---"
    echo "  Hint: run ./repair_year.sh ${year}"
    return 1
  fi
}

# ------------------------------------------------------------
# Main loop
# ------------------------------------------------------------

FAILED_YEARS=()

for (( year = START_YEAR; year <= END_YEAR; year++ )); do
  year_dir="$ARCHIVE_ROOT/$year"

  echo
  echo "=============================="
  echo " Verifying year: ${year}"
  echo "=============================="

  if [[ ! -d "$year_dir" ]]; then
    echo "  Skipping: directory not found ($year_dir)"
    continue
  fi

  if [[ ! -d "$year_dir/_par2" ]]; then
    echo "  Skipping: no _par2 directory."
    continue
  fi

  year_ok=true
  for label in RAW JPG Video; do
    verify_one "$year_dir" "$year" "$label" || year_ok=false
  done

  if $year_ok; then
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
echo " Verification summary"
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
echo "All years verified successfully."
