#!/usr/bin/env bash

# Firefox Version Manager (.fvm)
# Usage: ./.fvm <command> [options]
# Commands: install, exec, run, list, help
# Example: ./.fvm install 50.0
# Example: ./.fvm exec 50.0
# Example: ./.fvm run 50.0 --new-window

set -e  # Exit on any error

# Default installation directory
DEFAULT_INSTALL_DIR="${FVM_INSTALL_PATH:-$HOME}"

# Function to show usage
show_usage() {
    echo "Firefox Version Manager (.fvm)"
    echo ""
    echo "Usage: ./.fvm <command> [options]"
    echo ""
    echo "Commands:"
    echo "  install [version]     Install Firefox version (latest if no version specified)"
    echo "  exec <version>        Execute Firefox version"
    echo "  run <version> [args]  Run Firefox version with arguments"
    echo "  uninstall <version>   Uninstall Firefox version"
    echo "  list                  List installed versions"
    echo "  list-remote          List available versions from Mozilla"
    echo "  list-remote --all    List all available versions (including beta/ESR)"
    echo "  help                  Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  FVM_INSTALL_PATH     Override default installation path (default: \$HOME)"
    echo ""
    echo "Examples:"
    echo "  ./.fvm install        # Install latest Firefox version"
    echo "  ./.fvm install 50.0   # Install specific Firefox version"
    echo "  ./.fvm exec 50.0"
    echo "  ./.fvm run 50.0 --new-window"
    echo "  ./.fvm uninstall 50.0"
    echo "  ./.fvm list"
    echo ""
    echo "  # Using custom installation path:"
    echo "  FVM_INSTALL_PATH=/opt/firefox ./.fvm install 50.0"
}

# Function to get Firefox path
get_firefox_path() {
    local VERSION="$1"
    local INSTALL_DIR="${2:-$DEFAULT_INSTALL_DIR}"
    echo "${INSTALL_DIR}/firefox-${VERSION}"
}

# Function to check if Firefox version is installed
is_firefox_installed() {
    local VERSION="$1"
    local INSTALL_DIR="${2:-$DEFAULT_INSTALL_DIR}"
    local FIREFOX_DIR="$(get_firefox_path "$VERSION" "$INSTALL_DIR")"
    echo "[DEBUG] Checking: $FIREFOX_DIR/firefox" 1>&2
    [ -d "$FIREFOX_DIR" ] && [ -x "$FIREFOX_DIR/firefox" ]
}

# Function to list installed versions
list_installed_versions() {
    local INSTALL_DIR="${1:-$DEFAULT_INSTALL_DIR}"
    echo "Installed Firefox versions in ${INSTALL_DIR}:"
    
    if [ -d "$INSTALL_DIR" ]; then
        for dir in "${INSTALL_DIR}"/firefox-*; do
            if [ -d "$dir" ] && [ -x "$dir/firefox" ]; then
                local version=$(basename "$dir" | sed 's/firefox-//')
                echo "  - Firefox ${version}"
            fi
        done
    else
        echo "  No versions installed yet."
    fi
}

