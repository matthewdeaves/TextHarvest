#!/bin/bash

# TextHarvest Setup Script v2.0.0
# Cross-platform installation for Linux (apt/yum) and macOS (Homebrew)

# Load common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/lib/common.sh" ]]; then
    source "$SCRIPT_DIR/lib/common.sh"
else
    # Fallback functions if common.sh not available
    error_exit() { echo "ERROR: $1" >&2; exit "${2:-1}"; }
    warn() { echo "WARNING: $1" >&2; }
    info() { echo "INFO: $1"; }
    success() { echo "SUCCESS: $1"; }
fi

# Show help
show_help() {
    cat << EOF
TextHarvest Setup Script v${TEXTHARVEST_VERSION:-2.0.0}

USAGE:
    $0 [OPTIONS]

DESCRIPTION:
    Installs required dependencies for TextHarvest on Linux and macOS.
    Automatically detects the operating system and uses appropriate package manager.

OPTIONS:
    --force-platform OS    Force platform detection (linux, macos)
    --package-manager PM   Force package manager (apt, yum, dnf, brew)
    --skip-update         Skip updating package manager repositories
    --list-packages       Show packages that would be installed
    --dry-run             Show what would be installed without doing it
    -v, --verbose         Verbose output
    -q, --quiet           Quiet mode
    -h, --help            Show this help

SUPPORTED PLATFORMS:
    - Linux (Ubuntu/Debian) - apt package manager
    - Linux (RHEL/CentOS/Fedora) - yum/dnf package manager  
    - macOS - Homebrew package manager

DEPENDENCIES INSTALLED:
    - poppler (pdftotext and PDF utilities)
    - ocrmypdf (PDF OCR processing)
    - tesseract (OCR engine)
    - tesseract language packs (English + others)

EXAMPLES:
    $0                    # Auto-detect platform and install
    $0 --dry-run         # Preview installation
    $0 --force-platform macos  # Force macOS installation
    $0 --list-packages   # Show what would be installed

EOF
}

# Detect operating system
detect_os() {
    local os_type=""
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        os_type="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        os_type="linux"
    elif [[ -f /etc/os-release ]]; then
        # Linux with os-release file
        os_type="linux"
    else
        warn "Could not detect operating system type"
        return 1
    fi
    
    echo "$os_type"
}

# Detect package manager
detect_package_manager() {
    local os_type="$1"
    local pm=""
    
    case "$os_type" in
        macos)
            if command -v brew &> /dev/null; then
                pm="brew"
            else
                warn "Homebrew not found. Please install from https://brew.sh/"
                return 1
            fi
            ;;
        linux)
            if command -v apt &> /dev/null; then
                pm="apt"
            elif command -v dnf &> /dev/null; then
                pm="dnf"
            elif command -v yum &> /dev/null; then
                pm="yum"
            else
                warn "No supported package manager found (apt, yum, dnf)"
                return 1
            fi
            ;;
        *)
            warn "Unsupported operating system: $os_type"
            return 1
            ;;
    esac
    
    echo "$pm"
}

# Get package names for different package managers
get_packages() {
    local pm="$1"
    local -a packages=()
    
    case "$pm" in
        apt)
            packages=(
                "poppler-utils"      # PDF utilities including pdftotext
                "tesseract-ocr"      # OCR engine
                "tesseract-ocr-eng"  # English language pack
                "unpaper"            # Image preprocessing for OCR (--clean/--deskew)
                "python3-pip"        # For installing ocrmypdf
                "python3-venv"       # For creating virtual environments
            )
            ;;
        yum|dnf)
            packages=(
                "poppler-utils"      # PDF utilities
                "tesseract"          # OCR engine
                "tesseract-langpack-eng"  # English language pack
                "unpaper"            # Image preprocessing for OCR (--clean/--deskew)
                "python3-pip"        # For installing ocrmypdf
                "python3-venv"       # For creating virtual environments
            )
            ;;
        brew)
            packages=(
                "poppler"            # PDF utilities
                "tesseract"          # OCR engine with language packs
                "tesseract-lang"     # Additional language packs
                "unpaper"            # Image preprocessing for OCR (--clean/--deskew)
            )
            ;;
        *)
            error_exit "Unsupported package manager: $pm"
            ;;
    esac
    
    printf '%s\n' "${packages[@]}"
}

# Get Python packages to install via pip
get_python_packages() {
    local pm="$1"
    local -a packages=()
    
    case "$pm" in
        apt|yum|dnf)
            packages=("ocrmypdf")
            ;;
        brew)
            # Homebrew formula for ocrmypdf
            packages=()  # ocrmypdf will be installed via brew
            ;;
    esac
    
    printf '%s\n' "${packages[@]}"
}

