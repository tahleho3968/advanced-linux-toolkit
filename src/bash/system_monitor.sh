#!/bin/bash
# ============================================================
# System Monitor v2.0 - Real-time system resource monitoring
# ============================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
LOG_FILE=""
EMAIL_ALERT=""
CPU_THRESHOLD=80
MEM_THRESHOLD=80
DISK_THRESHOLD=80
LOG_TO_FILE=false
SEND_EMAIL=false

# Function to show usage
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -l <file>    Log output to file"
    echo "  -c <percent> CPU threshold for alerts (default: 80)"
    echo "  -m <percent> Memory threshold for alerts (default: 80)"
    echo "  -d <percent> Disk threshold for alerts (default: 80)"
    echo "  -e <email>   Send email alerts to specified address"
    echo "  -h           Show this help message"
    exit 1
}

# Parse command line arguments
while getopts "l:c:m:d:e:h" opt; do
    case $opt in
        l) LOG_FILE="$OPTARG"; LOG_TO_FILE=true ;;
        c) CPU_THRESHOLD="$OPTARG" ;;
        m) MEM_THRESHOLD="$OPTARG" ;;
        d) DISK_THRESHOLD="$OPTARG" ;;
        e) EMAIL_ALERT="$OPTARG"; SEND_EMAIL=true ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Function to log messages
log_message() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo -e "$msg"
    if [ "$LOG_TO_FILE" = true ] && [ -n "$LOG_FILE" ]; then
        echo -e "$msg" >> "$LOG_FILE"
    fi
}

# Function to send email alert
send_alert() {
    local subject="$1"
    local message="$2"
    if [ "$SEND_EMAIL" = true ] && [ -n "$EMAIL_ALERT" ]; then
        echo -e "$message" | mail -s "$subject" "$EMAIL_ALERT"
    fi
}

# Function to get CPU usage
get_cpu_usage() {
    # Get CPU usage from /proc/stat
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    echo "$cpu_usage"
}

# Function to get memory usage
get_memory_usage() {
    local total_mem=$(free -m | awk '/^Mem:/{print $2}')
    local used_mem=$(free -m | awk '/^Mem:/{print $3}')
    local mem_percent=$((used_mem * 100 / total_mem))
    echo "$mem_percent"
}

# Function to get disk usage
get_disk_usage() {
    local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    echo "$disk_usage"
}

# Function to display system info
display_system_info() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}        SYSTEM INFORMATION${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}Hostname:${NC} $(hostname)"
    echo -e "${GREEN}Kernel:${NC} $(uname -r)"
    echo -e "${GREEN}OS:${NC} $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo -e "${GREEN}Uptime:${NC} $(uptime -p | sed 's/up //')"
    echo -e "${GREEN}Users logged in:${NC} $(who | wc -l)"
    echo ""
}

# Function to display system load
display_system_load() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}        SYSTEM LOAD${NC}"
    echo -e "${CYAN}========================================${NC}"
    
    local load=$(uptime | awk -F'load average:' '{print $2}')
    echo -e "${GREEN}Load Average:${NC}$load"
    echo ""
    
    echo -e "${GREEN}Top 5 CPU-consuming processes:${NC}"
    ps aux --sort=-%cpu | head -6 | awk '{printf "  %-8s %-10s %-6s %s\n", $1, $2, $3"%", $11}'
    echo ""
}

# Function to display CPU info
display_cpu_info() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}        CPU INFORMATION${NC}"
    echo -e "${CYAN}========================================${NC}"
    
    local cpu_usage=$(get_cpu_usage)
    local cpu_usage_int=${cpu_usage%.*}
    
    if [ "$cpu_usage_int" -gt "$CPU_THRESHOLD" ]; then
        echo -e "${RED}CPU Usage: $cpu_usage% (⚠ Above threshold: ${CPU_THRESHOLD}%)${NC}"
        send_alert "CPU Alert" "CPU usage is at ${cpu_usage}% which exceeds threshold ${CPU_THRESHOLD}%"
    else
        echo -e "${GREEN}CPU Usage: $cpu_usage%${NC}"
    fi
    
    echo -e "${GREEN}CPU Info:${NC} $(lscpu | grep "Model name" | cut -d':' -f2 | xargs)"
    echo -e "${GREEN}CPU Cores:${NC} $(nproc)"
    echo ""
}

