# CLAUDE.md

This file provides comprehensive guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TextHarvest v2.0.0 is a modernized collection of Bash shell scripts for automated document and source code processing on Linux and macOS systems. The project has been completely refactored from v1.x with:

1. **Unified CLI Interface** - Single entry point (`textharvest.sh`) for all operations
2. **Shared Library Architecture** - Common functions in `lib/common.sh` for consistency
3. **Configuration Management** - Hierarchical settings system with `textharvest.conf`
4. **Enhanced Error Handling** - Comprehensive validation and user feedback
5. **Interactive Modes** - User-friendly file/project selection interfaces
6. **Parallel Processing** - Multi-threaded operations for better performance
7. **Cross-Platform Support** - Full Linux and macOS compatibility
8. **Plugin Architecture** - Foundation for extensibility

## File Structure Reference

```
TextHarvest/
├── textharvest.sh              # Main CLI interface (entry point)
├── textharvest.conf            # Configuration template
├── setup.sh                   # Cross-platform dependency installer
├── lib/
│   └── common.sh              # Shared utility functions library
├── process_code.sh            # Source code listing generator
├── process_pdf_text.sh        # PDF text extraction
├── process_pdf_ocr.sh         # OCR PDF processing
├── CLAUDE.md                  # This file
├── README.md                  # User documentation
├── INSTALL_MACOS.md           # macOS-specific installation guide
└── source_code/               # Input: project directories
└── source_pdf/                # Input: PDF files
└── code_listings/             # Output: source code listings
└── text_output/               # Output: PDF text extraction
└── ocr_pdf_output/            # Output: intermediate OCR PDFs
└── ocr_text_output/           # Output: OCR text results
└── office_text_output/        # Output: office document text (future)
```

## Command Interface

### Main Entry Point
**ALWAYS use the unified CLI interface:**
```bash
./textharvest.sh <command> [OPTIONS]
```

**NEVER directly call the individual process_*.sh scripts** - they are legacy interfaces maintained for the CLI.

### Available Commands

| Command | Purpose | Key Options |
|---------|---------|-------------|
| `code` | Generate source code listings | `--interactive`, `--dry-run`, `-i <dir>`, `-o <dir>` |
| `pdf-text` | Extract text from PDFs | `--parallel`, `--interactive`, `--max-jobs N` |
| `pdf-ocr` | OCR processing of PDFs | `-l <lang>`, `--force-ocr`, `--deskew`, `--clean` |
| `setup` | Install dependencies | `--dry-run`, `--list-packages`, `--force-platform` |
| `config` | Manage configuration | `--init`, `--show`, `--validate`, `--global` |
| `version` | Show version info | (no options) |
| `help` | Show help | (or use `<command> --help`) |

### Global Options (work with all commands)
- `-v, --verbose` - Verbose output (level 2)
- `-vv` - Very verbose/debug output (level 3)
- `-q, --quiet` - Quiet mode (level 0)
- `--dry-run` - Preview operations without executing
- `--help` - Show command-specific help

### Command Examples for Testing/Development
```bash
# Quick functionality tests
./textharvest.sh version                    # Check if CLI works
./textharvest.sh help                       # View main help
./textharvest.sh code --help               # Command-specific help

# Configuration management
./textharvest.sh config --show             # View current config
./textharvest.sh config --validate         # Check setup
./textharvest.sh config --init             # Create local config

# Safe testing with dry-run
./textharvest.sh code --dry-run -v         # Preview code processing
./textharvest.sh setup --dry-run           # Preview dependency install
./textharvest.sh pdf-text --dry-run --parallel  # Preview PDF processing

# Interactive modes (user-friendly)
./textharvest.sh code --interactive        # Select projects interactively
./textharvest.sh pdf-text --interactive    # Select PDFs interactively

# Production usage patterns
./textharvest.sh code -i my_projects -o listings  # Custom directories
./textharvest.sh pdf-text --parallel --max-jobs 8  # Parallel processing
./textharvest.sh pdf-ocr -l eng+fra+deu   # Multi-language OCR
```

## Configuration System

### Configuration Hierarchy (load order)
1. **`/etc/textharvest.conf`** - System-wide settings (lowest priority)
2. **`~/.textharvest.conf`** - User settings  
3. **`./textharvest.conf`** - Local project settings
4. **Environment Variables** - Runtime overrides (highest priority)

