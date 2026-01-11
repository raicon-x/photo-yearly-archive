# Photo Yearly Archive

A small, robust, shell-based system for **yearly photo and video archiving** with:

- deterministic file lists
- transport-friendly TAR archives
- PAR2-based integrity verification and repair
- explicit, testable restore workflow

Designed for **long-term cold storage**, external disks, and real-world **bit rot** scenarios.

## Directory Layout

```

MediaArchive/
└── <YEAR>/
├── <YEAR>_RAW.tar
├── <YEAR>_JPG.tar
├── <YEAR>_Video.tar
├── _lists/
│   ├── RAW.list
│   ├── JPG.list
│   ├── Video.list
│   └── ALL_MEDIA.list
└── _par2/
├── <YEAR>_RAW.par2
├── <YEAR>_RAW.vol*.par2
├── <YEAR>_JPG.par2
├── <YEAR>_JPG.vol*.par2
└── ...

````

### Directory Notes

- `*.tar`  
  Uncompressed, transport-friendly archives.  
  No compression is used to maximize repairability.

- `_lists/`  
  Authoritative file lists generated from the source directories.  
  All paths are **relative to `$HOME`**.

- `_par2/`  
  PAR2 recovery files providing error detection and correction.

---

## Scripts Overview

| Script | Purpose | Scope | Risk Level |
|------|--------|-------|------------|
| `make_yearly_lists.sh` | Generate authoritative file lists | Single year | Safe |
| `make_yearly_archive.sh` | Create TAR + PAR2 archives | Single year | Writes data |
| `verify_archives.sh` | Verify integrity of all archives | All years | Safe (read-only) |
| `repair_year.sh` | Repair damaged archives using PAR2 | Single year | **Destructive** |
| `restore_year.sh` | Verify → repair → extract data | Single year | **Destructive** |

---

## Script Usage

---

### 1. `make_yearly_lists.sh`

Generate authoritative file lists for one year.

**What it does**

- Scans:
  - `$HOME/Pictures/<YEAR>` for RAW and JPG files
  - `$HOME/Videos/<YEAR>` for video files
- Outputs file paths relative to `$HOME`
- Performs a strict completeness check

**Usage**

```bash
./make_yearly_lists.sh <YEAR>
````

**Example**

```bash
./make_yearly_lists.sh 2012
```

---

### 2. `make_yearly_archive.sh`

Create yearly TAR archives and corresponding PAR2 recovery files.

**What it does**

* Creates one TAR per media type:

  * `<YEAR>_RAW.tar`
  * `<YEAR>_JPG.tar`
  * `<YEAR>_Video.tar`
* Generates matching PAR2 recovery files
* Stores PAR2 files under `_par2/`

**Usage**

```bash
./make_yearly_archive.sh <YEAR>
```

**Example**

```bash
./make_yearly_archive.sh 2012
```

---

### 3. `verify_archives.sh`

Verify all yearly archives under an archive root.

**What it does**

* Traverses all `YYYY` directories
* Runs `par2 verify` on each archive
* Read-only and safe for automation
* On failure:

  * Prints detailed PAR2 diagnostic output
  * Suggests the appropriate repair command

**Usage**

```bash
./verify_archives.sh
./verify_archives.sh <ARCHIVE_ROOT>
```

**Examples**

```bash
./verify_archives.sh
./verify_archives.sh /Volumes/ColdBackup/MediaArchive
```

---

### 4. `repair_year.sh`

Repair a single year archive using PAR2.

**What it does**

* Explicit, manual repair operation
* Workflow:

  1. Verify
  2. Repair (if required)
  3. Verify again
* Aborts if damage is unrecoverable

⚠️ **This script modifies archive files. Use only when verification fails.**

**Usage**

```bash
./repair_year.sh <YEAR> [ARCHIVE_ROOT]
```

**Examples**

```bash
./repair_year.sh 2012
./repair_year.sh 2012 /Volumes/ColdBackup/MediaArchive
```

---

### 5. `restore_year.sh`

Restore archived data for one specific year.

**Workflow**

```
verify → (repair if needed) → verify → extract
```

**What it does**

* Operates on a single, explicitly specified year
* Requires an explicit destination directory
* Will not silently skip verification or repair failures

**Usage**

```bash
./restore_year.sh <YEAR> <DEST_DIR> [ARCHIVE_ROOT]
```

**Examples**

```bash
./restore_year.sh 2012 /tmp/restore_test
./restore_year.sh 2012 /Volumes/Recovery /Volumes/ColdBackup/MediaArchive
```

After restore, extracted files will appear under:

```
<DEST_DIR>/
  ├── Pictures/
  └── Videos/
```

---

## Typical Workflow

### Initial Archive Creation

```bash
./make_yearly_lists.sh 2012
./make_yearly_archive.sh 2012
```

---

### Periodic Integrity Check (Recommended)

```bash
./verify_archives.sh
```

Safe to run on:

* external drives
* cold storage disks
* archives after transport

---

### Repair After Detected Damage

```bash
./repair_year.sh 2012
```

---

### Full Data Restore

```bash
./restore_year.sh 2012 /path/to/restore
```

---

## Requirements

* macOS
* `bash`
* `tar`
* `par2cmdline`

Install PAR2 via Homebrew:

```bash
brew install par2
```

---

## Design Notes

* File lists are the **single source of truth**
* TAR archives are **uncompressed** for maximum repairability
* PAR2 is used for **error correction**, not just detection
* Verification and repair are intentionally separated
* Explicit working directory and `-B` are used for macOS `par2cmdline` compatibility
* All destructive operations require explicit user intent

---

## Philosophy

> Backups that were never verified
> are not backups.

This project is designed to be **tested, repaired, and trusted** — not just stored.

