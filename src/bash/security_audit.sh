#!/bin/bash
# ============================================================
# Security Audit v2.0 - System security auditing tool
# ============================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
LOG_FILE="/var/log/security_audit.log"
REPORT_FILE="/tmp/security_report_$(date '+%Y%m%d_%H%M%S').txt"
EMAIL_RECIPIENT=""
SEND_EMAIL=false
CHECK_PORTS=false
CHECK_FAILED_LOGINS=false
CHECK_ROOTKIT=false
HARDEN_MODE=false

# Function to show usage
usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -p           Check open ports"
    echo "  -f           Check failed logins"
    echo "  -r           Check for rootkits"
    echo "  -h           Harden system security"
    echo "  -e <email>   Send report to email"
    echo "  -l <file>    Log file (default: /var/log/security_audit.log)"
    echo "  --help       Show this help message"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p) CHECK_PORTS=true; shift ;;
        -f) CHECK_FAILED_LOGINS=true; shift ;;
        -r) CHECK_ROOTKIT=true; shift ;;
        -h) HARDEN_MODE=true; shift ;;
        -e) EMAIL_RECIPIENT="$2"; SEND_EMAIL=true; shift 2 ;;
        -l) LOG_FILE="$2"; shift 2 ;;
        --help) usage ;;
        *) usage ;;
    esac
done

# Function to log messages
log_message() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo -e "$msg" | tee -a "$LOG_FILE"
    echo -e "$msg" >> "$REPORT_FILE"
}

# Function to print section header
print_header() {
    echo -e "\n${BLUE}========================================${NC}" | tee -a "$REPORT_FILE"
    echo -e "${BLUE}$1${NC}" | tee -a "$REPORT_FILE"
    echo -e "${BLUE}========================================${NC}" | tee -a "$REPORT_FILE"
}

# Function to check system information
check_system_info() {
    print_header "SYSTEM INFORMATION"
    
    log_message "Hostname: $(hostname)"
    log_message "Kernel: $(uname -r)"
    log_message "OS: $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    log_message "Uptime: $(uptime -p)"
    log_message "Current Users: $(who | wc -l)"
}

# Function to check user accounts
check_user_accounts() {
    print_header "USER ACCOUNT AUDIT"
    
    log_message "${YELLOW}Checking for users with UID 0 (root privileges):${NC}"
    awk -F: '($3 == 0) {print "  " $1}' /etc/passwd | tee -a "$REPORT_FILE"
    
    log_message "${YELLOW}Checking for users without passwords:${NC}"
    awk -F: '($2 == "" || $2 == "*") {print "  " $1}' /etc/shadow 2>/dev/null | tee -a "$REPORT_FILE"
    
    log_message "${YELLOW}Checking for empty passwords:${NC}"
    awk -F: '($2 == "") {print "  " $1}' /etc/shadow 2>/dev/null | tee -a "$REPORT_FILE"
    
    log_message "${YELLOW}Checking for users with duplicate UIDs:${NC}"
    cut -d: -f3 /etc/passwd | sort | uniq -d | while read uid; do
        echo "  UID $uid is used by:" | tee -a "$REPORT_FILE"
        grep -E ".*:.*:$uid:" /etc/passwd | cut -d: -f1 | sed 's/^/    /' | tee -a "$REPORT_FILE"
    done
}

# Function to check file permissions
check_file_permissions() {
    print_header "FILE PERMISSIONS AUDIT"
    
    log_message "${YELLOW}Checking world-writable files:${NC}"
    find / -type f -perm -002 2>/dev/null | head -20 | tee -a "$REPORT_FILE"
    
    log_message "${YELLOW}Checking SUID/SGID files:${NC}"
    find / -type f \( -perm -4000 -o -perm -2000 \) 2>/dev/null | head -20 | tee -a "$REPORT_FILE"
    
    log_message "${YELLOW}Checking .rhosts files:${NC}"
    find /home -name .rhosts 2>/dev/null | tee -a "$REPORT_FILE"
    
    log_message "${YELLOW}Checking SSH directory permissions:${NC}"
    for user in $(ls /home); do
        if [ -d "/home/$user/.ssh" ]; then
            local perm=$(stat -c "%a" "/home/$user/.ssh")
            if [ "$perm" != "700" ]; then
                echo "  /home/$user/.ssh has incorrect permissions: $perm" | tee -a "$REPORT_FILE"
            fi
        fi
    done
}

