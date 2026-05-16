#!/bin/bash
# ============================================================
# Disk Cleaner v2.0 - Automated disk cleanup utility
# ============================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
DRY_RUN=false
AUTO_YES=false
THRESHOLD=80
CLEAN_TEMP=true
CLEAN_CACHE=true
CLEAN_LOGS=true
CLEAN_OLD_FILES=true
OLD_DAYS=30
LOG_FILE="/var/log/disk_cleaner.log"

# Function to show usage
usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -n           Dry run (show what would be deleted)"
    echo "  -y           Automatic yes to all prompts"
    echo "  -t <percent> Disk usage threshold (default: 80)"
    echo "  -d <days>    Days for old files (default: 30)"
    echo "  --no-temp    Skip temporary files"
    echo "  --no-cache   Skip cache files"
    echo "  --no-logs    Skip log files"
    echo "  --no-old     Skip old files"
    echo "  -l <file>    Log file (default: /var/log/disk_cleaner.log)"
    echo "  -h           Show this help message"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n) DRY_RUN=true; shift ;;
        -y) AUTO_YES=true; shift ;;
        -t) THRESHOLD="$2"; shift 2 ;;
        -d) OLD_DAYS="$2"; shift 2 ;;
        --no-temp) CLEAN_TEMP=false; shift ;;
        --no-cache) CLEAN_CACHE=false; shift ;;
        --no-logs) CLEAN_LOGS=false; shift ;;
        --no-old) CLEAN_OLD_FILES=false; shift ;;
        -l) LOG_FILE="$2"; shift 2 ;;
        -h) usage ;;
        *) usage ;;
    esac
done

# Function to log messages
log_message() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo -e "$msg" | tee -a "$LOG_FILE"
}

# Function to get disk usage
get_disk_usage() {
    df -h / | awk 'NR==2 {print $5}' | sed 's/%//'
}

# Function to format size
format_size() {
    du -sh "$1" 2>/dev/null | cut -f1
}

# Function to clean temporary files
clean_temp_files() {
    log_message "${BLUE}Cleaning temporary files...${NC}"
    
    local temp_dirs=("/tmp" "/var/tmp" "/var/cache")
    local total_saved=0
    
    for dir in "${temp_dirs[@]}"; do
        if [ -d "$dir" ]; then
            local size_before=$(du -sb "$dir" 2>/dev/null | cut -f1)
            
            if [ "$DRY_RUN" = true ]; then
                log_message "${YELLOW}  Would clean: $dir (Size: $(format_size "$dir"))${NC}"
            else
                find "$dir" -type f -atime +1 -delete 2>/dev/null
                find "$dir" -type f -name "*.tmp" -delete 2>/dev/null
                find "$dir" -type f -name "*.temp" -delete 2>/dev/null
                find "$dir" -type f -name "core.*" -delete 2>/dev/null
                
                local size_after=$(du -sb "$dir" 2>/dev/null | cut -f1)
                local saved=$((size_before - size_after))
                total_saved=$((total_saved + saved))
                
                log_message "${GREEN}  ✓ Cleaned $dir (Saved: $(numfmt --to=iec $saved))${NC}"
            fi
        fi
    done
    
    if [ "$DRY_RUN" = false ]; then
        log_message "${GREEN}✓ Total temp files cleaned: $(numfmt --to=iec $total_saved)${NC}"
    fi
}

# Function to clean cache files
clean_cache_files() {
    log_message "${BLUE}Cleaning cache files...${NC}"
    
    local cache_dirs=("/var/cache" "$HOME/.cache" "/home/*/.cache")
    local total_saved=0
    
    for dir_pattern in "${cache_dirs[@]}"; do
        for dir in $dir_pattern; do
            if [ -d "$dir" ]; then
                local size_before=$(du -sb "$dir" 2>/dev/null | cut -f1)
                
                if [ "$DRY_RUN" = true ]; then
                    log_message "${YELLOW}  Would clean: $dir (Size: $(format_size "$dir"))${NC}"
                else
                    rm -rf "$dir"/* 2>/dev/null
                    
                    local size_after=$(du -sb "$dir" 2>/dev/null | cut -f1)
                    local saved=$((size_before - size_after))
                    total_saved=$((total_saved + saved))
                    
                    log_message "${GREEN}  ✓ Cleaned $dir (Saved: $(numfmt --to=iec $saved))${NC}"
                fi
            fi
        done
    done
    
    # Clean package manager cache
    if command -v apt-get &> /dev/null; then
        if [ "$DRY_RUN" = true ]; then
            log_message "${YELLOW}  Would clean: APT cache (Size: $(format_size "/var/cache/apt/archives"))${NC}"
        else
            apt-get clean
            log_message "${GREEN}  ✓ Cleaned APT cache${NC}"
        fi
    fi
    
    if [ "$DRY_RUN" = false ]; then
        log_message "${GREEN}✓ Total cache cleaned: $(numfmt --to=iec $total_saved)${NC}"
    fi
}

# Function to clean log files
clean_log_files() {
    log_message "${BLUE}Cleaning log files...${NC}"
    
    local total_saved=0
    
    # Rotate logs
    if [ -f "/etc/logrotate.conf" ] && [ "$DRY_RUN" = false ]; then
        logrotate -f /etc/logrotate.conf 2>/dev/null
        log_message "${GREEN}  ✓ Rotated system logs${NC}"
    fi
    
    # Clean old logs
    local log_dirs=("/var/log" "/var/log/*.log" "/home/*/.log")
    
    for dir_pattern in "${log_dirs[@]}"; do
        for log in $dir_pattern; do
            if [ -f "$log" ]; then
                local size_before=$(stat -c%s "$log" 2>/dev/null)
                
                if [ "$DRY_RUN" = true ]; then
                    log_message "${YELLOW}  Would clean: $log (Size: $(format_size "$log"))${NC}"
                else
                    > "$log"
                    local saved=$size_before
                    total_saved=$((total_saved + saved))
                    log_message "${GREEN}  ✓ Cleaned $log (Saved: $(numfmt --to=iec $saved))${NC}"
                fi
            fi
        done
    done
    
    # Clean old log files
    find /var/log -name "*.gz" -delete 2>/dev/null
    find /var/log -name "*.old" -delete 2>/dev/null
    find /var/log -name "*.1" -delete 2>/dev/null
    
    if [ "$DRY_RUN" = false ]; then
        log_message "${GREEN}✓ Total logs cleaned: $(numfmt --to=iec $total_saved)${NC}"
    fi
}

