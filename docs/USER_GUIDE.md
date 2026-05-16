# User Guide - Advanced Linux Toolkit

## Table of Contents
1. [Getting Started](#getting-started)
2. [Interactive Menu](#interactive-menu)
3. [System Monitoring](#system-monitoring)
4. [Backup Management](#backup-management)
5. [Security Auditing](#security-auditing)
6. [Log Analysis](#log-analysis)
7. [Network Tools](#network-tools)
8. [Disk Management](#disk-management)
9. [File Organization](#file-organization)
10. [User Management](#user-management)
11. [Process Management](#process-management)

---

## Getting Started

### Step 1: Clone the Repository

```bash
git clone https://github.com/tahleho3968/advanced-linux-toolkit.git
cd advanced-linux-toolkit
```

### Step 2: Grant Execute Permissions

```bash
chmod +x permissions.sh
./permissions.sh
```

**Expected Output:**
```
========================================
  Setting Permissions for All Scripts
========================================

Bash Scripts:
  ✓ Set executable: system_monitor.sh
  ✓ Set executable: backup_manager.sh
  ...

========================================
Permissions fixed: 15
Already executable: 4
========================================
```

### Step 3: Verify Permissions & Test the Scripts
**Step 3.1: Verify Permissions** 
```bash
./permissions.sh --check
```

**Expected Output:**
```
========================================
  Checking Script Permissions
========================================

Bash Scripts:
  ✓ system_monitor.sh
  ✓ backup_manager.sh
  ...

Summary:
  Total scripts: 19
  Executable: 19
  Need permission: 0

✓ All scripts have correct permissions!
```

**Step 3.2: Test the Scripts**
```bash
./tests/test_scripts.sh
```


### Step 4: Install Dependencies and Virtual Environment

```bash
./scripts/auto_setup.sh
```

This will:
- Create a Python virtual environment at `~/.linux-toolkit-venv`
- Install all required Python packages (psutil, matplotlib, pandas, etc.)
- Set up logging directories
- Configure bashrc for auto-activation

### Step 5: Activate the Environment

```bash
source ~/.linux-toolkit-activate
```

You should see:
```
✓ Linux Toolkit environment activated
  Python: Python 3.x.x
  Pip: pip xx.xx from ...
```

### Step 6: Install Toolkit Scripts

```bash
make install
```

**Expected Output:**
```
=========================================
  Installing Advanced Linux Toolkit
=========================================

Installing Bash scripts...
  Installed: system_monitor.sh
  Installed: backup_manager.sh
  ...

Installing Python scripts...
  Installed: system_info.py
  Installed: file_organizer.py
  ...

Installing Perl scripts...
  Installed: log_parser.pl

Installing utility scripts...
  Installed: cron_jobs.sh
  Installed: aliases.sh

=========================================
  Installation complete!
=========================================
```

### Step 7: Set Up Command Aliases

```bash
./scripts/aliases.sh --install
source ~/.bashrc
```

### Step 8: Set Up Cron Jobs (Optional)

```bash
./scripts/cron_jobs.sh --install
```

---

## Interactive Menu

The toolkit includes a user-friendly interactive menu that provides easy access to all features.

### Launch the Main Menu

```bash
# After installation, simply run:
toolkit
```

Or from the source directory:

```bash
./scripts/toolkit_menu.sh
```

### Main Menu Options

```
╔════════════════════════════════════════════════════════════════════════════╗
║                    ADVANCED LINUX TOOLKIT v2.0                              ║
╠════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║  📊 SYSTEM HEALTH                                                          ║
║     1. System Monitor (Real-time)                                          ║
║     2. System Information                                                  ║
║     3. Process Manager                                                     ║
║                                                                            ║
║  🔒 SECURITY                                                               ║
║     4. Security Audit (Full)                                               ║
║     5. Check Open Ports                                                    ║
║     6. Check Failed Logins                                                 ║
║     7. Harden System                                                       ║
║                                                                            ║
║  💾 BACKUP                                                                 ║
║     8. Full Backup                                                         ║
║     9. Incremental Backup                                                  ║
║    10. List Backups                                                        ║
║    11. Restore Backup                                                      ║
║                                                                            ║
║  📝 LOG ANALYSIS                                                           ║
║    12. Analyze System Logs                                                 ║
║    13. Generate HTML Report                                                ║
║    14. Parse Large Log File (Perl)                                         ║
║    15. Visualize Log Data                                                  ║
║                                                                            ║
║  🌐 NETWORK                                                                ║
║    16. Ping Scan                                                           ║
║    17. Port Scan                                                           ║
║    18. Full Network Scan                                                   ║
║    19. Service Detection                                                   ║
║    20. Network Monitor (Real-time)                                         ║
║                                                                            ║
║  🧹 MAINTENANCE                                                            ║
║    21. Disk Cleanup (Dry Run)                                              ║
║    22. Disk Cleanup (Execute)                                              ║
║    23. Disk Usage Analyzer                                                 ║
║    24. File Organizer                                                      ║
║                                                                            ║
║  👤 USER MANAGEMENT                                                        ║
║    25. List Users                                                          ║
║    26. Add User                                                            ║
║    27. Delete User                                                         ║
║    28. Change User Password                                                ║
║                                                                            ║
║  ⚙️  UTILITIES                                                             ║
║    29. Manage Aliases                                                      ║
║    30. Manage Cron Jobs                                                    ║
║    31. View Toolkit Info                                                   ║
║                                                                            ║
║     0. Exit                                                                ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝
```

### Using the Interactive Menu

```bash
# After launching the menu, simply enter the number of your choice:

Enter choice: 1

# This will launch the System Monitor
# After the tool finishes, you'll return to the menu
```

### Quick Access Aliases (Available After Installation)

| Alias | Command | Description |
|-------|---------|-------------|
| `toolkit` | `./scripts/toolkit_menu.sh` | Launch main menu |
| `sysmon` | `system_monitor.sh` | Real-time system monitor |
| `sysinfo` | `system_info.py` | Detailed system info |
| `security` | `sudo security_audit.sh` | Full security audit |
| `backup` | `backup_manager.sh` | Backup manager |
| `logs` | `log_analyzer.sh` | Log analyzer |
| `netscan` | `network_scanner.sh` | Network scanner |
| `netmon` | `network_monitor.py` | Network monitor |
| `diskclean` | `disk_cleaner.sh` | Disk cleanup |
| `diskusage` | `disk_usage_analyzer.py` | Disk usage analyzer |
| `organizer` | `file_organizer.py` | File organizer |
| `users` | `sudo user_manager.sh` | User manager |
| `psmon` | `process_manager.sh` | Process manager |

---

## System Monitoring

### Real-time System Monitor (`system_monitor.sh`)

```bash
# From menu: Option 1
# Or directly:
sysmon

# Monitor with logging
system_monitor.sh -l /var/log/system.log

# Email alerts when CPU > 80%
system_monitor.sh -c 80 -e admin@example.com
```

**Output Example:**
```
========================================
        SYSTEM INFORMATION
========================================
Hostname: myserver
Kernel: 5.15.0-91-generic
OS: Ubuntu 22.04.3 LTS
Uptime: 3 days, 4 hours, 12 minutes
Users logged in: 2

========================================
        CPU INFORMATION
========================================
CPU Usage: 15.2%
CPU Info: Intel(R) Core(TM) i7-8700K CPU @ 3.70GHz
CPU Cores: 12
```

### Detailed System Info (`system_info.py`)

```bash
# From menu: Option 2
# Or directly:
sysinfo

# Output in JSON format
system_info.py -j

# Show only CPU info
system_info.py -c

# Show only memory info
system_info.py -m
```

### Process Manager (`process_manager.sh`)

```bash
# From menu: Option 3
# Or directly:
psmon

# Interactive mode commands:
#   k <pid> - Kill process
#   r <pid> <value> - Renice process
#   m <pid> - Monitor process
#   s <field> - Change sort (cpu, mem, pid, name)
#   c <name> - Check if process is running
#   z - Show zombie processes
#   q - Quit
```

---

## Security Auditing

### Security Audit (`security_audit.sh`)

```bash
# From menu: Option 4 (Full Security Audit)
# Or directly:
sudo security

# Check open ports only (Option 5)
sudo security_audit.sh -p

# Check failed logins only (Option 6)
sudo security_audit.sh -f

# Harden system security (Option 7)
sudo security_audit.sh -h

# Send report via email
sudo security_audit.sh -e admin@example.com
```

**What the Audit Checks:**
- User accounts (root privileges, empty passwords, duplicate UIDs)
- File permissions (world-writable files, SUID/SGID files)
- Open ports and network connections
- Failed login attempts
- Rootkit detection
- SSH configuration
- Firewall status
- Running services

---

## Backup Management

### Backup Manager (`backup_manager.sh`)

```bash
# From menu: Option 8 (Full Backup)
# Or directly:
backup -b /home/user -d /backup -t full

# Incremental backup (Option 9)
backup -b /home/user -d /backup -t incremental

# List backups (Option 10)
backup --list

# Restore backup (Option 11)
backup --restore backup_file.tar.gz

# Verify backup
backup --verify backup_file.tar.gz

# Remote backup
backup -b /home/user -r remote.host.com -u user -p /backup
```

**Backup Types Explained:**

| Type | Description | Space | Speed | Best For |
|------|-------------|-------|-------|----------|
| Full | Complete backup of all files | Most | Slowest | Weekly |
| Incremental | Only files changed since last backup | Least | Fastest | Daily |
| Differential | Files changed since last full backup | Medium | Medium | Weekly |

---

## Log Analysis

### Log Analyzer (`log_analyzer.sh`)

```bash
# From menu: Option 12 (Analyze System Logs)
# Or directly:
logs /var/log/syslog

# Show only errors
logs /var/log/syslog -e

# Show only warnings
logs /var/log/syslog -w

# Generate HTML report (Option 13)
logs /var/log/apache2/access.log -h

# Filter by date range
logs /var/log/syslog -f "2024-01-01" -t "2024-01-31"

# Show summary only
logs /var/log/syslog -s
```

### Log Parser (Perl) - For Large Files (`log_parser.pl`)

```bash
# From menu: Option 14 (Parse Large Log File)
# Or directly:
log_parser.pl /var/log/syslog

# Follow log file (like tail -f)
log_parser.pl --follow /var/log/syslog

# Show only errors with statistics
log_parser.pl --errors-only --stats /var/log/syslog

# Export to JSON
log_parser.pl --stats --format json /var/log/syslog

# Search with pattern
log_parser.pl --pattern "failed password" /var/log/auth.log
```

### Log Visualizer (`log_visualizer.py`)

```bash
# From menu: Option 15 (Visualize Log Data)
# Or directly:
log-viz /var/log/syslog

# Specify output prefix
log_visualizer.py /var/log/syslog -o my_report
```

**Generated Charts:**
- Timeline chart (events over time)
- Pie chart (log level distribution)
- Bar chart (top IP addresses)
- Hourly distribution chart

---

## Network Tools

### Network Scanner (`network_scanner.sh`)

```bash
# From menu: Option 16 (Ping Scan)
# Or directly:
netscan 192.168.1.1

# Port scan (Option 17)
netscan -t port -p 22,80,443 google.com

# Full port scan (Option 18)
sudo netscan -t full 192.168.1.1

# Service detection (Option 19)
sudo netscan -t service 192.168.1.1

# Scan network range
netscan 192.168.1.0/24

# Save results to file
netscan -t full 192.168.1.1 -o scan_results.txt
```

### Network Monitor (`network_monitor.py`)

```bash
# From menu: Option 20 (Network Monitor)
# Or directly:
netmon

# Continuous monitoring
netmon -c

# Monitor for 60 seconds
netmon -d 60

# Log to file
netmon -c -o network_stats.log

# Custom interval (2 seconds)
netmon -i 2
```

---

## Disk Management

### Disk Cleaner (`disk_cleaner.sh`)

```bash
# From menu: Option 21 (Dry Run)
# Or directly:
diskclean -n

# Execute cleanup (Option 22)
diskclean -y

# Set threshold to 90%
diskclean -t 90

# Skip temporary files
diskclean --no-temp

# Clean files older than 60 days
diskclean -d 60

# Full cleanup with logging
diskclean -y -l /var/log/cleanup.log
```

### Disk Usage Analyzer (`disk_usage_analyzer.py`)

```bash
# From menu: Option 23 (Disk Usage Analyzer)
# Or directly:
diskusage

# Analyze specific directory
diskusage /home/user

# Display directory tree
diskusage /home/user -t

# Set depth to 5
diskusage /home/user -d 5

# Export to JSON
diskusage /home/user -j report.json

# Minimum size 10MB
diskusage /home/user -m 10M
```

---

## File Organization

### File Organizer (`file_organizer.py`)

```bash
# From menu: Option 24 (File Organizer)
# Or directly:
organizer ~/Downloads

# Organize by date
organizer ~/Downloads -m date

# Organize by name (alphabetical)
organizer ~/Downloads -m name

# Dry run (preview only)
organizer ~/Downloads -n

# Process subdirectories recursively
organizer ~/Downloads -r

# Combine options
organizer ~/Downloads -m date -r -n
```

**Organization Methods:**

| Method | Description | Result Structure |
|--------|-------------|------------------|
| type | By file extension | Images/, Documents/, Videos/, etc. |
| date | By modification date | ByDate/2024/01_January/ |
| name | By first letter | ByName/A/, ByName/B/, ByName/0-9/ |

---

## User Management

### User Manager (`user_manager.sh`)

```bash
# From menu: Option 25 (List Users)
# Or directly:
users -l

# Add user (Option 26)
sudo users -a username

# Delete user (Option 27)
sudo users -d username

# Change password (Option 28)
sudo users -p username

# Show user info
users -i username

# Add user to group
sudo users -g add username groupname

# Remove user from group
sudo users -g remove username groupname

# Create group
sudo users -g create groupname

# Delete group
sudo users -g delete groupname
```

---

## Utilities

### Aliases Manager (`aliases.sh`)

```bash
# From menu: Option 29 (Manage Aliases)
# Or directly:
aliases.sh --install      # Install all aliases
aliases.sh --list         # List available aliases
aliases.sh --show         # Show installed aliases
aliases.sh --categorized  # Show categorized aliases
aliases.sh --remove       # Remove aliases
```

### Cron Jobs Manager (`cron_jobs.sh`)

```bash
# From menu: Option 30 (Manage Cron Jobs)
# Or directly:
cron_jobs.sh --install    # Install default cron jobs
cron_jobs.sh --list       # List current cron jobs
cron_jobs.sh --remove     # Remove all toolkit cron jobs
cron_jobs.sh --backup     # Backup current crontab
cron_jobs.sh --edit       # Edit cron jobs manually
```

### View Toolkit Info

```bash
# From menu: Option 31
# Or directly:
make info
```

---

## Quick Reference Card

```bash
# Quick Commands After Installation
toolkit          # Launch interactive menu
sysmon           # System monitor
security         # Security audit
backup           # Backup manager
logs             # Log analyzer
netscan          # Network scanner
diskclean        # Disk cleanup
organizer        # File organizer
users            # User manager
psmon            # Process manager
```

---

## Troubleshooting

### Common Issues and Solutions

| Issue | Solution |
|-------|----------|
| Permission denied | Run `./permissions.sh` again |
| Python module not found | Run `source ~/.linux-toolkit-activate` |
| Aliases not working | Run `source ~/.bashrc` |
| make: command not found | Install build-essential: `sudo apt install build-essential` |
| Cron jobs not running | Check service: `sudo systemctl status cron` |

### Getting Help

```bash
# Script-specific help
script_name.sh -h
script_name.sh --help

# Toolkit information
make info
make list
```

---

## Best Practices

1. **Always run permissions.sh first** - Ensures all scripts are executable
2. **Use the interactive menu** - Easiest way to access all features
3. **Dry run before destructive operations** - Use `-n` flag
4. **Regular backups** - Set up cron jobs for automated backups
5. **Weekly security audits** - Run `security` weekly
6. **Monthly cleanup** - Schedule `diskclean` via cron
7. **Keep virtual environment activated** - Or add to your bashrc

---

<div align="center">
  <sub>Built with ❤️ using Bash, Python, and Perl | Advanced Linux Administration Toolkit</sub>
</div>