### Key Configuration Variables
```bash
# Directories
CODE_DIR="source_code"                    # Input source code directory
PDF_DIR="source_pdf"                      # Input PDF directory
CODE_OUTPUT_DIR="code_listings"           # Code listing output
PDF_TEXT_OUTPUT_DIR="text_output"         # PDF text output
PDF_OCR_OUTPUT_DIR="ocr_pdf_output"       # OCR PDF output
PDF_OCR_TEXT_OUTPUT_DIR="ocr_text_output" # OCR text output

# Processing settings
VERBOSE_LEVEL=1                           # 0=quiet, 1=normal, 2=verbose, 3=debug
MAX_JOBS=4                                # Parallel processing limit
MIN_DISK_SPACE_MB=100                     # Minimum free space required

# File processing
CODE_EXTENSIONS=".c .h .cpp .hpp .java .py .js .ts .html .css .sh .rb .go .rs .php .swift .kt .kts .scala"
SPECIFIC_FILENAMES="CMakeLists.txt Makefile package.json requirements.txt Cargo.toml pom.xml"

# OCR settings
OCR_LANG="eng"                            # Default OCR language
OCR_MODE="force-ocr"                      # OCR processing mode
OCRMYPDF_ARGS="--deskew --clean"          # OCR preprocessing options
```

### Environment Variable Overrides
Prefix any config variable with `TEXTHARVEST_` to override:
```bash
export TEXTHARVEST_CODE_DIR="/custom/source/path"
export TEXTHARVEST_VERBOSE_LEVEL=3
export TEXTHARVEST_MAX_JOBS=8
```

### Configuration Management Commands
```bash
./textharvest.sh config --init             # Create ./textharvest.conf
./textharvest.sh config --init --global    # Create ~/.textharvest.conf
./textharvest.sh config --show             # Display effective config
./textharvest.sh config --validate         # Check config and dependencies
```

## Architecture Deep Dive

### Core Components

#### 1. Main CLI (`textharvest.sh`)
- **Entry point** for all operations
- **Command routing** to appropriate processing scripts
- **Global argument parsing** (verbose, dry-run, etc.)
- **Configuration initialization** and validation
- **Help system** management

#### 2. Shared Library (`lib/common.sh`)
Essential functions used across all scripts:

**Error Handling:**
- `error_exit(message, exit_code)` - Fatal errors with cleanup
- `warn(message)` - Non-fatal warnings
- `info(message, level)` - Informational output with verbosity control
- `success(message)` - Success confirmations
- `debug(message)` - Debug output (level 3 only)

**Validation:**
- `validate_input_dir(dir, description)` - Check directory exists/readable
- `create_output_dir(dir, description)` - Create output directories
- `check_dependencies(cmd1, cmd2, ...)` - Verify required commands
- `check_disk_space(dir, min_mb)` - Ensure sufficient space

**Configuration:**
- `load_config(file)` - Load configuration file
- `get_config(var_name, default)` - Get config value with fallback
- `init_common()` - Initialize library (auto-called when sourced)

**Progress Tracking:**
- `init_progress(total, task_name)` - Initialize progress counter
- `update_progress(current, item_name)` - Update progress display
- `finish_progress()` - Complete progress tracking

**Parallel Processing:**
- `parallel_execute(commands...)` - Execute commands in parallel

**Cross-Platform Utilities:**
- `get_file_size(file)` - Get human-readable file size
- `detect_os()` - Platform detection
- Platform-specific file operations (stat, df, etc.)

#### 3. Processing Scripts
- **`process_code.sh`** - Source code listing generation
- **`process_pdf_text.sh`** - Direct PDF text extraction
- **`process_pdf_ocr.sh`** - OCR processing workflow

Each script:
- Sources `lib/common.sh` for shared functionality
- Implements command-line argument parsing
- Uses common error handling and progress tracking
- Supports dry-run mode and verbosity levels

#### 4. Setup System (`setup.sh`)
- **Cross-platform dependency installer**
- **Automatic OS/package manager detection**
- **Support for**: Linux (apt/yum/dnf), macOS (Homebrew)
- **Package verification** and version reporting

### Cross-Platform Support

#### Supported Platforms
- **Linux**: Ubuntu/Debian (apt), RHEL/CentOS/Fedora (yum/dnf)
- **macOS**: Homebrew package manager

#### Platform-Specific Handling
The codebase handles platform differences through:

1. **OS Detection** in `setup.sh`:
   ```bash
   if [[ "$OSTYPE" == "darwin"* ]]; then
       os_type="macos"
   elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
       os_type="linux"
   ```

2. **Command Variations** in `lib/common.sh`:
   ```bash
   # File size - cross-platform
   if [[ "$OSTYPE" == "darwin"* ]]; then
       stat -f%z "$file"  # macOS
   else
       stat -c%s "$file"  # Linux
   fi
   ```

3. **Package Manager Detection**:
   - Linux: `apt`, `yum`, `dnf`
   - macOS: `brew`

#### Dependencies by Platform

