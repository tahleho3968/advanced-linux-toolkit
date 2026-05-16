#!/bin/bash
# ============================================================
# Log Analyzer v2.0 - Advanced log file analysis tool
# FIXED: HTML reports now save to home directory
# ============================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
LOG_FILE=""
ERROR_PATTERN="ERROR|FATAL|CRITICAL"
WARNING_PATTERN="WARN|WARNING"
INFO_PATTERN="INFO|NOTICE"
DEBUG_MODE=false
OUTPUT_HTML=false
SUMMARY_ONLY=false
DATE_FROM=""
DATE_TO=""
TOP_IPS=10

# Create report directory in home folder
REPORT_DIR="$HOME/.linux-toolkit-reports"
mkdir -p "$REPORT_DIR" 2>/dev/null

# Function to show usage
usage() {
    echo "Usage: $0 <logfile> [options]"
    echo ""
    echo "Options:"
    echo "  -e <pattern>  Error pattern (default: ERROR|FATAL|CRITICAL)"
    echo "  -w <pattern>  Warning pattern (default: WARN|WARNING)"
    echo "  -i <pattern>  Info pattern (default: INFO|NOTICE)"
    echo "  -d            Enable debug mode"
    echo "  -h            Generate HTML report"
    echo "  -s            Show summary only"
    echo "  -f <date>     From date (YYYY-MM-DD)"
    echo "  -t <date>     To date (YYYY-MM-DD)"
    echo "  -n <number>   Number of top IPs to show (default: 10)"
    echo "  --help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 /var/log/auth.log"
    echo "  $0 /var/log/auth.log -s"
    echo "  $0 /var/log/syslog -h           # Creates HTML report in ~/.linux-toolkit-reports/"
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e) ERROR_PATTERN="$2"; shift 2 ;;
        -w) WARNING_PATTERN="$2"; shift 2 ;;
        -i) INFO_PATTERN="$2"; shift 2 ;;
        -d) DEBUG_MODE=true; shift ;;
        -h) OUTPUT_HTML=true; shift ;;
        -s) SUMMARY_ONLY=true; shift ;;
        -f) DATE_FROM="$2"; shift 2 ;;
        -t) DATE_TO="$2"; shift 2 ;;
        -n) TOP_IPS="$2"; shift 2 ;;
        --help) usage ;;
        *)
            if [ -z "$LOG_FILE" ]; then
                LOG_FILE="$1"
                shift
            else
                echo -e "${RED}Unknown option: $1${NC}"
                usage
            fi
            ;;
    esac
done

# Check if log file is provided
if [ -z "$LOG_FILE" ]; then
    echo -e "${RED}Error: Log file not specified${NC}"
    usage
fi

# Check existence and readability
if [ ! -e "$LOG_FILE" ]; then
    echo -e "${RED}Error: Log file does not exist: $LOG_FILE${NC}"
    echo -e "${YELLOW}Tip: Try one of these common log files:${NC}"
    echo "  /var/log/auth.log     - Authentication logs"
    echo "  /var/log/syslog       - System logs"
    echo "  /var/log/dpkg.log     - Package manager logs"
    echo "  /var/log/kern.log     - Kernel logs"
    exit 1
fi

if [ ! -r "$LOG_FILE" ]; then
    echo -e "${RED}Error: Cannot read log file: $LOG_FILE${NC}"
    echo -e "${YELLOW}Tip: Run with sudo: sudo $0 $LOG_FILE${NC}"
    exit 1
fi

# ── Helpers ───────────────────────────────────────────────────────────────────

# Read the log file, applying optional date filter
read_log() {
    if [ -n "$DATE_FROM" ] && [ -n "$DATE_TO" ]; then
        awk -v from="$DATE_FROM" -v to="$DATE_TO" '$0 ~ from, $0 ~ to' "$LOG_FILE"
    elif [ -n "$DATE_FROM" ]; then
        awk -v from="$DATE_FROM" '$0 ~ from' "$LOG_FILE"
    else
        cat "$LOG_FILE"
    fi
}

count_entries() {
    local pattern="$1"
    if [ -n "$pattern" ]; then
        read_log | grep -cE "$pattern" 2>/dev/null || echo "0"
    else
        read_log | wc -l 2>/dev/null | tr -d ' '
    fi
}

extract_ips() {
    read_log | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" 2>/dev/null \
        | sort | uniq -c | sort -rn | head -"$TOP_IPS"
}

extract_frequent_errors() {
    read_log | grep -E "$ERROR_PATTERN" 2>/dev/null \
        | sed 's/^[^:]*: //' | sort | uniq -c | sort -rn | head -20
}

hourly_distribution() {
    read_log 2>/dev/null | grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}' | \
        awk '{print $1, $2}' | cut -d':' -f1 | sort | uniq -c
}

# ── HTML report ───────────────────────────────────────────────────────────────

