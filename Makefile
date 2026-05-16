# Makefile for Advanced Linux Toolkit

.PHONY: all install clean help

# Script directories
INSTALL_DIR = $(HOME)/.local/bin

# Script lists
BASH_SCRIPTS = system_monitor.sh backup_manager.sh security_audit.sh \
               log_analyzer.sh user_manager.sh process_manager.sh \
               network_scanner.sh disk_cleaner.sh

PYTHON_SCRIPTS = system_info.py file_organizer.py network_monitor.py \
                 disk_usage_analyzer.py log_visualizer.py

PERL_SCRIPTS = log_parser.pl

UTILITY_SCRIPTS = cron_jobs.sh aliases.sh

all: install

install:
	@echo "========================================="
	@echo "  Installing Advanced Linux Toolkit"
	@echo "========================================="
	@mkdir -p $(INSTALL_DIR)
	@echo ""
	@echo "Installing Bash scripts..."
	@for script in $(BASH_SCRIPTS); do \
		if [ -f "src/bash/$$script" ]; then \
			cp src/bash/$$script $(INSTALL_DIR)/; \
			chmod +x $(INSTALL_DIR)/$$script; \
			echo "  Installed: $$script"; \
		fi \
	done
	@echo ""
	@echo "Installing Python scripts..."
	@for script in $(PYTHON_SCRIPTS); do \
		if [ -f "src/python/$$script" ]; then \
			cp src/python/$$script $(INSTALL_DIR)/; \
			chmod +x $(INSTALL_DIR)/$$script; \
			echo "  Installed: $$script"; \
		fi \
	done
	@echo ""
	@echo "Installing Perl scripts..."
	@for script in $(PERL_SCRIPTS); do \
		if [ -f "src/perl/$$script" ]; then \
			cp src/perl/$$script $(INSTALL_DIR)/; \
			chmod +x $(INSTALL_DIR)/$$script; \
			echo "  Installed: $$script"; \
		fi \
	done
	@echo ""
	@echo "Installing utility scripts..."
	@for script in $(UTILITY_SCRIPTS); do \
		if [ -f "scripts/$$script" ]; then \
			cp scripts/$$script $(INSTALL_DIR)/; \
			chmod +x $(INSTALL_DIR)/$$script; \
			echo "  Installed: $$script"; \
		fi \
	done
	@echo ""
	@echo "========================================="
	@echo "  Installation complete!"
	@echo "========================================="
	@echo ""
	@echo "Next steps:"
	@echo "  1. Run './scripts/aliases.sh --install' to set up command aliases"
	@echo "  2. Run './scripts/cron_jobs.sh --install' to set up automated tasks"
	@echo "  3. Run 'source ~/.bashrc' to enable aliases"
	@echo ""
	@echo "Quick test: system_monitor.sh"

clean:
	@echo "Removing installed scripts..."
	@for script in $(BASH_SCRIPTS); do \
		rm -f $(INSTALL_DIR)/$$script; \
		echo "  Removed: $$script"; \
	done
	@for script in $(PYTHON_SCRIPTS); do \
		rm -f $(INSTALL_DIR)/$$script; \
		echo "  Removed: $$script"; \
	done
	@for script in $(PERL_SCRIPTS); do \
		rm -f $(INSTALL_DIR)/$$script; \
		echo "  Removed: $$script"; \
	done
	@for script in $(UTILITY_SCRIPTS); do \
		rm -f $(INSTALL_DIR)/$$script; \
		echo "  Removed: $$script"; \
	done
	@echo "Cleanup complete"

help:
	@echo "========================================="
	@echo "  Advanced Linux Toolkit - Help"
	@echo "========================================="
	@echo ""
	@echo "Available targets:"
	@echo "  make install  - Install all scripts to ~/.local/bin"
	@echo "  make clean    - Remove installed scripts"
	@echo "  make help     - Show this help message"
	@echo ""
	@echo "Installed Scripts:"
	@echo "  Bash (8):"
	@echo "    system_monitor.sh   - Real-time system monitor"
	@echo "    backup_manager.sh   - Automated backup system"
	@echo "    security_audit.sh   - Security auditing tool"
	@echo "    log_analyzer.sh     - Log file analyzer"
	@echo "    user_manager.sh     - User management tool"
	@echo "    process_manager.sh  - Process monitor"
	@echo "    network_scanner.sh  - Network scanner"
	@echo "    disk_cleaner.sh     - Disk cleanup utility"
	@echo ""
	@echo "  Python (5):"
	@echo "    system_info.py      - System information collector"
	@echo "    file_organizer.py   - File organizer"
	@echo "    network_monitor.py  - Network traffic monitor"
	@echo "    disk_usage_analyzer.py - Disk usage analyzer"
	@echo "    log_visualizer.py   - Log visualization"
	@echo ""
	@echo "  Perl (1):"
	@echo "    log_parser.pl       - High-performance log parser"
	@echo ""
	@echo "  Utilities (2):"
	@echo "    cron_jobs.sh        - Cron job manager"
	@echo "    aliases.sh          - Alias manager"
	@echo ""
	@echo "For detailed usage: script_name -h"
