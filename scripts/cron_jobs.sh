#!/bin/bash
# Activate toolkit virtual environment
if [ -f "$HOME/.linux-toolkit-activate" ]; then
    source "$HOME/.linux-toolkit-activate"
fi

# ============================================================
# Cron Jobs Manager - Setup and manage automated tasks
# ============================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
CRON_FILE="/tmp/linux_toolkit_cron"
BACKUP_DIR="$HOME/.cron_backups"

# Function to show usage
usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -i, --install     Install cron jobs"
    echo "  -r, --remove      Remove all toolkit cron jobs"
    echo "  -l, --list        List current toolkit cron jobs"
    echo "  -b, --backup      Backup current crontab"
    echo "  -e, --edit        Edit cron jobs manually"
    echo "  -h, --help        Show this help message"
    exit 0
}

# Function to backup crontab
backup_crontab() {
    mkdir -p "$BACKUP_DIR"
    local backup_file="$BACKUP_DIR/crontab_backup_$(date +%Y%m%d_%H%M%S).txt"
    
    if crontab -l 2>/dev/null > "$backup_file"; then
        echo -e "${GREEN}✓ Crontab backed up to: $backup_file${NC}"
    else
        echo -e "${YELLOW}No existing crontab to backup${NC}"
    fi
}

# Function to list toolkit cron jobs
list_cron_jobs() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}        TOOLKIT CRON JOBS${NC}"
    echo -e "${BLUE}========================================${NC}\n"
    
    if crontab -l 2>/dev/null | grep -q "# Linux Toolkit"; then
        crontab -l | grep -A 10 "# Linux Toolkit" | while read line; do
            if [[ "$line" == "# Linux Toolkit"* ]]; then
                echo -e "${GREEN}$line${NC}"
            else
                echo "$line"
            fi
        done
    else
        echo -e "${YELLOW}No toolkit cron jobs found${NC}"
    fi
}

# Function to remove toolkit cron jobs
remove_cron_jobs() {
    echo -e "${YELLOW}Removing Linux Toolkit cron jobs...${NC}"
    
    if crontab -l 2>/dev/null | grep -q "# Linux Toolkit"; then
        crontab -l | sed -n '/# Linux Toolkit/,/# End Linux Toolkit/!p' | crontab -
        echo -e "${GREEN}✓ Toolkit cron jobs removed${NC}"
    else
        echo -e "${YELLOW}No toolkit cron jobs found to remove${NC}"
    fi
}

# Function to create cron job file
create_cron_file() {
    cat > "$CRON_FILE" << 'EOF'
# Linux Toolkit - Automated System Maintenance
# ==============================================
# Edit this file to customize cron jobs
# Format: minute hour day month weekday command

# System Monitoring (every 5 minutes)
*/5 * * * * $HOME/.local/bin/system_monitor.sh -l /var/log/linux-toolkit/system_monitor.log

# Security Audit (daily at 2 AM)
0 2 * * * sudo $HOME/.local/bin/security_audit.sh -l /var/log/linux-toolkit/security_audit.log

# Disk Cleanup (weekly on Sunday at 3 AM)
0 3 * * 0 $HOME/.local/bin/disk_cleaner.sh -y -t 85 -d 30

# Backup (daily at 1 AM)
0 1 * * * $HOME/.local/bin/backup_manager.sh -b $HOME -d /backup -t incremental

# Log Rotation and Analysis (daily at midnight)
0 0 * * * $HOME/.local/bin/log_analyzer.sh /var/log/syslog -s -o /var/log/linux-toolkit/daily_summary.log

# Network Monitor Report (hourly)
0 * * * * $HOME/.local/bin/network_monitor.py -c -d 300 -o /var/log/linux-toolkit/network_stats.log

# Disk Usage Report (daily at 6 AM)
0 6 * * * $HOME/.local/bin/disk_usage_analyzer.py $HOME -t -o /var/log/linux-toolkit/disk_usage.txt

# System Info Collection (daily at 8 AM)
0 8 * * * $HOME/.local/bin/system_info.py -j > /var/log/linux-toolkit/system_info_$(date +\%Y\%m\%d).json

# File Organization (weekly on Monday at 4 AM)
0 4 * * 1 $HOME/.local/bin/file_organizer.py $HOME/Downloads -m type -r

# Log Visualization Report (weekly on Sunday at 5 AM)
0 5 * * 0 $HOME/.local/bin/log_visualizer.py /var/log/syslog -o weekly_report_$(date +\%Y\%m\%d)

# End Linux Toolkit
EOF
    echo -e "${GREEN}✓ Cron job file created at: $CRON_FILE${NC}"
}

