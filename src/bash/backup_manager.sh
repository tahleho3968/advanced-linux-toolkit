#!/bin/bash
# ============================================================
# Backup Manager v2.0 - Automated backup system
# Supports: Full, Incremental, Differential backups
# ============================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ── User-writable defaults (no root required) ──────────────
BACKUP_DIR="$HOME/backups"
LOG_FILE="$HOME/.local/share/linux-toolkit/backup_manager.log"
# ──────────────────────────────────────────────────────────

RETENTION_DAYS=30
BACKUP_TYPE="full"
SCHEDULE_TIME=""
COMPRESSION=true
ENCRYPTION=false
REMOTE_HOST=""
REMOTE_USER=""
REMOTE_PATH=""
EXCLUDE_FILE=""

# Ensure log directory exists before anything tries to write to it
mkdir -p "$(dirname "$LOG_FILE")"

# Function to show usage
usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Backup Options:"
    echo "  -b <dir>     Source directory to backup"
    echo "  -d <dir>     Destination backup directory (default: ~/backups)"
    echo "  -t <type>    Backup type: full, incremental, differential (default: full)"
    echo "  -e <file>    Exclude file list"
    echo ""
    echo "Schedule Options:"
    echo "  -s <schedule> Schedule backup (daily, weekly, monthly)"
    echo "  -T <time>    Time for scheduled backup (HH:MM)"
    echo ""
    echo "Remote Options:"
    echo "  -r <host>    Remote host for backup"
    echo "  -u <user>    Remote username"
    echo "  -p <path>    Remote path"
    echo ""
    echo "Other Options:"
    echo "  -R <days>    Retention days (default: 30)"
    echo "  -n           Disable compression"
    echo "  -c           Enable encryption"
    echo "  -l <file>    Log file (default: ~/.local/share/linux-toolkit/backup_manager.log)"
    echo "  -h           Show this help message"
    echo ""
    echo "Recovery Options:"
    echo "  --restore <backup>   Restore from backup file"
    echo "  --list              List available backups"
    echo "  --verify <backup>   Verify backup integrity"
    exit 0
}

# Parse command line arguments
RESTORE_MODE=false
LIST_MODE=false
VERIFY_MODE=false
BACKUP_SOURCE=""
RESTORE_FILE=""
VERIFY_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -b) BACKUP_SOURCE="$2"; shift 2 ;;
        -d) BACKUP_DIR="$2"; shift 2 ;;
        -t) BACKUP_TYPE="$2"; shift 2 ;;
        -e) EXCLUDE_FILE="$2"; shift 2 ;;
        -s) SCHEDULE="$2"; shift 2 ;;
        -T) SCHEDULE_TIME="$2"; shift 2 ;;
        -r) REMOTE_HOST="$2"; shift 2 ;;
        -u) REMOTE_USER="$2"; shift 2 ;;
        -p) REMOTE_PATH="$2"; shift 2 ;;
        -R) RETENTION_DAYS="$2"; shift 2 ;;
        -n) COMPRESSION=false; shift ;;
        -c) ENCRYPTION=true; shift ;;
        -l) LOG_FILE="$2"; mkdir -p "$(dirname "$LOG_FILE")"; shift 2 ;;
        --restore) RESTORE_MODE=true; RESTORE_FILE="$2"; shift 2 ;;
        --list) LIST_MODE=true; shift ;;
        --verify) VERIFY_MODE=true; VERIFY_FILE="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo -e "${RED}Unknown option: $1${NC}"; usage ;;
    esac
done

# Function to log messages
log_message() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo -e "$msg" | tee -a "$LOG_FILE"
}

# Function to create backup directory
create_backup_dir() {
    mkdir -p "$BACKUP_DIR"
    if [ ! -d "$BACKUP_DIR" ]; then
        echo -e "${RED}Error: Cannot create backup directory $BACKUP_DIR${NC}"
        exit 1
    fi
}

# Function to generate backup filename
generate_backup_name() {
    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_name="${BACKUP_TYPE}_backup_${timestamp}"

    if [ "$COMPRESSION" = true ]; then
        echo "${backup_name}.tar.gz"
    else
        echo "${backup_name}.tar"
    fi
}

