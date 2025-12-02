#!/bin/ksh

#### SYSADMIN.KSH - Comprehensive System Administration Tool for OpenBSD
#### Author: William Butler <coldboot@mailfence.com>
#### Description: Menu-driven interface for OpenBSD system management

set -eu
set -o pipefail 2>/dev/null || true
PATH=/usr/bin:/bin:/usr/sbin:/sbin
export PATH
umask 027

# Verify script is run as root
if [ "$(id -u)" -ne 0 ]; then
  print "This script must be run as root. Exiting."
  exit 1
fi

# File paths
SYSADMIN_DIR="/root/sysadmin"
PASSWORDS_FILE="passwords.txt"
PING_RESULTS_FILE="ping_results.txt"
PINGSWEEP_RESULTS_FILE="pingsweep_results.txt"
PORTSCAN_RESULTS_FILE="portscan_results.txt"
LOG_FILE="sysadmin.log"

# Colors
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
NC="\033[0m" # Reset Color

# Basic functions
function clear_screen {
  clear
}

function ensure_directories {
  mkdir -p "$SYSADMIN_DIR" 2>/dev/null || true
}

function log_action {
  ensure_directories
  touch "$LOG_FILE" 2>/dev/null || true
  print "$(date '+%B %d, %Y %H:%M:%S') - $1" >> "$LOG_FILE"
}

function cleanup {
  # Add any temporary file cleanup later
  return 0
}
trap cleanup INT TERM EXIT

function pause {
  print ""
  print -n "${YELLOW}Press Enter to continue . . .${NC}"
  read -r
}

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

function confirm {
  print -n "${YELLOW}Are you sure? (y/n): ${NC}"
  read answer
  if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
    print_msg warn "Action canceled."
    return 1
  fi
  return 0
}

