# Firefox Version Manager (fvm)

A simple version manager for Firefox that allows you to easily install, switch between, and manage different Firefox versions from the command line on Linux systems.

## Features

- **Install Firefox versions**: Download and install specific Firefox versions or the latest release
- **Run specific versions**: Execute Firefox with specific versions in isolated environments
- **List installed versions**: See what Firefox versions you have installed
- **List remote versions**: Browse available Firefox versions from Mozilla's FTP servers
- **Isolated profiles**: Each version runs with its own isolated profile directory
- **Auto-update disabled**: Each installation has updates disabled by default
- **Environment isolation**: Runs each version with proper Mozilla environment variables
- **POSIX-compliant**: Works with bash and other POSIX-compliant shells

## Installation

### Prerequisites

The following tools are required:
- `curl` or `wget` for downloading files
- `tar` for extracting Firefox archives
- `file` command for identifying archive types

### Quick Install

```bash
curl -o- https://raw.githubusercontent.com/pablo-guelu/fvm/main/install.sh | bash
```

This will:
1. Install fvm to `$HOME/.fvm` by default
2. Add fvm to your PATH in `.bashrc` or `.zshrc`
3. Make the script executable

You can customize the installation directory where diffrent versions of Firefox are installed by setting `FVM_INSTALL_DIR`:

```bash
FVM_INSTALL_DIR=/custom/path curl -o- https://raw.githubusercontent.com/pablo-guelu/fvm/main/install.sh | bash
```

### Manual Install

1. Clone the repository:
```bash
git clone https://github.com/pablo-guelu/fvm.git
cd fvm
```

2. Make the script executable:
```bash
chmod +x fvm.sh
```

## Usage

### Basic Commands

```bash
# Install latest Firefox version
./fvm.sh install

# Install specific Firefox version
./fvm.sh install 50.0

# Execute Firefox version
./fvm.sh exec 50.0

# Run Firefox with arguments
./fvm.sh run 50.0 --new-window

# List installed versions
./fvm.sh list

# List available versions (release only)
./fvm.sh list-remote

# List all versions (including beta/ESR)
./fvm.sh list-remote --all

# Uninstall a version
./fvm.sh uninstall 50.0

# Show help
./fvm.sh help
```

### Environment Variables

- `FVM_INSTALL_PATH`: Override default installation path (default: `$HOME`)

### Installation Directory Structure

Each Firefox version is installed in its own directory:
```
$FVM_INSTALL_PATH/
  └── firefox-50.0/
      ├── firefox (executable)
      ├── profile/ (isolated profile directory)
      └── distribution/
          └── policies.json (update policies)
```

### Version Isolation

Each Firefox version:
- Has its own profile directory to prevent conflicts
- Runs with updates disabled via `policies.json`
- Uses proper Mozilla environment variables for isolation:
  - `MOZ_NO_REMOTE=1`
  - `MOZ_ALLOW_DOWNGRADE=1`
  - `MOZ_DISABLE_AUTO_SAFE_MODE=1`
  - And more...

## Testing

A test script is included to verify basic functionality:

```bash
./test_fvm.sh
```

This will test:
1. Help command
2. Remote version listing
3. Installation
4. Version listing
5. Execution
6. Running with arguments
7. Uninstallation

Note: Testing requires downloading Firefox (~50MB+ per version).

## Notes

- Firefox versions are downloaded from Mozilla's official FTP servers
- Each version is installed with its own isolated profile
- Updates are disabled by default through `policies.json`
- The script requires write permissions to the installation directory

