#!/bin/sh

# Function to send notifications (optional)
send_notification() {
    local message=$1
    echo "$(date): $message"
    # Here you can add sending to Slack/Telegram etc.
}

# Main backup function
perform_backup() {
    echo "$(date): Starting MongoDB backup..."
    
    # Create MongoDB dump
    mongodump \
        --host=$MONGO_HOST \
        --port=$MONGO_PORT \
        --username=$MONGO_USER \
        --password=$MONGO_PASS \
        --out=/tmp/backup \
        --authenticationDatabase=admin
    
    if [ $? -ne 0 ]; then
        send_notification "MongoDB dump failed!"
        return 1
    fi
    
    # Create timestamped archive
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    ARCHIVE_NAME="mongo-backup-$TIMESTAMP.tar.gz"
    tar -czf "/tmp/$ARCHIVE_NAME" -C /tmp/backup .
    
    # Configure AWS CLI for Filebase
    aws configure set aws_access_key_id "$FILEBASE_ACCESS_KEY"
    aws configure set aws_secret_access_key "$FILEBASE_SECRET_KEY"
    aws configure set default.region us-east-1
    
    # Upload to Filebase
    echo "$(date): Uploading to Filebase..."
    aws --endpoint-url https://s3.filebase.com s3 cp \
        "/tmp/$ARCHIVE_NAME" \
        "s3://$FILEBASE_BUCKET/$ARCHIVE_NAME"
    
    if [ $? -eq 0 ]; then
        send_notification "Backup completed and uploaded successfully: $ARCHIVE_NAME"
        
        # Cleanup temporary files
        rm -rf /tmp/backup "/tmp/$ARCHIVE_NAME"
        
        # Remove old backups (keep last 7 by default)
        if [ -n "$RETENTION_COUNT" ]; then
            echo "$(date): Cleaning up old backups..."
            aws --endpoint-url https://s3.filebase.com s3 ls "s3://$FILEBASE_BUCKET/" | \
            grep mongo-backup- | \
            sort -r | \
            tail -n +$((RETENTION_COUNT + 1)) | \
            while read -r line; do
                FILE_NAME=$(echo "$line" | awk '{print $4}')
                if [ -n "$FILE_NAME" ]; then
                    aws --endpoint-url https://s3.filebase.com s3 rm "s3://$FILEBASE_BUCKET/$FILE_NAME"
                    echo "Deleted old backup: $FILE_NAME"
                fi
            done
        fi
    else
        send_notification "Backup upload failed!"
        return 1
    fi
}

# Loop forever, running backup every BACKUP_INTERVAL seconds
while true; do
    perform_backup
    echo "$(date): Sleeping for $BACKUP_INTERVAL seconds until next backup..."
    sleep "$BACKUP_INTERVAL"
done
