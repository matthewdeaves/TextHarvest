#!/bin/bash

# TextHarvest Code Processor v2.0.0
# Generates combined source code listings from project directories

# Load common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh" || { echo "Error: Cannot load common library"; exit 1; }

# Script-specific variables
SCRIPT_NAME="$(basename "$0")"
TEMP_FILES=()

# Show help
show_help() {
    cat << EOF
TextHarvest Code Processor v$TEXTHARVEST_VERSION

USAGE:
    $SCRIPT_NAME [OPTIONS]

DESCRIPTION:
    Generates combined source code listings from project directories.
    Recursively scans each project in the source directory and creates
    a single text file containing all source files.

OPTIONS:
    -i, --input DIR     Input directory containing projects (default: source_code)
    -o, --output DIR    Output directory for listings (default: code_listings)
    -e, --extensions    Comma-separated list of file extensions
    -f, --files         Comma-separated list of specific filenames to include
    --interactive       Interactive project selection mode
    --dry-run          Show what would be processed without doing it
    -v, --verbose      Verbose output
    -vv                Very verbose output (debug)
    -q, --quiet        Quiet mode
    --version          Show version information
    -h, --help         Show this help

EXAMPLES:
    $SCRIPT_NAME                           # Process all projects
    $SCRIPT_NAME --interactive             # Select projects interactively
    $SCRIPT_NAME -i custom_src -o output   # Custom directories
    $SCRIPT_NAME --dry-run                 # Preview what would be processed
    $SCRIPT_NAME -e ".c,.h,.cpp"            # Only C/C++ files

CONFIGURATION:
    Settings can be configured in textharvest.conf or via environment variables.
    Environment variables: TEXTHARVEST_CODE_DIR, TEXTHARVEST_CODE_OUTPUT_DIR, etc.

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
                CODE_DIR="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            -e|--extensions)
                IFS=',' read -r -a CODE_EXTENSIONS <<< "$2"
                shift 2
                ;;
            -f|--files)
                IFS=',' read -r -a SPECIFIC_FILENAMES <<< "$2"
                shift 2
                ;;
            --interactive)
                INTERACTIVE_MODE=true
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
    CODE_DIR=$(get_config "CODE_DIR" "source_code")
    OUTPUT_DIR=$(get_config "CODE_OUTPUT_DIR" "code_listings")
    OUTPUT_SUFFIX=$(get_config "CODE_OUTPUT_SUFFIX" "_listing.txt")
    
    # Parse extensions from config
    local ext_string
    ext_string=$(get_config "CODE_EXTENSIONS" ".c .h .cpp .hpp .java .py .js .ts .html .css .sh .rb .go .rs .php .swift .kt .kts .scala")
    IFS=' ' read -r -a CODE_EXTENSIONS <<< "$ext_string"
    
    # Parse specific filenames from config
    local files_string
    files_string=$(get_config "SPECIFIC_FILENAMES" "CMakeLists.txt Makefile package.json")
    IFS=' ' read -r -a SPECIFIC_FILENAMES <<< "$files_string"
    
    INTERACTIVE_MODE=$(get_config "INTERACTIVE_MODE" "false")
}

# Initialize script
init_script() {
    debug "Starting $SCRIPT_NAME v$TEXTHARVEST_VERSION"
    
    # Load configuration
    load_configuration
    
    # Validate input directory
    validate_input_dir "$CODE_DIR" "Source code directory"
    
    # Create output directory
    create_output_dir "$OUTPUT_DIR" "Code listings directory"
    
    # Check disk space
    check_disk_space "$OUTPUT_DIR" "$(get_config 'MIN_DISK_SPACE_MB' '100')"
    
    info "Input directory: '$CODE_DIR'" 2
    info "Output directory: '$OUTPUT_DIR'" 2
    info "Extensions: ${CODE_EXTENSIONS[*]}" 2
    info "Specific files: ${SPECIFIC_FILENAMES[*]}" 2
}

