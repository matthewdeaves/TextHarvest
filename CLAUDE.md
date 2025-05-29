# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TextHarvest v2.0.0 is a modernized collection of Bash shell scripts for automated document and source code processing on Linux systems. The project has been refactored with:

1. **Unified CLI Interface** - Single entry point (`textharvest.sh`) for all operations
2. **Shared Library Architecture** - Common functions in `lib/common.sh`
3. **Configuration Management** - Centralized settings in `textharvest.conf`
4. **Enhanced Error Handling** - Consistent error reporting and validation
5. **Interactive Modes** - User-friendly selection interfaces
6. **Parallel Processing** - Multi-threaded operations for better performance

## Main Commands

### Unified CLI Usage
```bash
./textharvest.sh <command> [OPTIONS]
```

**Primary Commands:**
- `code` - Generate source code listings from project directories
- `pdf-text` - Extract text directly from text-based PDF files
- `pdf-ocr` - OCR and extract text from scanned/image PDFs
- `setup` - Install required dependencies
- `config` - Manage configuration settings

**Global Options:**
- `-v, --verbose` - Verbose output
- `-vv` - Very verbose (debug) output
- `-q, --quiet` - Quiet mode
- `--dry-run` - Preview operations without executing
- `--help` - Show help for any command

### Examples
```bash
# Get help for any command
./textharvest.sh code --help
./textharvest.sh pdf-ocr --help

# Interactive project/file selection
./textharvest.sh code --interactive
./textharvest.sh pdf-text --interactive

# Dry run to preview operations
./textharvest.sh code --dry-run --verbose

# Parallel processing
./textharvest.sh pdf-text --parallel

# Custom directories
./textharvest.sh code -i custom_source -o custom_output
```

## Configuration System

### Configuration Files (loaded in order):
1. `/etc/textharvest.conf` - System-wide settings
2. `~/.textharvest.conf` - User settings
3. `./textharvest.conf` - Local project settings

### Environment Variables (highest priority):
- `TEXTHARVEST_CODE_DIR` - Source code input directory
- `TEXTHARVEST_PDF_DIR` - PDF input directory
- `TEXTHARVEST_VERBOSE_LEVEL` - Default verbosity (0-3)
- `TEXTHARVEST_MAX_JOBS` - Parallel processing jobs

### Configuration Management:
```bash
./textharvest.sh config --init           # Create local config
./textharvest.sh config --init --global  # Create user config
./textharvest.sh config --show          # Show current settings
./textharvest.sh config --validate      # Verify configuration
```

## Directory Structure

**Input directories:**
- `source_code/` - Project subdirectories with source files
- `source_pdf/` - PDF files to process

**Output directories (auto-created):**
- `code_listings/` - Source code listings
- `text_output/` - PDF text extraction results
- `ocr_pdf_output/` - Intermediate OCR'd PDFs  
- `ocr_text_output/` - OCR text extraction results

**Project structure:**
- `lib/common.sh` - Shared utility functions
- `textharvest.conf` - Default configuration template
- `textharvest.sh` - Main CLI interface
- `process_*.sh` - Individual processing scripts

## Architecture Notes

### Shared Library Functions (`lib/common.sh`):
- **Error Handling**: `error_exit()`, `warn()`, `info()`, `success()`
- **Validation**: `validate_input_dir()`, `check_dependencies()`, `check_disk_space()`
- **Progress Tracking**: `init_progress()`, `update_progress()`, `finish_progress()`
- **Configuration**: `get_config()`, `load_config()`
- **Parallel Processing**: `parallel_execute()`

### Key Improvements:
- Modular function-based architecture
- Consistent error handling and user feedback
- Configuration file hierarchy with environment variable overrides
- Interactive modes for file/project selection
- Dry-run capability for safe previewing
- Multi-level verbosity control
- Parallel processing support
- Plugin architecture foundation

### Development Commands:
```bash
# Test basic functionality
./textharvest.sh version
./textharvest.sh help

# Validate setup
./textharvest.sh config --validate

# Test with dry run
./textharvest.sh code --dry-run -v
```

The project maintains backward compatibility while providing enhanced functionality through the new unified interface.

## Cross-Platform Support

TextHarvest v2.0.0 works on both Linux and macOS:

### Supported Platforms:
- **Linux**: Ubuntu/Debian (apt), RHEL/CentOS/Fedora (yum/dnf)
- **macOS**: Homebrew package manager

### Platform Detection:
The setup script automatically detects the operating system and package manager:
```bash
./textharvest.sh setup --list-packages  # Show what would be installed
./textharvest.sh setup --dry-run        # Preview installation
```

### macOS-Specific Notes:
- Requires Homebrew package manager
- Uses different stat command syntax (`stat -f%z` vs `stat -c%s`)
- Homebrew installs binaries to `/opt/homebrew/bin` (Apple Silicon) or `/usr/local/bin` (Intel)
- All core functionality works identically to Linux

### Development Testing:
```bash
# Test platform detection
./textharvest.sh setup --force-platform macos --list-packages

# Cross-platform file operations
./textharvest.sh code --dry-run -v       # Works on both platforms
```