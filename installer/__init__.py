"""
CODITECT Framework Installer Package

Cross-platform installation system for Windows, macOS, and Linux.

Modules:
- install.py - CLI installer with automated setup
- install_gui.py - GUI installer with modern interface
- install.sh - Bash installer (Unix/Linux/macOS only)

Usage:
    # GUI installer (recommended for users)
    python3 -m installer.gui

    # CLI installer (recommended for automation)
    python3 -m installer.cli

    # Direct execution
    python3 scripts/installer/install_gui.py
    python3 scripts/installer/install.py

Author: AZ1.AI CODITECT Team
Sprint: Sprint +1 Week 2
Date: 2025-11-16
"""

__version__ = "1.0.0"
__author__ = "AZ1.AI CODITECT Team"
__all__ = ["CrossPlatformInstaller"]

from .install import CrossPlatformInstaller
