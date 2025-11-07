#!/bin/ksh
################################################################
#### OpenBSD System Admin Tool
################################################################

# Verify script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Exiting."
  exit 1
fi

################################################################
#### Configure variables
################################################################

PASSWORD_LIST="passwordlist.txt"
PINGSWEEP_LOG="pingsweep.txt"
PORTSCAN_LOG="portscan.txt"
LOG_FILE="/var/log/sysadmin.log"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Reset Color

################################################################
#### Clear screen function
################################################################

function clear_screen {
  clear
}

################################################################
#### Log actions with timestamp
################################################################

function log_action {
  print "$(date '+%B %d, %Y %H:%M:%S') - $1" >> "$LOG_FILE"
}

################################################################
#### Print messages
################################################################

function print_msg {
  local msg_type=$1
  shift
  case "$msg_type" in
    info) print "$GREEN[INFO]$NC $*" ;;
    warn) print "$YELLOW[WARNING]$NC $*" ;;
    error) print "$RED[ERROR]$NC $*" >&2 ;;
    success) print "$BLUE[SUCCESS]$NC $*" ;;
    *) print "$*" ;;
  esac
}

################################################################
#### Confirmation prompt
################################################################

function confirm {
  print -n "Are you sure? (y/n): "
  read -r answer
  if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
    print_msg warn "Action canceled."
    return 1
  fi
  return 0
}

################################################################
#### Validation functions
################################################################

function validate_username {
  local username=$1
  if [ -z "$username" ]; then
    print_msg error "Username cannot be empty."
    return 1
  fi
  return 0
}

function validate_service {
  local service=$1
  if [ -z "$service" ]; then
    print_msg error "Service name cannot be empty."
    return 1
  fi
  if [ ! -f "/etc/rc.d/$service" ]; then
    print_msg error "Service '$service' not found in /etc/rc.d/"
    return 1
  fi
  return 0
}

function validate_network {
  local network=$1
  if ! echo "$network" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    print_msg error "Invalid network format. Use format: XXX.XXX.XXX"
    return 1
  fi
  return 0
}

################################################################
#### User Management Menu
################################################################

function user_management {
  while true; do
    print "##########################################"
    print "#           User Management              #"
    print "##########################################"
    print "# 1) Add user                            #"
    print "# 2) Delete user                         #"
    print "# 3) Lock user                           #"
    print "# 4) Unlock user                         #"
    print "# 5) List all users                      #"
    print "# 0) Return to main menu                 #"
    print "##########################################"
    print -n "Select an option: "
    read -r um_choice
    case "$um_choice" in
      1) add_user ;;
      2) delete_user ;;
      3) lock_user ;;
      4) unlock_user ;;
      5) list_all_users ;;
      0) clear_screen; return ;;
      *) print_msg warn "Invalid choice." ;;
    esac
    clear_screen
  done
}

# Add user function
function add_user {
  print -n "Enter username to add: "
  read -r username
  if validate_username "$username"; then
    if useradd "$username"; then
      print_msg success "User '$username' added successfully."
      log_action "Added user '$username'"
    else
      print_msg error "Failed to add user '$username'."
    fi
  fi
}

# Delete user function
function delete_user {
  print -n "Enter username to delete: "
  read -r username
  if validate_username "$username"; then
    if ! id "$username" > /dev/null 2>&1; then
      print_msg warn "User '$username' does not exist."
    elif confirm; then
      if userdel -r "$username"; then
        print_msg success "User '$username' deleted successfully."
        log_action "Deleted user '$username'"
      else
        print_msg error "Failed to delete user '$username'."
      fi
    fi
  fi
}

# Lock user
function lock_user {
  print -n "Enter username to lock: "
  read -r username
  if validate_username "$username"; then
    if usermod -L "$username"; then
      print_msg success "User '$username' locked successfully."
      log_action "Locked user '$username'"
    else
      print_msg error "Failed to lock user '$username'."
    fi
  fi
}

