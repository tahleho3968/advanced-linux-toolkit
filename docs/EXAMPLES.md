# Examples - Advanced Linux Toolkit

## Real-World Usage Examples

### Example 1: Daily System Health Check

Create a daily health check script:

```bash
#!/bin/bash
# daily_health_check.sh

echo "=== Daily Health Check: $(date) ==="

# System monitoring
system_monitor.sh -l /var/log/health_check/system.log

# Disk usage
disk_usage_analyzer.py / -d 2

# Security quick check
sudo security_audit.sh -p -f

# Log errors
log_analyzer.sh /var/log/syslog -e -s

echo "=== Health check complete ==="
```

### Example 2: Weekly Backup Routine

```bash
#!/bin/bash
# weekly_backup.sh

BACKUP_DATE=$(date +%Y%m%d)
BACKUP_DIR="/backup/weekly"

# Full backup of home directory
backup_manager.sh -b /home -d $BACKUP_DIR -t full

# Backup important configs
backup_manager.sh -b /etc -d $BACKUP_DIR/etc_$BACKUP_DATE -t full

# Backup web files
backup_manager.sh -b /var/www -d $BACKUP_DIR/www_$BACKUP_DATE -t full

# Send to remote server
scp $BACKUP_DIR/*.tar.gz backup@remote:/backup/

# Verify backups
for backup in $BACKUP_DIR/*.tar.gz; do
    backup_manager.sh --verify $backup
done
```

### Example 3: Security Incident Response

```bash
#!/bin/bash
# incident_response.sh

ALERT_EMAIL="security@example.com"

echo "=== Security Incident Investigation ==="

# Full security audit
sudo security_audit.sh -e $ALERT_EMAIL

# Check failed logins
echo "Failed login attempts in last 24 hours:"
sudo security_audit.sh -f | grep "$(date -d 'yesterday' +%Y-%m-%d)"

# Check open ports
sudo security_audit.sh -p

# Check for rootkits
sudo security_audit.sh -r

# Analyze auth log
log_analyzer.sh /var/log/auth.log -e -f "$(date -d 'yesterday' +%Y-%m-%d)"

# Find recently modified files
find / -type f -mtime -1 -ls 2>/dev/null | head -50
```

### Example 4: Automated Disk Cleanup

```bash
#!/bin/bash
# auto_cleanup.sh

THRESHOLD=85
CURRENT_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

if [ $CURRENT_USAGE -gt $THRESHOLD ]; then
    echo "Disk usage at ${CURRENT_USAGE}%, running cleanup..."
    
    # Dry run first
    disk_cleaner.sh -n
    
    # Confirm with user
    read -p "Proceed with cleanup? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        disk_cleaner.sh -y -l /var/log/cleanup.log
    fi
else
    echo "Disk usage at ${CURRENT_USAGE}% - below threshold"
fi
```

### Example 5: Log Monitoring and Alerting

```bash
#!/bin/bash
# log_monitor.sh

LOG_FILE="/var/log/syslog"
ERROR_PATTERN="ERROR|FATAL|CRITICAL"
ALERT_EMAIL="admin@example.com"

# Count errors in last hour
ERROR_COUNT=$(log_analyzer.sh $LOG_FILE -e -s | grep "Errors:" | awk '{print $2}')

if [ $ERROR_COUNT -gt 10 ]; then
    echo "High error count detected: $ERROR_COUNT errors in last hour" | \
        mail -s "Alert: High Error Rate" $ALERT_EMAIL
    
    # Generate detailed report
    log_analyzer.sh $LOG_FILE -e -h -o error_report_$(date +%Y%m%d_%H%M%S)
fi
```

### Example 6: Network Performance Testing

