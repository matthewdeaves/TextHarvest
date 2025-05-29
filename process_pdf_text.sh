#!/bin/bash

# TextHarvest PDF Text Extractor v2.0.0
# Extracts text directly from text-based PDF files

# Load common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh" || { echo "Error: Cannot load common library"; exit 1; }

# Script-specific variables
SCRIPT_NAME="$(basename "$0")"
TEMP_FILES=()

# Show help
show_help() {
    cat << EOF
TextHarvest PDF Text Extractor v$TEXTHARVEST_VERSION

USAGE:
    $SCRIPT_NAME [OPTIONS]

DESCRIPTION:
    Extracts text content directly from PDF files that contain selectable text.
    Uses pdftotext to extract text from all PDFs in the input directory.

OPTIONS:
    -i, --input DIR     Input directory containing PDF files (default: source_pdf)
    -o, --output DIR    Output directory for text files (default: text_output)
    --interactive       Interactive PDF selection mode
    --parallel          Enable parallel processing
    --dry-run          Show what would be processed without doing it
    -v, --verbose      Verbose output
    -vv                Very verbose output (debug)
    -q, --quiet        Quiet mode
    --version          Show version information
    -h, --help         Show this help

EXAMPLES:
    $SCRIPT_NAME                           # Process all PDFs
    $SCRIPT_NAME --interactive             # Select PDFs interactively
    $SCRIPT_NAME -i custom_pdf -o output   # Custom directories
    $SCRIPT_NAME --dry-run                 # Preview what would be processed
    $SCRIPT_NAME --parallel               # Use parallel processing

DEPENDENCIES:
    - pdftotext (from poppler-utils package)

CONFIGURATION:
    Settings can be configured in textharvest.conf or via environment variables.
    Environment variables: TEXTHARVEST_PDF_DIR, TEXTHARVEST_PDF_TEXT_OUTPUT_DIR, etc.

EOF
}

# Parse arguments
parse_args() {
    local remaining_args
    remaining_args=$(parse_common_args "$@")
    
    if [[ $? -eq 1 ]]; then
        show_help
        exit 0
    fi
    
    eval set -- "$remaining_args"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--input)
                PDF_DIR="$2"
                shift 2
                ;;
            -o|--output)
                TXT_DIR="$2"
                shift 2
                ;;
            --interactive)
                INTERACTIVE_MODE=true
                shift
                ;;
            --parallel)
                ENABLE_PARALLEL=true
                shift
                ;;
            *)
                error_exit "Unknown option: $1. Use --help for usage information."
                ;;
        esac
    done
}

# Load configuration with fallbacks
load_configuration() {
    PDF_DIR=$(get_config "PDF_DIR" "source_pdf")
    TXT_DIR=$(get_config "PDF_TEXT_OUTPUT_DIR" "text_output")
    INTERACTIVE_MODE=$(get_config "INTERACTIVE_MODE" "false")
    ENABLE_PARALLEL=$(get_config "ENABLE_PARALLEL" "false")
}

# Initialize script
init_script() {
    debug "Starting $SCRIPT_NAME v$TEXTHARVEST_VERSION"
    
    # Load configuration
    load_configuration
    
    # Check dependencies
    check_dependencies "pdftotext"
    
    # Validate input directory
    validate_input_dir "$PDF_DIR" "PDF input directory"
    
    # Create output directory
    create_output_dir "$TXT_DIR" "Text output directory"
    
    # Check disk space
    check_disk_space "$TXT_DIR" "$(get_config 'MIN_DISK_SPACE_MB' '100')"
    
    info "Input directory: '$PDF_DIR'" 2
    info "Output directory: '$TXT_DIR'" 2
}