# Interactive project selection
select_projects_interactive() {
    local -a all_projects=()
    local -a selected_projects=()
    
    # Find all project directories
    shopt -s nullglob
    for dir in "$CODE_DIR"/*; do
        if [[ -d "$dir" ]]; then
            all_projects+=("$(basename "$dir")")
        fi
    done
    shopt -u nullglob
    
    if (( ${#all_projects[@]} == 0 )); then
        error_exit "No project directories found in '$CODE_DIR'"
    fi
    
    while true; do
        echo "" >&2
        echo "Available projects in '$CODE_DIR':" >&2
        for i in "${!all_projects[@]}"; do
            printf "  %2d) %s\n" "$((i + 1))" "${all_projects[$i]}" >&2
        done

        echo "" >&2
        echo "Options:" >&2
        echo "  a) Process ALL projects" >&2
        echo "  1,2,3) Select specific projects (comma-separated)" >&2
        echo "  q) Quit" >&2

        read -r -p "Enter your choice: " choice
        
        case "$choice" in
            [Qq]*)
                info "Exiting at user request"
                exit 0
                ;;
            [Aa]*)
                selected_projects=("${all_projects[@]}")
                break
                ;;
            *)
                # Parse comma-separated numbers
                IFS=',' read -r -a indices <<< "$choice"
                selected_projects=()
                local valid=true
                
                for idx_str in "${indices[@]}"; do
                    idx_str=$(echo "$idx_str" | xargs) # Trim whitespace
                    if [[ "$idx_str" =~ ^[1-9][0-9]*$ ]]; then
                        local idx=$((idx_str - 1))
                        if (( idx >= 0 && idx < ${#all_projects[@]} )); then
                            selected_projects+=("${all_projects[$idx]}")
                        else
                            warn "Invalid project number: $idx_str"
                            valid=false
                        fi
                    else
                        warn "Invalid input: $idx_str"
                        valid=false
                    fi
                done
                
                if [[ "$valid" == true ]] && (( ${#selected_projects[@]} > 0 )); then
                    break
                fi
                ;;
        esac
    done
    
    echo "${selected_projects[@]}"
}

# Discover projects to process
discover_projects() {
    if [[ "$INTERACTIVE_MODE" == "true" ]]; then
        mapfile -t projects_to_process < <(select_projects_interactive)
    else
        # Process all projects
        shopt -s nullglob
        for dir in "$CODE_DIR"/*; do
            if [[ -d "$dir" ]]; then
                projects_to_process+=("$(basename "$dir")")
            fi
        done
        shopt -u nullglob
    fi
    
    if (( ${#projects_to_process[@]} == 0 )); then
        info "No projects to process"
        exit 0
    fi
    
    info "Will process ${#projects_to_process[@]} project(s): ${projects_to_process[*]}" 2
}

# Process a single project
process_project() {
    local project_dir="$1"
    local project_output_file="$OUTPUT_DIR/${project_dir}${OUTPUT_SUFFIX}"
    local file_count=0
    
    debug "Processing project: $project_dir"
    
    # Check if project directory exists
    if [[ ! -d "$CODE_DIR/$project_dir" ]]; then
        warn "Project directory '$CODE_DIR/$project_dir' not found, skipping"
        return 1
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        info "DRY RUN: Would process project '$project_dir' -> '$project_output_file'" 2
        return 0
    fi
    
    # Create or clear the output file
    > "$project_output_file"
    
    # Add header
    cat >> "$project_output_file" << EOF
=======================================
=== Project Listing: $project_dir ===
=======================================

EOF
    
    # Build find arguments
    local -a find_args=()
    local first_condition=true
    
    # Add extension conditions
    for ext in "${CODE_EXTENSIONS[@]}"; do
        if [[ "$first_condition" == true ]]; then
            find_args+=(-name "*$ext")
            first_condition=false
        else
            find_args+=(-o -name "*$ext")
        fi
    done
    
    # Add specific filename conditions
    for filename in "${SPECIFIC_FILENAMES[@]}"; do
        if [[ "$first_condition" == true ]]; then
            find_args+=(-name "$filename")
            first_condition=false
        else
            find_args+=(-o -name "$filename")
        fi
    done
    
    if [[ "$first_condition" == true ]]; then
        warn "No file patterns defined for project '$project_dir', skipping"
        return 1
    fi
    
    # Find and process files
    while IFS= read -r -d $'\0' code_file; do
        local relative_path="${code_file#$CODE_DIR/$project_dir/}"
        debug "Processing file: $relative_path"
        
        echo "--- File: $relative_path ---" >> "$project_output_file"
        if [[ -r "$code_file" ]]; then
            cat "$code_file" >> "$project_output_file"
            ((file_count++))
        else
            echo "Error: Could not read file '$code_file'" >> "$project_output_file"
        fi
        echo -e "\n" >> "$project_output_file"
    done < <(find "$CODE_DIR/$project_dir" -type f \( "${find_args[@]}" \) -print0 | sort -z)
    
    if (( file_count > 0 )); then
        success "Project '$project_dir': $file_count files -> '$project_output_file'"
    else
        warn "Project '$project_dir': No matching files found"
    fi
    
    return 0
}

# Main processing function
main_processing() {
    local -a projects_to_process=()
    
    discover_projects
    
    init_progress "${#projects_to_process[@]}" "Processing projects"
    
    local processed=0
    local failed=0
    
    for project in "${projects_to_process[@]}"; do
        if process_project "$project"; then
            ((processed++))
        else
            ((failed++))
        fi
        update_progress
    done
    
    echo "" # New line after progress
    
    if [[ "$DRY_RUN" == true ]]; then
        info "DRY RUN completed: Would have processed $processed projects"
    else
        success "Processing completed: $processed projects processed, $failed failed"
        if (( failed > 0 )); then
            warn "$failed projects had issues (see output above)"
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