function validate_username {
  local username=$1
  if [ -z "$username" ]; then
    print_msg error "Username cannot be empty."
    return 1
  fi
  # Check if username contains only valid characters
  if ! echo "$username" | grep -Eq '^[a-z_][a-z0-9_-]*$'; then
    print_msg error "Invalid username format. Use only letters, numbers, hyphens, and underscores."
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
  
  # Validate each octet
  local octet1 octet2 octet3
  octet1=${network%%.*}
  octet2=${network%.*}; octet2=${octet2#*.}
  octet3=${network##*.}
  
  for octet in "$octet1" "$octet2" "$octet3"; do
    if [ "$octet" -lt 0 ] || [ "$octet" -gt 255 ]; then
      print_msg error "Invalid octet: $octet (must be 0-255)"
    return 1
    fi
  done
  
  return 0
}

function validate_ip {
  local ip=$1
  if ! echo "$ip" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'; then
    print_msg error "Invalid IP address format."
    return 1
  fi
  
  local octet1 octet2 octet3 octet4
  octet1=${ip%%.*}; ip=${ip#*.}
  octet2=${ip%%.*}; ip=${ip#*.}
  octet3=${ip%%.*}; ip=${ip#*.}
  octet4=$ip
  
  for octet in "$octet1" "$octet2" "$octet3" "$octet4"; do
    if [ "$octet" -lt 0 ] || [ "$octet" -gt 255 ]; then
      print_msg error "Invalid IP address: $ip"
      return 1
    fi
  done
  
  return 0
}

function check_service_exists {
  local service=$1
  if ! rcctl get "$service" >/dev/null 2>&1; then
    print_msg error "Service '$service' does not exist or is not managed by rc.d"
    return 1
  fi
  return 0
}

function show_system_info {
  print "System Information:"
  print "Hostname: $(hostname)"
  print "Kernel: $(uname -s -r)"
  print "Architecture: $(uname -m)"
  print "Uptime: $(uptime | sed 's/.*up //' | sed 's/,.*//')"
  print "Load Average: $(uptime | sed 's/.*load average: //')"
  print "Memory: $(vmstat | awk 'NR==3 {print $4 "K free"}')"
  print "Disk Usage:"
  df -h
  pause
  log_action "Displayed system information"
}

function show_firewall_rules {
  print_msg info "Firewall rules (pf):"
  if pfctl -s rules 2>/dev/null; then
    pfctl -s rules
  else
    print_msg error "Failed to show firewall rules or pf not running"
  fi
  pause
  log_action "Showed firewall rules"
}

function show_disk_usage {
  print_msg info "Disk usage:"
  df -h
  pause
  log_action "Showed disk usage"
}

function show_file_permissions {
  print_msg info "File permissions:"
  print -n "Enter file path: "
  read -r filepath
  if [ -z "$filepath" ]; then
    print_msg error "File path cannot be empty"
    return
  fi
  if [ -f "$filepath" ] || [ -d "$filepath" ]; then
    ls -ld "$filepath"
    pause
    log_action "Showed permissions for file: $filepath"
  else
    print_msg error "File not found: $filepath"
  fi
}

function show_network_interfaces {
  print_msg info "Network interfaces:"
  ifconfig -a
  pause
  log_action "Showed network interfaces"
}

function perform_traceroute {
  print_msg info "Tracerouting host..."
  print -n "Enter host to trace: "
  read -r host
  if [ -z "$host" ]; then
    print_msg error "Host cannot be empty"
    return
  fi
  print "Tracerouting $host..."
  traceroute "$host"
  pause
  log_action "Tracerouted host: $host"
}

function show_routing_table {
  print_msg info "Routing table:"
  netstat -rn
  pause
  log_action "Showed routing table"
}

function show_listening_ports {
  print_msg info "Listening ports:"
  echo "TCP listening ports:"
  netstat -an | grep LISTEN | grep '^tcp'
  echo ""
  echo "UDP ports:"
  netstat -an | grep '^udp'
  pause
  log_action "Showed listening ports"
}

function show_network_statistics {
  print_msg info "Network statistics:"
  netstat -s
  pause
  log_action "Showed network statistics"
}

# User Management Functions
function add_user {
  print -n "Enter username to add: "
  read -r username
  if validate_username "$username"; then
    if pw useradd "$username" -m -s /bin/ksh; then
      print_msg success "User '$username' added successfully."
      log_action "Added user '$username'"
    else
      print_msg error "Failed to add user '$username'."
    fi
  fi
}

function delete_user {
  print -n "Enter username to delete: "
  read -r username
  if validate_username "$username"; then
    if id "$username" > /dev/null 2>&1; then
      if confirm; then
        if pw userdel "$username"; then
          print_msg success "User '$username' deleted successfully."
          log_action "Deleted user '$username'"
        else
          print_msg error "Failed to delete user '$username'."
        fi
      fi
    else
      print_msg warn "User '$username' does not exist."
    fi
  fi
}

function lock_user {
  print -n "Enter username to lock: "
  read -r username
  if validate_username "$username"; then
    if pw lock "$username"; then
      print_msg success "User '$username' locked successfully."
      log_action "Locked user '$username'"
    else
      print_msg error "Failed to lock user '$username'."
    fi
  fi
}

function unlock_user {
  print -n "Enter username to unlock: "
  read -r username
  if validate_username "$username"; then
    if pw unlock "$username"; then
      print_msg success "User '$username' unlocked successfully."
      log_action "Unlocked user '$username'"
    else
      print_msg error "Failed to unlock user '$username'."
    fi
  fi
}

function list_all_users {
  print_msg info "Listing all users..."
  awk -F: '{print $1, $3, $7}' /etc/passwd
  pause
  log_action "Listed all users"
}

# Service Management Functions
function start_service {
  local service=$1
  if check_service_exists "$service"; then
    if rcctl start "$service"; then
      print_msg success "Service $service started successfully"
      log_action "Started service $service"
    else
      print_msg error "Failed to start service $service"
    fi
  fi
}

function stop_service {
  local service=$1
  if check_service_exists "$service"; then
    if rcctl stop "$service"; then
      print_msg success "Service $service stopped successfully"
      log_action "Stopped service $service"
    else
      print_msg error "Failed to stop service $service"
    fi
  fi
}

function restart_service {
  local service=$1
  if check_service_exists "$service"; then
    if rcctl restart "$service"; then
      print_msg success "Service $service restarted successfully"
      log_action "Restarted service $service"
    else
      print_msg error "Failed to restart service $service"
    fi
  fi
}

function enable_service {
  local service=$1
  if check_service_exists "$service"; then
    if rcctl enable "$service"; then
      print_msg success "Service $service enabled on boot"
      log_action "Enabled service $service on boot"
    else
      print_msg error "Failed to enable service $service"
    fi
  fi
}

function disable_service {
  local service=$1
  if check_service_exists "$service"; then
    if rcctl disable "$service"; then
      print_msg success "Service $service disabled on boot"
      log_action "Disabled service $service on boot"
    else
      print_msg error "Failed to disable service $service"
    fi
  fi
}

function list_running_services {
  print_msg info "Listing all running services..."
  rcctl ls started
  pause
  log_action "Listed running services"
}

# Main menus
function user_management_menu {
  while true; do
    clear_screen
    print "${GREEN}##########################################${NC}"
    print "${GREEN}#           ${YELLOW}User Management${NC}${GREEN}              #${NC}"
    print "${GREEN}##########################################${NC}"
    print "${GREEN}# ${YELLOW}1) Add user${NC}${GREEN}                            #${NC}"
    print "${GREEN}# ${YELLOW}2) Delete user${NC}${GREEN}                         #${NC}"
    print "${GREEN}# ${YELLOW}3) Lock user${NC}${GREEN}                           #${NC}"
    print "${GREEN}# ${YELLOW}4) Unlock user${NC}${GREEN}                         #${NC}"
    print "${GREEN}# ${YELLOW}5) List all users${NC}${GREEN}                      #${NC}"
    print "${GREEN}# ${YELLOW}0) Return to main menu${NC}${GREEN}                 #${NC}"
    print "${GREEN}##########################################${NC}"
    print -n "${YELLOW}Select an option: ${NC}"
    read um_choice
    case "$um_choice" in
      1) clear_screen && add_user ;;
      2) clear_screen && delete_user ;;
      3) clear_screen && lock_user ;;
      4) clear_screen && unlock_user ;;
      5) clear_screen && list_all_users ;;
      0) clear_screen; return ;;
      *) print_msg warn "Invalid choice." ;;
    esac
    clear_screen
  done
}

