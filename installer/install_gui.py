#!/usr/bin/env python3
"""
CODITECT Framework GUI Installer

Modern graphical installer for Windows, macOS, and Linux.
Wraps the cross-platform CLI installer (install.py) with a user-friendly GUI.

Features:
- Platform detection and display
- Real-time progress tracking
- Installation logs viewer
- Error handling with user-friendly messages
- Success notifications

Usage:
    python3 scripts/install_gui.py

Requirements:
    - Python 3.8+
    - tkinter (included with most Python installations)

Author: AZ1.AI CODITECT Team
Sprint: Sprint +1 Week 2
Date: 2025-11-16
"""

import os
import sys
import subprocess
import platform
import threading
import queue
from pathlib import Path
from typing import Optional

# Import tkinter with error handling
try:
    import tkinter as tk
    from tkinter import ttk, scrolledtext, messagebox
except ImportError:
    print("Error: tkinter not found. Please install tkinter:")
    print("  Ubuntu/Debian: sudo apt-get install python3-tk")
    print("  Fedora: sudo dnf install python3-tkinter")
    print("  macOS: tkinter should be included with Python")
    print("  Windows: tkinter should be included with Python")
    sys.exit(1)

# Import the CLI installer
sys.path.insert(0, str(Path(__file__).parent))
from install import CrossPlatformInstaller


