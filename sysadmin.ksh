#!/bin/ksh
################################################################
################################################################
#### A simple system admin tool for OpenBSD
################################################################
################################################################

################################################################
#### Set Debug Mode
################################################################
# set -x

################################################################
#### Set config file and function library
################################################################
#### will become availible in Version 2
# CFILE=$HOME/sysadmin/sysadmin.conf
# export FPATH=$HOME/sysadmin/functions

################################################################
#### Set variables
################################################################

MSG="Hello $USER, Please select your option:"
#### mtree_ids will become availible in Version 2
#IDS_DIR="$HOME/sysadmin/mtree_ids"
PASSWORD_LIST="passwordlist.txt"
PINGSWEEP_LOG="pingsweep.txt"
PORTSCAN_LOG="portscan.txt"
HOST_IP="192.168.1"
TARGET="$HOST_IP.$ip"
START_IP=1
END_IP=254
remote_host='127.0.0.1'
port_range=({0..100})
PASSGEN_AMOUNT="10"
PASSGEN_LENGTH="15"
MENU_COLOR="\033[0m"
RESET_MENU_COLOR="\033[0m"

################################################################
#### Set functions
################################################################

function displaymsg {
  print "
Program: sysadmin.ksh
Version 1.0
Author: William Butler (coldboot@mailfence.com)
License: MIT License.
"
}

function passgen_sysadmin {
    for p in $(seq 1 $PASSGEN_AMOUNT); do
	openssl rand -base64 48 | cut -c1-$PASSGEN_LENGTH
    done
}

function pingsweep_sysadmin {
	for ip in $(seq $START_IP $END_IP)
	do
    	ping -c 1 -W 1 "$TARGET" > $PINGSWEEP_LOG
	done
}

function portscan_sysadmin {
    for port in $(seq 20 100)
    do
    nc -z -w 1 "$remote_host" "$port" && echo "Port $port is open" > "$PORTSCAN_LOG"
    done
}

function menu_sysadmin {
    echo -e "$MENU_COLOR"
    echo "###################################################"
    echo "#     System Admin Tool - Select an option:       #"
    echo "###################################################"
    echo "#                                                 #"
    echo "# 1) List all users, UID, and shell               #"
    echo "# 2) Add user                                     #"
    echo "# 3) Delete user                                  #"
    echo "# 4) Lock user                                    #"
    echo "# 5) List running services                        #"
    echo "# 6) Start/Stop/Restart a service                 #"
    echo "# 7) List open ports                              #"
    echo "# 8) Ping sweep                                   #"
    echo "# 9) Read /var/log/authlog                        #"
    echo "# 10) Read /var/log/secure                        #"
    echo "# 11) Read /var/log/pflog                         #"
    echo "# 12) Run password generator                      #"
    echo "# 13) Run full system update                      #"
    echo "# 14) Reboot System                               #"
    echo "# 15) Shut Down System                            #"
    echo "# 0) Exit                                         #"
    echo "#                                                 #"
    echo "###################################################"
    echo ""
    echo -e "$RESET_MENU_COLOR"
    echo ""
    echo "$MSG"
    
    read -r choice;

################################################################
#### Case option in
################################################################

case $choice in
1)
    echo "Listing all users, UID, and shell:"
    awk -F: '{print $1, $3, $7}' /etc/passwd | less
    menu_sysadmin
    ;;
2)
    echo "enter user name:"
    read -r username;
    if id "$username" > /dev/null 2>&1; then
        echo "User $username exists."
    else
        useradd "$username"
        echo "User $username added."
    fi
    menu_sysadmin
    ;;
3)
    echo "enter user name:"
    read -r username;
    if id "$username" > /dev/null 2>&1; then
        userdel -r "$username"
        echo "User $username deleted."
    else
        echo "User $username does not exist."
    fi
    menu_sysadmin
    ;;
4)
    echo "enter user name:"
    read -r username;
    if id "$username" > /dev/null 2>&1; then
        usermod -L "$username"
        echo "User $username locked."
    else
        echo "User $username does not exist."
    fi
    menu_sysadmin
    ;;
5)
    echo "Listing running services:"
    rcctl ls on | less
    menu_sysadmin
    ;;
6)
    echo "enter name of service: (example: sshd):"
    read -r service;
    echo "Choose action: start, stop, restart"
    read -r action;
    rcctl "$action" -f "$service"
    menu_sysadmin
    ;;
7)
    portscan_sysadmin
    echo "Running port scan with netcat."
    ;;
8)
    pingsweep_sysadmin
    echo "Running a simple ping sweep"
    ;;
9)
    echo "Reading /var/log/authlog:"
    grep "Failed password" /var/log/authlog | less
    menu_sysadmin
    ;;
10)
    echo "Reading /var/log/secure:"
    grep "doas" /var/log/secure | less
    menu_sysadmin
    ;;
11)
    echo "Read /var/log/pflog:"
    tcpdump -n -e -ttt -r /var/log/pflog | less
    menu_sysadmin
    ;;
12)
    passgen_sysadmin
    echo "Passwords generated."
    ;;

13)
    echo "Run syspatch, fw_update, and updating packages"
    syspatch
    fw_update
    pkg_add -Uu
    menu_sysadmin
    ;;
14)
    echo "Rebooting System"
    reboot
    ;;
15)
    echo "Shuting Down System"
    halt -p
    ;;
0)
    echo "Exiting..."
    ;;
*)
    echo "Invalid choice. Please try again."
    ;;
esac

}

################################################################
#### Run sysadmin functions
################################################################

menu_sysadmin
displaymsg

################################################################
#### Exit
################################################################

exit ${?}