# Update package manager repositories
update_packages() {
    local pm="$1"
    local skip_update="$2"
    
    if [[ "$skip_update" == true ]]; then
        info "Skipping package manager update"
        return 0
    fi
    
    info "Updating package manager repositories..."
    
    case "$pm" in
        apt)
            if sudo apt update; then
                info "Package list updated successfully"
            else
                error_exit "Failed to update package list"
            fi
            ;;
        yum)
            # yum check-update returns 0 if no updates, 100 if updates available, other codes on error
            local yum_rc=0
            sudo yum check-update || yum_rc=$?
            if (( yum_rc == 0 || yum_rc == 100 )); then
                info "Package cache updated successfully"
            else
                error_exit "Failed to update package cache (exit code: $yum_rc)"
            fi
            ;;
        dnf)
            # dnf check-update returns 0 if no updates, 100 if updates available, other codes on error
            local dnf_rc=0
            sudo dnf check-update || dnf_rc=$?
            if (( dnf_rc == 0 || dnf_rc == 100 )); then
                info "Package cache updated successfully"
            else
                error_exit "Failed to update package cache (exit code: $dnf_rc)"
            fi
            ;;
        brew)
            if brew update; then
                info "Homebrew formulae updated successfully"
            else
                error_exit "Failed to update Homebrew"
            fi
            ;;
    esac
}

# Install system packages
install_packages() {
    local pm="$1"
    local dry_run="$2"
    local -a packages=()
    while IFS= read -r pkg; do
        [[ -n "$pkg" ]] && packages+=("$pkg")
    done < <(get_packages "$pm")
    
    info "Installing packages: ${packages[*]}"
    
    if [[ "$dry_run" == true ]]; then
        info "DRY RUN: Would install packages: ${packages[*]}"
        return 0
    fi
    
    case "$pm" in
        apt)
            if sudo apt install -y "${packages[@]}"; then
                success "System packages installed successfully"
            else
                error_exit "Failed to install system packages"
            fi
            ;;
        yum)
            if sudo yum install -y "${packages[@]}"; then
                success "System packages installed successfully"
            else
                error_exit "Failed to install system packages"
            fi
            ;;
        dnf)
            if sudo dnf install -y "${packages[@]}"; then
                success "System packages installed successfully"
            else
                error_exit "Failed to install system packages"
            fi
            ;;
        brew)
            # Add ocrmypdf to brew packages for macOS
            local brew_packages=("${packages[@]}" "ocrmypdf")
            if brew install "${brew_packages[@]}"; then
                success "Homebrew packages installed successfully"
            else
                error_exit "Failed to install Homebrew packages"
            fi
            ;;
    esac
}

