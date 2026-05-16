#!/bin/bash
# ============================================================
# Auto Setup Script - Install dependencies and configure system
# Creates isolated Python virtual environment
# ============================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Configuration
VENV_DIR="$HOME/.linux-toolkit-venv"
PYTHON_VERSION="python3"
REQUIREMENTS_FILE="/tmp/toolkit_requirements.txt"
LOG_FILE="/var/log/linux-toolkit/auto_setup.log"

# Create log directory
sudo mkdir -p /var/log/linux-toolkit
sudo chown $USER:$USER /var/log/linux-toolkit

# Function to log messages
log_message() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo -e "$msg" | tee -a "$LOG_FILE"
}

# Function to print colored output
print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Function to check if running on supported OS
check_os() {
    print_header "Checking Operating System"
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
        print_success "OS: $OS $VER"
        
        case $OS in
            *Ubuntu*|*Debian*)
                PKG_MANAGER="apt"
                PKG_UPDATE="sudo apt update"
                PKG_INSTALL="sudo apt install -y"
                ;;
            *CentOS*|*Red*|*Fedora*)
                PKG_MANAGER="yum"
                PKG_UPDATE="sudo yum update -y"
                PKG_INSTALL="sudo yum install -y"
                ;;
            *SUSE*)
                PKG_MANAGER="zypper"
                PKG_UPDATE="sudo zypper refresh"
                PKG_INSTALL="sudo zypper install -y"
                ;;
            *Arch*)
                PKG_MANAGER="pacman"
                PKG_UPDATE="sudo pacman -Sy"
                PKG_INSTALL="sudo pacman -S --noconfirm"
                ;;
            *)
                print_warning "Unknown OS: $OS"
                print_info "You may need to install packages manually"
                PKG_MANAGER="unknown"
                ;;
        esac
    else
        print_warning "Cannot detect OS"
        PKG_MANAGER="unknown"
    fi
}

# Function to install system packages
install_system_packages() {
    print_header "Installing System Packages"
    
    if [ "$PKG_MANAGER" = "unknown" ]; then
        print_warning "Skipping automatic package installation"
        print_info "Please install the following packages manually:"
        echo "  - python3, python3-pip, python3-venv"
        echo "  - htop, iotop, ncdu, rsync, net-tools, nmap"
        echo "  - curl, wget, tree, tmux, vim"
        echo "  - mailutils, logrotate, rkhunter, chkrootkit"
        return
    fi
    
    log_message "Updating package lists..."
    $PKG_UPDATE 2>/dev/null || print_warning "Update skipped"
    
    log_message "Installing packages..."
    
    case $PKG_MANAGER in
        apt)
            $PKG_INSTALL python3 python3-pip python3-venv \
                htop iotop ncdu rsync net-tools nmap \
                curl wget tree tmux vim \
                mailutils logrotate rkhunter chkrootkit
            ;;
        yum)
            $PKG_INSTALL python3 python3-pip \
                htop iotop ncdu rsync net-tools nmap \
                curl wget tree tmux vim \
                mailx logrotate rkhunter chkrootkit
            ;;
        pacman)
            $PKG_INSTALL python python-pip \
                htop iotop ncdu rsync net-tools nmap \
                curl wget tree tmux vim \
                mailutils logrotate rkhunter chkrootkit
            ;;
        *)
            $PKG_INSTALL python3 python3-pip python3-venv \
                htop iotop ncdu rsync net-tools nmap \
                curl wget tree tmux vim \
                mailutils logrotate rkhunter chkrootkit 2>/dev/null || \
                print_warning "Some packages may not have installed correctly"
            ;;
    esac
    
    print_success "System packages installed"
}

# Function to create requirements file
create_requirements_file() {
    cat > "$REQUIREMENTS_FILE" << 'EOF'
# Advanced Linux Toolkit - Python Requirements
# Install using: pip install -r requirements.txt

# System information and monitoring
psutil>=5.9.0

# Data visualization and charts
matplotlib>=3.5.0
numpy>=1.21.0

# Data manipulation and analysis
pandas>=1.3.0

# Additional utilities
requests>=2.25.0
colorama>=0.4.4

# JSON handling (built-in, but included for completeness)
# Note: json is part of Python standard library
EOF
}

