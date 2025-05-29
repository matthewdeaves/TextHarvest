#!/bin/bash

# TextHarvest Unified CLI v2.0.0
# Main interface for all TextHarvest processing tasks

# Load common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh" || { echo "Error: Cannot load common library"; exit 1; }

# Script-specific variables
SCRIPT_NAME="$(basename "$0")"

# Show main help
show_help() {
    cat << EOF
TextHarvest v$TEXTHARVEST_VERSION - Document and Code Processing Utilities

USAGE:
    $SCRIPT_NAME <command> [OPTIONS]

COMMANDS:
    code        Generate source code listings from project directories
    pdf-text    Extract text directly from text-based PDF files  
    pdf-ocr     OCR and extract text from scanned/image PDF files
    setup       Install required dependencies
    config      Manage configuration settings
    version     Show version information
    help        Show this help message

GLOBAL OPTIONS:
    -v, --verbose      Verbose output
    -vv                Very verbose output (debug)
    -q, --quiet        Quiet mode
    --dry-run         Show what would be processed without doing it
    --version         Show version information
    -h, --help        Show this help

EXAMPLES:
    $SCRIPT_NAME code --help              # Help for code processing
    $SCRIPT_NAME code --interactive       # Interactive project selection
    $SCRIPT_NAME pdf-text --parallel      # Parallel PDF text extraction
    $SCRIPT_NAME pdf-ocr -l eng+fra       # OCR with English and French
    $SCRIPT_NAME setup                    # Install dependencies
    $SCRIPT_NAME config --init            # Create default config file

CONFIGURATION:
    Configuration files are loaded in this order:
    1. /etc/textharvest.conf
    2. ~/.textharvest.conf  
    3. ./textharvest.conf
    
    Environment variables override config files:
    TEXTHARVEST_CODE_DIR, TEXTHARVEST_PDF_DIR, etc.

For command-specific help, use: $SCRIPT_NAME <command> --help

EOF
}

# Show config management help
show_config_help() {
    cat << EOF
TextHarvest Configuration Management

USAGE:
    $SCRIPT_NAME config <action> [OPTIONS]

ACTIONS:
    --init              Create default configuration file
    --show              Show current configuration
    --validate          Validate configuration settings
    --reset             Reset to default configuration

OPTIONS:
    --global            Use global config file (~/.textharvest.conf)
    --local             Use local config file (./textharvest.conf)
    --system            Use system config file (/etc/textharvest.conf)

EXAMPLES:
    $SCRIPT_NAME config --init             # Create local config
    $SCRIPT_NAME config --init --global    # Create global config
    $SCRIPT_NAME config --show             # Show current settings
    $SCRIPT_NAME config --validate         # Check configuration

EOF
}

# Config management functions
config_init() {
    local config_file="./textharvest.conf"
    
    if [[ "$1" == "--global" ]]; then
        config_file="$HOME/.textharvest.conf"
    elif [[ "$1" == "--system" ]]; then
        config_file="/etc/textharvest.conf"
    fi
    
    if [[ -f "$config_file" ]]; then
        read -r -p "Configuration file '$config_file' exists. Overwrite? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            info "Configuration unchanged"
            return 0
        fi
    fi
    
    # Copy template config
    if cp "$SCRIPT_DIR/textharvest.conf" "$config_file"; then
        success "Configuration file created at '$config_file'"
        info "Edit this file to customize your settings"
    else
        error_exit "Failed to create configuration file '$config_file'"
    fi
}

config_show() {
    info "Current TextHarvest Configuration:"
    echo ""
    echo "Loaded configuration files:"
    
    local config_files=(
        "/etc/textharvest.conf"
        "$HOME/.textharvest.conf"
        "./textharvest.conf"
    )
    
    for config_file in "${config_files[@]}"; do
        if [[ -f "$config_file" ]]; then
            echo "  ✓ $config_file"
        else
            echo "  ✗ $config_file (not found)"
        fi
    done
    
    echo ""
    echo "Effective settings:"
    echo "  CODE_DIR = $(get_config 'CODE_DIR' 'source_code')"
    echo "  PDF_DIR = $(get_config 'PDF_DIR' 'source_pdf')"
    echo "  CODE_OUTPUT_DIR = $(get_config 'CODE_OUTPUT_DIR' 'code_listings')"
    echo "  PDF_TEXT_OUTPUT_DIR = $(get_config 'PDF_TEXT_OUTPUT_DIR' 'text_output')"
    echo "  PDF_OCR_OUTPUT_DIR = $(get_config 'PDF_OCR_OUTPUT_DIR' 'ocr_pdf_output')"
    echo "  PDF_OCR_TEXT_OUTPUT_DIR = $(get_config 'PDF_OCR_TEXT_OUTPUT_DIR' 'ocr_text_output')"
    echo "  VERBOSE_LEVEL = $(get_config 'VERBOSE_LEVEL' '1')"
    echo "  MAX_JOBS = $(get_config 'MAX_JOBS' '4')"
    echo "  OCR_LANG = $(get_config 'OCR_LANG' 'eng')"
}