| Tool | Linux Package | macOS Package | Purpose |
|------|---------------|---------------|---------|
| pdftotext | poppler-utils | poppler | PDF text extraction |
| tesseract | tesseract-ocr | tesseract | OCR engine |
| ocrmypdf | pip install | ocrmypdf | PDF OCR processing |
| Language packs | tesseract-ocr-eng | tesseract-lang | OCR languages |

## Development Workflows

### Testing Changes
```bash
# Basic functionality test
./textharvest.sh version && echo "CLI working"

# Configuration test
./textharvest.sh config --validate

# Dry-run tests (safe)
./textharvest.sh code --dry-run -v
./textharvest.sh pdf-text --dry-run --parallel
./textharvest.sh setup --dry-run

# Cross-platform testing
./textharvest.sh setup --force-platform macos --list-packages
./textharvest.sh setup --force-platform linux --list-packages
```

### Common Debugging
```bash
# Debug mode (maximum verbosity)
./textharvest.sh code --dry-run -vv

# Check effective configuration
./textharvest.sh config --show

# Verify dependencies
./textharvest.sh config --validate

# Test specific components
bash lib/common.sh  # Test library loading
bash setup.sh --help  # Test setup script
```

### Adding New Features

When adding new functionality:

1. **Add shared functions** to `lib/common.sh` if reusable
2. **Use existing error handling** patterns (`error_exit`, `warn`, etc.)
3. **Support dry-run mode** with `if [[ "$DRY_RUN" == true ]]`
4. **Add verbosity control** using `info()` with appropriate levels
5. **Update configuration** in `textharvest.conf` if needed
6. **Add command help** following existing patterns
7. **Test cross-platform** compatibility

### Code Style Guidelines

- **Use shared library functions** instead of duplicating code
- **Follow existing error handling** patterns
- **Support all global options** (verbose, dry-run, etc.)
- **Use consistent variable naming** (`CODE_DIR`, `PDF_DIR`, etc.)
- **Add progress tracking** for long-running operations
- **Include help text** for new commands/options

## Troubleshooting Guide

### Common Issues and Solutions

1. **"Command not found" errors**:
   ```bash
   ./textharvest.sh config --validate  # Check dependencies
   ./textharvest.sh setup              # Install missing tools
   ```

2. **Permission errors**:
   ```bash
   chmod +x textharvest.sh             # Make executable
   sudo ./textharvest.sh setup         # Install with sudo if needed
   ```

3. **macOS PATH issues**:
   ```bash
   export PATH="/opt/homebrew/bin:$PATH"  # Apple Silicon
   export PATH="/usr/local/bin:$PATH"     # Intel Mac
   ```

4. **Configuration problems**:
   ```bash
   ./textharvest.sh config --show       # Check effective config
   ./textharvest.sh config --init       # Reset to defaults
   ```

### Testing Installation
```bash
# Verify all components work
./textharvest.sh version              # Test CLI
./textharvest.sh config --validate    # Test dependencies
./textharvest.sh setup --list-packages # Show what's installed
./textharvest.sh code --dry-run -v    # Test processing pipeline
```

## Future Development Notes

### Plugin Architecture
The codebase includes a foundation for plugins:
- `load_plugin(name)` function in `lib/common.sh`
- `PLUGIN_DIR` configuration variable
- Plugin discovery with `list_plugins()`

### Planned Enhancements
- Office document processing (`.docx`, `.xlsx`, `.pptx`)
- Additional OCR languages and preprocessing
- Web interface for batch processing
- Integration with cloud storage providers
- Enhanced parallel processing controls

### Backward Compatibility
v2.0.0 maintains compatibility with v1.x through:
- Individual `process_*.sh` scripts still functional
- Same input/output directory structure
- Equivalent command-line options where applicable
- Migration path via unified CLI

This ensures existing workflows continue to work while providing enhanced functionality through the new interface.

## License Information

TextHarvest is licensed under the MIT License, which means:

### For Users:
- ✅ **Free to use** for any purpose (personal, commercial, educational)
- ✅ **Free to modify** and customize for your needs
- ✅ **Free to distribute** original or modified versions
- ✅ **No restrictions** on usage or redistribution

### For Contributors:
- 📋 **Attribution required** - Keep the copyright notice in source files
- 🔧 **Add license headers** to new files following the existing pattern
- 📝 **Document changes** appropriately in commit messages
- 🤝 **Respect the license** when incorporating external code

### License Header Template:
```bash
#!/bin/bash

# [Script Name]
# [Brief description]
#
# Copyright (c) 2025 Matthew Deaves
# Licensed under the MIT License - see LICENSE file for details
```

The MIT License promotes maximum adoption and contribution while requiring minimal restrictions. This aligns perfectly with TextHarvest's goal of being a simple, effective tool that anyone can use and improve.