# Unlock user
function unlock_user {
  print -n "Enter username to unlock: "
  read -r username
  if validate_username "$username"; then
    if usermod -U "$username"; then
      print_msg success "User '$username' unlocked successfully."
      log_action "Unlocked user '$username'"
    else
      print_msg error "Failed to unlock user '$username'."
    fi
  fi
}

# List all users
function list_all_users {
  print_msg info "Listing all users..."
  awk -F: '{print $1, $3, $7}' /etc/passwd | less
  log_action "Listed all users"
}

################################################################
#### Password Generation
################################################################

function passgen_sysadmin {
  print -n "Enter number of passwords to generate (default: 10): "
  read -r amount
  amount=${amount:-10}
  print -n "Enter password length (default: 15): "
  read -r length
  length=${length:-15}
  : > "$PASSWORD_LIST"
  count=1
  while [ "$count" -le "$amount" ]; do
    openssl rand -base64 48 | cut -c1-"$length" >> "$PASSWORD_LIST"
    count=$((count + 1))
  done
  print_msg success "Passwords generated and saved to $PASSWORD_LIST"
}

################################################################
#### Ping sweep
################################################################

function pingsweep_sysadmin {
  print -n "Enter network prefix (default: 192.168.1): "
  read -r network_prefix
  network_prefix=${network_prefix:-192.168.1}
  if ! validate_network "$network_prefix"; then
    return 1
  fi
  print_msg info "Starting ping sweep on network $network_prefix.0/24..."
  : > "$PINGSWEEP_LOG"
  i=1
  while [ "$i" -le 254 ]; do
    ip="${network_prefix}.${i}"
    if ping -c 1 -W 1 "$ip" > /dev/null 2>&1; then
      echo "Host $ip is alive" | tee -a "$PINGSWEEP_LOG"
    fi
    i=$((i + 1))
  done
  print_msg success "Ping sweep completed. Results saved to $PINGSWEEP_LOG"
}

################################################################
#### Port Scanning
################################################################

function portscan_sysadmin {
  print -n "Enter target host (default: 127.0.0.1): "
  read -r target
  target=${target:-127.0.0.1}
  if ! echo "$target" | grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}$' && [ "$target" != "localhost" ]; then
    print_msg error "Invalid IP address format"
    return 1
  fi
  print -n "Enter port range (default: 20-100): "
  read -r port_range
  port_range=${port_range:-20-100}
  if ! echo "$port_range" | grep -Eq '^[0-9]+-[0-9]+$'; then
    print_msg error "Invalid port range format. Use: start-end"
    return 1
  fi
  start_port=$(echo "$port_range" | cut -d- -f1)
  end_port=$(echo "$port_range" | cut -d- -f2)
  if [ "$start_port" -lt 1 ] || [ "$end_port" -gt 65535 ] || [ "$start_port" -gt "$end_port" ]; then
    print_msg error "Invalid port numbers. Must be 1-65535 and start <= end"
    return 1
  fi
  print_msg info "Scanning $target ports $start_port to $end_port..."
  : > "$PORTSCAN_LOG"
  port="$start_port"
  while [ "$port" -le "$end_port" ]; do
    if nc -z -w 1 "$target" "$port" 2>/dev/null; then
      echo "Port $port is open" | tee -a "$PORTSCAN_LOG"
    fi
    port=$((port + 1))
  done
  print_msg success "Port scan completed. Results saved to $PORTSCAN_LOG"
}

################################################################
#### List all running services
################################################################

function list_running_services {
  print_msg info "Listing all running services..."
  rcctl ls started | less
  log_action "Listed running services"
}

################################################################
#### Service Management
################################################################