class InstallerGUI:
    """Modern GUI installer for CODITECT framework"""

    def __init__(self, root):
        self.root = root
        self.root.title("CODITECT Framework Installer")
        self.root.geometry("700x600")
        self.root.resizable(False, False)

        # Platform detection
        self.os_type = platform.system()
        self.os_version = platform.release()

        # Installation state
        self.installing = False
        self.installation_complete = False

        # Thread communication
        self.message_queue = queue.Queue()

        # Build UI
        self._create_ui()

        # Start message processor
        self.root.after(100, self._process_messages)

    def _create_ui(self):
        """Create the user interface"""

        # Header Section
        header_frame = tk.Frame(self.root, bg="#2563eb", height=120)
        header_frame.pack(fill=tk.X, padx=0, pady=0)
        header_frame.pack_propagate(False)

        title_label = tk.Label(
            header_frame,
            text="CODITECT Framework",
            font=("Helvetica", 24, "bold"),
            bg="#2563eb",
            fg="white"
        )
        title_label.pack(pady=(20, 5))

        subtitle_label = tk.Label(
            header_frame,
            text="Cross-Platform Installation Wizard",
            font=("Helvetica", 12),
            bg="#2563eb",
            fg="#dbeafe"
        )
        subtitle_label.pack()

        # Platform Info Section
        info_frame = tk.Frame(self.root, bg="#f3f4f6", height=80)
        info_frame.pack(fill=tk.X, padx=20, pady=(20, 10))
        info_frame.pack_propagate(False)

        platform_label = tk.Label(
            info_frame,
            text=f"Platform: {self.os_type} {self.os_version}",
            font=("Helvetica", 11),
            bg="#f3f4f6",
            fg="#374151"
        )
        platform_label.pack(anchor=tk.W, padx=15, pady=(15, 5))

        python_version = f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}"
        python_label = tk.Label(
            info_frame,
            text=f"Python: {python_version}",
            font=("Helvetica", 11),
            bg="#f3f4f6",
            fg="#374151"
        )
        python_label.pack(anchor=tk.W, padx=15)

        # Progress Section
        progress_frame = tk.Frame(self.root)
        progress_frame.pack(fill=tk.X, padx=20, pady=10)

        self.progress_label = tk.Label(
            progress_frame,
            text="Ready to install",
            font=("Helvetica", 10),
            fg="#6b7280"
        )
        self.progress_label.pack(anchor=tk.W, pady=(0, 5))

        self.progress_bar = ttk.Progressbar(
            progress_frame,
            mode='indeterminate',
            length=660
        )
        self.progress_bar.pack()

        # Log Section
        log_frame = tk.Frame(self.root)
        log_frame.pack(fill=tk.BOTH, expand=True, padx=20, pady=10)

        log_label = tk.Label(
            log_frame,
            text="Installation Log:",
            font=("Helvetica", 10, "bold"),
            fg="#374151"
        )
        log_label.pack(anchor=tk.W, pady=(0, 5))

        self.log_text = scrolledtext.ScrolledText(
            log_frame,
            height=12,
            font=("Courier", 9),
            bg="#1f2937",
            fg="#e5e7eb",
            insertbackground="#e5e7eb",
            state=tk.DISABLED
        )
        self.log_text.pack(fill=tk.BOTH, expand=True)

        # Buttons Section
        button_frame = tk.Frame(self.root)
        button_frame.pack(fill=tk.X, padx=20, pady=(10, 20))

        self.install_button = tk.Button(
            button_frame,
            text="Install",
            command=self._start_installation,
            font=("Helvetica", 11, "bold"),
            bg="#2563eb",
            fg="white",
            activebackground="#1d4ed8",
            activeforeground="white",
            relief=tk.FLAT,
            padx=30,
            pady=10,
            cursor="hand2"
        )
        self.install_button.pack(side=tk.LEFT, padx=(0, 10))

        self.close_button = tk.Button(
            button_frame,
            text="Close",
            command=self._close_application,
            font=("Helvetica", 11),
            bg="#6b7280",
            fg="white",
            activebackground="#4b5563",
            activeforeground="white",
            relief=tk.FLAT,
            padx=30,
            pady=10,
            cursor="hand2"
        )
        self.close_button.pack(side=tk.RIGHT)

        # Initial log message
        self._log_message("Welcome to the CODITECT Framework Installer!")
        self._log_message(f"Detected platform: {self.os_type} {self.os_version}")
        self._log_message(f"Python version: {python_version}")
        self._log_message("")
        self._log_message("Click 'Install' to begin setup.")

    def _log_message(self, message: str):
        """Add message to log display"""
        self.log_text.config(state=tk.NORMAL)
        self.log_text.insert(tk.END, message + "\n")
        self.log_text.see(tk.END)
        self.log_text.config(state=tk.DISABLED)

    def _update_progress(self, message: str):
        """Update progress label"""
        self.progress_label.config(text=message)

    def _start_installation(self):
        """Start the installation process"""
        if self.installing:
            return

        # Disable install button
        self.install_button.config(state=tk.DISABLED, bg="#9ca3af")

        # Reset state
        self.installing = True
        self.installation_complete = False

        # Clear log
        self.log_text.config(state=tk.NORMAL)
        self.log_text.delete(1.0, tk.END)
        self.log_text.config(state=tk.DISABLED)

        # Start progress animation
        self.progress_bar.start(10)

        # Run installation in separate thread
        install_thread = threading.Thread(target=self._run_installation, daemon=True)
        install_thread.start()

    def _run_installation(self):
        """Run installation in background thread"""
        try:
            self.message_queue.put(("log", "Starting installation..."))
            self.message_queue.put(("log", ""))

            # Check Python version
            self.message_queue.put(("progress", "Checking Python version..."))
            self.message_queue.put(("log", "Checking Python version..."))

            if sys.version_info < (3, 8):
                version = f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}"
                self.message_queue.put(("error", f"Python 3.8+ required (found {version})"))
                return

            self.message_queue.put(("log", "✓ Python version OK"))
            self.message_queue.put(("log", ""))

            # Create virtual environment
            self.message_queue.put(("progress", "Creating virtual environment..."))
            self.message_queue.put(("log", "Creating virtual environment..."))

            installer = CrossPlatformInstaller()
            if not installer.create_venv():
                self.message_queue.put(("error", "Failed to create virtual environment"))
                return

            self.message_queue.put(("log", "✓ Virtual environment created"))
            self.message_queue.put(("log", ""))

            # Install dependencies
            self.message_queue.put(("progress", "Installing dependencies..."))
            self.message_queue.put(("log", "Installing dependencies..."))

            if not installer.install_dependencies():
                self.message_queue.put(("error", "Failed to install dependencies"))
                return

            self.message_queue.put(("log", "✓ Dependencies installed"))
            self.message_queue.put(("log", ""))

            # Success
            self.message_queue.put(("success", "Installation complete!"))

        except Exception as e:
            self.message_queue.put(("error", f"Installation failed: {str(e)}"))

    def _process_messages(self):
        """Process messages from installation thread"""
        try:
            while True:
                message_type, message = self.message_queue.get_nowait()

                if message_type == "log":
                    self._log_message(message)
                elif message_type == "progress":
                    self._update_progress(message)
                elif message_type == "success":
                    self._installation_success(message)
                elif message_type == "error":
                    self._installation_error(message)

        except queue.Empty:
            pass

        # Schedule next check
        self.root.after(100, self._process_messages)

    def _installation_success(self, message: str):
        """Handle successful installation"""
        self.installing = False
        self.installation_complete = True

        # Stop progress bar
        self.progress_bar.stop()
        self.progress_bar.config(mode='determinate', value=100)

        # Update UI
        self._update_progress(message)
        self._log_message("")
        self._log_message("=" * 68)
        self._log_message("✓ Installation Complete!")
        self._log_message("=" * 68)
        self._log_message("")

        installer = CrossPlatformInstaller()
        activation_cmd = installer.get_venv_activation_command()

        self._log_message("Next steps:")
        self._log_message("")
        self._log_message("1. Activate the virtual environment:")
        self._log_message(f"   {activation_cmd}")
        self._log_message("")
        self._log_message("2. Run tests to verify installation:")
        if self.os_type == 'Windows':
            self._log_message("   python tests/core/test_memory_context_integration.py")
        else:
            self._log_message("   python3 tests/core/test_memory_context_integration.py")
        self._log_message("")
        self._log_message("3. Deactivate when done:")
        self._log_message("   deactivate")

        # Show success dialog
        messagebox.showinfo(
            "Installation Complete",
            "CODITECT Framework has been installed successfully!\n\n"
            "See the log for next steps."
        )

        # Change button text
        self.install_button.config(
            text="Reinstall",
            state=tk.NORMAL,
            bg="#2563eb"
        )

    def _installation_error(self, message: str):
        """Handle installation error"""
        self.installing = False

        # Stop progress bar
        self.progress_bar.stop()

        # Update UI
        self._update_progress("Installation failed")
        self._log_message("")
        self._log_message("=" * 68)
        self._log_message(f"✗ Error: {message}")
        self._log_message("=" * 68)

        # Show error dialog
        messagebox.showerror(
            "Installation Failed",
            f"An error occurred during installation:\n\n{message}\n\n"
            "Please check the log for details."
        )

        # Re-enable install button
        self.install_button.config(state=tk.NORMAL, bg="#2563eb")

    def _close_application(self):
        """Close the application"""
        if self.installing:
            response = messagebox.askyesno(
                "Installation In Progress",
                "Installation is currently running. Are you sure you want to exit?"
            )
            if not response:
                return

        self.root.destroy()


def main():
    """Main entry point"""
    # Create root window
    root = tk.Tk()

    # Set window icon if available (optional)
    # root.iconbitmap('icon.ico')

    # Create installer GUI
    app = InstallerGUI(root)

    # Center window on screen
    root.update_idletasks()
    width = root.winfo_width()
    height = root.winfo_height()
    x = (root.winfo_screenwidth() // 2) - (width // 2)
    y = (root.winfo_screenheight() // 2) - (height // 2)
    root.geometry(f'{width}x{height}+{x}+{y}')

    # Run main loop
    root.mainloop()


if __name__ == '__main__':
    main()
