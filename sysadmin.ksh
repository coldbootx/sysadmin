#!/bin/ksh
################################################################
# Enhanced System Admin Tool for OpenBSD
# Features: Error handling, validation, logging, user prompts
################################################################

# Uncomment for debug
# set -x

# Configuration
PASSWORD_LIST="passwordlist.txt"
PINGSWEEP_LOG="pingsweep.txt"
PORTSCAN_LOG="portscan.txt"
LOG_FILE="/var/log/sysadmin.log"
HOST_IP="192.168.1"
remote_host='127.0.0.1'
PASSGEN_AMOUNT="10"
PASSGEN_LENGTH="15"

# Colors for output
COLOR_RED="\033[0;31m"
COLOR_GREEN="\033[0;32m"
COLOR_YELLOW="\033[1;33m"
COLOR_RESET="\033[0m"

# Logging function
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to display messages
print_msg() {
    local msg_type=$1
    shift
    case "$msg_type" in
        info) echo -e "${COLOR_GREEN}$*${COLOR_RESET}" ;;
        warn) echo -e "${COLOR_YELLOW}$*${COLOR_RESET}" ;;
        error) echo -e "${COLOR_RED}$*${COLOR_RESET}" ;;
        *) echo "$*" ;;
    esac
}

# Confirm prompt
confirm_action() {
    print_msg warn "Are you sure you want to proceed? (y/n): "
    read -r confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        print_msg info "Action canceled."
        return 1
    fi
    return 0
}

# Password generator
passgen_sysadmin() {
    > "$PASSWORD_LIST"
    for p in $(seq 1 "$PASSGEN_AMOUNT"); do
        openssl rand -base64 48 | cut -c1-"$PASSGEN_LENGTH"
    done > "$PASSWORD_LIST"
    if [ $? -eq 0 ]; then
        print_msg info "Passwords generated successfully."
        log_action "Generated passwords and saved to $PASSWORD_LIST"
    else
        print_msg error "Failed to generate passwords."
    fi
}

# Ping sweep
pingsweep_sysadmin() {
    print_msg info "Starting ping sweep..."
    > "$PINGSWEEP_LOG"
    for i in {1..254}
    do
        ip="${HOST_IP}.${i}"
        ping -c 1 -W 1 "$ip" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "Host $ip is alive" | tee -a "$PINGSWEEP_LOG"
        else
            echo "Host $ip is unreachable" | tee -a "$PINGSWEEP_LOG"
        fi
    done
    print_msg info "Ping sweep completed. Results saved to $PINGSWEEP_LOG."
    log_action "Performed ping sweep"
}

# Port scan
portscan_sysadmin() {
    print_msg info "Starting port scan on $remote_host..."
    > "$PORTSCAN_LOG"
    for port in $(seq 20 100)
    do
        nc -z -w 1 "$remote_host" "$port" && echo "Port $port is open" | tee -a "$PORTSCAN_LOG"
    done
    print_msg info "Port scan completed. Results saved to $PORTSCAN_LOG."
    log_action "Performed port scan on $remote_host"
}

# Main menu
menu_sysadmin() {
    while true; do
        echo -e "$COLOR_YELLOW"
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
        echo "# 12) Run password generator                       #"
        echo "# 13) Run full system update                       #"
        echo "# 14) Reboot System                                #"
        echo "# 15) Shut Down System                             #"
        echo "# 0) Exit                                         #"
        echo "###################################################"
        echo "#     Thanks for using sysadmin                   #"
        echo "###################################################"
        echo ""
        echo -n "$MSG "
        read -r choice

        case "$choice" in
            1)
                awk -F: '{print $1, $3, $7}' /etc/passwd | less
                ;;
            2)
                echo -n "Enter new username: "
                read -r username
                if [ -z "$username" ]; then
                    print_msg error "Username cannot be empty."
                elif id "$username" > /dev/null 2>&1; then
                    print_msg warn "User $username already exists."
                else
                    if useradd "$username"; then
                        print_msg info "User $username added."
                        log_action "Added user $username"
                    else
                        print_msg error "Failed to add user."
                    fi
                fi
                ;;
            3)
                echo -n "Enter username to delete: "
                read -r username
                if [ -z "$username" ]; then
                    print_msg error "Username cannot be empty."
                elif id "$username" > /dev/null 2>&1; then
                    if confirm_action; then
                        if userdel -r "$username"; then
                            print_msg info "User $username deleted."
                            log_action "Deleted user $username"
                        else
                            print_msg error "Failed to delete user."
                        fi
                    fi
                else
                    print_msg warn "User $username does not exist."
                fi
                ;;
            4)
                echo -n "Enter username to lock: "
                read -r username
                if [ -z "$username" ]; then
                    print_msg error "Username cannot be empty."
                elif id "$username" > /dev/null 2>&1; then
                    if confirm_action; then
                        if usermod -L "$username"; then
                            print_msg info "User $username locked."
                            log_action "Locked user $username"
                        else
                            print_msg error "Failed to lock user."
                        fi
                    fi
                else
                    print_msg warn "User $username does not exist."
                fi
                ;;
            5)
                rcctl ls on | less
                log_action "Listed running services"
                ;;
            6)
                echo -n "Enter service name (e.g., sshd): "
                read -r service
                echo -n "Choose action: start, stop, restart: "
                read -r action
                if [[ "$action" =~ ^(start|stop|restart)$ ]]; then
                    if confirm_action; then
                        if rcctl "$action" -f "$service"; then
                            print_msg info "Service $service $actioned."
                            log_action "Service $service $actioned"
                        else
                            print_msg error "Failed to $action service $service."
                        fi
                    fi
                else
                    print_msg warn "Invalid action."
                fi
                ;;
            7)
                portscan_sysadmin
                ;;
            8)
                pingsweep_sysadmin
                ;;
            9)
                echo "Reading /var/log/authlog:"
                grep "Failed password" /var/log/authlog | less
                log_action "Read /var/log/authlog"
                ;;
            10)
                echo "Reading /var/log/secure:"
                grep "doas" /var/log/secure | less
                log_action "Read /var/log/secure"
                ;;
            11)
                echo "Read /var/log/pflog:"
                tcpdump -n -e -ttt -r /var/log/pflog | less
                log_action "Read /var/log/pflog"
                ;;
            12)
                passgen_sysadmin
                ;;
            13)
                if confirm_action; then
                    echo "Running system update..."
                    if syspatch && fw_update && pkg_add -Uu; then
                        print_msg info "System updated successfully."
                        log_action "System update performed"
                    else
                        print_msg error "System update failed."
                    fi
                fi
                ;;
            14)
                if confirm_action; then
                    print_msg warn "Rebooting system..."
                    log_action "System reboot initiated"
                    reboot
                fi
                ;;
            15)
                if confirm_action; then
                    print_msg warn "Shutting down system..."
                    log_action "System shutdown initiated"
                    halt -p
                fi
                ;;
            0)
                print_msg info "Exiting sysadmin tool. Goodbye!"
                log_action "Exited sysadmin tool"
                break
                ;;
            *)
                print_msg warn "Invalid choice. Please try again."
                ;;
        esac
        echo ""
        echo -n "Press Enter to return to menu..."
        read
    done
}

# Start the menu loop
menu_sysadmin

exit 0