# Function to display memory info
display_memory_info() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}        MEMORY INFORMATION${NC}"
    echo -e "${CYAN}========================================${NC}"
    
    local total_mem=$(free -h | awk '/^Mem:/{print $2}')
    local used_mem=$(free -h | awk '/^Mem:/{print $3}')
    local free_mem=$(free -h | awk '/^Mem:/{print $4}')
    local mem_percent=$(get_memory_usage)
    
    if [ "$mem_percent" -gt "$MEM_THRESHOLD" ]; then
        echo -e "${RED}Memory Usage: ${mem_percent}% (⚠ Above threshold: ${MEM_THRESHOLD}%)${NC}"
        send_alert "Memory Alert" "Memory usage is at ${mem_percent}% which exceeds threshold ${MEM_THRESHOLD}%"
    else
        echo -e "${GREEN}Memory Usage: ${mem_percent}%${NC}"
    fi
    
    echo -e "${GREEN}Total Memory:${NC} $total_mem"
    echo -e "${GREEN}Used Memory:${NC} $used_mem"
    echo -e "${GREEN}Free Memory:${NC} $free_mem"
    echo ""
    
    echo -e "${GREEN}Top 5 Memory-consuming processes:${NC}"
    ps aux --sort=-%mem | head -6 | awk '{printf "  %-8s %-10s %-6s %s\n", $1, $2, $4"%", $11}'
    echo ""
}

# Function to display disk info
display_disk_info() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}        DISK INFORMATION${NC}"
    echo -e "${CYAN}========================================${NC}"
    
    local disk_usage=$(get_disk_usage)
    
    if [ "$disk_usage" -gt "$DISK_THRESHOLD" ]; then
        echo -e "${RED}Disk Usage: ${disk_usage}% (⚠ Above threshold: ${DISK_THRESHOLD}%)${NC}"
        send_alert "Disk Alert" "Disk usage is at ${disk_usage}% which exceeds threshold ${DISK_THRESHOLD}%"
    else
        echo -e "${GREEN}Disk Usage: ${disk_usage}%${NC}"
    fi
    
    echo ""
    df -h | awk 'NR==1 {printf "  %-20s %-8s %-8s %-8s %s\n", "Filesystem", "Size", "Used", "Avail", "Use%"}; NR>1 {printf "  %-20s %-8s %-8s %-8s %s\n", $1, $2, $3, $4, $5}'
    echo ""
}

# Function to display network info
display_network_info() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}        NETWORK INFORMATION${NC}"
    echo -e "${CYAN}========================================${NC}"
    
    echo -e "${GREEN}Network Interfaces:${NC}"
    ip -br addr show | awk '{printf "  %-10s %s\n", $1, $3}'
    echo ""
    
    echo -e "${GREEN}Active Connections:${NC}"
    local connections=$(ss -tun | tail -n +2 | wc -l)
    echo -e "  Total connections: $connections"
    echo ""
    
    echo -e "${GREEN}Top 5 Connections by IP:${NC}"
    ss -tn | awk 'NR>1 {print $5}' | cut -d':' -f1 | sort | uniq -c | sort -rn | head -5 | awk '{printf "  %-15s %d connections\n", $2, $1}'
    echo ""
}

# Main function
main() {
    log_message "Starting System Monitor"
    
    display_system_info
    display_system_load
    display_cpu_info
    display_memory_info
    display_disk_info
    display_network_info
    
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}Monitor completed at $(date)${NC}"
    
    log_message "System Monitor completed"
}

# Run main function
main
