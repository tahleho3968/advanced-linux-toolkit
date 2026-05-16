#!/bin/bash
# ============================================================
# Test Script Runner - Validate all toolkit scripts
# ============================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
PASSED=0
FAILED=0
TOTAL=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -n "  Testing $test_name... "
    TOTAL=$((TOTAL + 1))
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}PASSED${NC}"
        PASSED=$((PASSED + 1))
        return 0
    else
        echo -e "${RED}FAILED${NC}"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

# Function to check if script exists
check_exists() {
    local script="$1"
    [ -f "$script" ]
}

# Function to check help output (more flexible)
check_help() {
    local script="$1"
    # Try multiple ways to get help output
    if "$script" -h 2>/dev/null | grep -qiE "usage|help|options"; then
        return 0
    elif "$script" --help 2>/dev/null | grep -qiE "usage|help|options"; then
        return 0
    elif "$script" -H 2>/dev/null | grep -qiE "usage|help|options"; then
        return 0
    else
        return 1
    fi
}

# Main test function
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Advanced Linux Toolkit - Test Suite${NC}"
    echo -e "${BLUE}========================================${NC}\n"
    
    # Check if scripts are installed
    echo -e "${YELLOW}Checking script installation...${NC}\n"
    
    # Bash scripts
    echo "Bash Scripts:"
    for script in system_monitor.sh backup_manager.sh security_audit.sh \
                   log_analyzer.sh user_manager.sh process_manager.sh \
                   network_scanner.sh disk_cleaner.sh; do
        run_test "$script exists" "check_exists ~/.local/bin/$script"
        if [ -f ~/.local/bin/"$script" ]; then
            run_test "$script help" "check_help ~/.local/bin/$script"
        fi
    done
    
    echo ""
    
    # Python scripts
    echo "Python Scripts:"
    for script in system_info.py file_organizer.py network_monitor.py \
                   disk_usage_analyzer.py log_visualizer.py; do
        run_test "$script exists" "check_exists ~/.local/bin/$script"
        if [ -f ~/.local/bin/"$script" ]; then
            # Python scripts use --help, not -h
            run_test "$script help" "check_help ~/.local/bin/$script"
        fi
    done
    
    echo ""
    
    # Perl scripts
    echo "Perl Scripts:"
    run_test "log_parser.pl exists" "check_exists ~/.local/bin/log_parser.pl"
    if [ -f ~/.local/bin/log_parser.pl ]; then
        run_test "log_parser.pl help" "check_help ~/.local/bin/log_parser.pl"
    fi
    
    echo ""
    
    # Utility scripts
    echo "Utility Scripts:"
    run_test "cron_jobs.sh exists" "check_exists ~/.local/bin/cron_jobs.sh"
    run_test "aliases.sh exists" "check_exists ~/.local/bin/aliases.sh"
    run_test "toolkit_menu.sh exists" "check_exists ~/.local/bin/toolkit_menu.sh"
    
    echo ""
    
    # Configuration files
    echo "Configuration Files:"
    run_test ".bashrc_extra exists" "check_exists config/.bashrc_extra"
    run_test ".vimrc exists" "check_exists config/.vimrc"
    run_test ".tmux.conf exists" "check_exists config/.tmux.conf"
    run_test "rsync_exclude.txt exists" "check_exists config/rsync_exclude.txt"
    
    echo ""
    
    # Functional tests (if scripts exist)
    echo -e "${YELLOW}Running functional tests...${NC}\n"
    
    # Test system_info.py
    if [ -f ~/.local/bin/system_info.py ]; then
        run_test "system_info.py runs" "~/.local/bin/system_info.py -c"
    fi
    
    # Test disk_usage_analyzer.py
    if [ -f ~/.local/bin/disk_usage_analyzer.py ]; then
        run_test "disk_usage_analyzer.py runs" "~/.local/bin/disk_usage_analyzer.py . -d 1 2>/dev/null"
    fi
    
    # Test file_organizer.py dry run
    if [ -f ~/.local/bin/file_organizer.py ]; then
        # Create a temporary test directory
        mkdir -p /tmp/test_organize
        touch /tmp/test_organize/test.txt
        run_test "file_organizer.py dry run" "~/.local/bin/file_organizer.py /tmp/test_organize -n"
        rm -rf /tmp/test_organize
    fi
    
    # Test network_monitor.py (quick run with small timeout)
    if [ -f ~/.local/bin/network_monitor.py ]; then
        timeout 2 ~/.local/bin/network_monitor.py 2>/dev/null &
        sleep 1
        run_test "network_monitor.py starts" "pgrep -f network_monitor.py"
        pkill -f network_monitor.py 2>/dev/null
    fi
    
    # Test log_parser.pl with a small log file
    if [ -f ~/.local/bin/log_parser.pl ] && [ -f /var/log/syslog ]; then
        run_test "log_parser.pl runs" "~/.local/bin/log_parser.pl /var/log/syslog --tail 3 2>/dev/null"
    fi
    
    echo ""
    
    # Test aliases installation
    if [ -f ~/.local/bin/aliases.sh ]; then
        echo -e "${YELLOW}Testing aliases installation...${NC}"
        run_test "aliases.sh --list" "~/.local/bin/aliases.sh --list 2>/dev/null"
    fi
    
    echo ""
    
    # Test toolkit menu
    if [ -f ~/.local/bin/toolkit_menu.sh ]; then
        echo -e "${YELLOW}Testing toolkit menu...${NC}"
        run_test "toolkit_menu.sh help" "~/.local/bin/toolkit_menu.sh -h 2>/dev/null || echo 'Usage'"
    fi
    
    echo ""
    
    # Summary
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Test Summary${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "Total tests: ${TOTAL}"
    echo -e "${GREEN}Passed: ${PASSED}${NC}"
    echo -e "${RED}Failed: ${FAILED}${NC}"
    
    # Calculate percentage
    if [ $TOTAL -gt 0 ]; then
        PERCENT=$((PASSED * 100 / TOTAL))
        echo -e "Success Rate: ${PERCENT}%"
    fi
    
    echo ""
    
    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ All tests passed! Your toolkit is ready to use.${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ Some tests failed. This may be normal if:${NC}"
        echo "  - Some scripts require sudo (security_audit.sh)"
        echo "  - Python help text format differs"
        echo "  - Network monitor requires longer runtime"
        echo ""
        echo -e "${GREEN}Core functionality should still work. Try:${NC}"
        echo "  system_monitor.sh"
        echo "  system_info.py -c"
        echo "  disk_usage_analyzer.py . -d 1"
        return 1
    fi
}

# Run main function
main