# Function to perform full backup
full_backup() {
    local backup_file="$1"
    local backup_path="${BACKUP_DIR}/${backup_file}"

    log_message "${GREEN}Starting FULL backup of $BACKUP_SOURCE${NC}"

    local exclude_opts=()
    if [ -n "$EXCLUDE_FILE" ] && [ -f "$EXCLUDE_FILE" ]; then
        while IFS= read -r pattern; do
            [ -n "$pattern" ] && exclude_opts+=(--exclude="$pattern")
        done < "$EXCLUDE_FILE"
    fi

    if [ "$COMPRESSION" = true ]; then
        tar czf "$backup_path" "${exclude_opts[@]}" \
            -C "$(dirname "$BACKUP_SOURCE")" "$(basename "$BACKUP_SOURCE")" 2>/dev/null
    else
        tar cf "$backup_path" "${exclude_opts[@]}" \
            -C "$(dirname "$BACKUP_SOURCE")" "$(basename "$BACKUP_SOURCE")" 2>/dev/null
    fi

    if [ $? -eq 0 ]; then
        local backup_size
        backup_size=$(du -h "$backup_path" | cut -f1)
        log_message "${GREEN}✓ Full backup completed: $backup_file (Size: $backup_size)${NC}"

        if [ "$ENCRYPTION" = true ]; then
            gpg -c --batch --passphrase "$BACKUP_PASSPHRASE" "$backup_path"
            rm -f "$backup_path"
            log_message "${GREEN}✓ Backup encrypted${NC}"
        fi
        return 0
    else
        log_message "${RED}✗ Full backup failed${NC}"
        return 1
    fi
}

# Function to perform incremental backup
incremental_backup() {
    local backup_file="$1"
    local snapshot_file="${BACKUP_DIR}/.snapshot"
    local backup_path="${BACKUP_DIR}/${backup_file}"

    log_message "${GREEN}Starting INCREMENTAL backup of $BACKUP_SOURCE${NC}"

    if [ "$COMPRESSION" = true ]; then
        tar czf "$backup_path" -g "$snapshot_file" \
            -C "$(dirname "$BACKUP_SOURCE")" "$(basename "$BACKUP_SOURCE")" 2>/dev/null
    else
        tar cf "$backup_path" -g "$snapshot_file" \
            -C "$(dirname "$BACKUP_SOURCE")" "$(basename "$BACKUP_SOURCE")" 2>/dev/null
    fi

    if [ $? -eq 0 ]; then
        local backup_size
        backup_size=$(du -h "$backup_path" | cut -f1)
        log_message "${GREEN}✓ Incremental backup completed: $backup_file (Size: $backup_size)${NC}"
        return 0
    else
        log_message "${RED}✗ Incremental backup failed${NC}"
        return 1
    fi
}

# Function to perform differential backup
differential_backup() {
    local backup_file="$1"
    local last_full
    last_full=$(ls -t "${BACKUP_DIR}"/full_backup_*.tar* 2>/dev/null | head -1)
    local backup_path="${BACKUP_DIR}/${backup_file}"

    log_message "${GREEN}Starting DIFFERENTIAL backup of $BACKUP_SOURCE${NC}"

    if [ -f "$last_full" ]; then
        if [ "$COMPRESSION" = true ]; then
            tar czf "$backup_path" --newer-mtime="$last_full" \
                -C "$(dirname "$BACKUP_SOURCE")" "$(basename "$BACKUP_SOURCE")" 2>/dev/null
        else
            tar cf "$backup_path" --newer-mtime="$last_full" \
                -C "$(dirname "$BACKUP_SOURCE")" "$(basename "$BACKUP_SOURCE")" 2>/dev/null
        fi
    else
        log_message "${YELLOW}No previous full backup found — running full backup instead${NC}"
        full_backup "$backup_file"
        return $?
    fi

    if [ $? -eq 0 ]; then
        local backup_size
        backup_size=$(du -h "$backup_path" | cut -f1)
        log_message "${GREEN}✓ Differential backup completed: $backup_file (Size: $backup_size)${NC}"
        return 0
    else
        log_message "${RED}✗ Differential backup failed${NC}"
        return 1
    fi
}

# Function to send to remote host
send_to_remote() {
    local backup_file="$1"

    if [ -n "$REMOTE_HOST" ] && [ -n "$REMOTE_USER" ] && [ -n "$REMOTE_PATH" ]; then
        log_message "${GREEN}Sending backup to remote host $REMOTE_HOST${NC}"
        scp "${BACKUP_DIR}/${backup_file}" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}/"
        if [ $? -eq 0 ]; then
            log_message "${GREEN}✓ Backup sent to remote host${NC}"
        else
            log_message "${RED}✗ Failed to send backup to remote host${NC}"
        fi
    fi
}

# Function to rotate old backups
rotate_backups() {
    log_message "${GREEN}Rotating backups older than $RETENTION_DAYS days${NC}"
    find "$BACKUP_DIR" -name "*.tar*" -type f -mtime +"$RETENTION_DAYS" -delete
    find "$BACKUP_DIR" -name "*.gpg"  -type f -mtime +"$RETENTION_DAYS" -delete
    log_message "${GREEN}✓ Old backups removed${NC}"
}