# Install Python packages via pip
install_python_packages() {
    local pm="$1"
    local dry_run="$2"
    local -a python_packages=()
    while IFS= read -r pkg; do
        [[ -n "$pkg" ]] && python_packages+=("$pkg")
    done < <(get_python_packages "$pm")
    
    if [[ ${#python_packages[@]} -eq 0 ]]; then
        info "No Python packages to install via pip"
        return 0
    fi
    
    info "Installing Python packages into a virtual environment: ${python_packages[*]}"

    local venv_dir="$SCRIPT_DIR/venv"
    
    if [[ "$dry_run" == true ]]; then
        info "DRY RUN: Would create virtual environment at $venv_dir"
        info "DRY RUN: Would install Python packages: ${python_packages[*]}"
        return 0
    fi

    # Create virtual environment if it doesn't exist
    if [[ ! -d "$venv_dir" ]]; then
        info "Creating Python virtual environment at $venv_dir..."
        if ! python3 -m venv "$venv_dir"; then
            error_exit "Failed to create Python virtual environment."
        fi
    else
        info "Virtual environment already exists at $venv_dir"
    fi

    # Install packages using pip from the virtual environment
    local pip_cmd="$venv_dir/bin/pip"
    
    if "$pip_cmd" install "${python_packages[@]}"; then
        success "Python packages installed successfully in $venv_dir"
    else
        error_exit "Failed to install Python packages into the virtual environment"
    fi
}

# Verify installation
verify_installation() {
    local -a system_commands=("pdftotext" "tesseract")
    local venv_dir="$SCRIPT_DIR/venv"
    local -a venv_commands=("ocrmypdf")
    local failed=0
    
    info "Verifying installation..."
    
    # Verify system-wide commands
    for cmd in "${system_commands[@]}"; do
        if command -v "$cmd" &> /dev/null; then
            local version
            case "$cmd" in
                pdftotext)
                    version=$(pdftotext -v 2>&1 | head -n1 || echo "unknown")
                    ;;
                tesseract)
                    version=$(tesseract --version 2>&1 | head -n1 || echo "unknown")
                    ;;
            esac
            success "$cmd is available - $version"
        else
            warn "$cmd is not available in PATH"
            ((failed++))
        fi
    done

    # Verify commands in virtual environment (or system-wide on macOS/brew)
    for cmd in "${venv_commands[@]}"; do
        if [[ -x "$venv_dir/bin/$cmd" ]]; then
            local version=$("$venv_dir/bin/$cmd" --version 2>&1 || echo "unknown")
            success "$cmd is available in the virtual environment - $version"
        elif command -v "$cmd" &> /dev/null; then
            # Check if it's available system-wide (e.g., installed via brew on macOS)
            local version=$("$cmd" --version 2>&1 | head -n1 || echo "unknown")
            success "$cmd is available system-wide - $version"
        else
            warn "$cmd is not available in the virtual environment ($venv_dir/bin/$cmd) or system-wide"
            ((failed++))
        fi
    done
    
    if [[ $failed -eq 0 ]]; then
        success "All required tools are installed and available"
        echo ""
        # Show venv instructions only if venv was created
        if [[ -d "$venv_dir" && -x "$venv_dir/bin/ocrmypdf" ]]; then
            info "The 'ocrmypdf' command has been installed in a virtual environment."
            info "To use it, you can either activate the environment or call the executable directly:"
            echo ""
            echo "  1. Activate the virtual environment (recommended for interactive sessions):"
            echo "     source venv/bin/activate"
            echo "     # Now you can run the scripts directly"
            echo "     ./textharvest.sh pdf-ocr --help"
            echo "     # Deactivate when you are done"
            echo "     deactivate"
            echo ""
            echo "  2. Run the scripts directly (they will use the venv automatically):"
            echo "     ./textharvest.sh pdf-ocr --help"
            echo ""
        else
            info "All tools are available system-wide. You can run the scripts directly:"
            echo ""
            echo "     ./textharvest.sh pdf-ocr --help"
            echo ""
        fi
    else
        error_exit "$failed required tools are missing or not configured correctly."
    fi
}

# Parse command line arguments
parse_args() {
    FORCE_PLATFORM=""
    FORCE_PACKAGE_MANAGER=""
    SKIP_UPDATE=false
    LIST_PACKAGES=false
    DRY_RUN=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force-platform)
                FORCE_PLATFORM="$2"
                shift 2
                ;;
            --package-manager)
                FORCE_PACKAGE_MANAGER="$2"
                shift 2
                ;;
            --skip-update)
                SKIP_UPDATE=true
                shift
                ;;
            --list-packages)
                LIST_PACKAGES=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE_LEVEL=2
                shift
                ;;
            -q|--quiet)
                VERBOSE_LEVEL=0
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                error_exit "Unknown option: $1. Use --help for usage."
                ;;
        esac
    done
}

# List packages that would be installed
list_packages() {
    local os_type="$1"
    local pm="$2"
    
    echo "Platform: $os_type"
    echo "Package Manager: $pm"
    echo ""
    echo "System packages:"
    get_packages "$pm" | sed 's/^/  - /'
    echo ""
    echo "Python packages:"
    local -a python_packages=()
    while IFS= read -r pkg; do
        [[ -n "$pkg" ]] && python_packages+=("$pkg")
    done < <(get_python_packages "$pm")
    if [[ ${#python_packages[@]} -gt 0 ]]; then
        printf '  - %s\n' "${python_packages[@]}"
    else
        echo "  (none)"
    fi
}

# Main installation function
main() {
    parse_args "$@"
    
    info "TextHarvest Setup Script v${TEXTHARVEST_VERSION:-2.0.0}"
    info "Cross-platform dependency installer"
    echo ""
    
    # Detect platform
    local os_type
    if [[ -n "$FORCE_PLATFORM" ]]; then
        os_type="$FORCE_PLATFORM"
        info "Using forced platform: $os_type"
    else
        os_type=$(detect_os) || error_exit "Could not detect operating system"
        info "Detected platform: $os_type"
    fi
    
    # Detect package manager
    local pm
    if [[ -n "$FORCE_PACKAGE_MANAGER" ]]; then
        pm="$FORCE_PACKAGE_MANAGER"
        info "Using forced package manager: $pm"
    else
        pm=$(detect_package_manager "$os_type") || error_exit "Could not detect package manager"
        info "Using package manager: $pm"
    fi
    
    # List packages if requested
    if [[ "$LIST_PACKAGES" == true ]]; then
        list_packages "$os_type" "$pm"
        exit 0
    fi
    
    echo ""
    
    # Update package repositories
    update_packages "$pm" "$SKIP_UPDATE"
    
    # Install packages
    install_packages "$pm" "$DRY_RUN"
    
    # Install Python packages
    install_python_packages "$pm" "$DRY_RUN"
    
    # Verify installation
    if [[ "$DRY_RUN" != true ]]; then
        echo ""
        verify_installation
    else
        echo ""
        info "DRY RUN completed - no packages were actually installed"
    fi
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi