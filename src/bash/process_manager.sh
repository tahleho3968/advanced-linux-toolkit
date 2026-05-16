#!/bin/bash
# ============================================================
# Process Manager v2.0 - Process monitoring and management
# ============================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
REFRESH_INTERVAL=2
SORT_BY="cpu"  # cpu, mem, pid, name

# Function to show usage
usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -t <seconds>  Refresh interval (default: 2)"
    echo "  -s <field>    Sort by: cpu, mem, pid, name (default: cpu)"
    echo "  -k <pid>      Kill process"
    echo "  -r <pid>      Renice process"
    echo "  -m <pid>      Monitor specific process"
    echo "  -c <name>     Check if process is running"
    echo "  -l            List all processes"
    echo "  -h            Show this help message"
    exit 1
}

# Parse command line arguments
KILL_PID=""
RENICE_PID=""
RENICE_VALUE=""
MONITOR_PID=""
CHECK_NAME=""
LIST_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -t) REFRESH_INTERVAL="$2"; shift 2 ;;
        -s) SORT_BY="$2"; shift 2 ;;
        -k) KILL_PID="$2"; shift 2 ;;
        -r) RENICE_PID="$2"; RENICE_VALUE="$3"; shift 3 ;;
        -m) MONITOR_PID="$2"; shift 2 ;;
        -c) CHECK_NAME="$2"; shift 2 ;;
        -l) LIST_MODE=true; shift ;;
        -h) usage ;;
        *) usage ;;
    esac
done

# Function to get process list
get_process_list() {
    local processes=()
    
    while IFS= read -r line; do
        processes+=("$line")
    done < <(ps aux --sort=-%$SORT_BY 2>/dev/null | head -30)
    
    printf "%s\n" "${processes[@]}"
}

# Function to display process table
display_processes() {
    clear
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}        PROCESS MONITOR${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "Time: $(date)"
    echo -e "Sorting by: ${GREEN}$SORT_BY${NC}"
    echo -e "Refresh: ${GREEN}${REFRESH_INTERVAL}s${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    echo -e "${YELLOW}USER       PID  %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND${NC}"
    get_process_list | tail -n +2 | head -20
}

# Function to kill process
kill_process() {
    local pid="$1"
    
    if ! ps -p "$pid" > /dev/null 2>&1; then
        echo -e "${RED}✗ Process $pid not found${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Killing process $pid...${NC}"
    
    # Get process name
    local name=$(ps -p "$pid" -o comm=)
    
    echo -e "Process: $name"
    echo -e "1. SIGTERM (graceful)"
    echo -e "2. SIGKILL (force)"
    read -r choice
    
    case $choice in
        1)
            kill "$pid"
            echo -e "${GREEN}✓ SIGTERM sent to process $pid${NC}"
            ;;
        2)
            kill -9 "$pid"
            echo -e "${GREEN}✓ SIGKILL sent to process $pid${NC}"
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            ;;
    esac
}

# Function to renice process
renice_process() {
    local pid="$1"
    local nice_value="$2"
    
    if ! ps -p "$pid" > /dev/null 2>&1; then
        echo -e "${RED}✗ Process $pid not found${NC}"
        return 1
    fi
    
    renice "$nice_value" -p "$pid"
    echo -e "${GREEN}✓ Process $pid nice value changed to $nice_value${NC}"
}

# Function to monitor specific process
monitor_process() {
    local pid="$1"
    
    if ! ps -p "$pid" > /dev/null 2>&1; then
        echo -e "${RED}✗ Process $pid not found${NC}"
        return 1
    fi
    
    while true; do
        clear
        echo -e "${BLUE}========================================${NC}"
        echo -e "${BLUE}        MONITORING PROCESS $pid${NC}"
        echo -e "${BLUE}========================================${NC}"
        
        ps -p "$pid" -o pid,ppid,user,%cpu,%mem,vsz,rss,stat,start,time,comm
        
        echo -e "\n${BLUE}Process Tree:${NC}"
        pstree -p "$pid"
        
        echo -e "\n${BLUE}Open Files:${NC}"
        lsof -p "$pid" 2>/dev/null | head -10
        
        echo -e "\n${YELLOW}Press Ctrl+C to exit monitoring${NC}"
        sleep "$REFRESH_INTERVAL"
    done
}

# Function to check if process is running
check_process() {
    local name="$1"
    
    local pids=$(pgrep -f "$name")
    
    if [ -z "$pids" ]; then
        echo -e "${RED}✗ No process found matching '$name'${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓ Found processes matching '$name':${NC}"
    ps -p "$pids" -o pid,user,%cpu,%mem,etime,comm
}

# Function to list all processes
list_all_processes() {
    clear
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}        ALL PROCESSES${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    echo -e "${YELLOW}USER       PID  %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND${NC}"
    ps aux | head -50
}

# Function to show top CPU consumers
show_top_cpu() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}        TOP CPU CONSUMERS${NC}"
    echo -e "${BLUE}========================================${NC}"
    ps aux --sort=-%cpu | head -11
}

# Function to show top memory consumers
show_top_memory() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}        TOP MEMORY CONSUMERS${NC}"
    echo -e "${BLUE}========================================${NC}"
    ps aux --sort=-%mem | head -11
}

# Function to show zombie processes
show_zombie_processes() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}        ZOMBIE PROCESSES${NC}"
    echo -e "${BLUE}========================================${NC}"
    ps aux | awk '$8=="Z" {print}'
}

# Interactive mode
interactive_mode() {
    while true; do
        display_processes
        
        echo -e "\n${YELLOW}Commands:${NC}"
        echo "  k <pid> - Kill process"
        echo "  r <pid> <value> - Renice process"
        echo "  m <pid> - Monitor process"
        echo "  s <field> - Change sort (cpu, mem, pid, name)"
        echo "  t <seconds> - Change refresh interval"
        echo "  c <name> - Check if process is running"
        echo "  z - Show zombie processes"
        echo "  q - Quit"
        echo -n "> "
        
        read -r cmd arg1 arg2
        
        case $cmd in
            k) kill_process "$arg1" ;;
            r) renice_process "$arg1" "$arg2" ;;
            m) monitor_process "$arg1" ;;
            s) SORT_BY="$arg1" ;;
            t) REFRESH_INTERVAL="$arg1" ;;
            c) check_process "$arg1" ;;
            z) show_zombie_processes; sleep 3 ;;
            q) break ;;
            *) echo -e "${RED}Unknown command${NC}"; sleep 1 ;;
        esac
    done
}

# Main function
main() {
    if [ -n "$KILL_PID" ]; then
        kill_process "$KILL_PID"
    elif [ -n "$RENICE_PID" ]; then
        renice_process "$RENICE_PID" "$RENICE_VALUE"
    elif [ -n "$MONITOR_PID" ]; then
        monitor_process "$MONITOR_PID"
    elif [ -n "$CHECK_NAME" ]; then
        check_process "$CHECK_NAME"
    elif [ "$LIST_MODE" = true ]; then
        list_all_processes
    else
        interactive_mode
    fi
}

# Run main function
main
