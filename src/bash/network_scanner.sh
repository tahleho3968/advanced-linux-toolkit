#!/bin/bash
# ============================================================
# Network Scanner v2.0 - Network scanning and monitoring tool
# ============================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SCAN_TYPE="quick"  # quick, full, port, service
TARGET=""
PORTS="1-1000"
TIMEOUT=1
THREADS=10
OUTPUT_FILE=""

# Function to show usage
usage() {
    echo "Usage: $0 [options] <target>"
    echo ""
    echo "Scan Types:"
    echo "  -t quick    Quick ping scan (default)"
    echo "  -t full     Full port scan"
    echo "  -t port     Specific port scan"
    echo "  -t service  Service detection scan"
    echo ""
    echo "Options:"
    echo "  -p <ports>  Ports to scan (e.g., 22,80,443 or 1-1000)"
    echo "  -T <sec>    Timeout in seconds (default: 1)"
    echo "  -o <file>   Output file"
    echo "  -h          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 192.168.1.1"
    echo "  $0 -t full 192.168.1.0/24"
    echo "  $0 -t port -p 22,80,443 google.com"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t) SCAN_TYPE="$2"; shift 2 ;;
        -p) PORTS="$2"; shift 2 ;;
        -T) TIMEOUT="$2"; shift 2 ;;
        -o) OUTPUT_FILE="$2"; shift 2 ;;
        -h) usage ;;
        *) 
            if [ -z "$TARGET" ]; then
                TARGET="$1"
                shift
            else
                usage
            fi
            ;;
    esac
done

# Check if target is provided
if [ -z "$TARGET" ]; then
    echo -e "${RED}Error: Target not specified${NC}"
    usage
fi

# Function to check if host is up
ping_scan() {
    local host="$1"
    ping -c 1 -W "$TIMEOUT" "$host" > /dev/null 2>&1
    return $?
}

# Function to scan port
scan_port() {
    local host="$1"
    local port="$2"
    timeout "$TIMEOUT" bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null
    return $?
}

# Function to get service name
get_service() {
    local port="$1"
    grep -w "$port/tcp" /etc/services 2>/dev/null | awk '{print $1}' | head -1
    if [ $? -ne 0 ]; then
        echo "unknown"
    fi
}

# Function to scan a range of ports
scan_ports() {
    local host="$1"
    local ports="$2"
    local open_ports=()
    
    echo -e "${GREEN}Scanning ports on $host...${NC}"
    
    if [[ "$ports" == *-* ]]; then
        # Range scan
        local start=$(echo "$ports" | cut -d'-' -f1)
        local end=$(echo "$ports" | cut -d'-' -f2)
        
        for port in $(seq "$start" "$end"); do
            if scan_port "$host" "$port"; then
                open_ports+=("$port")
                local service=$(get_service "$port")
                echo -e "  ${GREEN}Port $port/tcp open${NC} - $service"
            fi
        done
    else
        # List scan
        IFS=',' read -ra port_list <<< "$ports"
        for port in "${port_list[@]}"; do
            if scan_port "$host" "$port"; then
                open_ports+=("$port")
                local service=$(get_service "$port")
                echo -e "  ${GREEN}Port $port/tcp open${NC} - $service"
            fi
        done
    fi
    
    echo -e "\n${GREEN}Open ports found: ${#open_ports[@]}${NC}"
    
    if [ ${#open_ports[@]} -gt 0 ]; then
        echo -e "${BLUE}Open ports: ${open_ports[*]}${NC}"
    fi
}

# Function for quick scan (ping only)
quick_scan() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}        QUICK SCAN${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    if [[ "$TARGET" == *"/"* ]]; then
        # Network range
        local network=$(echo "$TARGET" | cut -d'/' -f1)
        local cidr=$(echo "$TARGET" | cut -d'/' -f2)
        
        echo -e "Scanning network: $TARGET"
        
        for i in {1..254}; do
            local ip="${network%.*}.$i"
            if ping_scan "$ip"; then
                echo -e "  ${GREEN}✓ $ip is up${NC}"
            fi
        done
    else
        # Single host
        if ping_scan "$TARGET"; then
            echo -e "${GREEN}✓ $TARGET is up${NC}"
        else
            echo -e "${RED}✗ $TARGET is down${NC}"
        fi
    fi
}

# Function for full scan
full_scan() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}        FULL PORT SCAN${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    if ! ping_scan "$TARGET"; then
        echo -e "${RED}✗ Host is down, skipping port scan${NC}"
        return 1
    fi
    
    scan_ports "$TARGET" "1-65535"
}