function service_management_menu {
  while true; do
    clear_screen
    print "${GREEN}##########################################${NC}"
    print "${GREEN}#         ${YELLOW}Service Management${NC}${GREEN}             #${NC}"
    print "${GREEN}##########################################${NC}"
    print "${GREEN}# ${YELLOW}1) Start service${NC}${GREEN}                       #${NC}"
    print "${GREEN}# ${YELLOW}2) Stop service${NC}${GREEN}                        #${NC}"
    print "${GREEN}# ${YELLOW}3) Restart service${NC}${GREEN}                     #${NC}"
    print "${GREEN}# ${YELLOW}4) Enable on boot${NC}${GREEN}                      #${NC}"
    print "${GREEN}# ${YELLOW}5) Disable on boot${NC}${GREEN}                     #${NC}"
    print "${GREEN}# ${YELLOW}6) List running services${NC}${GREEN}               #${NC}"
    print "${GREEN}# ${YELLOW}0) Return to main menu${NC}${GREEN}                 #${NC}"
    print "${GREEN}##########################################${NC}"
    print -n "Select an option: "
    read -r sm_choice
    case "$sm_choice" in
      1|2|3|4|5)
        print -n "${YELLOW}Enter service name: ${NC}"
        read -r service
        if [ -z "$service" ]; then
          print_msg error "Service name cannot be empty."
          continue
        fi
        case "$sm_choice" in
          1) start_service "$service" ;;
          2) stop_service "$service" ;;
          3) restart_service "$service" ;;
          4) enable_service "$service" ;;
          5) disable_service "$service" ;;
        esac
        ;;
      6) list_running_services ;;
      0) clear_screen; return ;;
      *) print_msg warn "Invalid choice." ;;
    esac
    clear_screen
  done
}

