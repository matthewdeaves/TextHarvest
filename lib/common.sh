#!/bin/bash

# TextHarvest Common Library
# Shared functions for all TextHarvest scripts
# Version: 2.0.0

# Global variables
TEXTHARVEST_VERSION="2.0.0"
VERBOSE_LEVEL=1  # 0=quiet, 1=normal, 2=verbose, 3=debug
DRY_RUN=false

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# =============================================================================
# ERROR HANDLING FUNCTIONS
# =============================================================================

# Standardized error handling
error_exit() {
    local message="${1:-Unknown error occurred}"
    local exit_code="${2:-1}"
    echo -e "${RED}ERROR:${NC} $message" >&2
    exit "$exit_code"
}

# Warning messages
warn() {
    local message="$1"
    echo -e "${YELLOW}WARNING:${NC} $message" >&2
}

# Info messages with verbosity control
info() {
    local message="$1"
    local level="${2:-1}"
    if (( VERBOSE_LEVEL >= level )); then
        echo -e "${BLUE}INFO:${NC} $message"
    fi
}

# Success messages
success() {
    local message="$1"
    echo -e "${GREEN}SUCCESS:${NC} $message"
}

# Debug messages
debug() {
    local message="$1"
    if (( VERBOSE_LEVEL >= 3 )); then
        echo -e "${BLUE}DEBUG:${NC} $message" >&2
    fi
}

# =============================================================================
# DEPENDENCY CHECKING FUNCTIONS
# =============================================================================

# Check if a command exists
check_command() {
    local cmd="$1"
    local package="${2:-$cmd}"
    
    if ! command -v "$cmd" &> /dev/null; then
        error_exit "'$cmd' command not found. Please install $package package."
    fi
    debug "Command '$cmd' found"
}

