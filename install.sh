#!/usr/bin/env bash

# Firefox Version Manager (fvm) installer
# This script downloads and installs the fvm script

set -e # Exit on any error

FVM_INSTALL_DIR="${FVM_INSTALL_DIR:-$HOME/.fvm}"
FVM_SCRIPT_URL="https://raw.githubusercontent.com/yourusername/fvm/main/.fvm"

# Function to check if command exists
has_command() {
    command -v "$1" >/dev/null 2>&1
}

# Check required dependencies
if ! has_command curl && ! has_command wget; then
    echo "Error: curl or wget is required to download fvm"
    exit 1
fi

# Create install directory
mkdir -p "$FVM_INSTALL_DIR"

echo "Installing fvm to $FVM_INSTALL_DIR..."

# Download fvm script
if has_command curl; then
    curl -o "$FVM_INSTALL_DIR/fvm" "$FVM_SCRIPT_URL"
else
    wget -O "$FVM_INSTALL_DIR/fvm" "$FVM_SCRIPT_URL" 
fi

# Make script executable
chmod +x "$FVM_INSTALL_DIR/fvm"

# Add to PATH if not already there
PROFILE=""
if [ -f "$HOME/.bashrc" ]; then
    PROFILE="$HOME/.bashrc"
elif [ -f "$HOME/.zshrc" ]; then
    PROFILE="$HOME/.zshrc"
fi

if [ -n "$PROFILE" ]; then
    echo "Adding fvm to PATH in $PROFILE"
    echo "" >> "$PROFILE"
    echo "# fvm" >> "$PROFILE"
    echo "export PATH=\"\$PATH:$FVM_INSTALL_DIR\"" >> "$PROFILE"
    echo "Reload your shell or run: source $PROFILE"
else
    echo "Please manually add $FVM_INSTALL_DIR to your PATH"
fi

echo "fvm has been installed successfully!"
echo "Run 'fvm help' to get started"
