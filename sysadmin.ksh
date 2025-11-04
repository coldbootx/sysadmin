#!/bin/ksh
################################################################
#### A Simple OpenBSD System Admin Script with Menu
#### Features:
#### - Checks for root privileges
#### - Validates all user inputs
#### - Checks return codes after commands
#### - Logs all actions with timestamps
#### - Provides a help/documentation menu
################################################################

################################################################
#### Verify script is run as root
################################################################

if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Exiting."
  exit 1
fi

################################################################
#### Set config file and function library
################################################################
#### will become availible in Version 2
# CFILE=$HOME/sysadmin/sysadmin.conf
# export FPATH=$HOME/sysadmin/functions

################################################################
#### Configure variables
################################################################

PASSWORD_LIST="passwordlist.txt"
PINGSWEEP_LOG="pingsweep.txt"
PORTSCAN_LOG="portscan.txt"
LOG_FILE="/var/log/sysadmin.log"
HOST_IP="192.168.1"
remote_host='127.0.0.1'
PASSGEN_AMOUNT="10"
PASSGEN_LENGTH="15"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color - Reset Color

################################################################
#### Log actions with timestamp
################################################################

function log_action {
  print "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

################################################################
#### Print messages
################################################################

function print_msg {
  local msg_type=$1
  shift
  case "$msg_type" in
    info) print "$*";;
    warn) print "WARNING: $*" >&2;;
    error) print "ERROR: $*" >&2;;
    *) print "$*";;
  esac
}

################################################################
#### Confirmation prompt
################################################################

function confirm {
  print -n "Are you sure? (y/n): "
  read -r answer
  if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
    print_msg warn "Action canceled."
    return 1
  fi
  return 0
}

################################################################
#### Validation: Username
################################################################

function validate_username {
  local username=$1
  if [[ -z "$username" ]]; then
    print_msg error "Username cannot be empty."
    return 1
  fi
  return 0
}

################################################################
#### Validation: Service name
################################################################

function validate_service {
  local service=$1
  if [[ -z "$service" ]]; then
    print_msg error "Service name cannot be empty."
    return 1
  fi
  if rcctl status "$service" > /dev/null 2>&1; then
    return 0
  else
    print_msg error "Service '$service' does not exist."
    return 1
  fi
}

################################################################
#### Generate passwords
################################################################

function passgen_sysadmin {
  : > "$PASSWORD_LIST"
  for _ in $(seq 1 "$PASSGEN_AMOUNT"); do
    openssl rand -base64 48 | cut -c1-"$PASSGEN_LENGTH" >> "$PASSWORD_LIST"
  done
  print_msg info "Passwords generated and saved to $PASSWORD_LIST."
  return 0
}

################################################################
#### Ping sweep
################################################################

function pingsweep_sysadmin {
  print_msg info "Starting ping sweep..."
  : > "$PINGSWEEP_LOG"
  for i in {1..254}; do
    ip="${HOST_IP}.${i}"
    if ping -c 1 -W 1 "$ip"; then
      echo "Host $ip is alive" | tee -a "$PINGSWEEP_LOG"
    else
      echo "Host $ip is unreachable" | tee -a "$PINGSWEEP_LOG"
    fi
  done
  print_msg info "Ping sweep completed. Results saved to $PINGSWEEP_LOG."
  log_action "Performed ping sweep"
}

################################################################
#### Port scan
################################################################

function portscan_sysadmin {
  print_msg info "Starting port scan on $remote_host..."
  : > "$PORTSCAN_LOG"
  for port in $(seq 20 100); do
    if nc -z -w 1 "$remote_host" "$port"; then
      echo "Port $port is open" | tee -a "$PORTSCAN_LOG"
    fi
  done
  print_msg info "Port scan completed. Results saved to $PORTSCAN_LOG."
  log_action "Performed port scan on $remote_host"
}

################################################################
#### Manage service (start/stop/restart)
################################################################

function manage_service {
  local service=$1
  local action=$2
  if rcctl "$action" "$service"; then
    print_msg info "Service '$service' $action successful."
    log_action "Service '$service' $action."
    return 0
  else
    print_msg error "Failed to $action service '$service'."
    return 1
  fi
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
    print "# 0) Return to main menu                 #"
    print "##########################################"
    print -n "Select an option: "
    read -r um_choice
    case "$um_choice" in
      1) add_user ;;
      2) delete_user ;;
      3) lock_user ;;
      0) return ;;
      *) print_msg warn "Invalid choice." ;;
    esac
  done
}

################################################################
#### Add user
################################################################

function add_user {
  print -n "Enter username to add: "
  read -r username
  if validate_username "$username"; then
    if useradd "$username"; then
      print_msg info "User '$username' added successfully."
      log_action "Added user '$username'"
    else
      print_msg error "Failed to add user '$username'."
    fi
  fi
}