# Function to install Firefox
install_firefox() {
    local VERSION="$1"
    local INSTALL_DIR="${2:-$DEFAULT_INSTALL_DIR}"
    local IS_LATEST=0
    local TEMP_DIR=""
    local DOWNLOAD_FILE=""
    
    echo "[DEBUG] Starting installation with VERSION='$VERSION'"
    
    # Expand tilde in installation directory
    INSTALL_DIR="${INSTALL_DIR/#\~/$HOME}"
    echo "[DEBUG] Installation directory: $INSTALL_DIR"
    
    # Check if we have wget
    if ! command -v wget &> /dev/null; then
        echo "Error: wget is not installed. Please install wget first."
        return 1
    fi
    
    # Check if we have tar
    if ! command -v tar &> /dev/null; then
        echo "Error: tar is not installed. Please install tar first."
        return 1
    fi
    
    # Check if we can write to the installation directory
    if [ ! -w "$INSTALL_DIR" ]; then
        echo "Error: Cannot write to ${INSTALL_DIR}."
        echo "This directory requires sudo privileges."
        echo "Please run: sudo ./.fvm install $VERSION -d $INSTALL_DIR"
        echo "Or choose a user-writable directory: ./.fvm install $VERSION -d ~/firefox"
        return 1
    fi
    
    if [ -z "$VERSION" ]; then
        IS_LATEST=1
        echo "Installing latest Firefox version..."
        
        # Create a temporary directory for downloading
        TEMP_DIR=$(mktemp -d)
        echo "[DEBUG] Created temp directory: $TEMP_DIR"
        if [ -z "${TEMP_DIR}" ]; then
            echo "Error: Unable to create temporary directory"
            return 1
        fi
        
        # Download latest version
        DOWNLOAD_FILE="${TEMP_DIR}/firefox-latest.tar.bz2"
        echo "Downloading latest Firefox..."
        if ! wget -q --show-progress -O "${DOWNLOAD_FILE}" "https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=en-US"; then
            echo "Error: Failed to download latest Firefox"
            rm -rf "$TEMP_DIR"
            return 1
        fi

        # First try to identify the file type
        FILE_TYPE=$(file -b "${DOWNLOAD_FILE}")
        echo "[DEBUG] Downloaded file type: ${FILE_TYPE}"

        # Extract version number from the downloaded binary
        cd "${TEMP_DIR}"
        if [[ "${FILE_TYPE}" == *"XZ compressed data"* ]]; then
            # Handle .tar.xz format
            mv "${DOWNLOAD_FILE}" "${TEMP_DIR}/firefox-latest.tar.xz"
            DOWNLOAD_FILE="${TEMP_DIR}/firefox-latest.tar.xz"
            if ! tar -xJf "${DOWNLOAD_FILE}" firefox/application.ini; then
                echo "Error: Failed to extract version information"
                rm -rf "$TEMP_DIR"
                return 1
            fi
        elif [[ "${FILE_TYPE}" == *"bzip2 compressed data"* ]]; then
            # Handle .tar.bz2 format
            if ! tar -xjf "${DOWNLOAD_FILE}" firefox/application.ini; then
                echo "Error: Failed to extract version information"
                rm -rf "$TEMP_DIR"
                return 1
            fi
        else
            echo "Error: Unsupported file format: ${FILE_TYPE}"
            rm -rf "$TEMP_DIR"
            return 1
        fi

        echo "Reading version from application.ini..."
        VERSION=$(grep -E "^Version=" firefox/application.ini | cut -d'=' -f2)
        if [ -z "$VERSION" ]; then
            echo "Error: Could not determine Firefox version"
            rm -rf "$TEMP_DIR"
            return 1
        fi
        echo "Latest version is: $VERSION"
    fi
    
    ARCH="$(uname -m)"
    FINAL_INSTALL_DIR="${INSTALL_DIR}/firefox-${VERSION}"
    echo "[DEBUG] Final installation directory: $FINAL_INSTALL_DIR"
    
    echo "Installing Firefox version ${VERSION}..."
    echo "Installation directory: ${FINAL_INSTALL_DIR}"
    
    # Check if already installed
    if is_firefox_installed "$VERSION" "$INSTALL_DIR"; then
        echo "Firefox ${VERSION} is already installed at ${FINAL_INSTALL_DIR}"
        echo "To reinstall, first run: ./.fvm uninstall ${VERSION}"
        [ $IS_LATEST -eq 1 ] && [ -n "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"
        return 0
    fi
    
    # Create installation directory
    mkdir -p "$FINAL_INSTALL_DIR"
    echo "[DEBUG] Created installation directory"
    
    if [ $IS_LATEST -eq 1 ]; then
        echo "Extracting Firefox ${VERSION} to ${FINAL_INSTALL_DIR}..."
        cd "$FINAL_INSTALL_DIR"
        if [[ "${FILE_TYPE}" == *"XZ compressed data"* ]]; then
            tar -xJf "${DOWNLOAD_FILE}" --strip-components=1
        else
            tar -xjf "${DOWNLOAD_FILE}" --strip-components=1
        fi
        rm -rf "$TEMP_DIR"
        echo "Cleaned up temp directory"
    else
        echo "Downloading and extracting Firefox ${VERSION} directly to ${FINAL_INSTALL_DIR}..."
        DOWNLOAD_URL="http://ftp.mozilla.org/pub/firefox/releases/${VERSION}/linux-${ARCH}/en-US/firefox-${VERSION}.tar.bz2"
        
        # Download and extract directly to the target directory
        cd "$FINAL_INSTALL_DIR"
        wget -q --show-progress "$DOWNLOAD_URL" -O firefox-${VERSION}.tar.bz2
        tar -xjf firefox-${VERSION}.tar.bz2 --strip-components=1
        rm firefox-${VERSION}.tar.bz2
    fi
    
    # Set permissions
    chmod +x firefox
    echo "[DEBUG] Set executable permissions"
    
    # Create distribution directory and policies.json to disable updates
    mkdir -p "${FINAL_INSTALL_DIR}/distribution"
    cat > "${FINAL_INSTALL_DIR}/distribution/policies.json" << 'EOF'
{
    "policies": {
        "ManualAppUpdateOnly": true
    }
}
EOF
    echo "[DEBUG] Created policies.json"
    
    echo "Firefox ${VERSION} installed successfully!"
    echo "Location: ${FINAL_INSTALL_DIR}"
    echo ""
    echo "To run Firefox ${VERSION}:"
    echo "  ./.fvm exec ${VERSION}"
    echo "  ./.fvm run ${VERSION} --new-window"
}

# Function to get latest installed version
get_latest_installed_version() {
    local INSTALL_DIR="${1:-$DEFAULT_INSTALL_DIR}"
    
    if [ -d "$INSTALL_DIR" ]; then
        for dir in "${INSTALL_DIR}"/firefox-*; do
            if [ -d "$dir" ] && [ -x "$dir/firefox" ]; then
                basename "$dir" | sed 's/firefox-//'
            fi
        done | sort -V | tail -n 1
    fi
}

# Function to execute Firefox
exec_firefox() {
    local VERSION="$1"
    shift
    local INSTALL_DIR="$DEFAULT_INSTALL_DIR"
    
    # If no version specified, run system Firefox
    if [ -z "$VERSION" ]; then
        echo "No version specified, using system Firefox..."
        firefox "$@"
        return $?
    fi
    
    # Expand tilde in installation directory
    INSTALL_DIR="${INSTALL_DIR/#\~/$HOME}"
    
    if ! is_firefox_installed "$VERSION" "$INSTALL_DIR"; then
        echo "Error: Firefox ${VERSION} is not installed."
        echo "Please install it first: ./.fvm install ${VERSION}"
        return 1
    fi
    
    local FIREFOX_DIR="$(get_firefox_path "$VERSION" "$INSTALL_DIR")"
    local PROFILE_DIR="${FIREFOX_DIR}/profile"
    echo "Executing Firefox ${VERSION} from ${FIREFOX_DIR}..."
    
    # Create profile directory if it doesn't exist
    mkdir -p "${PROFILE_DIR}"
    
    # Change to the Firefox directory and run with isolated environment
    cd "$FIREFOX_DIR"
    MOZ_ALLOW_DOWNGRADE=1 \
    MOZ_APP_LAUNCHER="$PWD/firefox" \
    MOZ_NO_REMOTE=1 \
    MOZ_DISABLE_AUTO_SAFE_MODE=1 \
    MOZ_LEGACY_PROFILES=1 \
    MOZILLA_DISABLE_PLUGINS_SCAN=1 \
    ./firefox -no-remote --allow-downgrade -profile "${PROFILE_DIR}" "$@"
}

# Function to run Firefox with arguments
run_firefox() {
    local VERSION="$1"
    shift
    local INSTALL_DIR="$DEFAULT_INSTALL_DIR"
    
    # Expand tilde in installation directory
    INSTALL_DIR="${INSTALL_DIR/#\~/$HOME}"
    
    if ! is_firefox_installed "$VERSION" "$INSTALL_DIR"; then
        echo "Error: Firefox ${VERSION} is not installed."
        echo "Please install it first: ./.fvm install ${VERSION}"
        return 1
    fi
    
    local FIREFOX_DIR="$(get_firefox_path "$VERSION" "$INSTALL_DIR")"
    local PROFILE_DIR="${FIREFOX_DIR}/profile"
    echo "Running Firefox ${VERSION} with arguments: $@"
    
    # Create profile directory if it doesn't exist
    mkdir -p "${PROFILE_DIR}"
    
    # Change to the Firefox directory and run with isolated environment
    cd "$FIREFOX_DIR"
    MOZ_ALLOW_DOWNGRADE=1 \
    MOZ_APP_LAUNCHER="$PWD/firefox" \
    MOZ_NO_REMOTE=1 \
    MOZ_DISABLE_AUTO_SAFE_MODE=1 \
    MOZ_LEGACY_PROFILES=1 \
    MOZILLA_DISABLE_PLUGINS_SCAN=1 \
    ./firefox -no-remote --allow-downgrade -profile "${PROFILE_DIR}" "$@"
}

# Function to uninstall Firefox
uninstall_firefox() {
    local VERSION="$1"
    local INSTALL_DIR="${2:-$DEFAULT_INSTALL_DIR}"
    
    # Expand tilde in installation directory
    INSTALL_DIR="${INSTALL_DIR/#\~/$HOME}"
    
    local FIREFOX_DIR="$(get_firefox_path "$VERSION" "$INSTALL_DIR")"
    
    if ! is_firefox_installed "$VERSION" "$INSTALL_DIR"; then
        echo "Error: Firefox ${VERSION} is not installed at ${FIREFOX_DIR}"
        return 1
    fi
    
    echo "Uninstalling Firefox ${VERSION} from ${FIREFOX_DIR}..."
    rm -rf "$FIREFOX_DIR"
    echo "Firefox ${VERSION} has been uninstalled successfully!"
}

# Function to list available versions from Mozilla's FTP server
list_available_versions() {
    echo "Fetching available Firefox versions..."
    
    # Check if we have curl
    if ! command -v curl &> /dev/null; then
        echo "Error: curl is not installed. Please install curl first."
        return 1
    fi
    
    # Create a temporary file for the HTML output
    TEMP_FILE=$(mktemp)
    
    # Fetch the directory listing
    echo "Downloading version list..."
    curl -s https://ftp.mozilla.org/pub/firefox/releases/ > "$TEMP_FILE"
    
    echo "Processing version list..."
    # Extract version numbers and filter for release versions
    cat "$TEMP_FILE" | \
    grep -o '<td><a href="/pub/firefox/releases/[^"]*/">' | \
    sed 's|<td><a href="/pub/firefox/releases/\([^/]*\)/">|\1|' | \
    grep -v '^\..' | \
    grep -E '^[0-9]+\.[0-9]+(\.[0-9]+)?$' | \
    sort -V
    
    # Clean up
    rm -f "$TEMP_FILE"

    echo ""
    echo "Note: This list shows release versions only. For beta/ESR versions, use:"
    echo "  ./.fvm list-remote --all"
}

# Function to list all available versions including beta/ESR
list_all_available_versions() {
    echo "Fetching all available Firefox versions (including beta/ESR)..."
    
    # Check if we have curl
    if ! command -v curl &> /dev/null; then
        echo "Error: curl is not installed. Please install curl first."
        return 1
    fi
    
    # Create a temporary file for the HTML output
    TEMP_FILE=$(mktemp)
    
    # Fetch the directory listing
    echo "Downloading version list..."
    curl -s https://ftp.mozilla.org/pub/firefox/releases/ > "$TEMP_FILE"
    
    echo "Processing version list..."
    # Extract all version numbers
    cat "$TEMP_FILE" | \
    grep -o '<td><a href="/pub/firefox/releases/[^"]*/">' | \
    sed 's|<td><a href="/pub/firefox/releases/\([^/]*\)/">|\1|' | \
    grep -v '^\..' | \
    sort -V
    
    # Clean up
    rm -f "$TEMP_FILE"
}

# Parse command line arguments
if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

COMMAND="$1"
shift

echo "[DEBUG] Command: $COMMAND, Remaining args: $@"

case "$COMMAND" in
    "install")
        install_firefox "$@"
        ;;
    "exec")
        VERSION=""
        if [ $# -gt 0 ]; then
            VERSION="$1"
            shift
        fi
        exec_firefox "$VERSION" "$@"
        ;;
    "run")
        if [ $# -eq 0 ]; then
            echo "Error: Version is required for run command"
            echo "Usage: ./.fvm run <version> [arguments...]"
            exit 1
        fi
        VERSION="$1"
        shift
        run_firefox "$VERSION" "$@"
        ;;
    "uninstall")
        if [ $# -eq 0 ]; then
            echo "Error: Version is required for uninstall command"
            echo "Usage: ./.fvm uninstall <version>"
            exit 1
        fi
        VERSION="$1"
        shift
        uninstall_firefox "$VERSION" "$@"
        ;;
    "list")
        list_installed_versions "$@"
        ;;
    "list-remote")
        if [ "$1" = "--all" ]; then
            list_all_available_versions
        else
            list_available_versions
        fi
        ;;
    "help"|"--help"|"-h")
        show_usage
        ;;
    *)
        echo "Error: Unknown command '$COMMAND'"
        show_usage
        exit 1
        ;;
esac 