function system_update {
  print_msg info "Starting OpenBSD system update..."
  log_action "Started system update"

  # Update system patches
  print_msg info "Checking for system patches..."
  if syspatch; then
    print_msg success "System patches updated"
    log_action "System patches updated"
  else
    print_msg warn "No new patches or update failed"
  fi

  # Update firmware if available
  print_msg info "Checking for firmware updates..."
  if fw_update; then
    print_msg success "Firmware updated"
    log_action "Firmware updated"
  else
    print_msg warn "No firmware updates available"
  fi

  # Update packages
  print_msg info "Updating packages..."
  if pkg_add -Uuv; then
    print_msg success "Package update completed"
  else
    print_msg error "Package update failed"
  fi
  log_action "System update process completed"
}

function read_logs_menu {
  while true; do
    clear_screen
    print "${GREEN}##########################################${NC}"
    print "${GREEN}#             ${YELLOW}Read Logs Menu${NC}${GREEN}             #${NC}"
    print "${GREEN}##########################################${NC}"
    print "${GREEN}# ${YELLOW}1) Read /var/log/authlog${NC}${GREEN}               #${NC}"
    print "${GREEN}# ${YELLOW}2) Read /var/log/secure${NC}${GREEN}                #${NC}"
    print "${GREEN}# ${YELLOW}3) Read /var/log/pflog${NC}${GREEN}                 #${NC}"
    print "${GREEN}# ${YELLOW}0) Return to main menu${NC}${GREEN}                 #${NC}"
    print "${GREEN}##########################################${NC}"
    print -n "${YELLOW}Select an option: ${NC}"
    read -r log_choice

    case "$log_choice" in
      1)
        print "Reading /var/log/authlog:"
        if [ -f "/var/log/authlog" ]; then
          less /var/log/authlog
          clear_screen
          log_action "Read /var/log/authlog"
        else
          print_msg error "/var/log/authlog not found"
        fi
        ;;
      2)
        print "Reading /var/log/secure:"
        if [ -f "/var/log/secure" ]; then
          less /var/log/secure
          clear_screen
          log_action "Read /var/log/secure"
        else
          print_msg error "/var/log/secure not found"
        fi
        ;;
      3)
        print "Reading /var/log/pflog:"
        if [ -f "/var/log/pflog" ]; then
          tcpdump -n -e -ttt -r /var/log/pflog | less
          clear_screen
          log_action "Read /var/log/pflog"
        else
          print_msg error "/var/log/pflog not found"
        fi
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

function find_files {
  print_msg info "Finding files..."
  print -n "Enter search pattern: "
  read -r pattern
  if [ -z "$pattern" ]; then
        print_msg error "Pattern cannot be empty"
        return
      fi
      print "Searching for files matching: $pattern"
      find / -name "$pattern" 2>/dev/null
      pause
      log_action "Searched for files matching pattern: $pattern"
}

function file_system_tools_menu {
  while true; do
    clear_screen
    print "${GREEN}##########################################${NC}"
    print "${GREEN}#    ${YELLOW}FILE SYSTEM TOOLS MENU${NC}${GREEN}              #${NC}"
    print "${GREEN}##########################################${NC}"
    print "${GREEN}# ${YELLOW}1) Show disk usage${NC}${GREEN}                     #${NC}"
    print "${GREEN}# ${YELLOW}2) Find files${NC}${GREEN}                          #${NC}"
    print "${GREEN}# ${YELLOW}3) Show file permissions${NC}${GREEN}               #${NC}"
    print "${GREEN}# ${YELLOW}0) Back to main menu${NC}${GREEN}                   #${NC}"
    print "${GREEN}##########################################${NC}"
    print -n "${YELLOW}Select an option: ${NC}"
    read -r choice

    case "$choice" in
      1) show_disk_usage ;;
      2) find_files ;;
      3) show_file_permissions ;;
      0) break ;;
      *) print_msg error "Invalid option" ;;
    esac
  done
}

