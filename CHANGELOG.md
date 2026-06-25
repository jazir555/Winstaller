# Changelog

All notable changes to the UMU Game Installer project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **KDE Plasma 6 support** - Auto-detects Plasma version and uses correct paths
- Service menu support for both Plasma 5 and Plasma 6
- Forward compatibility: Installs to both locations on Plasma 5 for smooth upgrades
- `kbuildsycoca6` support in uninstaller
- KDE 6 migration guide (KDE6-MIGRATION.md)

### Planned
- GUI application (GTK/Qt frontend)
- Automatic dependency download from known URLs
- Game icon extraction from executables
- Binary shortcuts.vdf integration for better Steam support
- Automated game uninstaller script generation
- Save game location detection and backup
- Cloud save integration (Steam Cloud, GOG Galaxy)
- Web-based management interface
- Game update detection
- Performance profiling tools

## [1.0.0] - 2024-01-15

### Added
- Initial release of UMU Game Installer
- Core installation workflow with GUI installer support
- Automatic dependency detection for:
  - Visual C++ Redistributables (2010-2022)
  - .NET Framework (3.5-4.8)
  - DirectX (9, 11, 12)
- Global dependency management with zero-duplication storage
- Dependency database (deps.db) for tracking installed libraries
- Game database (games.db) for tracking installed games
- Wine prefix creation and management
- Automatic game executable detection with intelligent filtering
- Steam integration via .desktop files
- Desktop shortcut creation
- Launch script generation with proper environment variables
- UMU Game Manager utility for:
  - Listing installed games and dependencies
  - Launching games
  - Uninstalling games
  - Showing game information
  - Disk usage analysis
  - Orphaned file cleanup
  - Game list export
- Comprehensive documentation:
  - README.md with full feature documentation
  - INSTALL.md with step-by-step installation guide
  - EXAMPLES.md with real-world usage scenarios
  - TESTING.md with testing procedures
  - QUICK_REFERENCE.md for command reference
  - ARCHITECTURE.md with system design documentation
  - PROJECT_SUMMARY.md with project overview
- Configuration file support (umu-installer.conf)
- Colored terminal output for better UX
- Error handling and logging
- Support for multiple installer types (InstallShield, Inno Setup, NSIS, MSI)

### Technical Details
- Written in Bash for maximum compatibility
- Requires umu-run for Wine/Proton integration
- Works on SteamOS, Arch, Ubuntu, Fedora
- No root/sudo required (user-space only)
- Uses simple pipe-delimited databases for easy inspection
- Symlink-based dependency sharing for storage efficiency

### Known Issues
- No automatic game uninstaller (manual process documented)
- Generic icon used (no executable icon extraction yet)
- Limited shortcuts.vdf integration (uses .desktop files instead)
- No automatic game update detection
- English-only interface
- No GUI application (CLI only)

## [0.9.0] - 2024-01-10 (Beta)

### Added
- Beta release for community testing
- Basic installation workflow
- Manual dependency management
- Simple game database
- Basic Steam integration

### Fixed
- Dependency detection patterns
- Executable detection filtering
- Wine prefix initialization issues

### Changed
- Improved error messages
- Better logging output
- Simplified configuration

## [0.5.0] - 2024-01-05 (Alpha)

### Added
- Alpha release for initial testing
- Proof of concept installer
- Manual game launching
- Basic dependency installation

### Known Issues
- No automatic dependency detection
- Manual Steam integration required
- Limited error handling
- No game management tools

## Development Guidelines

### Version Number Scheme

- **Major (X.0.0)**: Breaking changes, major feature additions
- **Minor (0.X.0)**: New features, non-breaking changes
- **Patch (0.0.X)**: Bug fixes, documentation updates

### Change Categories

- **Added**: New features
- **Changed**: Changes to existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Removed features
- **Fixed**: Bug fixes
- **Security**: Security improvements

## Release Process

1. Update version in scripts (`SCRIPT_VERSION` variable)
2. Update CHANGELOG.md with changes
3. Test on target platforms (SteamOS, Arch, Ubuntu)
4. Create git tag: `git tag -a v1.0.0 -m "Release version 1.0.0"`
5. Push tag: `git push origin v1.0.0`
6. Create GitHub release with binaries and documentation
7. Update documentation links if needed

## Migration Notes

### From 0.x to 1.0

No migration needed - fresh install recommended.

If upgrading from beta:
```bash
# Backup existing data
tar -czf umu-backup.tar.gz ~/.config/umu-game-installer/

# Remove old version
rm -rf ~/.config/umu-game-installer/

# Install new version
curl -O https://raw.githubusercontent.com/.../umu-game-installer.sh
chmod +x umu-game-installer.sh

# Initialize
./umu-game-installer.sh --help

# Restore game data (optional)
# Note: May require manual database updates
```

## Contributors

Thanks to all contributors who have helped improve this project!

- Initial development and release
- Community testing and feedback
- Documentation improvements
- Bug reports and feature requests

## Links

- GitHub Repository: https://github.com/yourusername/umu-game-installer
- Issue Tracker: https://github.com/yourusername/umu-game-installer/issues
- Documentation: https://github.com/yourusername/umu-game-installer/wiki
- umu-run Project: https://github.com/Open-Wine-Components/umu-launcher

---

[Unreleased]: https://github.com/yourusername/umu-game-installer/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/yourusername/umu-game-installer/releases/tag/v1.0.0
[0.9.0]: https://github.com/yourusername/umu-game-installer/releases/tag/v0.9.0
[0.5.0]: https://github.com/yourusername/umu-game-installer/releases/tag/v0.5.0