```bash
#!/bin/bash
# network_test.sh

TARGET="8.8.8.8"
OUTPUT_DIR="/var/log/network_tests"
mkdir -p $OUTPUT_DIR

echo "=== Network Performance Test ==="

# Basic connectivity
network_scanner.sh $TARGET

# Port scan for DNS, HTTP, HTTPS
network_scanner.sh -t port -p 53,80,443 $TARGET

# Service detection
sudo network_scanner.sh -t service $TARGET

# Monitor network for 5 minutes
network_monitor.py -d 300 -o $OUTPUT_DIR/network_stats_$(date +%Y%m%d_%H%M%S).log
```

### Example 7: User Onboarding Script

```bash
#!/bin/bash
# onboard_user.sh

NEW_USER=$1
GROUP=${2:-users}

if [ -z "$NEW_USER" ]; then
    echo "Usage: $0 <username> [group]"
    exit 1
fi

echo "=== Onboarding user: $NEW_USER ==="

# Create user
sudo user_manager.sh -a $NEW_USER

# Add to specified group
sudo user_manager.sh -g add $NEW_USER $GROUP

# Setup SSH directory
sudo mkdir -p /home/$NEW_USER/.ssh
sudo chmod 700 /home/$NEW_USER/.ssh

# Copy skeleton files
cp -r /etc/skel/. /home/$NEW_USER/

# Set ownership
sudo chown -R $NEW_USER:$NEW_USER /home/$NEW_USER

echo "=== User $NEW_USER onboarded successfully ==="
echo "Please have them set their password: sudo passwd $NEW_USER"
```

### Example 8: File Organization Automation

```bash
#!/bin/bash
# organize_all.sh

DIRS=(
    "$HOME/Downloads"
    "$HOME/Desktop"
    "$HOME/Documents/incoming"
)

for DIR in "${DIRS[@]}"; do
    if [ -d "$DIR" ]; then
        echo "Organizing $DIR..."
        file_organizer.py "$DIR" -m type -r
    fi
done

# Clean up old files in Downloads
find "$HOME/Downloads" -type f -atime +30 -delete

echo "Organization complete!"
```

### Example 9: System Migration Preparation

```bash
#!/bin/bash
# migrate_prep.sh

BACKUP_DIR="/backup/migration_$(date +%Y%m%d)"

echo "=== Preparing for system migration ==="

# Backup critical data
backup_manager.sh -b /home -d $BACKUP_DIR -t full
backup_manager.sh -b /etc -d $BACKUP_DIR -t full
backup_manager.sh -b /var/lib/mysql -d $BACKUP_DIR -t full

# List installed packages
dpkg -l > $BACKUP_DIR/packages.txt

# List running services
systemctl list-units --type=service --state=running > $BACKUP_DIR/services.txt

# Export crontab
crontab -l > $BACKUP_DIR/crontab.txt

# Generate system info
system_info.py -j > $BACKUP_DIR/system_info.json

echo "=== Migration preparation complete ==="
echo "Backup location: $BACKUP_DIR"
```

### Example 10: Daily Log Rotation and Analysis

```bash
#!/bin/bash
# daily_log_processing.sh

YESTERDAY=$(date -d "yesterday" +%Y-%m-%d)
LOG_DIR="/var/log/linux-toolkit/daily"

mkdir -p $LOG_DIR

echo "=== Daily Log Processing: $YESTERDAY ==="

# Rotate and compress old logs
logrotate -f /etc/logrotate.conf

# Analyze syslog
log_analyzer.sh /var/log/syslog -s -f "$YESTERDAY" > $LOG_DIR/syslog_summary_$YESTERDAY.txt

# Generate HTML report
log_visualizer.py /var/log/syslog -o $LOG_DIR/syslog_report_$YESTERDAY

# Check for anomalies
ERROR_COUNT=$(grep -c "ERROR" $LOG_DIR/syslog_summary_$YESTERDAY.txt)
if [ $ERROR_COUNT -gt 50 ]; then
    echo "High error count detected: $ERROR_COUNT" | \
        mail -s "Daily Log Alert: High Error Rate" admin@example.com
fi

echo "=== Daily log processing complete ==="
```

### Example 11: Network Inventory Scan

