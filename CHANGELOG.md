# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2024-03-20

### Added
- Initial release of Firefox Version Manager
- Basic version management commands:
  - `install`: Install Firefox versions (latest or specific)
  - `exec`: Execute Firefox versions
  - `run`: Run Firefox with arguments
  - `uninstall`: Remove installed versions
  - `list`: Show installed versions
  - `list-remote`: Browse available versions
  - `version`: Display fvm version
- Version existence checking before installation
- Improved error handling and cleanup
- Support for latest Firefox releases
- Support for specific Firefox versions
- Isolated profile directories per version
- Auto-update disabled via policies.json
- Environment isolation with Mozilla variables
- Custom installation directory support
- POSIX-compliant shell script
- Documentation and usage examples

[0.1.0]: https://github.com/pablo-guelu/fvm/releases/tag/v0.1.0 