# Function to setup virtual environment
setup_virtual_env() {
    print_header "Setting Up Python Virtual Environment"
    
    # Check if python3-venv is installed
    if ! python3 -c "import venv" 2>/dev/null; then
        print_error "python3-venv not found. Installing..."
        case $PKG_MANAGER in
            apt) sudo apt install -y python3-venv ;;
            yum) sudo yum install -y python3-venv ;;
            pacman) sudo pacman -S --noconfirm python-virtualenv ;;
            *) print_error "Please install python3-venv manually"; exit 1 ;;
        esac
    fi
    
    # Remove existing virtual environment if it exists
    if [ -d "$VENV_DIR" ]; then
        print_info "Removing existing virtual environment..."
        rm -rf "$VENV_DIR"
    fi
    
    # Create new virtual environment
    log_message "Creating virtual environment at $VENV_DIR"
    python3 -m venv "$VENV_DIR"
    
    if [ $? -eq 0 ]; then
        print_success "Virtual environment created at $VENV_DIR"
    else
        print_error "Failed to create virtual environment"
        exit 1
    fi
    
    # Create requirements file
    create_requirements_file
    
    # Activate virtual environment and install packages
    print_info "Installing Python packages in virtual environment..."
    
    # Upgrade pip first
    "$VENV_DIR/bin/pip" install --upgrade pip setuptools wheel
    
    # Install requirements
    "$VENV_DIR/bin/pip" install -r "$REQUIREMENTS_FILE"
    
    if [ $? -eq 0 ]; then
        print_success "Python packages installed successfully"
    else
        print_error "Failed to install some packages"
        print_info "You may need to install them manually:"
        echo "  $VENV_DIR/bin/pip install -r $REQUIREMENTS_FILE"
    fi
    
    # Clean up
    rm -f "$REQUIREMENTS_FILE"
}

# Function to create activation script
create_activation_script() {
    cat > "$HOME/.linux-toolkit-activate" << EOF
# Linux Toolkit Virtual Environment Activation
# Source this file to activate the toolkit environment

export TOOLKIT_VENV="$VENV_DIR"
export PATH="\$TOOLKIT_VENV/bin:\$PATH"
export PYTHONPATH="\$TOOLKIT_VENV/lib/python3*/site-packages:\$PYTHONPATH"

# Alias for activating environment
alias toolkit-activate="source \$TOOLKIT_VENV/bin/activate"
alias toolkit-deactivate="deactivate"

# Automatically activate for toolkit scripts
toolkit-activate 2>/dev/null

echo "✓ Linux Toolkit environment activated"
echo "  Python: \$(python3 --version)"
echo "  Pip: \$(pip --version)"
EOF

    chmod +x "$HOME/.linux-toolkit-activate"
    print_success "Activation script created at ~/.linux-toolkit-activate"
}

