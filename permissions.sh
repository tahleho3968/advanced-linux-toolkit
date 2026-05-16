#!/bin/bash
# ============================================================
# permissions.sh - Set execute permissions for all toolkit scripts
#                 Automatically fixes Python shebangs
# ============================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Counters
TOTAL_FIXED=0
TOTAL_ALREADY=0
TOTAL_ERRORS=0

# Function to print colored output
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "  ${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "  ${YELLOW}○${NC} $1"
}

print_error() {
    echo -e "  ${RED}✗${NC} $1"
}

print_info() {
    echo -e "  ${CYAN}ℹ${NC} $1"
}

# Function to set permissions for a file
set_permission() {
    local file="$1"
    local filename=$(basename "$file")
    
    if [ ! -f "$file" ]; then
        print_error "File not found: $filename"
        TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
        return 1
    fi
    
    if [ -x "$file" ]; then
        print_warning "Already executable: $filename"
        TOTAL_ALREADY=$((TOTAL_ALREADY + 1))
        return 0
    fi
    
    if chmod +x "$file" 2>/dev/null; then
        print_success "Set executable: $filename"
        TOTAL_FIXED=$((TOTAL_FIXED + 1))
        return 0
    else
        print_error "Failed to set permission: $filename"
        TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
        return 1
    fi
}

# Function to process directory
process_directory() {
    local dir="$1"
    local pattern="$2"
    local description="$3"
    
    if [ ! -d "$dir" ]; then
        print_error "Directory not found: $dir"
        return 1
    fi
    
    echo -e "\n${MAGENTA}$description${NC}"
    
    local count=0
    for file in $dir/$pattern; do
        if [ -f "$file" ]; then
            set_permission "$file"
            count=$((count + 1))
        fi
    done
    
    if [ $count -eq 0 ]; then
        print_warning "No files found in $dir"
    fi
    
    return 0
}

