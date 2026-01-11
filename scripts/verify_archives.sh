#!/usr/bin/env bash
set -euo pipefail

ARCHIVE_ROOT="${1:-$HOME/Documents/MediaArchive}"

if [[ ! -d "$ARCHIVE_ROOT" ]]; then
  echo "ERROR: Archive root not found:"
  echo "  $ARCHIVE_ROOT"
  exit 1
fi

if ! command -v par2 >/dev/null 2>&1; then
  echo "ERROR: par2 not found. Install with: brew install par2"
  exit 1
fi

echo "Verifying all archives under:"
echo "  $ARCHIVE_ROOT"

for dir in "$ARCHIVE_ROOT"/*; do
  [[ -d "$dir" ]] || continue

  year="$(basename "$dir")"
  [[ "$year" =~ ^[0-9]{4}$ ]] || continue

  par2_dir="$dir/_par2"
  [[ -d "$par2_dir" ]] || {
    echo
    echo "Skipping ${year}: no _par2 directory."
    continue
  }

  echo
  echo "=== Verifying year ${year} ==="

  for label in RAW JPG Video; do
    par2_file="_par2/${year}_${label}.par2"

    if [[ ! -f "$dir/$par2_file" ]]; then
      echo "  Skipping ${label}: PAR2 not found."
      continue
    fi

    echo "  Verifying ${label} ..."

    if (
      cd "$dir" || exit 1
      par2 verify -B . "$par2_file" >/dev/null
    ); then
      echo "  OK: ${label}"
    else
      echo "  ERROR: ${label} verification failed."
      echo "  --- par2 diagnostic output ---"
      (
        cd "$dir" || exit 1
        par2 verify -B . -v "$par2_file"
      )
      echo "  --- end of diagnostic ---"
      echo "  Hint: run ./repair_year.sh ${year}"
      exit 1
    fi
  done
done

echo
echo "All archives verified successfully."