function service_management_menu {
  while true; do
    print "##########################################"
    print "#         Service Management             #"
    print "##########################################"
    print "# 1) Start service                       #"
    print "# 2) Stop service                        #"
    print "# 3) Restart service                     #"
    print "# 4) Enable on boot                      #"
    print "# 5) Disable on boot                     #"
    print "# 6) List running services               #"
    print "# 0) Return to main menu                 #"
    print "##########################################"
    print -n "Select an option: "
    read -r sm_choice
    case "$sm_choice" in
      1|2|3|4|5)
        print -n "Enter service name: "
        read -r service
        if validate_service "$service"; then
          case "$sm_choice" in
            1) if rcctl start "$service"; then
                 print_msg success "Service $service started"
               else
                 print_msg error "Failed to start $service"
               fi ;;
            2) if rcctl stop "$service"; then
                 print_msg success "Service $service stopped"
               else
                 print_msg error "Failed to stop $service"
               fi ;;
            3) if rcctl restart "$service"; then
                 print_msg success "Service $service restarted"
               else
                 print_msg error "Failed to restart $service"
               fi ;;
            4) if rcctl enable "$service"; then
                 print_msg success "Service $service enabled on boot"
               else
                 print_msg error "Failed to enable $service"
               fi ;;
            5) if rcctl disable "$service"; then
                 print_msg success "Service $service disabled on boot"
               else
                 print_msg error "Failed to disable $service"
               fi ;;
          esac
        fi
        ;;
      6) list_running_services ;;
      0) clear_screen; return ;;
      *) print_msg warn "Invalid choice." ;;
    esac
    clear_screen
  done
}

################################################################
#### Read Logs Menu
################################################################

function read_logs_menu {
  while true; do
    print "##########################################"
    print "#             Read Logs Menu             #"
    print "##########################################"
    print "# 1) Read /var/log/authlog               #"
    print "# 2) Read /var/log/secure                #"
    print "# 3) Read /var/log/pflog                 #"
    print "# 0) Return to main menu                 #"
    print "##########################################"
    print -n "Select an option: "
    read -r log_choice

    case "$log_choice" in
      1)
        print "Reading /var/log/authlog:"
        grep "Failed password" /var/log/authlog | less
        log_action "Read /var/log/authlog"
        ;;
      2)
        print "Reading /var/log/secure:"
        grep "doas" /var/log/secure | less
        log_action "Read /var/log/secure"
        ;;
      3)
        print "Reading /var/log/pflog:"
        tcpdump -n -e -ttt -r /var/log/pflog | less
        log_action "Read /var/log/pflog"
        ;;
      0)
        break
        ;;
      *)
        print_msg warn "Invalid choice."
        ;;
    esac
  done
}

################################################################
#### Main Menu
################################################################

function main_menu {
  while true; do
    print "##########################################"
    print "#        SYSADMIN MAIN MENU              #"
    print "##########################################"
    print "# 1) User Management                     #"
    print "# 2) Service Management                  #"
    print "# 3) Port Scanning                       #"
    print "# 4) Ping Sweep                          #"
    print "# 5) Generate passwords                  #"
    print "# 6) System update                       #"
    print "# 7) Reboot system                       #"
    print "# 8) Shutdown system                     #"
    print "# 9) Read logs                           #"
    print "# q) Quit                                #"
    print "##########################################"
    print -n "Select an option: "
    read -r choice

    case "$choice" in
      1) user_management ;;
      2) service_management_menu ;;
      3) portscan_sysadmin ;;
      4) pingsweep_sysadmin ;;
      5) passgen_sysadmin ;;
      6)
        if confirm; then
          print_msg info "Running full system update..."
          syspatch
          fw_update
          pkg_add -Uuv
        fi
        ;;
      7)
        if confirm; then
          print_msg warn "Rebooting system..."
          reboot
        fi
        ;;
      8)
        if confirm; then
          print_msg warn "Shutting down system..."
          halt -p
        fi
        ;;
      9) read_logs_menu ;;
      q|Q) clear_screen && print_msg info "Exiting. Goodbye!"; break ;;
      *) print_msg warn "Invalid option." ;;
    esac
    clear_screen
  done
}

################################################################
#### Initialize and run
################################################################

clear_screen
print_msg info "OpenBSD System Admin Tool Starting..."
log_action "Sysadmin started"
main_menu
