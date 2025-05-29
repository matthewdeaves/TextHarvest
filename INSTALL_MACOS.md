# TextHarvest macOS Installation Guide

This guide covers installing TextHarvest on macOS using Homebrew.

## Prerequisites

### 1. Install Homebrew

If you don't have Homebrew installed:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. Add Homebrew to PATH

After installation, add Homebrew to your PATH. The installer will show you the exact commands, but typically:

**For Apple Silicon Macs (M1/M2/M3):**
```bash
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

**For Intel Macs:**
```bash
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### 3. Verify Homebrew Installation

```bash
brew --version
which brew
```

## Installing TextHarvest Dependencies

### Automatic Installation (Recommended)

```bash
# Navigate to TextHarvest directory
cd /path/to/TextHarvest

# Make scripts executable
chmod +x textharvest.sh setup.sh

# Install dependencies automatically
./textharvest.sh setup
```

### Preview Installation

To see what would be installed without actually installing:

```bash
./textharvest.sh setup --dry-run
./textharvest.sh setup --list-packages
```

### Manual Installation

If you prefer to install dependencies manually:

```bash
brew install poppler tesseract tesseract-lang ocrmypdf
```

## Verification

Verify that all required tools are installed:

```bash
# Check tool availability
which pdftotext
which tesseract  
which ocrmypdf

# Check versions
pdftotext -v
tesseract --version
ocrmypdf --version

# Or use TextHarvest's built-in validation
./textharvest.sh config --validate
```

## Usage

Once installed, TextHarvest works identically on macOS and Linux:

```bash
# Get help
./textharvest.sh help

# Process source code
./textharvest.sh code --interactive

# Process PDFs
./textharvest.sh pdf-text --parallel
./textharvest.sh pdf-ocr -l eng --interactive

# Configure settings
./textharvest.sh config --init
./textharvest.sh config --show
```

## Troubleshooting

### Homebrew Not Found

If you get "Homebrew not found" errors:

1. Verify Homebrew is installed: `which brew`
2. Check your PATH includes Homebrew: `echo $PATH`
3. Restart your terminal or run `source ~/.zshrc`

### Permission Errors

If you encounter permission errors:

```bash
# Fix Homebrew permissions
sudo chown -R $(whoami) /opt/homebrew  # Apple Silicon
sudo chown -R $(whoami) /usr/local     # Intel
```

### Command Not Found

If tools aren't found after installation:

1. Verify installation: `brew list | grep -E "(poppler|tesseract|ocrmypdf)"`
2. Check PATH: `echo $PATH | grep -E "(homebrew|local)"`
3. Reinstall if needed: `brew reinstall poppler tesseract ocrmypdf`

### OCR Language Packs

To install additional language packs for OCR:

```bash
# List available languages
brew search tesseract-lang

# Example: Install French language pack
brew install tesseract-lang  # Includes many languages
```

## Platform Differences

TextHarvest automatically handles platform differences:

- **File size calculation**: Uses `stat -f%z` on macOS vs `stat -c%s` on Linux
- **Disk space checking**: Handles different `df` output formats
- **Package management**: Uses `brew` instead of `apt`/`yum`
- **Path handling**: Works with Homebrew's bin directories

All functionality remains identical between platforms.