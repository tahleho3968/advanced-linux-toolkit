# Advanced Linux System Administration Toolkit

[![Bash](https://img.shields.io/badge/Bash-5.0+-green.svg)](https://www.gnu.org/software/bash/)
[![Python](https://img.shields.io/badge/Python-3.8+-blue.svg)](https://www.python.org/)
[![Perl](https://img.shields.io/badge/Perl-5.30+-red.svg)](https://www.perl.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

<div align="center">
  <img src="https://img.shields.io/badge/Status-Production_Ready-brightgreen" alt="Status">
  <img src="https://img.shields.io/badge/Scripts-15-blue" alt="Scripts">
  <img src="https://img.shields.io/badge/Languages-Bash%20%7C%20Python%20%7C%20Perl-orange" alt="Languages">
</div>

## 📋 Overview

A comprehensive, production-ready **Linux System Administration Toolkit** that automates common system management tasks, monitoring, security auditing, and maintenance. Perfect for system administrators, DevOps engineers, and Linux enthusiasts.

### 🎯 Key Features

#### 📊 System Monitoring
- Real-time CPU, memory, disk, and network monitoring
- Process management and monitoring
- System information collection
- Performance metrics and alerts

#### 💾 Backup & Recovery
- Automated backup system (full/incremental/differential)
- Remote backup support (SCP/RSync)
- Backup verification and restoration
- Scheduled backups with cron

#### 🔒 Security & Auditing
- System security audit
- User account management
- Failed login monitoring
- Rootkit detection
- SSH configuration audit
- Firewall status check

#### 📝 Log Management
- Advanced log file analysis
- Log parsing with Perl (high performance)
- Log visualization with charts
- Pattern detection and alerts
- Log rotation and cleanup

#### 🌐 Network Tools
- Network scanning (ping/port/service)
- Real-time network traffic monitoring
- Connection tracking
- Service detection

#### 🧹 Maintenance
- Disk cleanup automation
- File organization by type/date/name
- Temporary file cleanup
- Cache management

## 🏗️ Toolkit Components

| Category | Script | Language | Description |
|----------|--------|----------|-------------|
| **Monitoring** | system_monitor.sh | Bash | Real-time system resource monitor |
| | system_info.py | Python | Detailed system information |
| | process_manager.sh | Bash | Process monitoring and management |
| **Backup** | backup_manager.sh | Bash | Automated backup system |
| **Security** | security_audit.sh | Bash | Security auditing and hardening |
| | user_manager.sh | Bash | User account management |
| **Logs** | log_analyzer.sh | Bash | Log file analysis |
| | log_parser.pl | Perl | High-performance log parsing |
| | log_visualizer.py | Python | Log visualization with charts |
| **Network** | network_scanner.sh | Bash | Network discovery and scanning |
| | network_monitor.py | Python | Real-time network traffic monitor |
| **Maintenance** | disk_cleaner.sh | Bash | Automated disk cleanup |
| | disk_usage_analyzer.py | Python | Disk space analysis |
| | file_organizer.py | Python | File organization by type/date/name |

## 🚀 Quick Start

### Installation

```bash
# Clone the repository
git clone https://github.com/tahleho3968/advanced-linux-toolkit.git
cd advanced-linux-toolkit

# Run auto setup (installs dependencies)
./scripts/auto_setup.sh

# Install all scripts
make install

# Set up aliases
./scripts/aliases.sh --install

# Set up cron jobs (optional)
./scripts/cron_jobs.sh --install

# Reload bash configuration
source ~/.bashrc
```

### Quick Usage Examples

```bash
# System monitoring
sysmon                          # Real-time system monitor
sysinfo                         # Detailed system information

# Security
sudo security                   # Full security audit
sudo security -p               # Check open ports only

# Backup
backup -b /home/user -d /backup -t full

# Log analysis
logs /var/log/syslog
log-viz /var/log/syslog        # Generate HTML report

# Network
netscan 192.168.1.1
netmon                          # Real-time network monitor

# Disk cleanup
diskclean -n                    # Dry run
diskclean -y                    # Clean with confirmation
```

## 📁 Project Structure

```
advanced-linux-toolkit/
├── src/
│   ├── bash/                   # 8 Bash scripts
│   ├── python/                 # 5 Python scripts
│   └── perl/                   # 1 Perl script
├── scripts/                    # Utility scripts
│   ├── python_wrapper.sh      # Wrapper script for Python scripts to use the virtual environment
│   ├── toolkit_menu.sh        # Menu
│   ├── auto_setup.sh          # Dependency installer
│   ├── cron_jobs.sh           # Cron job manager
│   └── aliases.sh             # Alias manager
├── config/                     # Configuration files
│   ├── .bashrc_extra          # Bash enhancements
│   ├── .vimrc                 # Vim configuration
│   ├── .tmux.conf             # Tmux configuration
│   └── rsync_exclude.txt      # Rsync exclude patterns
├── permissions.sh
├── Makefile
├── README.md
├── INSTALL.md
├── CHANGELOG.md
├── LICENSE
└── .gitignore
```

## 🔧 Scripts Documentation

### System Monitor (`system_monitor.sh`)
```bash
# Basic usage
./system_monitor.sh

# Log to file
./system_monitor.sh -l /var/log/system.log

# Email alerts when CPU > 80%
./system_monitor.sh -c 80 -m admin@example.com
```

### Backup Manager (`backup_manager.sh`)
```bash
# Full backup
./backup_manager.sh -b /home/user -d /backup -t full

# List backups
./backup_manager.sh --list

# Restore backup
./backup_manager.sh --restore backup_file.tar.gz
```

### Security Audit (`security_audit.sh`)
```bash
# Full audit
sudo ./security_audit.sh

# Check open ports only
sudo ./security_audit.sh -p

# Harden system
sudo ./security_audit.sh -h
```

### Log Parser (`log_parser.pl`)
```bash
# Basic parsing
./log_parser.pl /var/log/syslog

# Show only errors with statistics
./log_parser.pl --errors-only --stats /var/log/syslog

# Follow log file
./log_parser.pl --follow /var/log/syslog

# Export to JSON
./log_parser.pl --stats --format json /var/log/syslog
```

## 📊 Performance

| Script | Language | Speed | Use Case |
|--------|----------|-------|----------|
| system_monitor.sh | Bash | Fast | Real-time monitoring |
| log_parser.pl | Perl | Very Fast | Large log files (GBs) |
| log_visualizer.py | Python | Moderate | Data visualization |
| network_monitor.py | Python | Moderate | Traffic analysis |

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Open Pull Request

## 📝 License

MIT License - see LICENSE file

## 👤 Author

**Tahleho Paki**
- GitHub: [@tahleho3968](https://github.com/tahleho3968)
- Email: tahleho3968@gmail.com

## 🙏 Acknowledgments

- Linux system administration community
- Open source tools (rsync, grep, awk, sed)
- Contributors and testers

---

<div align="center">
  <sub>Built with ❤️ using Bash, Python, and Perl | Advanced Linux Administration Toolkit</sub>
</div>