# Function to install cron jobs
install_cron_jobs() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}        INSTALLING CRON JOBS${NC}"
    echo -e "${BLUE}========================================${NC}\n"
    
    # Backup existing crontab
    backup_crontab
    
    # Create cron file
    create_cron_file
    
    # Install new cron jobs
    echo -e "${YELLOW}Installing cron jobs...${NC}"
    
    # Remove old toolkit jobs first
    remove_cron_jobs
    
    # Add new toolkit jobs
    (crontab -l 2>/dev/null; cat "$CRON_FILE") | crontab -
    
    echo -e "${GREEN}✓ Cron jobs installed successfully!${NC}"
    echo ""
    list_cron_jobs
    
    # Clean up
    rm -f "$CRON_FILE"
}

# Function to edit cron jobs
edit_cron_jobs() {
    echo -e "${YELLOW}Opening crontab for editing...${NC}"
    crontab -e
}

# Function to show help for individual jobs
show_job_help() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}        CRON JOB DESCRIPTIONS${NC}"
    echo -e "${BLUE}========================================${NC}\n"
    
    echo -e "${GREEN}System Monitor:${NC}"
    echo "  Runs every 5 minutes"
    echo "  Monitors CPU, memory, disk, and network"
    echo "  Logs to: /var/log/linux-toolkit/system_monitor.log"
    echo ""
    
    echo -e "${GREEN}Security Audit:${NC}"
    echo "  Runs daily at 2 AM"
    echo "  Checks for security issues, failed logins, open ports"
    echo "  Logs to: /var/log/linux-toolkit/security_audit.log"
    echo ""
    
    echo -e "${GREEN}Disk Cleanup:${NC}"
    echo "  Runs weekly on Sunday at 3 AM"
    echo "  Cleans temporary files, cache, old logs"
    echo "  Threshold: 85% disk usage"
    echo ""
    
    echo -e "${GREEN}Backup:${NC}"
    echo "  Runs daily at 1 AM"
    echo "  Performs incremental backup of home directory"
    echo "  Destination: /backup"
    echo ""
    
    echo -e "${GREEN}Log Analysis:${NC}"
    echo "  Runs daily at midnight"
    echo "  Analyzes system logs and generates summary"
    echo "  Output: /var/log/linux-toolkit/daily_summary.log"
    echo ""
    
    echo -e "${GREEN}Network Monitor:${NC}"
    echo "  Runs hourly"
    echo "  Monitors network traffic for 5 minutes"
    echo "  Logs to: /var/log/linux-toolkit/network_stats.log"
    echo ""
    
    echo -e "${GREEN}Disk Usage Report:${NC}"
    echo "  Runs daily at 6 AM"
    echo "  Analyzes disk usage and creates report"
    echo "  Output: /var/log/linux-toolkit/disk_usage.txt"
    echo ""
    
    echo -e "${GREEN}System Info Collection:${NC}"
    echo "  Runs daily at 8 AM"
    echo "  Collects system information in JSON format"
    echo "  Output: /var/log/linux-toolkit/system_info_YYYYMMDD.json"
    echo ""
    
    echo -e "${GREEN}File Organization:${NC}"
    echo "  Runs weekly on Monday at 4 AM"
    echo "  Organizes Downloads folder by file type"
    echo ""
    
    echo -e "${GREEN}Log Visualization:${NC}"
    echo "  Runs weekly on Sunday at 5 AM"
    echo "  Generates HTML report with charts"
    echo "  Output: weekly_report_YYYYMMDD"
    echo ""
}

# Main function
main() {
    case "$1" in
        -i|--install)
            install_cron_jobs
            ;;
        -r|--remove)
            remove_cron_jobs
            ;;
        -l|--list)
            list_cron_jobs
            ;;
        -b|--backup)
            backup_crontab
            ;;
        -e|--edit)
            edit_cron_jobs
            ;;
        -h|--help)
            show_job_help
            usage
            ;;
        *)
            echo -e "${YELLOW}No option specified. Showing help...${NC}\n"
            show_job_help
            usage
            ;;
    esac
}

# Run main function
main "$@"
