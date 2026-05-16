# Troubleshooting Guide

## Common Issues and Solutions

### Installation Issues

#### Issue: Permission denied when running scripts

**Solution:**
```bash
chmod +x script_name.sh
# or for all scripts
chmod +x ~/.local/bin/*
```

#### Issue: Python modules not found

**Solution:**
```bash
pip3 install --user psutil matplotlib pandas
# or with sudo
sudo pip3 install psutil matplotlib pandas
```

#### Issue: Perl module not found

**Solution:**
```bash
sudo cpan install JSON
# or
sudo apt install libjson-perl
```

#### Issue: Command not found

**Solution:**
```bash
# Add to PATH
export PATH="$HOME/.local/bin:$PATH"
# Add to ~/.bashrc for permanent
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
```

### System Monitor Issues

#### Issue: CPU usage shows 0%

**Solution:**
```bash
# Install sysstat package
sudo apt install sysstat
# Or use alternative method
top -bn1 | grep "Cpu(s)"
```

#### Issue: Email alerts not sending

**Solution:**
```bash
# Install mailutils
sudo apt install mailutils
# Configure mail
sudo dpkg-reconfigure postfix
# Test mail
echo "test" | mail -s "test" your@email.com
```

### Backup Issues

#### Issue: Permission denied creating backup

**Solution:**
```bash
# Ensure backup directory exists and has correct permissions
sudo mkdir -p /backup
sudo chown $USER:$USER /backup
```

#### Issue: Remote backup failing

**Solution:**
```bash
# Test SSH connection
ssh user@remote_host
# Setup SSH keys for passwordless login
ssh-keygen -t rsa
ssh-copy-id user@remote_host
```

#### Issue: Backup verification fails

**Solution:**
```bash
# Check disk space
df -h
# Check if backup file is corrupted
tar tf backup_file.tar.gz
```

### Security Audit Issues

#### Issue: Need to run as root

**Solution:**
```bash
# Always use sudo
sudo security_audit.sh
```

#### Issue: rkhunter not found

**Solution:**
```bash
# Install rkhunter
sudo apt install rkhunter
# Update database
sudo rkhunter --update
```

### Log Analysis Issues

#### Issue: Large log files take too long

**Solution:**
```bash
# Use Perl parser for large files
log_parser.pl large_log_file.log

# Limit date range
log_analyzer.sh /var/log/syslog -f "2024-01-01" -t "2024-01-31"
```

#### Issue: HTML report not generating

**Solution:**
```bash
# Install matplotlib
pip3 install matplotlib
# Check if DISPLAY is set
echo $DISPLAY
# Use Agg backend
export MPLBACKEND=Agg
```

### Network Issues

#### Issue: Port scan shows no results

**Solution:**
```bash
# Run with sudo for full scan
sudo network_scanner.sh -t full 192.168.1.1
# Check firewall
sudo ufw status
```

#### Issue: Network monitor shows no traffic

**Solution:**
```bash
# Check network interface
ip link show
# Ensure you have traffic
ping google.com
```

### Disk Cleanup Issues

#### Issue: Disk usage threshold not triggering

**Solution:**
```bash
# Check current usage
df -h /
# Lower threshold
disk_cleaner.sh -t 50
```

#### Issue: Files not being deleted

**Solution:**
```bash
# Run with sudo if needed
sudo disk_cleaner.sh -y
# Check file permissions
ls -la /path/to/file
```

### Process Manager Issues

#### Issue: Cannot kill process

**Solution:**
```bash
# Use SIGKILL
process_manager.sh -k 1234
# Or manually
sudo kill -9 1234
```

#### Issue: Process not found

**Solution:**
```bash
# Use full name with pgrep
pgrep -f "process name"
# List all processes
ps aux | grep -i "process name"
```

### Cron Job Issues

#### Issue: Cron jobs not running

**Solution:**
```bash
# Check cron service
sudo systemctl status cron
# Check crontab
crontab -l
# Check logs
grep CRON /var/log/syslog
```

#### Issue: Scripts not finding commands in cron

**Solution:**
```bash
# Use full paths in cron
0 2 * * * /usr/bin/python3 /home/user/script.py
# Or set PATH in crontab
PATH=/usr/local/bin:/usr/bin:/bin
0 2 * * * script.py
```

### Alias Issues

#### Issue: Aliases not working

**Solution:**
```bash
# Source bashrc
source ~/.bashrc
# Check if alias file exists
ls -la ~/.bashrc_aliases
# Reinstall aliases
aliases.sh --remove
aliases.sh --install
```

### General Troubleshooting

#### Enable Debug Mode

```bash
# For bash scripts
bash -x script_name.sh

# For Python scripts
python3 -u script_name.py

# For Perl scripts
perl -d script_name.pl
```

#### Check Logs

```bash
# Toolkit logs
tail -f /var/log/linux-toolkit/*.log

# System logs
tail -f /var/log/syslog

# Auth logs
tail -f /var/log/auth.log
```

#### Verbose Output

```bash
# Most scripts support -v for verbose
script_name.sh -v
```

#### Reset Configuration

```bash
# Remove all toolkit files
make clean
rm -rf ~/.local/bin/linux_toolkit*
rm -f ~/.bashrc_aliases

# Reinstall
make install
aliases.sh --install
```

### Getting Help

```bash
# Script-specific help
script_name.sh -h
script_name.sh --help

# Check version
script_name.sh --version
```

### Reporting Issues

When reporting issues, include:

1. **Script name and version**
```bash
script_name.sh --version
```

2. **Error message**
```bash
# Capture full output
script_name.sh 2>&1 | tee error.log
```

3. **System information**
```bash
system_info.py
```

4. **Steps to reproduce**

## Frequently Asked Questions (FAQ)

### Q: Can I use these scripts on CentOS/RHEL?
A: Yes, but you may need to adjust package names in `auto_setup.sh` (`yum install` instead of `apt install`).

### Q: How much disk space do I need for backups?
A: Depends on your data. Use `disk_usage_analyzer.py` to estimate.

### Q: How often should I run security audits?
A: Weekly for normal systems, daily for high-security environments.

### Q: Can I schedule backups more frequently?
A: Yes, edit cron jobs with `cron_jobs.sh --edit`.

### Q: Are my backups encrypted?
A: Use the `-c` flag with `backup_manager.sh` for GPG encryption.

### Q: How long are logs retained?
A: Logrotate is configured for weekly rotation, 4 weeks retention.

### Q: Can I run these scripts remotely via SSH?
A: Yes, all scripts work over SSH sessions.

### Q: Do I need root for all scripts?
A: Only security audits and system modifications need root. Monitoring scripts work as regular user.
