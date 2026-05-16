#!/bin/bash
# Activate toolkit virtual environment
if [ -f "$HOME/.linux-toolkit-activate" ]; then
    source "$HOME/.linux-toolkit-activate"
fi

# ============================================================
# Advanced Linux Toolkit - Interactive Main Menu
# ============================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Script directory — all installed scripts live here
BIN="$HOME/.local/bin"

# Clear screen
clear

# Function to display header
display_header() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════════════════╗"
    echo "║                    ADVANCED LINUX TOOLKIT v2.0                              ║"
    echo "╠════════════════════════════════════════════════════════════════════════════╣"
    echo -e "║${NC}                    $(date '+%Y-%m-%d %H:%M:%S')                                  ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
}

# Function to display menu
display_menu() {
    echo -e "${GREEN}"
    echo "  📊 SYSTEM HEALTH"
    echo -e "${NC}     1. System Monitor (Real-time)"
    echo "     2. System Information"
    echo "     3. Process Manager"
    echo ""
    echo -e "${RED}  🔒 SECURITY"
    echo -e "${NC}     4. Security Audit (Full)"
    echo "     5. Check Open Ports"
    echo "     6. Check Failed Logins"
    echo "     7. Harden System"
    echo ""
    echo -e "${BLUE}  💾 BACKUP"
    echo -e "${NC}     8. Full Backup"
    echo "     9. Incremental Backup"
    echo "    10. List Backups"
    echo "    11. Restore Backup"
    echo ""
    echo -e "${YELLOW}  📝 LOG ANALYSIS"
    echo -e "${NC}    12. Analyze System Logs"
    echo "    13. Generate HTML Report"
    echo "    14. Parse Large Log File (Perl)"
    echo "    15. Visualize Log Data"
    echo ""
    echo -e "${CYAN}  🌐 NETWORK"
    echo -e "${NC}    16. Ping Scan"
    echo "    17. Port Scan"
    echo "    18. Full Network Scan"
    echo "    19. Service Detection"
    echo "    20. Network Monitor (Real-time)"
    echo ""
    echo -e "${MAGENTA}  🧹 MAINTENANCE"
    echo -e "${NC}    21. Disk Cleanup (Dry Run)"
    echo "    22. Disk Cleanup (Execute)"
    echo "    23. Disk Usage Analyzer"
    echo "    24. File Organizer"
    echo ""
    echo -e "${GREEN}  👤 USER MANAGEMENT"
    echo -e "${NC}    25. List Users"
    echo "    26. Add User"
    echo "    27. Delete User"
    echo "    28. Change User Password"
    echo ""
    echo -e "${YELLOW}  ⚙️  UTILITIES"
    echo -e "${NC}    29. Manage Aliases"
    echo "    30. Manage Cron Jobs"
    echo "    31. View Toolkit Info"
    echo ""
    echo -e "${RED}     0. Exit${NC}"
    echo ""
    echo -n "Enter choice: "
}

# ── System Health ─────────────────────────────────────────────────────────────

run_system_monitor() {
    echo -e "\n${GREEN}Launching System Monitor...${NC}\n"
    "$BIN/system_monitor.sh"
}

run_system_info() {
    echo -e "\n${GREEN}Collecting System Information...${NC}\n"
    "$BIN/system_info.py"
}

run_process_manager() {
    echo -e "\n${GREEN}Launching Process Manager...${NC}\n"
    "$BIN/process_manager.sh"
}

# ── Security ──────────────────────────────────────────────────────────────────

run_security_audit() {
    echo -e "\n${GREEN}Running Security Audit...${NC}\n"
    sudo "$BIN/security_audit.sh"
}

check_open_ports() {
    echo -e "\n${GREEN}Checking Open Ports...${NC}\n"
    sudo "$BIN/security_audit.sh" -p
}

check_failed_logins() {
    echo -e "\n${GREEN}Checking Failed Logins...${NC}\n"
    sudo "$BIN/security_audit.sh" -f
}

harden_system() {
    echo -e "\n${YELLOW}⚠ This will modify system security settings. Continue? (y/n): ${NC}"
    read -r confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        sudo "$BIN/security_audit.sh" -h
    else
        echo "Operation cancelled."
    fi
}

# ── Backup ────────────────────────────────────────────────────────────────────

run_full_backup() {
    echo -e "\n${GREEN}Running Full Backup...${NC}"
    echo -n "Enter source directory: "
    read -r source_dir
    echo -n "Enter backup destination: "
    read -r dest_dir
    "$BIN/backup_manager.sh" -b "$source_dir" -d "$dest_dir" -t full
}

run_incremental_backup() {
    echo -e "\n${GREEN}Running Incremental Backup...${NC}"
    echo -n "Enter source directory: "
    read -r source_dir
    echo -n "Enter backup destination: "
    read -r dest_dir
    "$BIN/backup_manager.sh" -b "$source_dir" -d "$dest_dir" -t incremental
}

