# 🌾 TextHarvest v2.0.0

**Document and Code Processing Utilities for Linux and macOS**

TextHarvest is a powerful, modernized collection of Bash shell scripts designed for automated document and source code processing. Version 2.0.0 introduces a unified CLI interface, cross-platform support, and enhanced functionality while maintaining the simplicity and effectiveness of the original design.

## ✨ Features

- **📁 Source Code Processing** - Generate consolidated listings from project directories
- **📄 PDF Text Extraction** - Extract text directly from text-based PDF files
- **🔍 OCR Processing** - Perform optical character recognition on scanned/image PDFs
- **🖥️ Cross-Platform** - Works on Linux (Ubuntu/Debian, RHEL/CentOS/Fedora) and macOS
- **⚡ Parallel Processing** - Multi-threaded operations for improved performance
- **🎛️ Interactive Mode** - User-friendly file and project selection
- **⚙️ Configuration Management** - Hierarchical config system with environment overrides
- **🧪 Dry Run Mode** - Preview operations before execution

## 🚀 Quick Start

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/user/textharvest.git
   cd textharvest
   ```

2. **Make the main script executable:**
   ```bash
   chmod +x textharvest.sh
   ```

3. **Install dependencies:**
   ```bash
   ./textharvest.sh setup
   ```

### First Use

1. **Create input directories:**
   ```bash
   mkdir source_code source_pdf
   ```

2. **Add your files:**
   - Place project folders in `source_code/`
   - Place PDF files in `source_pdf/`

3. **Process your files:**
   ```bash
   ./textharvest.sh code --interactive     # Process source code
   ./textharvest.sh pdf-text --parallel    # Extract PDF text
   ./textharvest.sh pdf-ocr -l eng+fra     # OCR with multiple languages
   ```

## 📋 Command Reference

### Main Commands

| Command | Description |
|---------|-------------|
| `code` | Generate source code listings from project directories |
| `pdf-text` | Extract text directly from text-based PDF files |
| `pdf-ocr` | OCR and extract text from scanned/image PDF files |
| `setup` | Install required dependencies |
| `config` | Manage configuration settings |
| `version` | Show version information |
| `help` | Show help information |

### Global Options

| Option | Description |
|--------|-------------|
| `-v, --verbose` | Verbose output |
| `-vv` | Very verbose output (debug) |
| `-q, --quiet` | Quiet mode |
| `--dry-run` | Preview operations without executing |
| `--help` | Show help for any command |

### Usage Examples

```bash
# Get help for specific commands
./textharvest.sh code --help
./textharvest.sh pdf-ocr --help

# Interactive project selection
./textharvest.sh code --interactive

# Parallel processing with custom directories
./textharvest.sh pdf-text --parallel -i my_pdfs -o text_results

# OCR with multiple languages
./textharvest.sh pdf-ocr -l eng+fra+deu --force-ocr

# Dry run to preview operations
./textharvest.sh code --dry-run --verbose

# Custom configuration
./textharvest.sh config --init
./textharvest.sh config --show
```

## 📂 Directory Structure

### Input Directories
- **`source_code/`** - Project subdirectories containing source files
- **`source_pdf/`** - PDF files for text extraction or OCR processing

### Output Directories (auto-created)
- **`code_listings/`** - Generated source code listings
- **`text_output/`** - PDF text extraction results
- **`ocr_pdf_output/`** - Intermediate OCR-processed PDFs
- **`ocr_text_output/`** - Final OCR text extraction results

### Project Files
```
TextHarvest/
├── textharvest.sh          # Main CLI interface
├── textharvest.conf        # Configuration template
├── setup.sh               # Cross-platform installer
├── lib/
│   └── common.sh          # Shared utility functions
├── process_code.sh        # Source code processing
├── process_pdf_text.sh    # PDF text extraction
├── process_pdf_ocr.sh     # OCR processing
└── README.md              # This file
```

## ⚙️ Configuration

### Configuration Hierarchy

Configuration files are loaded in this order (later files override earlier ones):

1. **`/etc/textharvest.conf`** - System-wide settings
2. **`~/.textharvest.conf`** - User settings  
3. **`./textharvest.conf`** - Local project settings

### Environment Variables (highest priority)

| Variable | Description | Default |
|----------|-------------|---------|
| `TEXTHARVEST_CODE_DIR` | Source code input directory | `source_code` |
| `TEXTHARVEST_PDF_DIR` | PDF input directory | `source_pdf` |
| `TEXTHARVEST_VERBOSE_LEVEL` | Default verbosity (0-3) | `1` |
| `TEXTHARVEST_MAX_JOBS` | Parallel processing jobs | `4` |

### Configuration Management

```bash
# Create configuration files
./textharvest.sh config --init              # Create local config
./textharvest.sh config --init --global     # Create user config

