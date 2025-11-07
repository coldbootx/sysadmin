
OpenBSD System Administration Script
Overview

This is a comprehensive command-line tool designed to simplify and automate common system administration tasks on OpenBSD. It provides functionalities such as user management, service control, network troubleshooting, password generation, log analysis, and system updates.
Features

    User Management:
        Add, delete, lock, unlock, and list users
    Service Management:
        Start, stop, restart, enable, disable services
        List running services
    Network Tools:
        Ping sweep to identify active hosts on a subnet
        Port scanning on target hosts
    Password Generation:
        Generate secure random passwords and save them to a file
    Log Analysis:
        Read and filter system logs
    System Maintenance:
        Perform system updates, reboot, or shutdown

Requirements

    OpenBSD operating system
    Basic command-line utilities (bash, openssl, nc, grep, awk, rcctl, etc.)
    Root privileges to execute system management commands

Usage

    Save the script to a file, e.g., sysadmin.sh.
    Make it executable:

              

chmod +x sysadmin.sh

      

Run the script as root:

          

doas ./sysadmin.sh