list_backups() {
    echo -e "\n${GREEN}Listing Backups...${NC}"
    "$BIN/backup_manager.sh" --list
}

restore_backup() {
    echo -e "\n${GREEN}Restoring Backup...${NC}"
    echo -n "Enter backup file path: "
    read -r backup_file
    "$BIN/backup_manager.sh" --restore "$backup_file"
}

# ── Log Analysis ──────────────────────────────────────────────────────────────

# Helper: check file exists and is readable; offer sudo if not readable
_resolve_log_file() {
    local log_file="$1"
    if [ ! -e "$log_file" ]; then
        echo -e "${RED}File not found: $log_file${NC}"
        return 1
    fi
    if [ ! -r "$log_file" ]; then
        echo -e "${YELLOW}File requires elevated permissions: $log_file${NC}"
        echo -n "Run with sudo? (y/n): "
        read -r use_sudo
        if [ "$use_sudo" = "y" ] || [ "$use_sudo" = "Y" ]; then
            echo "sudo"   # signal to caller
            return 0
        else
            echo -e "${RED}Cannot read file without sudo. Aborting.${NC}"
            return 1
        fi
    fi
    echo "normal"
    return 0
}

analyze_logs() {
    echo -e "\n${GREEN}Analyzing Logs...${NC}"
    echo -n "Enter log file path: "
    read -r log_file
    local mode
    mode=$(_resolve_log_file "$log_file") || return
    if [ "$mode" = "sudo" ]; then
        sudo "$BIN/log_analyzer.sh" "$log_file"
    else
        "$BIN/log_analyzer.sh" "$log_file"
    fi
}

generate_html_report() {
    echo -e "\n${GREEN}Generating HTML Report...${NC}"
    echo -n "Enter log file path: "
    read -r log_file
    local mode
    mode=$(_resolve_log_file "$log_file") || return
    if [ "$mode" = "sudo" ]; then
        sudo "$BIN/log_analyzer.sh" "$log_file" -h
    else
        "$BIN/log_analyzer.sh" "$log_file" -h
    fi
}

parse_large_log() {
    echo -e "\n${GREEN}Parsing Large Log File...${NC}"
    echo -n "Enter log file path: "
    read -r log_file
    local mode
    mode=$(_resolve_log_file "$log_file") || return
    if [ "$mode" = "sudo" ]; then
        sudo "$BIN/log_parser.pl" "$log_file" --stats
    else
        "$BIN/log_parser.pl" "$log_file" --stats
    fi
}

visualize_log() {
    echo -e "\n${GREEN}Visualizing Log Data...${NC}"
    echo -n "Enter log file path: "
    read -r log_file
    local mode
    mode=$(_resolve_log_file "$log_file") || return
    if [ "$mode" = "sudo" ]; then
        sudo "$BIN/log_visualizer.py" "$log_file"
    else
        "$BIN/log_visualizer.py" "$log_file"
    fi
}

# ── Network ───────────────────────────────────────────────────────────────────

run_ping_scan() {
    echo -e "\n${GREEN}Running Ping Scan...${NC}"
    echo -n "Enter target IP or hostname: "
    read -r target
    "$BIN/network_scanner.sh" "$target"
}

run_port_scan() {
    echo -e "\n${GREEN}Running Port Scan...${NC}"
    echo -n "Enter target IP or hostname: "
    read -r target
    echo -n "Enter ports (e.g., 22,80,443 or 1-1000): "
    read -r ports
    "$BIN/network_scanner.sh" -t port -p "$ports" "$target"
}

run_full_network_scan() {
    echo -e "\n${GREEN}Running Full Network Scan...${NC}"
    echo -n "Enter target (IP or network range): "
    read -r target
    sudo "$BIN/network_scanner.sh" -t full "$target"
}

run_service_detection() {
    echo -e "\n${GREEN}Running Service Detection...${NC}"
    echo -n "Enter target IP or hostname: "
    read -r target
    sudo "$BIN/network_scanner.sh" -t service "$target"
}

run_network_monitor() {
    echo -e "\n${GREEN}Running Network Monitor...${NC}"
    "$BIN/network_monitor.py" -c
}

# ── Maintenance ───────────────────────────────────────────────────────────────

disk_cleanup_dryrun() {
    echo -e "\n${GREEN}Running Disk Cleanup (Dry Run)...${NC}"
    "$BIN/disk_cleaner.sh" -n
}

disk_cleanup_execute() {
    echo -e "\n${YELLOW}⚠ This will delete files. Continue? (y/n): ${NC}"
    read -r confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        "$BIN/disk_cleaner.sh" -y
    else
        echo "Operation cancelled."
    fi
}

