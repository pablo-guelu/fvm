#!/usr/bin/env bash

# Test script for Firefox Version Manager (fvm)
# This script demonstrates the basic functionality of fvm

set -e

echo "=== Firefox Version Manager (fvm) Test ==="
echo

# Source fvm
if [ -f "./fvm.sh" ]; then
    source ./fvm.sh
else
    echo "Error: fvm.sh not found in current directory"
    exit 1
fi

echo "1. Testing help command:"
show_usage
echo

echo "2. Testing list-remote command:"
echo "Fetching first 10 remote versions..."
list_remote_versions | head -10
echo

echo "3. Testing install command:"
echo "Installing Firefox 50.0..."
install_firefox "50.0"
echo

echo "4. Testing list command:"
echo "Listing installed versions:"
list_installed_versions
echo

echo "5. Testing exec command:"
echo "Executing Firefox 50.0..."
exec_firefox "50.0" "--version"
echo

echo "6. Testing run command:"
echo "Running Firefox 50.0 with --new-window..."
run_firefox "50.0" "--new-window"
echo

echo "7. Testing uninstall command:"
echo "Uninstalling Firefox 50.0..."
uninstall_firefox "50.0"
echo

echo "=== Test completed ==="
echo
echo "Basic functionality tests completed."
echo "For manual testing, try:"
echo "  ./fvm.sh install 50.0"
echo "  ./fvm.sh exec 50.0"
echo "  ./fvm.sh run 50.0 --new-window"
echo
echo "Note: Installing Firefox versions requires ~50MB+ download per version"