# View and validate settings
./textharvest.sh config --show              # Show current settings
./textharvest.sh config --validate          # Verify configuration
```

## 🖥️ Cross-Platform Support

### Supported Platforms

| Platform | Package Managers | Status |
|----------|------------------|--------|
| **Linux** | `apt` (Ubuntu/Debian)<br>`yum`/`dnf` (RHEL/CentOS/Fedora) | ✅ Full support |
| **macOS** | `brew` (Homebrew) | ✅ Full support |

### macOS Installation

1. **Install Homebrew** (if not already installed):
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **Add Homebrew to PATH**:
   ```bash
   # For Apple Silicon Macs:
   export PATH="/opt/homebrew/bin:$PATH"
   
   # For Intel Macs:
   export PATH="/usr/local/bin:$PATH"
   ```

3. **Run TextHarvest setup**:
   ```bash
   ./textharvest.sh setup
   ```

### Platform-Specific Features

- **Automatic OS detection** and package manager selection
- **Cross-platform file operations** with proper path handling
- **Native dependency installation** for each platform
- **Consistent CLI behavior** across all supported systems

## 🔧 Dependencies

TextHarvest automatically installs these dependencies via your system's package manager:

| Tool | Purpose | Linux Package | macOS Package |
|------|---------|---------------|---------------|
| **poppler** | PDF text extraction | `poppler-utils` | `poppler` |
| **tesseract** | OCR engine | `tesseract-ocr` | `tesseract` |
| **ocrmypdf** | PDF OCR processing | `pip install ocrmypdf` | `ocrmypdf` |
| **Language packs** | OCR languages | `tesseract-ocr-eng` | `tesseract-lang` |

### Manual Installation

If you prefer to install dependencies manually:

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install poppler-utils tesseract-ocr tesseract-ocr-eng python3-pip
pip3 install --user ocrmypdf
```

**Linux (RHEL/CentOS/Fedora):**
```bash
sudo dnf install poppler-utils tesseract tesseract-langpack-eng python3-pip
pip3 install --user ocrmypdf
```

**macOS (Homebrew):**
```bash
brew install poppler tesseract tesseract-lang ocrmypdf
```

## 🎯 Use Cases

### Source Code Documentation
- **Project archival** - Create comprehensive text-based documentation
- **Code review preparation** - Generate consolidated listings for review
- **Documentation generation** - Extract code for technical documentation
- **Analysis and auditing** - Prepare code for external analysis tools

### Document Processing
- **Research workflows** - Extract text from academic papers and reports
- **Data extraction** - Convert PDFs to searchable text for analysis
- **Archive digitization** - OCR scanned documents and legacy files
- **Content migration** - Extract text for content management systems

### Batch Processing
- **Automated workflows** - Process hundreds of files efficiently
- **CI/CD integration** - Generate documentation as part of build processes
- **Content indexing** - Prepare documents for search engines
- **Format conversion** - Convert document collections to text format

## 🔍 Advanced Features

### Interactive Mode
```bash
./textharvest.sh code --interactive
```
- Browse and select specific projects or files
- Preview operations before execution
- Step-by-step processing with user confirmation

### Parallel Processing
```bash
./textharvest.sh pdf-text --parallel --max-jobs 8
```
- Multi-threaded processing for large file collections
- Configurable job limits for system optimization
- Progress tracking and ETA calculations

### OCR Customization
```bash
./textharvest.sh pdf-ocr -l eng+fra+deu --deskew --clean
```
- Multiple language support
- Image preprocessing options
- Customizable OCR parameters

### Dry Run Mode
```bash
./textharvest.sh code --dry-run --verbose
```
- Preview operations without making changes
- Validate input files and directories
- Test configuration and command syntax

## 🏗️ Architecture

### Modular Design

TextHarvest v2.0.0 features a modern, modular architecture:

- **Unified CLI Interface** - Single entry point (`textharvest.sh`) for all operations
- **Shared Library** - Common functions in `lib/common.sh` for consistency
- **Configuration System** - Hierarchical config with environment variable overrides
- **Error Handling** - Comprehensive error checking and user feedback
- **Progress Tracking** - Real-time progress indicators and timing information

### Key Improvements from v1.x

- ✅ **Single command interface** replaces multiple scripts
- ✅ **Cross-platform support** for Linux and macOS
- ✅ **Interactive modes** for better user experience
- ✅ **Configuration management** system
- ✅ **Parallel processing** capabilities
- ✅ **Dry run mode** for safe operation testing
- ✅ **Enhanced error handling** and logging
- ✅ **Plugin architecture** foundation for extensibility

## 🤝 Contributing

TextHarvest is designed to be simple, reliable, and extensible. Contributions are welcome for:

- Additional file format support
- Platform compatibility improvements
- Performance optimizations
- Documentation enhancements
- Bug fixes and feature requests

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**MIT License Summary:**
- ✅ Commercial use allowed
- ✅ Modification and distribution permitted  
- ✅ Private use encouraged
- ✅ No warranty or liability
- 📋 Attribution required (keep copyright notice)

## 🔗 Links

- **GitHub Repository**: [https://github.com/matthewdeaves/textharvest](https://github.com/matthewdeaves/textharvest)
- **Issue Tracker**: Report bugs and request features
- **Documentation**: Additional guides and examples

---

**TextHarvest v2.0.0** - Efficient document and code processing for the modern developer.