# Function to run fix_shebangs.sh
run_fix_shebangs() {
    if [ -f "fix_shebangs.sh" ]; then
        echo -e "\n${MAGENTA}Running shebang fixer...${NC}"
        set_permission "fix_shebangs.sh"
        ./fix_shebangs.sh
        if [ $? -eq 0 ]; then
            print_success "Python shebangs fixed successfully"
        else
            print_warning "Shebang fixer encountered issues"
        fi
    else
        print_warning "fix_shebangs.sh not found - skipping shebang fix"
    fi
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Set execute permissions for all scripts in the Advanced Linux Toolkit.
Also automatically fixes Python script shebangs.

OPTIONS:
    -a, --all       Set permissions for all scripts (default)
    -b, --bash      Set permissions for bash scripts only
    -p, --python    Set permissions for python scripts only
    -l, --perl      Set permissions for perl scripts only
    -u, --utils     Set permissions for utility scripts only
    -m, --menu      Set permissions for menu script only
    -c, --check     Check permissions without changing
    -s, --single FILE Set permission for a single file
    -n, --no-shebang Skip shebang fix (don't run fix_shebangs.sh)
    -v, --verbose   Show verbose output
    -h, --help      Show this help message

EXAMPLES:
    ./permissions.sh              # Set permissions for all scripts + fix shebangs
    ./permissions.sh --bash       # Set permissions for bash scripts only
    ./permissions.sh --check      # Check which scripts need permissions
    ./permissions.sh --no-shebang # Skip shebang fix

EOF
    exit 0
}

# Function to check permissions only
check_permissions() {
    print_header "Checking Script Permissions"
    
    local total=0
    local executable=0
    local missing=0
    
    # Check bash scripts
    echo -e "\n${YELLOW}Bash Scripts:${NC}"
    for script in src/bash/*.sh; do
        if [ -f "$script" ]; then
            total=$((total + 1))
            if [ -x "$script" ]; then
                echo -e "  ${GREEN}✓${NC} $(basename "$script")"
                executable=$((executable + 1))
            else
                echo -e "  ${RED}✗${NC} $(basename "$script")"
                missing=$((missing + 1))
            fi
        fi
    done
    
    # Check python scripts
    echo -e "\n${YELLOW}Python Scripts:${NC}"
    for script in src/python/*.py; do
        if [ -f "$script" ]; then
            total=$((total + 1))
            if [ -x "$script" ]; then
                echo -e "  ${GREEN}✓${NC} $(basename "$script")"
                executable=$((executable + 1))
            else
                echo -e "  ${RED}✗${NC} $(basename "$script")"
                missing=$((missing + 1))
            fi
        fi
    done
    
    # Check perl scripts
    echo -e "\n${YELLOW}Perl Scripts:${NC}"
    for script in src/perl/*.pl; do
        if [ -f "$script" ]; then
            total=$((total + 1))
            if [ -x "$script" ]; then
                echo -e "  ${GREEN}✓${NC} $(basename "$script")"
                executable=$((executable + 1))
            else
                echo -e "  ${RED}✗${NC} $(basename "$script")"
                missing=$((missing + 1))
            fi
        fi
    done
    
    # Check utility scripts
    echo -e "\n${YELLOW}Utility Scripts:${NC}"
    for script in scripts/*.sh; do
        if [ -f "$script" ]; then
            total=$((total + 1))
            if [ -x "$script" ]; then
                echo -e "  ${GREEN}✓${NC} $(basename "$script")"
                executable=$((executable + 1))
            else
                echo -e "  ${RED}✗${NC} $(basename "$script")"
                missing=$((missing + 1))
            fi
        fi
    done
    
    # Check fix_shebangs.sh
    if [ -f "fix_shebangs.sh" ]; then
        total=$((total + 1))
        if [ -x "fix_shebangs.sh" ]; then
            echo -e "\n${GREEN}✓${NC} fix_shebangs.sh"
            executable=$((executable + 1))
        else
            echo -e "\n${RED}✗${NC} fix_shebangs.sh"
            missing=$((missing + 1))
        fi
    fi
    
    # Check menu script
    if [ -f "scripts/toolkit_menu.sh" ]; then
        total=$((total + 1))
        if [ -x "scripts/toolkit_menu.sh" ]; then
            echo -e "\n${GREEN}✓${NC} scripts/toolkit_menu.sh"
            executable=$((executable + 1))
        else
            echo -e "\n${RED}✗${NC} scripts/toolkit_menu.sh"
            missing=$((missing + 1))
        fi
    fi
    
    # Check test script
    if [ -f "tests/test_scripts.sh" ]; then
        total=$((total + 1))
        if [ -x "tests/test_scripts.sh" ]; then
            echo -e "\n${GREEN}✓${NC} tests/test_scripts.sh"
            executable=$((executable + 1))
        else
            echo -e "\n${RED}✗${NC} tests/test_scripts.sh"
            missing=$((missing + 1))
        fi
    fi
    
    echo -e "\n${BLUE}Summary:${NC}"
    echo -e "  Total scripts: $total"
    echo -e "  ${GREEN}Executable: $executable${NC}"
    echo -e "  ${RED}Need permission: $missing${NC}"
    
    if [ $missing -eq 0 ]; then
        echo -e "\n${GREEN}✓ All scripts have correct permissions!${NC}"
    else
        echo -e "\n${YELLOW}⚠ Run '$0 --all' to fix permissions for $missing script(s)${NC}"
    fi
}

# Function to set all permissions
set_all_permissions() {
    print_header "Setting Permissions for All Scripts"
    
    process_directory "src/bash" "*.sh" "Bash Scripts:"
    process_directory "src/python" "*.py" "Python Scripts:"
    process_directory "src/perl" "*.pl" "Perl Scripts:"
    process_directory "scripts" "*.sh" "Utility Scripts:"
    
    # Menu script
    echo -e "\n${MAGENTA}Menu Script:${NC}"
    set_permission "scripts/toolkit_menu.sh"
    
    # Test script
    echo -e "\n${MAGENTA}Test Script:${NC}"
    set_permission "tests/test_scripts.sh"
    
    # This script itself
    echo -e "\n${MAGENTA}This Script:${NC}"
    set_permission "$0"
    
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${GREEN}Permissions fixed: $TOTAL_FIXED${NC}"
    echo -e "${YELLOW}Already executable: $TOTAL_ALREADY${NC}"
    if [ $TOTAL_ERRORS -gt 0 ]; then
        echo -e "${RED}Errors: $TOTAL_ERRORS${NC}"
    fi
    echo -e "${BLUE}========================================${NC}"
}

# Function to set bash permissions only
set_bash_permissions() {
    print_header "Setting Permissions for Bash Scripts"
    process_directory "src/bash" "*.sh" "Bash Scripts:"
    process_directory "scripts" "*.sh" "Utility Scripts:"
    set_permission "scripts/toolkit_menu.sh"
    set_permission "tests/test_scripts.sh"
    set_permission "fix_shebangs.sh"
    echo -e "\n${GREEN}Bash permissions completed!${NC}"
}

# Function to set python permissions only
set_python_permissions() {
    print_header "Setting Permissions for Python Scripts"
    process_directory "src/python" "*.py" "Python Scripts:"
    echo -e "\n${GREEN}Python permissions completed!${NC}"
}

# Function to set perl permissions only
set_perl_permissions() {
    print_header "Setting Permissions for Perl Scripts"
    process_directory "src/perl" "*.pl" "Perl Scripts:"
    echo -e "\n${GREEN}Perl permissions completed!${NC}"
}

# Function to set menu script permission only
set_menu_permission() {
    print_header "Setting Permission for Menu Script"
    set_permission "scripts/toolkit_menu.sh"
    echo -e "\n${GREEN}Menu script permission set!${NC}"
}

# Function to set single file permission
set_single_permission() {
    local file="$1"
    if [ -z "$file" ]; then
        print_error "No file specified"
        echo "Usage: $0 --single <filename>"
        exit 1
    fi
    
    print_header "Setting Permission for Single File"
    set_permission "$file"
}

# Parse command line arguments
SKIP_SHEBANG=false
case "${1:-}" in
    -a|--all|"")
        set_all_permissions
        ;;
    -b|--bash)
        set_bash_permissions
        ;;
    -p|--python)
        set_python_permissions
        ;;
    -l|--perl)
        set_perl_permissions
        ;;
    -u|--utils)
        set_bash_permissions
        ;;
    -m|--menu)
        set_menu_permission
        ;;
    -c|--check)
        check_permissions
        exit 0
        ;;
    -s|--single)
        set_single_permission "$2"
        exit 0
        ;;
    -n|--no-shebang)
        SKIP_SHEBANG=true
        set_all_permissions
        ;;
    -v|--verbose)
        set -x
        set_all_permissions
        set +x
        ;;
    -h|--help)
        show_usage
        exit 0
        ;;
    *)
        echo -e "${RED}Error: Unknown option '$1'${NC}"
        show_usage
        exit 1
        ;;
esac

# Run shebang fixer automatically (unless skipped)
if [ "$SKIP_SHEBANG" = false ] && [ "$1" != "--check" ] && [ "$1" != "-c" ] && [ "$1" != "--help" ] && [ "$1" != "-h" ]; then
    run_fix_shebangs
fi

# Final message
if [ "$1" != "--check" ] && [ "$1" != "-c" ] && [ "$1" != "--help" ] && [ "$1" != "-h" ]; then
    echo -e "\n${GREEN}✓ All done! You can now run the scripts.${NC}"
    echo -e "${YELLOW}Tip: Run './permissions.sh --check' to verify permissions${NC}"
    echo -e "${CYAN}To launch the interactive menu: ./scripts/toolkit_menu.sh${NC}"
    echo -e "${CYAN}Or simply type: toolkit${NC}"
fi