run_disk_usage() {
    echo -e "\n${GREEN}Running Disk Usage Analyzer...${NC}"
    echo -n "Enter directory path (default: current directory): "
    read -r dir_path
    if [ -z "$dir_path" ]; then
        "$BIN/disk_usage_analyzer.py" .
    else
        "$BIN/disk_usage_analyzer.py" "$dir_path"
    fi
}

run_file_organizer() {
    echo -e "\n${GREEN}Running File Organizer...${NC}"
    echo -n "Enter directory path: "
    read -r dir_path
    echo "Organization methods:"
    echo "  1. By Type (default)"
    echo "  2. By Date"
    echo "  3. By Name"
    echo -n "Choice: "
    read -r method_choice
    case $method_choice in
        2) method="date" ;;
        3) method="name" ;;
        *) method="type" ;;
    esac
    "$BIN/file_organizer.py" "$dir_path" -m "$method"
}

# ── User Management ───────────────────────────────────────────────────────────

list_users() {
    echo -e "\n${GREEN}Listing Users...${NC}"
    sudo "$BIN/user_manager.sh" -l
}

add_user() {
    echo -e "\n${GREEN}Adding User...${NC}"
    echo -n "Enter username: "
    read -r username
    sudo "$BIN/user_manager.sh" -a "$username"
}

delete_user() {
    echo -e "\n${RED}Deleting User...${NC}"
    echo -n "Enter username: "
    read -r username
    echo -e "${YELLOW}⚠ This will delete user $username. Continue? (y/n): ${NC}"
    read -r confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        sudo "$BIN/user_manager.sh" -d "$username"
    else
        echo "Operation cancelled."
    fi
}

change_user_password() {
    echo -e "\n${GREEN}Changing User Password...${NC}"
    echo -n "Enter username: "
    read -r username
    sudo "$BIN/user_manager.sh" -p "$username"
}

# ── Utilities ─────────────────────────────────────────────────────────────────

manage_aliases() {
    echo -e "\n${GREEN}Managing Aliases...${NC}"
    echo "  1. Install Aliases"
    echo "  2. List Available Aliases"
    echo "  3. Show Installed Aliases"
    echo "  4. Remove Aliases"
    echo -n "Choice: "
    read -r alias_choice
    case $alias_choice in
        1) "$BIN/aliases.sh" --install ;;
        2) "$BIN/aliases.sh" --list ;;
        3) "$BIN/aliases.sh" --show ;;
        4) "$BIN/aliases.sh" --remove ;;
        *) echo "Invalid choice" ;;
    esac
}

manage_cron_jobs() {
    echo -e "\n${GREEN}Managing Cron Jobs...${NC}"
    echo "  1. Install Cron Jobs"
    echo "  2. List Cron Jobs"
    echo "  3. Remove Cron Jobs"
    echo "  4. Backup Crontab"
    echo "  5. Edit Crontab"
    echo -n "Choice: "
    read -r cron_choice
    case $cron_choice in
        1) "$BIN/cron_jobs.sh" --install ;;
        2) "$BIN/cron_jobs.sh" --list ;;
        3) "$BIN/cron_jobs.sh" --remove ;;
        4) "$BIN/cron_jobs.sh" --backup ;;
        5) "$BIN/cron_jobs.sh" --edit ;;
        *) echo "Invalid choice" ;;
    esac
}

show_toolkit_info() {
    echo -e "\n${GREEN}Toolkit Information:${NC}\n"
    make info 2>/dev/null || echo "Run from the toolkit source directory for full info."
}

# ── Main loop ─────────────────────────────────────────────────────────────────

while true; do
    display_header
    display_menu
    read -r choice
    case $choice in
        1)  run_system_monitor ;;
        2)  run_system_info ;;
        3)  run_process_manager ;;
        4)  run_security_audit ;;
        5)  check_open_ports ;;
        6)  check_failed_logins ;;
        7)  harden_system ;;
        8)  run_full_backup ;;
        9)  run_incremental_backup ;;
        10) list_backups ;;
        11) restore_backup ;;
        12) analyze_logs ;;
        13) generate_html_report ;;
        14) parse_large_log ;;
        15) visualize_log ;;
        16) run_ping_scan ;;
        17) run_port_scan ;;
        18) run_full_network_scan ;;
        19) run_service_detection ;;
        20) run_network_monitor ;;
        21) disk_cleanup_dryrun ;;
        22) disk_cleanup_execute ;;
        23) run_disk_usage ;;
        24) run_file_organizer ;;
        25) list_users ;;
        26) add_user ;;
        27) delete_user ;;
        28) change_user_password ;;
        29) manage_aliases ;;
        30) manage_cron_jobs ;;
        31) show_toolkit_info ;;
        0)
            echo -e "\n${GREEN}Thank you for using Advanced Linux Toolkit!${NC}"
            exit 0
            ;;
        *)  echo -e "${RED}Invalid option. Please try again.${NC}" ;;
    esac
    echo -e "\n${YELLOW}Press Enter to continue...${NC}"
    read -r
    clear
done