# Function to check open ports
check_open_ports() {
    if [ "$CHECK_PORTS" = true ]; then
        print_header "OPEN PORTS"
        
        log_message "${YELLOW}Listening ports:${NC}"
        ss -tlnp 2>/dev/null | tail -n +2 | awk '{printf "  %-10s %-20s %s\n", $2, $4, $6}' | tee -a "$REPORT_FILE"
        
        log_message "${YELLOW}Established connections:${NC}"
        ss -tnp 2>/dev/null | tail -n +2 | wc -l | xargs echo "  Total connections:" | tee -a "$REPORT_FILE"
    fi
}

# Function to check failed logins
check_failed_logins() {
    if [ "$CHECK_FAILED_LOGINS" = true ]; then
        print_header "FAILED LOGIN ATTEMPTS"
        
        log_message "${YELLOW}Last 20 failed login attempts:${NC}"
        if [ -f "/var/log/auth.log" ]; then
            grep "Failed password" /var/log/auth.log | tail -20 | tee -a "$REPORT_FILE"
        elif [ -f "/var/log/secure" ]; then
            grep "Failed password" /var/log/secure | tail -20 | tee -a "$REPORT_FILE"
        fi
        
        log_message "${YELLOW}Failed login attempts by IP:${NC}"
        if [ -f "/var/log/auth.log" ]; then
            grep "Failed password" /var/log/auth.log | awk '{print $(NF-3)}' | sort | uniq -c | sort -rn | head -10 | tee -a "$REPORT_FILE"
        elif [ -f "/var/log/secure" ]; then
            grep "Failed password" /var/log/secure | awk '{print $(NF-3)}' | sort | uniq -c | sort -rn | head -10 | tee -a "$REPORT_FILE"
        fi
    fi
}

# Function to check for rootkits
check_rootkits() {
    if [ "$CHECK_ROOTKIT" = true ]; then
        print_header "ROOTKIT DETECTION"
        
        log_message "${YELLOW}Checking for rkhunter:${NC}"
        if command -v rkhunter &> /dev/null; then
            rkhunter --check --skip-keypress --report-warnings-only | tee -a "$REPORT_FILE"
        else
            log_message "${RED}rkhunter not installed. Install with: sudo apt install rkhunter${NC}"
        fi
        
        log_message "${YELLOW}Checking for chkrootkit:${NC}"
        if command -v chkrootkit &> /dev/null; then
            chkrootkit | grep INFECTED | tee -a "$REPORT_FILE"
        else
            log_message "${RED}chkrootkit not installed. Install with: sudo apt install chkrootkit${NC}"
        fi
    fi
}

# Function to check SSH configuration
check_ssh_config() {
    print_header "SSH CONFIGURATION AUDIT"
    
    if [ -f "/etc/ssh/sshd_config" ]; then
        log_message "${YELLOW}Checking SSH security settings:${NC}"
        
        # Check root login
        if grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config; then
            log_message "${RED}  ✗ Root login is enabled (should be disabled)${NC}"
        else
            log_message "${GREEN}  ✓ Root login is disabled${NC}"
        fi
        
        # Check password authentication
        if grep -q "^PasswordAuthentication yes" /etc/ssh/sshd_config; then
            log_message "${YELLOW}  ⚠ Password authentication is enabled (consider using keys)${NC}"
        fi
        
        # Check protocol
        if grep -q "^Protocol 1" /etc/ssh/sshd_config; then
            log_message "${RED}  ✗ SSH Protocol 1 is enabled (insecure)${NC}"
        else
            log_message "${GREEN}  ✓ SSH Protocol 2 is used${NC}"
        fi
    else
        log_message "${RED}SSH configuration file not found${NC}"
    fi
}