# Function to clean old files
clean_old_files() {
    log_message "${BLUE}Cleaning old files (older than $OLD_DAYS days)...${NC}"
    
    local total_saved=0
    
    # Find and delete old files in home directories
    for home_dir in /home/*; do
        if [ -d "$home_dir" ]; then
            local old_files=$(find "$home_dir" -type f -atime +$OLD_DAYS 2>/dev/null)
            local file_count=$(echo "$old_files" | wc -l)
            
            if [ "$DRY_RUN" = true ]; then
                log_message "${YELLOW}  Would delete $file_count old files in $home_dir${NC}"
            else
                echo "$old_files" | while read -r file; do
                    if [ -f "$file" ]; then
                        local size=$(stat -c%s "$file" 2>/dev/null)
                        total_saved=$((total_saved + size))
                        rm -f "$file"
                    fi
                done
                log_message "${GREEN}  ✓ Deleted $file_count old files in $home_dir (Saved: $(numfmt --to=iec $total_saved))${NC}"
            fi
        fi
    done
    
    # Clean trash
    for trash_dir in /home/*/.local/share/Trash; do
        if [ -d "$trash_dir" ]; then
            if [ "$DRY_RUN" = true ]; then
                log_message "${YELLOW}  Would empty trash: $trash_dir (Size: $(format_size "$trash_dir"))${NC}"
            else
                rm -rf "$trash_dir"/* 2>/dev/null
                log_message "${GREEN}  ✓ Emptied trash: $trash_dir${NC}"
            fi
        fi
    done
}

# Function to show disk usage before cleanup
show_usage_before() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}        DISK USAGE BEFORE CLEANUP${NC}"
    echo -e "${BLUE}========================================${NC}"
    df -h
    echo ""
}

# Function to show disk usage after cleanup
show_usage_after() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}        DISK USAGE AFTER CLEANUP${NC}"
    echo -e "${BLUE}========================================${NC}"
    df -h
    echo ""
}

# Function to get user confirmation
confirm_cleanup() {
    if [ "$AUTO_YES" = true ]; then
        return 0
    fi
    
    echo -e "${YELLOW}WARNING: This will clean up disk space. Continue? (y/n): ${NC}"
    read -r response
    case $response in
        y|Y) return 0 ;;
        *) return 1 ;;
    esac
}

# Main function
main() {
    log_message "Starting disk cleanup"
    
    local usage=$(get_disk_usage)
    echo -e "${BLUE}Current disk usage: ${usage}%${NC}"
    
    if [ "$usage" -lt "$THRESHOLD" ] && [ "$DRY_RUN" = false ] && [ "$AUTO_YES" = false ]; then
        echo -e "${GREEN}Disk usage is below threshold (${THRESHOLD}%). No cleanup needed.${NC}"
        echo -e "Continue anyway? (y/n): "
        read -r response
        if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
            exit 0
        fi
    fi
    
    show_usage_before
    
    if ! confirm_cleanup; then
        log_message "Cleanup cancelled by user"
        exit 0
    fi
    
    if [ "$CLEAN_TEMP" = true ]; then
        clean_temp_files
    fi
    
    if [ "$CLEAN_CACHE" = true ]; then
        clean_cache_files
    fi
    
    if [ "$CLEAN_LOGS" = true ]; then
        clean_log_files
    fi
    
    if [ "$CLEAN_OLD_FILES" = true ]; then
        clean_old_files
    fi
    
    show_usage_after
    
    local new_usage=$(get_disk_usage)
    local freed=$((usage - new_usage))
    
    log_message "${GREEN}========================================${NC}"
    log_message "${GREEN}        CLEANUP COMPLETE${NC}"
    log_message "${GREEN}========================================${NC}"
    log_message "Disk usage: ${usage}% → ${new_usage}%"
    log_message "Space freed: ${freed}%"
    
    if [ "$DRY_RUN" = true ]; then
        log_message "${YELLOW}This was a dry run. No files were actually deleted.${NC}"
    fi
}

# Run main function
main
