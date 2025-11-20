#!/usr/bin/env python3
"""
CODITECT Framework Installer Launcher

Universal launcher that automatically detects environment and launches
the appropriate installer (GUI or CLI).

Features:
- Auto-detects if GUI (tkinter) is available
- Falls back to CLI if GUI unavailable
- Handles command-line arguments for both modes
- Cross-platform support (Windows, macOS, Linux)

Usage:
    # Auto-detect and launch appropriate installer
    python3 scripts/installer/launch.py

    # Force GUI mode
    python3 scripts/installer/launch.py --gui

    # Force CLI mode
    python3 scripts/installer/launch.py --cli

    # CLI options (when in CLI mode)
    python3 scripts/installer/launch.py --cli --venv-only
    python3 scripts/installer/launch.py --cli --deps-only

Author: AZ1.AI CODITECT Team
Sprint: Sprint +1 Week 2
Date: 2025-11-16
"""

import sys
import argparse
from pathlib import Path

# Add installer package to path
INSTALLER_DIR = Path(__file__).parent
sys.path.insert(0, str(INSTALLER_DIR))


def check_gui_available() -> bool:
    """Check if GUI (tkinter) is available"""
    try:
        import tkinter
        return True
    except ImportError:
        return False


def launch_gui():
    """Launch GUI installer"""
    print("Launching GUI installer...")
    try:
        import install_gui
        install_gui.main()
    except Exception as e:
        print(f"Failed to launch GUI installer: {e}")
        print("\nFalling back to CLI installer...")
        launch_cli()


def launch_cli(venv_only=False, deps_only=False):
    """Launch CLI installer"""
    print("Launching CLI installer...")
    try:
        from install import CrossPlatformInstaller

        installer = CrossPlatformInstaller()
        exit_code = installer.run(venv_only=venv_only, deps_only=deps_only)
        sys.exit(exit_code)
    except Exception as e:
        print(f"Failed to launch CLI installer: {e}")
        sys.exit(1)


def print_banner():
    """Print welcome banner"""
    print()
    print("=" * 70)
    print("CODITECT Framework Installer")
    print("=" * 70)
    print()


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description='CODITECT Framework Universal Installer Launcher',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python3 scripts/installer/launch.py           # Auto-detect GUI/CLI
  python3 scripts/installer/launch.py --gui     # Force GUI mode
  python3 scripts/installer/launch.py --cli     # Force CLI mode

  python3 scripts/installer/launch.py --cli --venv-only  # CLI: venv only
  python3 scripts/installer/launch.py --cli --deps-only  # CLI: deps only

GUI Mode:
  Launches modern graphical installer with progress tracking and logs.

CLI Mode:
  Launches command-line installer with automation-friendly output.

Auto Mode (default):
  Attempts GUI first, falls back to CLI if tkinter unavailable.
        """
    )

    # Mode selection
    mode_group = parser.add_mutually_exclusive_group()
    mode_group.add_argument(
        '--gui',
        action='store_true',
        help='Force GUI mode (requires tkinter)'
    )
    mode_group.add_argument(
        '--cli',
        action='store_true',
        help='Force CLI mode'
    )

    # CLI options (only used in CLI mode)
    parser.add_argument(
        '--venv-only',
        action='store_true',
        help='CLI: Only create virtual environment'
    )
    parser.add_argument(
        '--deps-only',
        action='store_true',
        help='CLI: Only install dependencies (assumes venv exists)'
    )

    args = parser.parse_args()

    # Validate CLI options
    if (args.venv_only or args.deps_only) and not args.cli:
        print("Error: --venv-only and --deps-only require --cli mode")
        return 1

    if args.venv_only and args.deps_only:
        print("Error: Cannot use --venv-only and --deps-only together")
        return 1

    # Print banner
    print_banner()

    # Launch appropriate installer
    if args.gui:
        # Force GUI mode
        if not check_gui_available():
            print("Error: GUI mode requested but tkinter not available")
            print("\nInstall tkinter:")
            print("  Ubuntu/Debian: sudo apt-get install python3-tk")
            print("  Fedora: sudo dnf install python3-tkinter")
            print("  macOS: tkinter should be included with Python")
            print("  Windows: tkinter should be included with Python")
            return 1
        launch_gui()

    elif args.cli:
        # Force CLI mode
        launch_cli(venv_only=args.venv_only, deps_only=args.deps_only)

    else:
        # Auto-detect mode
        if check_gui_available():
            print("✓ GUI available - launching graphical installer")
            print("  (Use --cli flag to force command-line mode)")
            print()
            launch_gui()
        else:
            print("ℹ GUI not available - launching command-line installer")
            print("  (Install tkinter for graphical installer)")
            print()
            launch_cli()

    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\n\nInstallation cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n\nUnexpected error: {e}")
        sys.exit(1)