# Function to list backups
list_backups() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}        AVAILABLE BACKUPS${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}Backup directory: $BACKUP_DIR${NC}"
    echo ""

    if [ -d "$BACKUP_DIR" ]; then
        local count
        count=$(ls "$BACKUP_DIR"/*.tar* "$BACKUP_DIR"/*.gpg 2>/dev/null | wc -l)

        if [ "$count" -eq 0 ]; then
            echo "  No backups found in $BACKUP_DIR"
        else
            ls -lh "$BACKUP_DIR" 2>/dev/null | grep -E "\.(tar|gz|gpg)" \
                | awk '{printf "  %-40s %8s  %s %s %s\n", $9, $5, $6, $7, $8}'
        fi
    else
        echo "  Backup directory does not exist: $BACKUP_DIR"
        echo "  Run a backup first to create it."
    fi
}

# Function to restore backup
restore_backup() {
    local backup_file="$1"
    local restore_path="${BACKUP_DIR}/restore_$(date '+%Y%m%d_%H%M%S')"

    mkdir -p "$restore_path"
    log_message "${GREEN}Restoring backup $backup_file to $restore_path${NC}"

    if [ "$ENCRYPTION" = true ]; then
        gpg -d --batch --passphrase "$BACKUP_PASSPHRASE" \
            "${BACKUP_DIR}/${backup_file}" | tar xf - -C "$restore_path"
    else
        if [[ "$backup_file" == *.gz ]]; then
            tar xzf "${BACKUP_DIR}/${backup_file}" -C "$restore_path"
        else
            tar xf "${BACKUP_DIR}/${backup_file}" -C "$restore_path"
        fi
    fi

    if [ $? -eq 0 ]; then
        log_message "${GREEN}✓ Backup restored successfully to $restore_path${NC}"
    else
        log_message "${RED}✗ Restore failed${NC}"
    fi
}

# Function to verify backup integrity
verify_backup() {
    local backup_file="$1"
    log_message "${GREEN}Verifying backup integrity: $backup_file${NC}"

    if [ "$ENCRYPTION" = true ]; then
        gpg -d --batch --passphrase "$BACKUP_PASSPHRASE" \
            "${BACKUP_DIR}/${backup_file}" | tar tf - > /dev/null 2>&1
    else
        if [[ "$backup_file" == *.gz ]]; then
            tar tzf "${BACKUP_DIR}/${backup_file}" > /dev/null 2>&1
        else
            tar tf "${BACKUP_DIR}/${backup_file}" > /dev/null 2>&1
        fi
    fi

    if [ $? -eq 0 ]; then
        log_message "${GREEN}✓ Backup integrity verified${NC}"
    else
        log_message "${RED}✗ Backup integrity check failed${NC}"
    fi
}

# Function to setup cron job
setup_cron() {
    local cron_cmd="$0 -b $BACKUP_SOURCE -d $BACKUP_DIR -t $BACKUP_TYPE"

    case "$SCHEDULE" in
        daily)   echo "0 1 * * *   $cron_cmd" | crontab - ;;
        weekly)  echo "0 1 * * 0   $cron_cmd" | crontab - ;;
        monthly) echo "0 1 1 * *   $cron_cmd" | crontab - ;;
        *)
            log_message "${RED}Invalid schedule type: $SCHEDULE (use daily, weekly, monthly)${NC}"
            return 1
            ;;
    esac

    log_message "${GREEN}✓ Cron job scheduled for $SCHEDULE at $SCHEDULE_TIME${NC}"
}

# ── Main ──────────────────────────────────────────────────

main() {
    # For list/restore/verify we don't need to create the backup dir
    if [ "$LIST_MODE" = true ]; then
        list_backups
        exit 0
    fi

    if [ "$RESTORE_MODE" = true ]; then
        create_backup_dir
        restore_backup "$RESTORE_FILE"
        exit 0
    fi

    if [ "$VERIFY_MODE" = true ]; then
        verify_backup "$VERIFY_FILE"
        exit 0
    fi

    # Creating a new backup requires the directory
    create_backup_dir

    if [ -z "$BACKUP_SOURCE" ]; then
        log_message "${RED}Error: Source directory not specified. Use -b <dir>${NC}"
        echo ""
        usage
    fi

    if [ ! -d "$BACKUP_SOURCE" ]; then
        log_message "${RED}Error: Source directory '$BACKUP_SOURCE' does not exist${NC}"
        exit 1
    fi

    local backup_file
    backup_file=$(generate_backup_name)

    case "$BACKUP_TYPE" in
        full)         full_backup         "$backup_file" ;;
        incremental)  incremental_backup  "$backup_file" ;;
        differential) differential_backup "$backup_file" ;;
        *)
            log_message "${RED}Error: Invalid backup type '$BACKUP_TYPE' (use full, incremental, differential)${NC}"
            exit 1
            ;;
    esac

    if [ $? -eq 0 ]; then
        send_to_remote "$backup_file"
        rotate_backups
    fi

    if [ -n "${SCHEDULE:-}" ] && [ -n "$SCHEDULE_TIME" ]; then
        setup_cron
    fi
}

main