```bash
#!/bin/bash
# network_inventory.sh

NETWORK="192.168.1.0/24"
OUTPUT_DIR="/var/log/network_inventory"
mkdir -p $OUTPUT_DIR

echo "=== Network Inventory Scan ==="

# Discover active hosts
network_scanner.sh $NETWORK -o $OUTPUT_DIR/active_hosts.txt

# Scan each active host
while read host; do
    echo "Scanning $host..."
    network_scanner.sh -t port -p 22,80,443,3306,5432 $host >> $OUTPUT_DIR/services.txt
done < $OUTPUT_DIR/active_hosts.txt

# Generate summary
echo "=== Inventory Summary ==="
echo "Active hosts: $(wc -l < $OUTPUT_DIR/active_hosts.txt)"
echo "Services found: $(grep -c "open" $OUTPUT_DIR/services.txt)"
```

### Example 12: Performance Baseline

```bash
#!/bin/bash
# performance_baseline.sh

BASELINE_DIR="/var/log/performance_baseline"
mkdir -p $BASELINE_DIR

echo "=== Capturing Performance Baseline ==="

# CPU info
lscpu > $BASELINE_DIR/cpu_info.txt

# Memory info
free -h > $BASELINE_DIR/memory_info.txt

# Disk info
df -h > $BASELINE_DIR/disk_info.txt

# Network info
ip addr show > $BASELINE_DIR/network_info.txt

# Running processes
ps aux --sort=-%cpu | head -20 > $BASELINE_DIR/top_cpu.txt
ps aux --sort=-%mem | head -20 > $BASELINE_DIR/top_memory.txt

# System load over time
for i in {1..10}; do
    uptime >> $BASELINE_DIR/load_average.txt
    sleep 60
done

echo "=== Baseline captured in $BASELINE_DIR ==="
```

## Combining Tools

### Complete System Health Report

```bash
#!/bin/bash
# health_report.sh

REPORT_DIR="/var/log/health_reports"
mkdir -p $REPORT_DIR
REPORT_FILE="$REPORT_DIR/health_$(date +%Y%m%d_%H%M%S).html"

echo "<html><body><h1>System Health Report</h1>" > $REPORT_FILE

# System info
echo "<h2>System Information</h2><pre>" >> $REPORT_FILE
system_info.py >> $REPORT_FILE
echo "</pre>" >> $REPORT_FILE

# Disk usage
echo "<h2>Disk Usage</h2><pre>" >> $REPORT_FILE
disk_usage_analyzer.py / -d 2 >> $REPORT_FILE
echo "</pre>" >> $REPORT_FILE

# Security audit summary
echo "<h2>Security Audit</h2><pre>" >> $REPORT_FILE
sudo security_audit.sh -s >> $REPORT_FILE
echo "</pre>" >> $REPORT_FILE

# Log analysis
echo "<h2>Log Summary</h2><pre>" >> $REPORT_FILE
log_analyzer.sh /var/log/syslog -s >> $REPORT_FILE
echo "</pre>" >> $REPORT_FILE

echo "</body></html>" >> $REPORT_FILE

echo "Health report generated: $REPORT_FILE"
```

## Interactive Dashboard

```bash
#!/bin/bash
# dashboard.sh

while true; do
    clear
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    SYSTEM DASHBOARD                          ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    
    # CPU
    echo "📊 CPU Usage:"
    system_monitor.sh -c | grep "CPU Usage"
    echo ""
    
    # Memory
    echo "💾 Memory:"
    free -h | awk '/^Mem:/ {print "  Used: " $3 " / " $2 " (" $3/$2*100 "%)"}'
    echo ""
    
    # Disk
    echo "💿 Disk:"
    df -h / | awk 'NR==2 {print "  Used: " $3 " / " $2 " (" $5 ")"}'
    echo ""
    
    # Connections
    echo "🌐 Active Connections:"
    netstat -tun | tail -n +3 | wc -l | xargs echo "  Total:"
    echo ""
    
    # Last logins
    echo "👤 Last 5 Logins:"
    last -n 5 | head -5
    echo ""
    
    sleep 5
done