# Interactive PDF selection
select_pdfs_interactive() {
    local -a all_pdfs=()
    local -a selected_pdfs=()
    
    # Find all PDF files
    shopt -s nullglob
    all_pdfs=("$PDF_DIR"/*.pdf)
    shopt -u nullglob
    
    if (( ${#all_pdfs[@]} == 0 )); then
        error_exit "No PDF files found in '$PDF_DIR'"
    fi
    
    while true; do
        echo ""
        info "Available PDFs in '$PDF_DIR':"
        for i in "${!all_pdfs[@]}"; do
            printf "  %2d) %s\n" "$((i + 1))" "$(basename "${all_pdfs[$i]}")"
        done
        
        echo ""
        echo "Options:"
        echo "  a) Process ALL PDFs"
        echo "  1,2,3) Select specific PDFs (comma-separated)"
        echo "  q) Quit"
        
        read -r -p "Enter your choice: " choice
        
        case "$choice" in
            [Qq]*)
                info "Exiting at user request"
                exit 0
                ;;
            [Aa]*)
                selected_pdfs=("${all_pdfs[@]}")
                break
                ;;
            *)
                # Parse comma-separated numbers
                IFS=',' read -r -a indices <<< "$choice"
                selected_pdfs=()
                local valid=true
                
                for idx_str in "${indices[@]}"; do
                    idx_str=$(echo "$idx_str" | xargs) # Trim whitespace
                    if [[ "$idx_str" =~ ^[1-9][0-9]*$ ]]; then
                        local idx=$((idx_str - 1))
                        if (( idx >= 0 && idx < ${#all_pdfs[@]} )); then
                            selected_pdfs+=("${all_pdfs[$idx]}")
                        else
                            warn "Invalid PDF number: $idx_str"
                            valid=false
                        fi
                    else
                        warn "Invalid input: $idx_str"
                        valid=false
                    fi
                done
                
                if [[ "$valid" == true ]] && (( ${#selected_pdfs[@]} > 0 )); then
                    break
                fi
                ;;
        esac
    done
    
    printf '%s\n' "${selected_pdfs[@]}"
}

# Discover PDFs to process
discover_pdfs() {
    if [[ "$INTERACTIVE_MODE" == "true" ]]; then
        mapfile -t pdfs_to_process < <(select_pdfs_interactive)
    else
        # Process all PDFs
        shopt -s nullglob
        pdfs_to_process=("$PDF_DIR"/*.pdf)
        shopt -u nullglob
    fi
    
    if (( ${#pdfs_to_process[@]} == 0 )); then
        info "No PDFs to process"
        exit 0
    fi
    
    info "Will process ${#pdfs_to_process[@]} PDF(s)" 2
}

# Process a single PDF
process_pdf() {
    local pdf_file="$1"
    local base_name
    base_name=$(basename "$pdf_file" .pdf)
    local txt_file="$TXT_DIR/${base_name}.txt"
    
    debug "Processing PDF: $(basename "$pdf_file")"
    
    if [[ "$DRY_RUN" == true ]]; then
        info "DRY RUN: Would extract text from '$pdf_file' -> '$txt_file'" 2
        return 0
    fi
    
    # Extract text using pdftotext
    if pdftotext "$pdf_file" "$txt_file" 2>/dev/null; then
        local file_size
        file_size=$(get_file_size "$txt_file")
        success "Extracted text from '$(basename "$pdf_file")' -> '$txt_file' ($file_size)"
        return 0
    else
        warn "Failed to extract text from '$(basename "$pdf_file")'"
        return 1
    fi
}

# Process single PDF (for parallel execution)
process_pdf_parallel() {
    local pdf_file="$1"
    process_pdf "$pdf_file"
}

# Main processing function
main_processing() {
    local -a pdfs_to_process=()
    
    discover_pdfs
    
    local processed=0
    local failed=0
    
    if [[ "$ENABLE_PARALLEL" == "true" ]]; then
        info "Processing ${#pdfs_to_process[@]} PDFs in parallel" 2
        
        local -a commands=()
        for pdf in "${pdfs_to_process[@]}"; do
            commands+=("process_pdf_parallel \"$pdf\"")
        done
        
        parallel_execute "${commands[@]}"
        
        # Count results (simplified for parallel execution)
        processed=${#pdfs_to_process[@]}
    else
        init_progress "${#pdfs_to_process[@]}" "Extracting text from PDFs"
        
        for pdf in "${pdfs_to_process[@]}"; do
            if process_pdf "$pdf"; then
                ((processed++))
            else
                ((failed++))
            fi
            update_progress
        done
        
        echo "" # New line after progress
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        info "DRY RUN completed: Would have processed $processed PDFs"
    else
        success "Text extraction completed: $processed PDFs processed, $failed failed"
        if (( failed > 0 )); then
            warn "$failed PDFs had issues (see output above)"
        fi
    fi
}

# Main execution
main() {
    # Parse command line arguments
    parse_args "$@"
    
    # Initialize script (loads config, validates directories, etc.)
    init_script
    
    # Run main processing
    main_processing
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi