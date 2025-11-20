#!/usr/bin/env python3
"""
CODITECT Framework Cross-Platform Installation Script

Works on Windows, macOS, and Linux with automatic platform detection.
Automates setup of Python virtual environment and dependencies for the
MEMORY-CONTEXT system and CODITECT framework.

Usage:
    python3 scripts/install.py              # Full installation
    python3 scripts/install.py --venv-only  # Only create venv
    python3 scripts/install.py --deps-only  # Only install dependencies

Author: AZ1.AI CODITECT Team
Sprint: Sprint +1 Week 2
Date: 2025-11-16
"""

import os
import sys
import subprocess
import platform
import shutil
from pathlib import Path
from typing import Optional, Tuple

# Colors for terminal output (cross-platform)
class Colors:
    """ANSI color codes that work on all platforms"""
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    BOLD = '\033[1m'
    NC = '\033[0m'  # No Color

    @classmethod
    def disable_on_windows(cls):
        """Disable colors on Windows if not supported"""
        if platform.system() == 'Windows' and not os.environ.get('ANSICON'):
            for attr in dir(cls):
                if not attr.startswith('_') and attr != 'disable_on_windows':
                    setattr(cls, attr, '')


class CrossPlatformInstaller:
    """Cross-platform installer for CODITECT framework"""

    def __init__(self):
        self.script_dir = Path(__file__).parent.absolute()
        self.project_root = self.script_dir.parent
        self.venv_path = self.project_root / "venv"
        self.os_type = platform.system()  # 'Windows', 'Darwin' (macOS), or 'Linux'

        # Disable colors on old Windows terminals
        if self.os_type == 'Windows':
            Colors.disable_on_windows()

    def get_python_executable(self) -> str:
        """Get the correct Python executable name for the platform"""
        if self.os_type == 'Windows':
            return 'python'  # Windows typically uses 'python' not 'python3'
        return 'python3'

    def get_venv_activation_command(self) -> str:
        """Get the correct venv activation command for the platform"""
        if self.os_type == 'Windows':
            return str(self.venv_path / 'Scripts' / 'activate.bat')
        return f'source {self.venv_path / "bin" / "activate"}'

    def get_venv_python(self) -> Path:
        """Get the Python executable inside venv"""
        if self.os_type == 'Windows':
            return self.venv_path / 'Scripts' / 'python.exe'
        return self.venv_path / 'bin' / 'python'

    def get_venv_pip(self) -> Path:
        """Get the pip executable inside venv"""
        if self.os_type == 'Windows':
            return self.venv_path / 'Scripts' / 'pip.exe'
        return self.venv_path / 'bin' / 'pip'

    def print_status(self, message: str):
        """Print success message"""
        print(f"{Colors.GREEN}✓{Colors.NC} {message}")

    def print_warning(self, message: str):
        """Print warning message"""
        print(f"{Colors.YELLOW}⚠{Colors.NC} {message}")

    def print_error(self, message: str):
        """Print error message"""
        print(f"{Colors.RED}✗{Colors.NC} {message}")

    def print_header(self):
        """Print installation header"""
        print(f"\n{Colors.BLUE}{'='*68}{Colors.NC}")
        print(f"{Colors.BLUE}CODITECT Framework Cross-Platform Installation{Colors.NC}")
        print(f"{Colors.BLUE}{'='*68}{Colors.NC}")
        print(f"\nPlatform: {self.os_type}")
        print()

    def check_python_version(self) -> Tuple[bool, str]:
        """Check if Python version is sufficient"""
        print(f"{Colors.BLUE}Checking Python version...{Colors.NC}")

        if sys.version_info < (3, 8):
            version = f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}"
            return False, f"Python 3.8+ required (found {version})"

        version = f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}"
        self.print_status(f"Python {version} detected")
        return True, version

    def create_venv(self, force_recreate: bool = False) -> bool:
        """Create virtual environment"""
        print(f"\n{Colors.BLUE}Creating virtual environment...{Colors.NC}\n")

        if self.venv_path.exists():
            if force_recreate:
                self.print_warning(f"Removing existing venv at {self.venv_path}")
                shutil.rmtree(self.venv_path)
            else:
                self.print_warning(f"Virtual environment already exists at {self.venv_path}")
                response = input("Do you want to recreate it? (y/N): ").strip().lower()
                if response == 'y':
                    print("Removing existing venv...")
                    shutil.rmtree(self.venv_path)
                else:
                    self.print_status("Using existing virtual environment")
                    return True

        try:
            # Create venv using current Python
            python_exe = self.get_python_executable()
            subprocess.run([python_exe, '-m', 'venv', str(self.venv_path)], check=True)
            self.print_status(f"Virtual environment created at {self.venv_path}")
            return True
        except subprocess.CalledProcessError as e:
            self.print_error(f"Failed to create virtual environment: {e}")
            return False

    def install_dependencies(self) -> bool:
        """Install dependencies from requirements.txt"""
        print(f"\n{Colors.BLUE}Installing dependencies...{Colors.NC}\n")

        # Check if venv exists
        if not self.venv_path.exists():
            self.print_error("Virtual environment not found. Run without --deps-only first.")
            return False

        try:
            venv_pip = str(self.get_venv_pip())
            venv_python = str(self.get_venv_python())

            # Upgrade pip first
            print("Upgrading pip...")
            subprocess.run(
                [venv_python, '-m', 'pip', 'install', '--upgrade', 'pip'],
                check=True,
                capture_output=True
            )
            self.print_status("pip upgraded")

            # Install requirements
            requirements_file = self.project_root / 'requirements.txt'
            if requirements_file.exists():
                print("Installing from requirements.txt...")
                subprocess.run(
                    [venv_pip, 'install', '-r', str(requirements_file)],
                    check=True
                )
                self.print_status("Dependencies installed from requirements.txt")
            else:
                self.print_warning("requirements.txt not found, skipping dependency installation")
                return True

            # Verify GitPython installation
            try:
                result = subprocess.run(
                    [venv_python, '-c', 'import git; print(git.__version__)'],
                    capture_output=True,
                    text=True,
                    check=True
                )
                version = result.stdout.strip()
                self.print_status(f"GitPython {version} installed (80x faster git operations)")
            except subprocess.CalledProcessError:
                self.print_warning("GitPython not installed - git operations will use subprocess fallback")

            return True

        except subprocess.CalledProcessError as e:
            self.print_error(f"Dependency installation failed: {e}")
            return False

    def print_next_steps(self):
        """Print next steps for the user"""
        print(f"\n{Colors.BLUE}{'='*68}{Colors.NC}")
        print(f"{Colors.GREEN}✓ Installation Complete!{Colors.NC}")
        print(f"{Colors.BLUE}{'='*68}{Colors.NC}\n")

        print(f"{Colors.YELLOW}Next steps:{Colors.NC}\n")

        print("1. Activate the virtual environment:")
        activation_cmd = self.get_venv_activation_command()
        if self.os_type == 'Windows':
            print(f"   {Colors.CYAN}{activation_cmd}{Colors.NC}")
        else:
            print(f"   {Colors.CYAN}{activation_cmd}{Colors.NC}")

        print("\n2. Run tests to verify installation:")
        venv_python = "python" if self.os_type == 'Windows' else "python3"
        print(f"   {Colors.CYAN}{venv_python} tests/core/test_memory_context_integration.py{Colors.NC}")
        print(f"   {Colors.CYAN}{venv_python} tests/core/test_performance_benchmarks.py{Colors.NC}")

        print("\n3. Deactivate when done:")
        print(f"   {Colors.CYAN}deactivate{Colors.NC}\n")

        print(f"{Colors.YELLOW}Performance tip:{Colors.NC}")
        print("  GitPython provides 80x faster git operations compared to subprocess.")
        print("  All git operations in MEMORY-CONTEXT system will automatically use GitPython.\n")

    def run(self, venv_only: bool = False, deps_only: bool = False) -> int:
        """Main installation flow"""
        self.print_header()

        # Check Python version
        success, message = self.check_python_version()
        if not success:
            self.print_error(message)
            return 1

        # Create virtual environment
        if not deps_only:
            if not self.create_venv():
                return 1

        # Install dependencies
        if not venv_only:
            if not self.install_dependencies():
                return 1

        # Print next steps
        self.print_next_steps()
        return 0


def main():
    """Entry point for the installer"""
    import argparse

    parser = argparse.ArgumentParser(
        description='CODITECT Framework Cross-Platform Installer',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python3 scripts/install.py              # Full installation
  python3 scripts/install.py --venv-only  # Only create venv
  python3 scripts/install.py --deps-only  # Only install dependencies

Supported Platforms:
  - Windows 10/11
  - macOS 10.15+ (Catalina and later)
  - Linux (Ubuntu, Debian, Fedora, etc.)

Requirements:
  - Python 3.8 or higher
  - pip (usually included with Python)
        """
    )

    parser.add_argument(
        '--venv-only',
        action='store_true',
        help='Only create virtual environment'
    )
    parser.add_argument(
        '--deps-only',
        action='store_true',
        help='Only install dependencies (assumes venv exists)'
    )

    args = parser.parse_args()

    # Validate arguments
    if args.venv_only and args.deps_only:
        print("Error: Cannot use --venv-only and --deps-only together")
        return 1

    # Run installer
    installer = CrossPlatformInstaller()
    return installer.run(venv_only=args.venv_only, deps_only=args.deps_only)


if __name__ == '__main__':
    sys.exit(main())
