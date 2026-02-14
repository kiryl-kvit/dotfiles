# Restic Backup Setup Guide

Setting up automated restic backups from source machine to dedicated backup server via SSH, backing up specific directories under `/var`.

## Overview

- **Source:** Machine with data to backup
- **Destination:** Dedicated backup server
- **Transport:** SSH/SFTP over LAN
- **Schedule:** Weekly automated backups
- **Retention:** 7 daily, 4 weekly, 12 monthly snapshots

## Prerequisites (Phases 1 & 2 - Completed)

- Restic installed on source machine
- SSH key-based authentication configured between machines
- Restic repository initialized on backup server
- Repository location: `sftp:user@backup-server:/backup/restic-repo`

## Phase 3: Backup Configuration

### File 1: Password file
**Location:** `/root/.restic/password`
```
YOUR_REPOSITORY_PASSWORD_HERE
```
**Commands to create:**
```bash
sudo mkdir -p /root/.restic
sudo nano /root/.restic/password  # Add your restic repository password
sudo chmod 600 /root/.restic/password
```

### File 2: Exclusion patterns (optional but recommended)
**Location:** `/root/.restic/exclude.txt`
```
# Temporary files
*.tmp
*.temp
*.swp
*.swo

# Cache directories
/var/cache/*
/var/tmp/*

# Lock files
*.lock
*.pid

# Sockets
*.sock
*.socket

# Log files (uncomment if you don't want to backup logs)
# /var/log/*
```
**Commands to create:**
```bash
sudo nano /root/.restic/exclude.txt  # Add the above patterns
sudo chmod 644 /root/.restic/exclude.txt
```

### File 3: Main backup script
**Location:** `/root/.restic/backup.sh`
```bash
#!/bin/bash

# Restic backup script for backing up /var directories to remote server via SSH

# Configuration
BACKUP_USER="your-ssh-user"           # Replace with SSH username on backup server
BACKUP_SERVER="backup-server.lan"     # Replace with backup server hostname/IP
BACKUP_PATH="/backup/restic-repo"     # Replace with path on backup server
REPOSITORY="sftp:${BACKUP_USER}@${BACKUP_SERVER}:${BACKUP_PATH}"
PASSWORD_FILE="/root/.restic/password"
EXCLUDE_FILE="/root/.restic/exclude.txt"
LOG_FILE="/var/log/restic-backup.log"

# Directories to backup (CUSTOMIZE THESE)
BACKUP_PATHS=(
    "/var/www"                        # Example: web server files
    "/var/lib/your-app"               # Example: application data
    # Add more paths as needed
)

# Retention policy
KEEP_DAILY=7
KEEP_WEEKLY=4
KEEP_MONTHLY=12

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Start backup
log "=== Starting restic backup ==="

# Export password file location for restic
export RESTIC_PASSWORD_FILE="$PASSWORD_FILE"
export RESTIC_REPOSITORY="$REPOSITORY"

# Check if password file exists
if [ ! -f "$PASSWORD_FILE" ]; then
    log "ERROR: Password file not found at $PASSWORD_FILE"
    exit 1
fi

# Perform backup
log "Backing up: ${BACKUP_PATHS[*]}"

EXCLUDE_OPTION=""
if [ -f "$EXCLUDE_FILE" ]; then
    EXCLUDE_OPTION="--exclude-file=$EXCLUDE_FILE"
fi

restic backup \
    ${BACKUP_PATHS[@]} \
    $EXCLUDE_OPTION \
    --tag automated \
    --tag weekly \
    --verbose 2>&1 | tee -a "$LOG_FILE"

BACKUP_EXIT_CODE=${PIPESTATUS[0]}

if [ $BACKUP_EXIT_CODE -eq 0 ]; then
    log "Backup completed successfully"
else
    log "ERROR: Backup failed with exit code $BACKUP_EXIT_CODE"
    exit $BACKUP_EXIT_CODE
fi

# Apply retention policy (forget old snapshots)
log "Applying retention policy..."
restic forget \
    --keep-daily $KEEP_DAILY \
    --keep-weekly $KEEP_WEEKLY \
    --keep-monthly $KEEP_MONTHLY \
    --tag automated \
    --prune \
    --verbose 2>&1 | tee -a "$LOG_FILE"

FORGET_EXIT_CODE=${PIPESTATUS[0]}

if [ $FORGET_EXIT_CODE -eq 0 ]; then
    log "Retention policy applied successfully"
else
    log "WARNING: Retention policy failed with exit code $FORGET_EXIT_CODE"
fi

# Check repository integrity (every 4th backup - approximately monthly for weekly backups)
RANDOM_CHECK=$((RANDOM % 4))
if [ $RANDOM_CHECK -eq 0 ]; then
    log "Running repository integrity check..."
    restic check 2>&1 | tee -a "$LOG_FILE"
    CHECK_EXIT_CODE=${PIPESTATUS[0]}
    
    if [ $CHECK_EXIT_CODE -eq 0 ]; then
        log "Repository check passed"
    else
        log "WARNING: Repository check failed with exit code $CHECK_EXIT_CODE"
    fi
fi

log "=== Backup process completed ==="
log ""

exit 0
```