# Function to update shebang lines in Python scripts
update_python_shebangs() {
    print_header "Updating Python Script Shebangs"
    
    local python_path="$VENV_DIR/bin/python3"
    local scripts_dir="src/python"
    
    if [ -d "$scripts_dir" ]; then
        for script in "$scripts_dir"/*.py; do
            if [ -f "$script" ]; then
                # Add virtual environment python to PATH in script
                sed -i "1s|.*|#!$python_path|" "$script" 2>/dev/null
                print_success "Updated: $(basename "$script")"
            fi
        done
    fi
    
    # Also update the wrapper scripts
    if [ -d "scripts" ]; then
        for script in scripts/*.sh; do
            if [ -f "$script" ]; then
                # Add virtual environment activation to bash scripts
                if ! grep -q "source.*toolkit-activate" "$script"; then
                    sed -i "2i# Activate toolkit virtual environment\nif [ -f \"\$HOME/.linux-toolkit-activate\" ]; then\n    source \"\$HOME/.linux-toolkit-activate\"\nfi\n" "$script"
                fi
                print_success "Updated wrapper: $(basename "$script")"
            fi
        done
    fi
}

# Function to update bashrc
update_bashrc() {
    print_header "Updating .bashrc Configuration"
    
    local BASHRC="$HOME/.bashrc"
    local MARKER="# Linux Toolkit Virtual Environment"
    
    if ! grep -q "$MARKER" "$BASHRC" 2>/dev/null; then
        cat >> "$BASHRC" << EOF

$MARKER
if [ -f "\$HOME/.linux-toolkit-activate" ]; then
    source "\$HOME/.linux-toolkit-activate"
fi
# End Linux Toolkit Configuration
EOF
        print_success "Added toolkit configuration to .bashrc"
    else
        print_info "Toolkit configuration already in .bashrc"
    fi
}

# Function to create log directory
setup_logging() {
    print_header "Setting Up Logging"
    
    sudo mkdir -p /var/log/linux-toolkit
    sudo chown $USER:$USER /var/log/linux-toolkit
    
    # Setup logrotate configuration
    sudo cat > /etc/logrotate.d/linux-toolkit << EOF
/var/log/linux-toolkit/*.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    create 644 $USER $USER
}
EOF
    
    print_success "Logging configured"
}

# Function to verify installation
verify_installation() {
    print_header "Verifying Installation"
    
    # Check virtual environment
    if [ -d "$VENV_DIR" ]; then
        print_success "Virtual environment exists"
        
        # Check Python version
        PYTHON_VER=$("$VENV_DIR/bin/python3" --version 2>&1)
        print_info "Python: $PYTHON_VER"
        
        # Check installed packages
        "$VENV_DIR/bin/pip" list 2>/dev/null | grep -E "psutil|matplotlib|pandas" | while read line; do
            print_success "Package: $line"
        done
    else
        print_error "Virtual environment not found"
    fi
    
    # Check activation script
    if [ -f "$HOME/.linux-toolkit-activate" ]; then
        print_success "Activation script exists"
    else
        print_error "Activation script missing"
    fi
}

# Function to show next steps
show_next_steps() {
    print_header "Setup Complete!"
    
    echo ""
    echo -e "${GREEN}✓ Virtual environment installed at: $VENV_DIR${NC}"
    echo -e "${GREEN}✓ Activation script: ~/.linux-toolkit-activate${NC}"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "  1. Activate the environment:"
    echo -e "     ${CYAN}source ~/.linux-toolkit-activate${NC}"
    echo ""
    echo "  2. OR restart your terminal (environment auto-activates)"
    echo ""
    echo "  3. Install the toolkit scripts:"
    echo -e "     ${CYAN}make install${NC}"
    echo ""
    echo "  4. Set up aliases:"
    echo -e "     ${CYAN}./scripts/aliases.sh --install${NC}"
    echo ""
    echo "  5. Set up cron jobs (optional):"
    echo -e "     ${CYAN}./scripts/cron_jobs.sh --install${NC}"
    echo ""
    echo -e "${YELLOW}To verify the installation:${NC}"
    echo -e "  ${CYAN}python3 -c \"import psutil, matplotlib, pandas; print('All modules loaded')\"${NC}"
    echo ""
    echo -e "${GREEN}Happy monitoring!${NC}"
}

# Main function
main() {
    log_message "Starting Advanced Linux Toolkit Setup"
    
    echo -e "${MAGENTA}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║           Advanced Linux Toolkit - Auto Setup                 ║"
    echo "║                  Python Virtual Environment                    ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    check_os
    install_system_packages
    setup_virtual_env
    create_activation_script
    update_python_shebangs
    update_bashrc
    setup_logging
    verify_installation
    show_next_steps
    
    log_message "Setup completed successfully"
}

# Run main function
main "$@"
