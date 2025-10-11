# OpenBSD System Administration Tool (sysadmin.ksh)

# Overview

`sysadmin.ksh` is a comprehensive command-line system administration tool designed specifically for OpenBSD systems. It provides a user-friendly menu-driven interface to perform common administrative tasks such as user management, service control, network scanning, log viewing, system updates, and more.

# Features

- List all users with UID and shell information
- Add, delete, and lock user accounts
- List, start, stop, and restart system services
- Perform network port scans and ping sweeps
- Read and filter system logs
- Generate secure random passwords
- Perform full system updates
- Reboot or shut down the system
- Action logging with timestamps

# Requirements

- OpenBSD operating system
- Basic command-line knowledge
- Root or superuser privileges for certain actions (e.g., user management, system updates, reboot/shutdown)

# Usage

1. Save the script as `sysadmin.ksh`.
2. Make it executable:
   ```bash
   chmod +x sysadmin.ksh