function system_management_menu {
  while true; do
    clear_screen
    print "${GREEN}##########################################${NC}"
    print "${GREEN}#        ${YELLOW}SYSTEM MANAGEMENT MENU${NC}${GREEN}          #${NC}"
    print "${GREEN}##########################################${NC}"
    print "${GREEN}# ${YELLOW}1) System Information${NC}${GREEN}                  #${NC}"
    print "${GREEN}# ${YELLOW}2) System Update${NC}${GREEN}                       #${NC}"
    print "${GREEN}# ${YELLOW}3) Reboot System${NC}${GREEN}                       #${NC}"
    print "${GREEN}# ${YELLOW}4) Shutdown System${NC}${GREEN}                     #${NC}"
    print "${GREEN}# ${YELLOW}0) Back to main menu${NC}${GREEN}                   #${NC}"
    print "${GREEN}##########################################${NC}"
    print -n "${YELLOW}Select an option: ${NC}"
    read -r choice

    case "$choice" in
      1) show_system_info ;;
      2) 
        if confirm; then
          system_update
        fi
        ;;
      3)
        if confirm; then
          print_msg warn "Rebooting system..."
          log_action "System reboot initiated"
          reboot
        fi
        ;;
      4)
        if confirm; then
          print_msg warn "Shutting down system..."
          log_action "System shutdown initiated"
          halt -p
        fi
        ;;
      0) break ;;
      *) print_msg error "Invalid option" ;;
    esac
  done
}

function generate_passwords {
  print -n "Enter number of passwords to generate (default: 10): "
  read -r amount
  amount=${amount:-10}
  print -n "Enter password length (default: 15): "
  read -r length
  length=${length:-15}
  ensure_directories
  : > "$PASSWORDS_FILE"
  count=1
  while [ "$count" -le "$amount" ]; do
    openssl rand -base64 48 | cut -c1-"$length" >> "$PASSWORDS_FILE"
    count=$((count + 1))
  done
  print_msg success "Passwords generated and saved to $PASSWORDS_FILE"
  log_action "Generated $amount passwords"
}

function ping_host {
  print_msg info "Pinging host..."
  print -n "Enter host to ping: "
  read -r host
  if [ -z "$host" ]; then
    print_msg error "Host cannot be empty"
    return
  fi
  print "Pinging $host..."
  ping -c 4 "$host"
  pause
  log_action "Pinged host: $host"
}

function ping_sweep {
  print -n "Enter network prefix (default: 192.168.1): "
  read -r network_prefix
  network_prefix=${network_prefix:-192.168.1}
  if ! validate_network "$network_prefix"; then
    return 1
  fi
  print_msg info "Starting ping sweep on network $network_prefix.0/24..."
  ensure_directories
  : > "$PINGSWEEP_RESULTS_FILE"
  i=1
  while [ "$i" -le 254 ]; do
    ip="${network_prefix}.${i}"
    if ping -c 1 -w 1 "$ip" > /dev/null 2>&1; then
      echo "Host $ip is alive" | tee -a "$PINGSWEEP_RESULTS_FILE"
    fi
    i=$((i + 1))
  done
  print_msg success "Ping sweep completed. Results saved to $PINGSWEEP_RESULTS_FILE"
  log_action "Performed ping sweep on network $network_prefix.0/24"
}

