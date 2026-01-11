#!/bin/sh
# Athyr Install Script
# Usage: curl -sSL https://athyr.tech/install.sh | sh
#
# Environment variables:
#   ATHYR_VERSION  - Version to install (default: latest)
#   ATHYR_INSTALL  - Installation directory (default: /usr/local/bin or ~/.local/bin)
#   ATHYR_EDITION  - Edition to install: free or enterprise (default: free)

set -e

# Colors (disabled if not a terminal)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Configuration
GITHUB_REPO="athyr-tech/athyr-bin"
BINARY_NAME="athyr"

info() {
    printf "${BLUE}info${NC}: %s\n" "$1"
}

success() {
    printf "${GREEN}success${NC}: %s\n" "$1"
}

warn() {
    printf "${YELLOW}warning${NC}: %s\n" "$1"
}

error() {
    printf "${RED}error${NC}: %s\n" "$1" >&2
    exit 1
}

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Linux*)  echo "linux" ;;
        Darwin*) echo "darwin" ;;
        *)       error "Unsupported operating system: $(uname -s)" ;;
    esac
}

# Detect architecture
detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64)  echo "amd64" ;;
        aarch64|arm64) echo "arm64" ;;
        *)             error "Unsupported architecture: $(uname -m)" ;;
    esac
}

# Get latest version from GitHub
get_latest_version() {
    if command -v curl > /dev/null 2>&1; then
        curl -sSL "https://api.github.com/repos/${GITHUB_REPO}/releases/latest" | \
            grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
    elif command -v wget > /dev/null 2>&1; then
        wget -qO- "https://api.github.com/repos/${GITHUB_REPO}/releases/latest" | \
            grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
    else
        error "Neither curl nor wget found. Please install one of them."
    fi
}

# Download file
download() {
    url="$1"
    output="$2"

    if command -v curl > /dev/null 2>&1; then
        curl -fsSL "$url" -o "$output"
    elif command -v wget > /dev/null 2>&1; then
        wget -q "$url" -O "$output"
    else
        error "Neither curl nor wget found. Please install one of them."
    fi
}

# Verify checksum
verify_checksum() {
    file="$1"
    expected="$2"

    if command -v sha256sum > /dev/null 2>&1; then
        actual=$(sha256sum "$file" | cut -d' ' -f1)
    elif command -v shasum > /dev/null 2>&1; then
        actual=$(shasum -a 256 "$file" | cut -d' ' -f1)
    else
        warn "Neither sha256sum nor shasum found. Skipping checksum verification."
        return 0
    fi

    if [ "$actual" != "$expected" ]; then
        error "Checksum verification failed!\nExpected: $expected\nActual:   $actual"
    fi
}

# Determine install directory
get_install_dir() {
    if [ -n "$ATHYR_INSTALL" ]; then
        echo "$ATHYR_INSTALL"
    elif [ -w "/usr/local/bin" ]; then
        echo "/usr/local/bin"
    else
        mkdir -p "$HOME/.local/bin"
        echo "$HOME/.local/bin"
    fi
}

# Main installation
main() {
    info "Installing Athyr..."

    # Detect platform
    OS=$(detect_os)
    ARCH=$(detect_arch)
    info "Detected platform: ${OS}/${ARCH}"

    # Determine version
    VERSION="${ATHYR_VERSION:-}"
    if [ -z "$VERSION" ]; then
        info "Fetching latest version..."
        VERSION=$(get_latest_version)
        if [ -z "$VERSION" ]; then
            error "Failed to determine latest version. Set ATHYR_VERSION manually."
        fi
    fi
    info "Version: ${VERSION}"

    # Determine edition
    EDITION="${ATHYR_EDITION:-free}"
    if [ "$EDITION" = "enterprise" ]; then
        ARCHIVE_NAME="athyr-enterprise_${VERSION#v}_${OS}_${ARCH}.tar.gz"
    else
        ARCHIVE_NAME="athyr_${VERSION#v}_${OS}_${ARCH}.tar.gz"
    fi
    info "Edition: ${EDITION}"

    # Create temp directory
    TMP_DIR=$(mktemp -d)
    trap "rm -rf '$TMP_DIR'" EXIT

    # Download binary
    DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/${VERSION}/${ARCHIVE_NAME}"
    info "Downloading ${DOWNLOAD_URL}..."
    download "$DOWNLOAD_URL" "${TMP_DIR}/${ARCHIVE_NAME}" || \
        error "Failed to download binary. Check if version ${VERSION} exists."

    # Download checksums
    CHECKSUMS_URL="https://github.com/${GITHUB_REPO}/releases/download/${VERSION}/checksums.txt"
    info "Downloading checksums..."
    download "$CHECKSUMS_URL" "${TMP_DIR}/checksums.txt" || \
        warn "Failed to download checksums. Skipping verification."

    # Verify checksum
    if [ -f "${TMP_DIR}/checksums.txt" ]; then
        EXPECTED_SUM=$(grep "${ARCHIVE_NAME}" "${TMP_DIR}/checksums.txt" | cut -d' ' -f1)
        if [ -n "$EXPECTED_SUM" ]; then
            info "Verifying checksum..."
            verify_checksum "${TMP_DIR}/${ARCHIVE_NAME}" "$EXPECTED_SUM"
            success "Checksum verified"
        fi
    fi

    # Extract binary
    info "Extracting..."
    tar -xzf "${TMP_DIR}/${ARCHIVE_NAME}" -C "$TMP_DIR"

    # Find the binary (it might be in a subdirectory or root)
    if [ "$EDITION" = "enterprise" ]; then
        BINARY_FILE=$(find "$TMP_DIR" -name "athyr-enterprise" -type f | head -1)
        TARGET_NAME="athyr"  # Install as 'athyr' regardless of edition
    else
        BINARY_FILE=$(find "$TMP_DIR" -name "athyr" -type f | head -1)
        TARGET_NAME="athyr"
    fi

    if [ -z "$BINARY_FILE" ]; then
        error "Binary not found in archive"
    fi

    # Install
    INSTALL_DIR=$(get_install_dir)
    info "Installing to ${INSTALL_DIR}..."

    if [ -w "$INSTALL_DIR" ]; then
        cp "$BINARY_FILE" "${INSTALL_DIR}/${TARGET_NAME}"
        chmod +x "${INSTALL_DIR}/${TARGET_NAME}"
    else
        info "Requesting sudo access to install to ${INSTALL_DIR}..."
        sudo cp "$BINARY_FILE" "${INSTALL_DIR}/${TARGET_NAME}"
        sudo chmod +x "${INSTALL_DIR}/${TARGET_NAME}"
    fi

    # Verify installation
    if [ -x "${INSTALL_DIR}/${TARGET_NAME}" ]; then
        success "Athyr installed successfully!"
        echo ""
        "${INSTALL_DIR}/${TARGET_NAME}" --version
        echo ""

        # Check if install dir is in PATH
        case ":$PATH:" in
            *":${INSTALL_DIR}:"*) ;;
            *)
                warn "${INSTALL_DIR} is not in your PATH"
                echo ""
                echo "Add it to your shell profile:"
                echo "  export PATH=\"${INSTALL_DIR}:\$PATH\""
                echo ""
                ;;
        esac

        echo "Get started:"
        echo "  athyr serve              # Start the server"
        echo "  athyr --help             # Show all commands"
        echo ""
        echo "Documentation: https://athyr.tech/docs"
    else
        error "Installation failed"
    fi
}

main "$@"