# Check multiple dependencies at once
check_dependencies() {
    local -a deps=("$@")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if (( ${#missing_deps[@]} > 0 )); then
        error_exit "Missing dependencies: ${missing_deps[*]}. Please run setup.sh first."
    fi
    
    info "All dependencies satisfied" 2
}

# =============================================================================
# DIRECTORY AND FILE VALIDATION FUNCTIONS
# =============================================================================

# Validate input directory exists
validate_input_dir() {
    local dir="$1"
    local description="${2:-Input directory}"
    
    if [[ ! -d "$dir" ]]; then
        error_exit "$description '$dir' not found."
    fi
    
    if [[ ! -r "$dir" ]]; then
        error_exit "$description '$dir' is not readable."
    fi
    
    debug "Input directory '$dir' validated"
}

# Create output directory with proper permissions
create_output_dir() {
    local dir="$1"
    local description="${2:-Output directory}"
    
    if [[ -z "$dir" ]]; then
        error_exit "Output directory path cannot be empty"
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        info "DRY RUN: Would create $description '$dir'" 2
        return 0
    fi
    
    if ! mkdir -p "$dir"; then
        error_exit "Could not create $description '$dir'"
    fi
    
    if [[ ! -w "$dir" ]]; then
        error_exit "$description '$dir' is not writable"
    fi
    
    debug "$description '$dir' created/validated"
}

# Check available disk space (cross-platform)
check_disk_space() {
    local dir="$1"
    local min_space_mb="${2:-100}"
    
    local available_kb
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS version - df output format is different
        available_kb=$(df -k "$dir" | awk 'NR==2 {print $4}')
    else
        # Linux version
        available_kb=$(df "$dir" | awk 'NR==2 {print $4}')
    fi
    
    local available_mb=$((available_kb / 1024))
    
    if (( available_mb < min_space_mb )); then
        error_exit "Insufficient disk space. Available: ${available_mb}MB, Required: ${min_space_mb}MB"
    fi
    
    debug "Disk space check passed: ${available_mb}MB available"
}

# =============================================================================
# FILE PROCESSING FUNCTIONS
# =============================================================================

# Count files matching pattern
count_files() {
    local dir="$1"
    local pattern="$2"
    
    local count=0
    shopt -s nullglob
    local files=("$dir"/$pattern)
    count=${#files[@]}
    shopt -u nullglob
    
    echo "$count"
}

# Get file size in human readable format (cross-platform)
get_file_size() {
    local file="$1"
    if [[ -f "$file" ]]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS version
            local size_bytes
            size_bytes=$(stat -f%z "$file" 2>/dev/null || echo "0")
            if command -v numfmt &> /dev/null; then
                echo "$size_bytes" | numfmt --to=iec
            else
                # Fallback for macOS without numfmt
                if (( size_bytes >= 1073741824 )); then
                    echo "$((size_bytes / 1073741824))G"
                elif (( size_bytes >= 1048576 )); then
                    echo "$((size_bytes / 1048576))M"
                elif (( size_bytes >= 1024 )); then
                    echo "$((size_bytes / 1024))K"
                else
                    echo "${size_bytes}B"
                fi
            fi
        else
            # Linux version
            stat -c%s "$file" | numfmt --to=iec
        fi
    else
        echo "0"
    fi
}

# =============================================================================
# PROGRESS TRACKING FUNCTIONS
# =============================================================================

# Initialize progress tracking
init_progress() {
    local total="$1"
    local task="${2:-Processing}"
    
    export PROGRESS_TOTAL="$total"
    export PROGRESS_CURRENT=0
    export PROGRESS_TASK="$task"
    export PROGRESS_START_TIME=$(date +%s)
    
    info "Starting $task: 0/$total files" 2
}

# Update progress
update_progress() {
    local current="${1:-$((PROGRESS_CURRENT + 1))}"
    local item_name="${2:-}"
    
    export PROGRESS_CURRENT="$current"
    
    if (( VERBOSE_LEVEL >= 2 )); then
        local percentage=$((current * 100 / PROGRESS_TOTAL))
        local elapsed=$(($(date +%s) - PROGRESS_START_TIME))
        local eta=""
        
        if (( current > 0 && elapsed > 0 )); then
            local avg_time=$((elapsed / current))
            local remaining=$((PROGRESS_TOTAL - current))
            local eta_seconds=$((remaining * avg_time))
            eta=" (ETA: ${eta_seconds}s)"
        fi
        
        echo -ne "\r${PROGRESS_TASK}: $current/$PROGRESS_TOTAL (${percentage}%)${eta}"
        if [[ -n "$item_name" ]]; then
            echo -ne " - $item_name"
        fi
        
        if (( current == PROGRESS_TOTAL )); then
            echo "" # New line when complete
        fi
    fi
}

# Finish progress tracking
finish_progress() {
    local elapsed=$(($(date +%s) - PROGRESS_START_TIME))
    success "$PROGRESS_TASK completed: $PROGRESS_CURRENT/$PROGRESS_TOTAL files in ${elapsed}s"
}

# =============================================================================
# CONFIGURATION MANAGEMENT FUNCTIONS
# =============================================================================

# Load configuration from file
load_config() {
    local config_file="$1"
    
    if [[ -f "$config_file" ]]; then
        # Source the config file in a subshell to avoid polluting current environment
        debug "Loading configuration from '$config_file'"
        source "$config_file"
        info "Configuration loaded from '$config_file'" 2
    else
        debug "Configuration file '$config_file' not found, using defaults"
    fi
}

# Get configuration value with fallbacks
get_config() {
    local var_name="$1"
    local default_value="$2"
    local env_var="TEXTHARVEST_${var_name^^}"
    
    # Priority: environment variable > config file > default
    if [[ -n "${!env_var}" ]]; then
        echo "${!env_var}"
    elif [[ -n "${!var_name}" ]]; then
        echo "${!var_name}"
    else
        echo "$default_value"
    fi
}

# =============================================================================
# PLUGIN ARCHITECTURE FUNCTIONS
# =============================================================================

# Load plugin
load_plugin() {
    local plugin_name="$1"
    local plugin_dir="${TEXTHARVEST_PLUGIN_DIR:-./plugins}"
    local plugin_file="$plugin_dir/$plugin_name.sh"
    
    if [[ -f "$plugin_file" ]]; then
        debug "Loading plugin '$plugin_name'"
        source "$plugin_file"
        info "Plugin '$plugin_name' loaded" 2
        return 0
    else
        warn "Plugin '$plugin_name' not found at '$plugin_file'"
        return 1
    fi
}

# List available plugins
list_plugins() {
    local plugin_dir="${TEXTHARVEST_PLUGIN_DIR:-./plugins}"
    
    if [[ -d "$plugin_dir" ]]; then
        find "$plugin_dir" -name "*.sh" -type f -exec basename {} .sh \;
    fi
}

# =============================================================================
# PARALLEL PROCESSING FUNCTIONS
# =============================================================================

# Execute function in parallel
parallel_execute() {
    local -a commands=("$@")
    local max_jobs="${TEXTHARVEST_MAX_JOBS:-4}"
    local -a pids=()
    
    info "Running ${#commands[@]} commands with max $max_jobs parallel jobs" 2
    
    for cmd in "${commands[@]}"; do
        # Wait if we've reached max jobs
        while (( ${#pids[@]} >= max_jobs )); do
            for i in "${!pids[@]}"; do
                if ! kill -0 "${pids[i]}" 2>/dev/null; then
                    unset "pids[i]"
                fi
            done
            pids=("${pids[@]}")  # Re-index array
            sleep 0.1
        done
        
        # Start new job
        eval "$cmd" &
        pids+=($!)
        debug "Started job: $cmd (PID: $!)"
    done
    
    # Wait for all remaining jobs
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
    
    info "All parallel jobs completed" 2
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Show version information
show_version() {
    echo "TextHarvest v$TEXTHARVEST_VERSION"
    echo "https://github.com/user/textharvest"
}

# Cleanup function for trap handlers
cleanup() {
    debug "Cleanup function called"
    # Remove any temporary files
    if [[ -n "${TEMP_FILES:-}" ]]; then
        rm -f "${TEMP_FILES[@]}" 2>/dev/null || true
    fi
}

# Set up signal handlers
setup_signal_handlers() {
    trap cleanup EXIT
    trap 'error_exit "Script interrupted by user" 130' INT
    trap 'error_exit "Script terminated" 143' TERM
}

# Parse common command line arguments
parse_common_args() {
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
            --version)
                show_version
                exit 0
                ;;
            -h|--help)
                return 1  # Signal that help should be shown
                ;;
            *)
                # Return remaining args
                break
                ;;
        esac
    done
    
    # Return remaining arguments
    echo "$@"
}

# Initialize common library
init_common() {
    setup_signal_handlers
    
    # Load configuration files in order of priority
    load_config "/etc/textharvest.conf"
    load_config "$HOME/.textharvest.conf"
    load_config "./textharvest.conf"
    
    debug "Common library initialized"
}

# Auto-initialize when sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    init_common
fi