**Commands to create:**
```bash
sudo nano /root/.restic/backup.sh  # Add the above script
sudo chmod 700 /root/.restic/backup.sh
```

**Important:** Edit the script to customize:
- `BACKUP_USER`: Your SSH username on the backup server
- `BACKUP_SERVER`: Hostname or IP of your backup server
- `BACKUP_PATH`: Path where you initialized the restic repository
- `BACKUP_PATHS`: Array of directories under /var you want to backup

## Phase 4: Systemd Service & Timer

### File 4: Systemd service
**Location:** `/etc/systemd/system/restic-backup.service`
```ini
[Unit]
Description=Restic backup service
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=/root/.restic/backup.sh
User=root
Group=root

# Security settings
PrivateTmp=yes
NoNewPrivileges=yes

# Timeout settings (adjust based on your backup size)
TimeoutStartSec=0
TimeoutStopSec=30min

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=restic-backup

[Install]
WantedBy=multi-user.target
```

**Commands to create:**
```bash
sudo nano /etc/systemd/system/restic-backup.service  # Add the above content
sudo chmod 644 /etc/systemd/system/restic-backup.service
```

### File 5: Systemd timer
**Location:** `/etc/systemd/system/restic-backup.timer`
```ini
[Unit]
Description=Restic backup timer (weekly)
Requires=restic-backup.service

[Timer]
# Run every Sunday at 2:00 AM
OnCalendar=Sun *-*-* 02:00:00

# Run on boot if last run was missed
Persistent=true

# Add random delay of 0-30 minutes to avoid exact scheduling
RandomizedDelaySec=30min

[Install]
WantedBy=timers.target
```

**Commands to create:**
```bash
sudo nano /etc/systemd/system/restic-backup.timer  # Add the above content
sudo chmod 644 /etc/systemd/system/restic-backup.timer
```

**Note:** If you want different scheduling, modify the `OnCalendar` line:
- Daily at 2 AM: `OnCalendar=*-*-* 02:00:00`
- Every 6 hours: `OnCalendar=*-*-* 00/6:00:00`
- Twice daily (2 AM and 2 PM): `OnCalendar=*-*-* 02,14:00:00`

### Enable and start the timer:
```bash
sudo systemctl daemon-reload
sudo systemctl enable restic-backup.timer
sudo systemctl start restic-backup.timer
```

## Phase 5: Testing & Verification

### Test the backup script manually first:
```bash
# Run the backup manually
sudo /root/.restic/backup.sh

# Or via systemd service
sudo systemctl start restic-backup.service
```

### Check the logs:
```bash
# View the custom log file
sudo tail -f /var/log/restic-backup.log

# View systemd journal
sudo journalctl -u restic-backup.service -f
```

### Verify the timer is active:
```bash
# Check timer status
sudo systemctl status restic-backup.timer

# List all timers and see when next run is scheduled
sudo systemctl list-timers --all | grep restic
```

### Test snapshot listing:
```bash
# Set environment variables (replace with your values)
export RESTIC_REPOSITORY="sftp:user@backup-server:/backup/restic-repo"
export RESTIC_PASSWORD_FILE="/root/.restic/password"

# List all snapshots
sudo -E restic snapshots

# Show latest snapshot details
sudo -E restic snapshots --latest 1
```

### Test file restore:
```bash
# List files in latest snapshot
sudo -E restic ls latest

# Restore a specific file to /tmp for testing
sudo -E restic restore latest --target /tmp/restic-restore --include /var/www/test-file.txt

# Verify the restored file
sudo ls -la /tmp/restic-restore/var/www/
```

## Phase 6: Maintenance & Monitoring

