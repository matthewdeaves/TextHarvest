# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TextHarvest is a collection of Bash scripts for automated document and source code processing on Linux and macOS. It provides PDF text extraction, OCR processing, and source code listing generation through a unified CLI.

## Critical Rules

**ALWAYS use the unified CLI interface:**
```bash
./textharvest.sh <command> [OPTIONS]
```

**NEVER directly call the individual `process_*.sh` scripts** - they are internal implementation details invoked by the CLI.

## Commands

| Command | Purpose |
|---------|---------|
| `code` | Generate source code listings from project directories |
| `pdf-text` | Extract text from text-based PDFs |
| `pdf-ocr` | OCR processing for scanned/image PDFs |
| `setup` | Install dependencies (pdftotext, tesseract, ocrmypdf) |
| `config` | Manage configuration (`--init`, `--show`, `--validate`) |

**Global options:** `-v`/`-vv` (verbose), `-q` (quiet), `--dry-run`, `--help`

## Testing Commands

```bash
./textharvest.sh version                    # Verify CLI works
./textharvest.sh config --validate          # Check dependencies
./textharvest.sh code --dry-run -v          # Preview code processing
./textharvest.sh pdf-text --dry-run         # Preview PDF text extraction
./textharvest.sh setup --dry-run            # Preview dependency install
```

## Architecture

```
textharvest.sh          # Entry point - routes to processing scripts
├── lib/common.sh       # Shared library (error handling, config, progress)
├── process_code.sh     # Code listing generator
├── process_pdf_text.sh # PDF text extraction
├── process_pdf_ocr.sh  # OCR processing
└── setup.sh            # Cross-platform dependency installer
```

### Key Patterns

1. **All scripts source `lib/common.sh`** which provides:
   - Error handling: `error_exit()`, `warn()`, `info()`, `success()`, `debug()`
   - Validation: `validate_input_dir()`, `create_output_dir()`, `check_dependencies()`
   - Config: `load_config()`, `get_config(var_name, default)`
   - Progress: `init_progress()`, `update_progress()`, `finish_progress()`

2. **Dry-run support** - Check `if [[ "$DRY_RUN" == true ]]` before destructive operations

3. **Verbosity levels** - Use `info "message" 2` for verbose-only output, `debug "message"` for debug level

4. **Cross-platform handling** - Check `$OSTYPE` for macOS (`darwin*`) vs Linux differences (especially `stat` flags)

## Configuration

Config files load in order (later overrides earlier):
1. `/etc/textharvest.conf` → `~/.textharvest.conf` → `./textharvest.conf`

Environment variables override all (prefix with `TEXTHARVEST_`):
```bash
export TEXTHARVEST_CODE_DIR="/custom/path"
export TEXTHARVEST_MAX_JOBS=8
```

Key variables: `CODE_DIR`, `PDF_DIR`, `CODE_OUTPUT_DIR`, `PDF_TEXT_OUTPUT_DIR`, `VERBOSE_LEVEL`, `MAX_JOBS`, `OCR_LANG`

## Adding New Features

1. Add reusable functions to `lib/common.sh`
2. Use existing error handling patterns (`error_exit`, `warn`, etc.)
3. Support `--dry-run` and verbosity flags
4. Test on both Linux and macOS (or use `--force-platform` flag)
5. Add license header to new files:
   ```bash
   # Copyright (c) 2025 Matthew Deaves
   # Licensed under the MIT License - see LICENSE file for details
   ```