# Installation Guide

## System Requirements

- **OS:** Linux (Ubuntu 18.04+, Debian 10+, CentOS 7+, RHEL 7+)
- **Bash:** 4.0+
- **Python:** 3.6+
- **Perl:** 5.20+
- **Disk Space:** ~100MB
- **Memory:** 512MB minimum

## Quick Installation

### Step 1: Clone the Repository

```bash
git clone https://github.com/tahleho3968/advanced-linux-toolkit.git
cd advanced-linux-toolkit
```

### Step 2: Run Auto Setup

```bash
chmod +x scripts/auto_setup.sh
./scripts/auto_setup.sh
```

This will install all required dependencies:
- `htop`, `iotop`, `ncdu` - System monitoring
- `rsync` - Backup tool
- `nmap`, `net-tools` - Network tools
- `python3`, `python3-pip` - Python environment
- `psutil`, `matplotlib`, `pandas` - Python packages
- `mailutils` - Email alerts
- `logrotate` - Log management
- `rkhunter`, `chkrootkit` - Security tools

### Step 3: Install Scripts

```bash
make install
```

This installs all scripts to `~/.local/bin/`

### Step 4: Set Up Aliases (Optional)

```bash
./scripts/aliases.sh --install
source ~/.bashrc
```

### Step 5: Set Up Cron Jobs (Optional)

```bash
./scripts/cron_jobs.sh --install
```

## Manual Installation

### Option 1: Install Individual Scripts

```bash
# Copy to ~/.local/bin
cp src/bash/system_monitor.sh ~/.local/bin/
chmod +x ~/.local/bin/system_monitor.sh

# Repeat for other scripts
```

### Option 2: Add to PATH

Add to your `~/.bashrc`:
```bash
export PATH="$HOME/.local/bin:$PATH"
```

## Configuration

### Bash Enhancements

Add to `~/.bashrc`:
```bash
cat config/.bashrc_extra >> ~/.bashrc
```

### Vim Configuration

```bash
cp config/.vimrc ~/.vimrc
```

### Tmux Configuration

```bash
cp config/.tmux.conf ~/.tmux.conf
```

### Rsync Exclude File

```bash
# Use with rsync
rsync -av --exclude-from=config/rsync_exclude.txt /source/ /destination/
```

## Verification

Test the installation:

```bash
# Check if scripts are installed
ls ~/.local/bin/

# Test system monitor
system_monitor.sh

# Test Python script
system_info.py

# Test Perl script
log_parser.pl /var/log/syslog --stats
```

## Troubleshooting

### Permission Denied

```bash
chmod +x ~/.local/bin/*.sh
chmod +x ~/.local/bin/*.py
chmod +x ~/.local/bin/*.pl
```

### Python Module Not Found

```bash
pip3 install --user psutil matplotlib pandas
```

### Perl Module Not Found

```bash
sudo cpan JSON
```

### Cron Jobs Not Running

```bash
# Check crontab
crontab -l

# Check cron service
sudo systemctl status cron

# Check logs
grep CRON /var/log/syslog
```

## Uninstallation

```bash
# Remove aliases
./scripts/aliases.sh --remove

# Remove cron jobs
./scripts/cron_jobs.sh --remove

# Remove scripts
make clean

# Remove configuration files
rm -f ~/.bashrc_aliases
rm -f ~/.vimrc
rm -f ~/.tmux.conf
```

## Next Steps

1. Read the [README.md](README.md) for detailed usage
2. Check [CHANGELOG.md](CHANGELOG.md) for version history
3. Run `script_name -h` for help on individual scripts