### Manual repository maintenance commands:
```bash
# Check repository integrity
sudo -E restic check

# View repository statistics
sudo -E restic stats

# Manually prune repository to free space
sudo -E restic prune

# Check what would be removed by forget policy (dry-run)
sudo -E restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --dry-run
```

### Optional: Email notifications on failure

If you want email notifications when backups fail, modify the service file:

**Add to `/etc/systemd/system/restic-backup.service`** in the `[Service]` section:
```ini
OnFailure=status-email@%n.service
```

Then you'll need to set up `status-email@.service` (requires mail utilities like `mailutils` or `postfix`).

### Optional: Create a monitoring script
**Location:** `/root/.restic/check-last-backup.sh`
```bash
#!/bin/bash
# Check if last backup is recent enough

export RESTIC_REPOSITORY="sftp:user@backup-server:/backup/restic-repo"
export RESTIC_PASSWORD_FILE="/root/.restic/password"

# Get last snapshot timestamp
LAST_BACKUP=$(restic snapshots --json --latest 1 | jq -r '.[0].time')

if [ -z "$LAST_BACKUP" ] || [ "$LAST_BACKUP" = "null" ]; then
    echo "ERROR: No backups found!"
    exit 1
fi

# Convert to epoch seconds
LAST_BACKUP_EPOCH=$(date -d "$LAST_BACKUP" +%s)
NOW_EPOCH=$(date +%s)
DIFF_SECONDS=$((NOW_EPOCH - LAST_BACKUP_EPOCH))
DIFF_DAYS=$((DIFF_SECONDS / 86400))

# Alert if last backup is older than 8 days (for weekly backups)
if [ $DIFF_DAYS -gt 8 ]; then
    echo "WARNING: Last backup is $DIFF_DAYS days old!"
    exit 1
else
    echo "OK: Last backup was $DIFF_DAYS days ago"
    exit 0
fi
```

## Quick Reference Commands

```bash
# View timer schedule
sudo systemctl list-timers restic-backup.timer

# Check service status
sudo systemctl status restic-backup.service

# View logs
sudo journalctl -u restic-backup.service -n 50
sudo tail -100 /var/log/restic-backup.log

# Manual backup trigger
sudo systemctl start restic-backup.service

# Stop/disable automatic backups
sudo systemctl stop restic-backup.timer
sudo systemctl disable restic-backup.timer

# Re-enable automatic backups
sudo systemctl enable restic-backup.timer
sudo systemctl start restic-backup.timer

# List all snapshots
sudo -E restic -r sftp:user@backup-server:/backup/restic-repo snapshots

# Restore from specific snapshot
sudo -E restic -r sftp:user@backup-server:/backup/restic-repo restore SNAPSHOT_ID --target /restore/path
```

## Summary of Manual Steps

1. Create `/root/.restic/password` with your repository password (chmod 600)
2. Create `/root/.restic/exclude.txt` with exclusion patterns (chmod 644)
3. Create `/root/.restic/backup.sh` and customize the variables at the top (chmod 700)
4. Create `/etc/systemd/system/restic-backup.service` (chmod 644)
5. Create `/etc/systemd/system/restic-backup.timer` (chmod 644)
6. Run: `sudo systemctl daemon-reload`
7. Run: `sudo systemctl enable restic-backup.timer`
8. Run: `sudo systemctl start restic-backup.timer`
9. Test manually: `sudo systemctl start restic-backup.service`
10. Check logs: `sudo journalctl -u restic-backup.service -f`
11. Verify timer: `sudo systemctl list-timers | grep restic`

## Files Created

```
/root/.restic/password          # Repository password
/root/.restic/backup.sh         # Main backup script
/root/.restic/exclude.txt       # Exclusion patterns (optional)
/etc/systemd/system/restic-backup.service
/etc/systemd/system/restic-backup.timer
/var/log/restic-backup.log      # Log file (auto-created)
```

## Key Commands Reference

- Initialize: `restic -r <repo> init`
- Backup: `restic -r <repo> backup <paths>`
- List snapshots: `restic -r <repo> snapshots`
- Restore: `restic -r <repo> restore <snapshot-id> --target /restore/path`
- Forget old backups: `restic -r <repo> forget --keep-daily 7 --keep-weekly 4 --keep-monthly 12`
- Prune repository: `restic -r <repo> prune`
- Check integrity: `restic -r <repo> check`