# Function for port scan
port_scan() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}        PORT SCAN${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    if ! ping_scan "$TARGET"; then
        echo -e "${RED}✗ Host is down, skipping port scan${NC}"
        return 1
    fi
    
    scan_ports "$TARGET" "$PORTS"
}

# Function for service detection
service_scan() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}        SERVICE DETECTION${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    if ! ping_scan "$TARGET"; then
        echo -e "${RED}✗ Host is down, skipping service scan${NC}"
        return 1
    fi
    
    # First find open ports
    local open_ports=()
    local common_ports=(21 22 23 25 53 80 110 143 443 993 995 3306 3389 5432 8080)
    
    echo -e "${YELLOW}Checking common ports...${NC}"
    
    for port in "${common_ports[@]}"; do
        if scan_port "$TARGET" "$port"; then
            open_ports+=("$port")
        fi
    done
    
    if [ ${#open_ports[@]} -eq 0 ]; then
        echo -e "${RED}No common open ports found${NC}"
        return 1
    fi
    
    echo -e "\n${GREEN}Open ports found: ${open_ports[*]}${NC}\n"
    
    # Service detection
    for port in "${open_ports[@]}"; do
        echo -e "${BLUE}Port $port:${NC}"
        
        case $port in
            21)
                echo "  FTP service"
                echo "  Banner: $(echo QUIT | nc -w $TIMEOUT "$TARGET" 21 2>/dev/null | head -1)"
                ;;
            22)
                echo "  SSH service"
                echo "  Banner: $(nc -w $TIMEOUT "$TARGET" 22 2>/dev/null | head -1)"
                ;;
            25)
                echo "  SMTP service"
                echo "  Banner: $(nc -w $TIMEOUT "$TARGET" 25 2>/dev/null | head -1)"
                ;;
            80|443|8080)
                echo "  HTTP/HTTPS service"
                echo "  Server: $(curl -s -I -m $TIMEOUT "http://$TARGET:$port" 2>/dev/null | grep -i "server:" | head -1)"
                ;;
            3306)
                echo "  MySQL database"
                ;;
            5432)
                echo "  PostgreSQL database"
                ;;
            3389)
                echo "  RDP service"
                ;;
            *)
                echo "  Unknown service"
                ;;
        esac
        echo ""
    done
}

# Function to save results to file
save_results() {
    if [ -n "$OUTPUT_FILE" ]; then
        exec > >(tee -a "$OUTPUT_FILE")
    fi
}

# Function to print header
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}        NETWORK SCANNER v2.0${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "Target: ${GREEN}$TARGET${NC}"
    echo -e "Scan Type: ${GREEN}$SCAN_TYPE${NC}"
    echo -e "Time: $(date)"
    echo ""
}

# Main function
main() {
    print_header
    save_results
    
    case $SCAN_TYPE in
        quick) quick_scan ;;
        full) full_scan ;;
        port) port_scan ;;
        service) service_scan ;;
        *) echo -e "${RED}Invalid scan type${NC}"; usage ;;
    esac
    
    if [ -n "$OUTPUT_FILE" ]; then
        echo -e "\n${GREEN}Results saved to $OUTPUT_FILE${NC}"
    fi
}

# Check if running as root (for some scans)
if [ "$SCAN_TYPE" != "quick" ] && [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}Warning: Full scans work better with root privileges${NC}"
fi

# Run main function
main
