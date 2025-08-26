FROM alpine:3.18

# Install necessary tools
RUN apk add --no-cache mongodb-tools aws-cli curl tzdata

# Copy the backup script
COPY backup-script.sh /usr/local/bin/backup-script.sh
RUN chmod +x /usr/local/bin/backup-script.sh

# Set the entrypoint to run the script
ENTRYPOINT ["/usr/local/bin/backup-script.sh"]