config_validate() {
    local errors=0
    
    info "Validating TextHarvest configuration..."
    
    # Check directories
    local dirs=(
        "$(get_config 'CODE_DIR' 'source_code')"
        "$(get_config 'PDF_DIR' 'source_pdf')"
    )
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            warn "Directory '$dir' does not exist"
            ((errors++))
        elif [[ ! -r "$dir" ]]; then
            warn "Directory '$dir' is not readable"
            ((errors++))
        fi
    done
    
    # Check dependencies
    local deps=("pdftotext" "ocrmypdf" "tesseract")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            warn "Command '$dep' not found. Run 'textharvest setup' to install dependencies."
            ((errors++))
        fi
    done
    
    if (( errors == 0 )); then
        success "Configuration validation passed"
    else
        warn "Configuration validation found $errors issue(s)"
        return 1
    fi
}

# Setup function
run_setup() {
    info "Running TextHarvest setup..."
    
    if [[ -f "$SCRIPT_DIR/setup.sh" ]]; then
        bash "$SCRIPT_DIR/setup.sh" "$@"
    else
        error_exit "Setup script not found at '$SCRIPT_DIR/setup.sh'"
    fi
}

# Parse global arguments
parse_global_args() {
    local args=()
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                VERBOSE_LEVEL=2
                shift
                ;;
            -vv|--very-verbose)
                VERBOSE_LEVEL=3
                shift
                ;;
            -q|--quiet)
                VERBOSE_LEVEL=0
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --version|version)
                show_version
                exit 0
                ;;
            -h|--help|help)
                show_help
                exit 0
                ;;
            *)
                # Collect remaining args
                args+=("$1")
                shift
                ;;
        esac
    done
    
    # Return remaining arguments  
    if (( ${#args[@]} > 0 )); then
        printf '%s\n' "${args[@]}"
    fi
}

# Main execution
main() {
    # Handle help and version first
    case "${1:-}" in
        help|-h|--help)
            show_help
            exit 0
            ;;
        version|--version)
            show_version
            exit 0
            ;;
    esac
    
    # Parse global arguments
    local -a args=("$@")
    while [[ ${#args[@]} -gt 0 ]]; do
        case "${args[0]}" in
            -v|--verbose)
                VERBOSE_LEVEL=2
                args=("${args[@]:1}")
                ;;
            -vv|--very-verbose)
                VERBOSE_LEVEL=3
                args=("${args[@]:1}")
                ;;
            -q|--quiet)
                VERBOSE_LEVEL=0
                args=("${args[@]:1}")
                ;;
            --dry-run)
                DRY_RUN=true
                args=("${args[@]:1}")
                ;;
            *)
                break
                ;;
        esac
    done
    
    # Check if we have a command
    if [[ ${#args[@]} -eq 0 ]]; then
        show_help
        exit 1
    fi
    
    local command="${args[0]}"
    set -- "${args[@]:1}"
    
    # Execute command
    case "$command" in
        code)
            exec bash "$SCRIPT_DIR/process_code.sh" "$@"
            ;;
        pdf-text)
            exec bash "$SCRIPT_DIR/process_pdf_text.sh" "$@"
            ;;
        pdf-ocr)
            exec bash "$SCRIPT_DIR/process_pdf_ocr.sh" "$@"
            ;;
        setup)
            run_setup "$@"
            ;;
        config)
            if [[ $# -eq 0 ]]; then
                show_config_help
                exit 1
            fi
            
            case "$1" in
                --init)
                    shift
                    config_init "$@"
                    ;;
                --show)
                    config_show
                    ;;
                --validate)
                    config_validate
                    ;;
                --reset)
                    warn "Reset functionality not implemented yet"
                    ;;
                --help|-h)
                    show_config_help
                    ;;
                *)
                    error_exit "Unknown config action: $1. Use 'config --help' for usage."
                    ;;
            esac
            ;;
        version)
            show_version
            ;;
        help)
            show_help
            ;;
        *)
            error_exit "Unknown command: $command. Use '$SCRIPT_NAME help' for usage information."
            ;;
    esac
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi