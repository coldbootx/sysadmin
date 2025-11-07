OpenBSD System Administration Script
====================================

Overview:
---------
This script is a comprehensive system administration utility designed specifically for OpenBSD systems. It provides a user-friendly, bordered menu interface with color enhancements for easier navigation. The script automates common administrative tasks such as user management, service control, network scanning, log viewing, password generation, and system updates.

Features:
---------
- Root privilege check
- Color-enhanced bordered menus
- User management (add, delete, lock users)
- Service status checking and control (start, stop, restart)
- Network tools: ping sweep and port scanning
- Log viewing (authlog, secure, pflog)
- Password generation
- System update, reboot, and shutdown commands
- Action logging with timestamps
- Input validation and error handling

Requirements:
------------
- OpenBSD system
- `ksh` shell
- `openssl` for password generation
- `nc` (netcat) for port scanning
- `tcpdump` for pflog reading
- Proper permissions to run system commands

Usage:
------
1. Save the script to a file, e.g., `sysadmin.ksh`.
2. Make it executable:
   chmod +x sysadmin.ksh
3. Run the script as root:
   sudo ./sysadmin.ksh

Notes:
------
- Always review the script before running.
- Use with caution when performing system updates or shutdowns.
- Customize the IP address range and remote host as needed.
- Ensure required tools like `openssl`, `nc`, and `tcpdump` are installed.

Support:
--------
For questions or support, contact: coldboot@mailfence.com.com

Disclaimer:
-----------
This script is provided 'as-is' without any warranty. Use at your own risk.