# Function to check firewall status
check_firewall() {
    print_header "FIREWALL STATUS"
    
    if command -v ufw &> /dev/null; then
        log_message "${YELLOW}UFW Status:${NC}"
        ufw status | tee -a "$REPORT_FILE"
    elif command -v iptables &> /dev/null; then
        log_message "${YELLOW}IPTables Rules:${NC}"
        iptables -L -n | head -20 | tee -a "$REPORT_FILE"
    else
        log_message "${RED}No firewall detected${NC}"
    fi
}

# Function to check running services
check_services() {
    print_header "RUNNING SERVICES"
    
    log_message "${YELLOW}Running network services:${NC}"
    systemctl list-units --type=service --state=running | grep -E "\.service" | head -20 | tee -a "$REPORT_FILE"
    
    log_message "${YELLOW}Checking for unnecessary services:${NC}"
    unnecessary_services=("telnet" "ftp" "rsh" "rlogin" "rexec")
    for service in "${unnecessary_services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            log_message "${RED}  ✗ $service is running (insecure)${NC}"
        fi
    done
}

# Function to harden system
harden_system() {
    print_header "SYSTEM HARDENING"
    
    log_message "${YELLOW}Applying security hardening...${NC}"
    
    # Disable root SSH login
    if [ -f "/etc/ssh/sshd_config" ]; then
        sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
        systemctl restart sshd
        log_message "${GREEN}  ✓ Disabled root SSH login${NC}"
    fi
    
    # Set secure umask
    echo "umask 027" >> /etc/profile
    log_message "${GREEN}  ✓ Set secure umask${NC}"
    
    # Disable unnecessary services
    for service in telnet ftp rsh rlogin rexec; do
        if systemctl is-enabled --quiet "$service" 2>/dev/null; then
            systemctl disable "$service"
            log_message "${GREEN}  ✓ Disabled $service${NC}"
        fi
    done
    
    # Set password policies
    if [ -f "/etc/login.defs" ]; then
        sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/' /etc/login.defs
        sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 7/' /etc/login.defs
        sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE 14/' /etc/login.defs
        log_message "${GREEN}  ✓ Updated password policies${NC}"
    fi
    
    log_message "${GREEN}✓ System hardening completed${NC}"
}

# Function to generate report summary
generate_summary() {
    print_header "AUDIT SUMMARY"
    
    # Count warnings, issues, and passed checks
    local warnings=$(grep -c "⚠" "$REPORT_FILE" 2>/dev/null || echo 0)
    local issues=$(grep -c "✗" "$REPORT_FILE" 2>/dev/null || echo 0)
    local passed=$(grep -c "✓" "$REPORT_FILE" 2>/dev/null || echo 0)
    
    log_message "Total Warnings: $warnings"
    log_message "Total Issues: $issues"
    log_message "Total Passed Checks: $passed"
    
    # Fix: Proper numeric comparison
    if [ "$issues" -gt 0 ] 2>/dev/null; then
        log_message "${RED}⚠ Security issues found! Please review the report.${NC}"
    else
        log_message "${GREEN}✓ No critical security issues found.${NC}"
    fi
}

# Function to send email report
send_email_report() {
    if [ "$SEND_EMAIL" = true ] && [ -n "$EMAIL_RECIPIENT" ]; then
        mail -s "Security Audit Report - $(hostname)" "$EMAIL_RECIPIENT" < "$REPORT_FILE"
        log_message "${GREEN}✓ Report sent to $EMAIL_RECIPIENT${NC}"
    fi
}

# Function to cleanup old report files
cleanup_old_reports() {
    # Keep only last 10 reports
    ls -t /tmp/security_report_*.txt 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null
}

# Main function
main() {
    log_message "Starting Security Audit"
    
    check_system_info
    check_user_accounts
    check_file_permissions
    check_open_ports
    check_failed_logins
    check_rootkits
    check_ssh_config
    check_firewall
    check_services
    
    if [ "$HARDEN_MODE" = true ]; then
        harden_system
    fi
    
    generate_summary
    send_email_report
    cleanup_old_reports
    
    log_message "Security Audit completed. Report saved to $REPORT_FILE"
    echo -e "\n${GREEN}Report saved to: $REPORT_FILE${NC}"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

# Run main function
main