function port_scan {
  print -n "Enter target IP or hostname: "
  read -r target
  if [ -z "$target" ]; then
    print_msg error "Target cannot be empty"
    return 1
  fi

  print -n "Enter port range (default: 1-1000): "
  read -r port_range
  port_range=${port_range:-1-1000}

  print_msg info "Scanning $target ports $port_range..."
  ensure_directories
  : > "$PORTSCAN_RESULTS_FILE"

  start_port=${port_range%-*}
  end_port=${port_range#*-}

  print "Starting port scan on $target from port $start_port to $end_port..."

  open_count=0
  port=$start_port
  while [ "$port" -le "$end_port" ]; do
    if nc -z -w 1 "$target" "$port" 2>/dev/null; then
      echo "Port $port: OPEN" | tee -a "$PORTSCAN_RESULTS_FILE"
      open_count=$((open_count + 1))
    fi
    port=$((port + 1))
  done

  print_msg success "Port scan completed. Found $open_count open ports."
  print "Results saved to $PORTSCAN_RESULTS_FILE"
  log_action "Performed port scan on $target ports $port_range - Found $open_count open ports"
}

function network_tools_menu {
  while true; do
    clear_screen
    print "${GREEN}##########################################${NC}"
    print "${GREEN}#      ${YELLOW}NETWORK TOOLS MENU${NC}${GREEN}                #${NC}"
    print "${GREEN}##########################################${NC}"
    print "${GREEN}# ${YELLOW}1) Show network interfaces${NC}${GREEN}             #${NC}"
    print "${GREEN}# ${YELLOW}2) Ping host${NC}${GREEN}                           #${NC}"
    print "${GREEN}# ${YELLOW}3) Traceroute host${NC}${GREEN}                     #${NC}"
    print "${GREEN}# ${YELLOW}4) Show routing table${NC}${GREEN}                  #${NC}"
    print "${GREEN}# ${YELLOW}5) Show listening ports${NC}${GREEN}                #${NC}"
    print "${GREEN}# ${YELLOW}6) Show firewall rules${NC}${GREEN}                 #${NC}"
    print "${GREEN}# ${YELLOW}7) Show network statistics${NC}${GREEN}             #${NC}"
    print "${GREEN}# ${YELLOW}8) Ping Sweep${NC}${GREEN}                          #${NC}"
    print "${GREEN}# ${YELLOW}9) Port Scanning${NC}${GREEN}                       #${NC}"
    print "${GREEN}# ${YELLOW}0) Back to main menu${NC}${GREEN}                   #${NC}"
    print "${GREEN}##########################################${NC}"
    print -n "${YELLOW}Select an option: ${NC}"
    read -r choice

    case "$choice" in
      1) show_network_interfaces ;;
      2) ping_host ;;
      3) perform_traceroute ;;
      4) show_routing_table ;;
      5) show_listening_ports ;;
      6) show_firewall_rules ;;
      7) show_network_statistics ;;
      8) ping_sweep ;;
      9) port_scan ;;
      0) break ;;
      *) print_msg error "Invalid option" ;;
    esac
  done
}

# Main menu
function main_menu {
  while true; do
    clear_screen
    print "${GREEN}##########################################${NC}"
    print "${GREEN}#        ${YELLOW}SYSADMIN MAIN MENU${NC}${GREEN}              #${NC}"
    print "${GREEN}##########################################${NC}"
    print "${GREEN}# ${YELLOW}1) User Management${NC}${GREEN}                     #${NC}"
    print "${GREEN}# ${YELLOW}2) Service Management${NC}${GREEN}                  #${NC}"
    print "${GREEN}# ${YELLOW}3) Generate passwords${NC}${GREEN}                  #${NC}"
    print "${GREEN}# ${YELLOW}4) System Management${NC}${GREEN}                   #${NC}"
    print "${GREEN}# ${YELLOW}5) Read logs${NC}${GREEN}                           #${NC}"
    print "${GREEN}# ${YELLOW}6) File System Tools${NC}${GREEN}                   #${NC}"
    print "${GREEN}# ${YELLOW}7) Network Tools${NC}${GREEN}                       #${NC}"
    print "${GREEN}# ${YELLOW}q) Quit${NC}${GREEN}                                #${NC}"
    print "${GREEN}##########################################${NC}"
    print -n "${YELLOW}Select an option: ${NC}"
    read -r choice

    case "$choice" in
      1) clear_screen && user_management_menu ;;
      2) clear_screen && service_management_menu ;;
      3) clear_screen && generate_passwords ;;
      4) clear_screen && system_management_menu ;;
      5) clear_screen && read_logs_menu ;;
      6) clear_screen && file_system_tools_menu ;;
      7) clear_screen && network_tools_menu ;;
      q|Q) clear_screen && print_msg info "Exiting. Goodbye!"; break ;;
      *) print_msg warn "Invalid option." ;;
    esac
    clear_screen
  done
}

# Run the script
clear_screen
ensure_directories
print_msg info "${YELLOW}OpenBSD System Admin Tool Starting...${NC}"
log_action "Sysadmin tool started"

main_menu