################################################################
#### Delete user
################################################################

function delete_user {
  print -n "Enter username to delete: "
  read -r username
  if validate_username "$username"; then
    if ! id "$username" > /dev/null 2>&1; then
      print_msg warn "User '$username' does not exist."
    elif confirm; then
      if userdel -r "$username"; then
        print_msg info "User '$username' deleted."
        log_action "Deleted user '$username'"
      else
        print_msg error "Failed to delete user '$username'."
      fi
    fi
  fi
}

################################################################
#### Lock user
################################################################

function lock_user {
  print -n "Enter username to lock: "
  read -r username
  if validate_username "$username"; then
    if usermod -L "$username"; then
      print_msg info "User '$username' locked."
      log_action "Locked user '$username'"
    else
      print_msg error "Failed to lock user '$username'."
    fi
  fi
}

################################################################
#### Show help
################################################################

function show_help {
  print "##########################################"
  print "#        SYSTEM ADMIN HELP               #"
  print "##########################################"
  print "# This script performs system admin tasks#"
  print "# on OpenBSD. Use the options below.     #"
  print "##########################################"
  print "# 1) User Management                     #"
  print "# 2) List all users                      #"
  print "# 3) List services                       #"
  print "# 4) Start/Stop/Restart services         #"
  print "# 5) List open ports                     #"
  print "# 6) Run ping sweep                      #"
  print "# 7) Read authlog                        #"
  print "# 8) Read secure log                     #"
  print "# 9) Read pflog                          #"
  print "# 10) Generate passwords                 #"
  print "# 11) System update                      #"
  print "# 12) Reboot system                      #"
  print "# 13) Shutdown system                    #"
  print "#  h/? Help                              #"
  print "#  q Quit                                #"
  print "##########################################"
}

################################################################
#### Main menu with border
################################################################

function main_menu {
  while true; do
    print "##########################################"
    print "#        OPENBSD ADMIN MENU              #"
    print "##########################################"
    print "# 1) User Management                     #"
    print "# 2) List all users                      #"
    print "# 3) List services                       #"
    print "# 4) Start/Stop/Restart services         #"
    print "# 5) List open ports                     #"
    print "# 6) Run ping sweep                      #"
    print "# 7) Read authlog                        #"
    print "# 8) Read secure log                     #"
    print "# 9) Read pflog                          #"
    print "# 10) Generate passwords                 #"
    print "# 11) System update                      #"
    print "# 12) Reboot system                      #"
    print "# 13) Shutdown system                    #"
    print "#  h/? Help                              #"
    print "#  q Quit                                #"
    print "##########################################"
    print -n "Select an option: "
    read -r choice
    case "$choice" in
      [hH]|[?]) show_help ;;
      q|Q) print_msg info "Exiting. Goodbye!"; break ;;
      1) user_management ;;
      2) awk -F: '{print $1, $3, $7}' /etc/passwd | less; log_action "Listed all users" ;;
      3)
        print -n "Enter service name (e.g., sshd): "
        read -r service
        if validate_service "$service"; then
          if rcctl status "$service"; then
            print "Service '$service' is running."
            log_action "Checked status of '$service': running."
          else
            print "Service '$service' is not running."
            log_action "Checked status of '$service': not running."
          fi
        fi
        ;;
      4)
        print -n "Service name: "
        read -r service
        print -n "Action (start/stop/restart): "
        read -r act
        if [[ "$act" =~ ^(start|stop|restart)$ ]]; then
          manage_service "$service" "$act"
        else
          print_msg warn "Invalid action."
        fi
        ;;
      5) portscan_sysadmin ;;
      6) pingsweep_sysadmin ;;
      7)
        print "Reading /var/log/authlog:"
        grep "Failed password" /var/log/authlog | less
        log_action "Read /var/log/authlog"
        ;;
      8)
        print "Reading /var/log/secure:"
        grep "doas" /var/log/secure | less
        log_action "Read /var/log/secure"
        ;;
      9)
        print "Reading /var/log/pflog:"
        tcpdump -n -e -ttt -r /var/log/pflog | less
        log_action "Read /var/log/pflog"
        ;;
      10) passgen_sysadmin ;;
      11)
        if confirm; then
          print "Running full system update..."
          if syspatch && fw_update && pkg_add -Uuv; then
            print_msg info "System updated successfully."
            log_action "System updated"
          else
            print_msg error "System update failed."
          fi
        fi
        ;;
      12)
        if confirm; then
          print_msg warn "Rebooting system..."
          log_action "Reboot initiated"
          reboot
        fi
        ;;
      13)
        if confirm; then
          print_msg warn "Shutting down..."
          log_action "Shutdown initiated"
          halt -p
        fi
        ;;
      *)
        print_msg warn "Invalid option."
        ;;
    esac
  done
}

################################################################
#### Run the main menu
main_menu
