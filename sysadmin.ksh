#!/bin/ksh
################################################################
#### A simple sysadmin tool for OpenBSD
#### Must be root or use doas
################################################################

################################################################
#### Set Debug Mode
# set -x

################################################################
#### Display Message
function displaymsg {
  print "
Program: sysadmin.ksh
Date: 09/08/2025
Version: 0.1
Author: William Butler coldboot@yahoo.com
License: GNU GPL (version 3, or any later version).
"
}

echo "###################################################"
echo "#     System Admin Tool - Select an option:       #"
echo "# 1) List all users (UID and shell)               #"
echo "# 2) Add user                                     #"
echo "# 3) Delete user                                  #"
echo "# 4) Lock user                                    #"
echo "# 5) List running services                        #"
echo "# 6) Start/Stop/Restart a service                 #"
echo "# 7) List open ports                              #"
echo "# 8) Ping sweep                                   #"
echo "# 9) Scan logs for intrusions                     #"
echo "# 10) Scan logs for DOAS                          #"
echo "# 11) Run syspatch fw_update and update packages  #"
echo "# 12) Reboot System                               #"
echo "# 0) Exit                                         #"
echo "###################################################"

read -r "Enter choice: " choice

case $choice in
1)
    echo "Listing all users (UID and shell):"
    awk -F: '{print $1, $3, $7}' /etc/passwd
    ;;
2)
    read -r "Enter new username: " username
    useradd "$username"
    echo "User $username added."
    ;;
3)
    read -r "Enter username to delete: " username
    userdel -r "$username"
    echo "User $username deleted."
    ;;
4)
    read -r "Enter username to lock: " username
    usermod -L "$username"
    echo "User $username locked."
    ;;
5)
    echo "Listing running services:"
    rcctl ls on
    ;;
6)
    read -r "Enter service name: " service
    echo "Choose action: start, stop, restart"
    read -r "Action: " action
    rcctl "$action" "$service"
    ;;
7)
    echo "Listing open ports:"
    netstat -tuln | grep LISTEN
    ;;
8)
    read -r "Enter IP range for ping sweep (e.g., 192.168.1): " ip_range
    for ip in {1..254}; do
    ping -c 1 -W 1 "$ip_range.$ip" &> /dev/null && echo "$ip_range.$ip is up" &
    done
    wait
    ;;
9)
    echo "Scanning logs for intrusions (example: /var/log/authlog):"
    grep "Failed password" /var/log/authlog
    ;;
10)
    echo "Scanning logs for DOAS (example: /var/log/secure):"
    grep "doas" /var/log/secure
    ;;
11)
    echo "Run syspatch fw_update and update packages"
    syspatch
    fw_update
    pkg_add -Uu
    ;;
12)
    echo "Rebooting System"
    reboot
    ;;
0)
    echo "Exiting..."
    ;;
*)
    echo "Invalid choice. Please try again."
    ;;
esac
echo ""
    
################################################################
#### Run display message function
displaymsg

################################################################
#### Exit
exit ${?}