generate_html_report() {
    # Save to home directory instead of /var/log
    local base_name=$(basename "$LOG_FILE" | sed 's/\./_/g')
    local html_file="$REPORT_DIR/${base_name}_report_$(date '+%Y%m%d_%H%M%S').html"

    # Pre-compute values
    local total errors warnings info_count
    total=$(count_entries "")
    errors=$(count_entries "$ERROR_PATTERN")
    warnings=$(count_entries "$WARNING_PATTERN")
    info_count=$(count_entries "$INFO_PATTERN")

    cat > "$html_file" << HTML
<!DOCTYPE html>
<html>
<head>
    <title>Log Analysis Report - $(basename "$LOG_FILE")</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        h1 { color: #333; }
        h2 { color: #666; margin-top: 30px; }
        table { border-collapse: collapse; width: 100%; margin: 20px 0; background-color: white; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #4CAF50; color: white; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        .error { color: red; font-weight: bold; }
        .warning { color: orange; }
        .summary { background-color: #e0e0e0; padding: 10px; border-radius: 5px; margin: 10px 0; }
    </style>
</head>
<body>
    <h1>Log Analysis Report</h1>
    <p><strong>File:</strong> $LOG_FILE</p>
    <p><strong>Generated:</strong> $(date '+%Y-%m-%d %H:%M:%S')</p>
    <p><strong>Report saved to:</strong> $html_file</p>

    <div class="summary">
        <h2>Summary</h2>
        <p>Total Entries: <strong>$total</strong></p>
        <p>Errors: <strong class="error">$errors</strong></p>
        <p>Warnings: <strong class="warning">$warnings</strong></p>
        <p>Info: <strong>$info_count</strong></p>
    </div>

    <h2>Top $TOP_IPS IP Addresses</h2>
    <table>
        <tr><th>Count</th><th>IP Address</th></tr>
HTML

    local ip_data=$(extract_ips)
    if [ -n "$ip_data" ]; then
        echo "$ip_data" | while read -r count ip; do
            echo "        <tr><td style='text-align:center'>$count</td><td>$ip</td></tr>" >> "$html_file"
        done
    else
        echo "        <tr><td colspan='2'>No IP addresses found</td></tr>" >> "$html_file"
    fi

    cat >> "$html_file" << HTML
    </table>

    <h2>Most Frequent Errors</h2>
    <table>
        <tr><th>Count</th><th>Error Message</th></tr>
HTML

    local err_data=$(extract_frequent_errors | head -10)
    if [ -n "$err_data" ]; then
        echo "$err_data" | while read -r count error; do
            # Escape HTML special characters
            error_escaped=$(echo "$error" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
            echo "        <tr><td style='text-align:center'>$count</td><td>$error_escaped</td></tr>" >> "$html_file"
        done
    else
        echo "        <tr><td colspan='2'>No errors found matching: $ERROR_PATTERN</td></tr>" >> "$html_file"
    fi

    cat >> "$html_file" << HTML
    </table>
</body>
</html>
HTML

    echo -e "${GREEN}✓ HTML report generated: $html_file${NC}"
    echo -e "${YELLOW}  View it with: firefox $html_file${NC}"
}

# ── Display functions ─────────────────────────────────────────────────────────

display_summary() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}        LOG ANALYSIS SUMMARY${NC}"
    echo -e "${BLUE}========================================${NC}"

    local total errors warnings info_count
    total=$(count_entries "")
    errors=$(count_entries "$ERROR_PATTERN")
    warnings=$(count_entries "$WARNING_PATTERN")
    info_count=$(count_entries "$INFO_PATTERN")

    echo -e "File:          ${GREEN}$LOG_FILE${NC}"
    echo -e "Total Entries: ${GREEN}$total${NC}"
    echo -e "Errors:        ${RED}$errors${NC}"
    echo -e "Warnings:      ${YELLOW}$warnings${NC}"
    echo -e "Info:          ${GREEN}$info_count${NC}"
    echo ""
}

display_detailed_analysis() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}        TOP $TOP_IPS IP ADDRESSES${NC}"
    echo -e "${BLUE}========================================${NC}"
    local ip_data=$(extract_ips)
    if [ -n "$ip_data" ]; then
        echo "$ip_data" | awk '{printf "  %-15s %d requests\n", $2, $1}'
    else
        echo "  No IP addresses found in this log"
    fi
    echo ""

    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}        MOST FREQUENT ERRORS${NC}"
    echo -e "${BLUE}========================================${NC}"
    local err_data=$(extract_frequent_errors | head -10)
    if [ -n "$err_data" ]; then
        echo "$err_data" | awk '{printf "  %-5d %s\n", $1, substr($0, index($0,$2))}'
    else
        echo "  No errors matching pattern: $ERROR_PATTERN"
    fi
    echo ""

    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}        HOURLY DISTRIBUTION${NC}"
    echo -e "${BLUE}========================================${NC}"
    local hour_data=$(hourly_distribution | head -24)
    if [ -n "$hour_data" ]; then
        echo "$hour_data" | awk '{printf "  %-10s %d entries\n", $3, $1}'
    else
        echo "  No timestamp data found (logs may not have standard timestamps)"
    fi
    echo ""
}

# ── Main ──────────────────────────────────────────────────────────────────────

main() {
    echo -e "${GREEN}Analyzing log file: $LOG_FILE${NC}"

    [ "$DEBUG_MODE" = true ] && set -x

    display_summary

    if [ "$SUMMARY_ONLY" = false ]; then
        display_detailed_analysis
    fi

    if [ "$OUTPUT_HTML" = true ]; then
        generate_html_report
    fi

    echo -e "\n${GREEN}Analysis complete!${NC}"
}

main
