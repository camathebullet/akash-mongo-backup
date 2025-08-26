# Akash MongoDB to Filebase Backup

This repository contains configuration for deploying MongoDB and a backup service on Akash Network. The backup service periodically backs up MongoDB database and uploads backups to [Filebase](https://console.filebase.com/).

## Deploy on Akash Console
1. Go to [Akash Console](https://console.akash.network/)
2. Create a new deployment
3. Copy the content of deploy.yml and replace all `${VARIABLE}` placeholders with your actual values.
4. Complete the deployment process

## Monitoring
To check backup logs in [Akash Console](https://console.akash.network/):
1. Go to your deployment details
2. Select the `backupagent` service
3. View the logs to monitor backup activities

## Notes
- Ensure your [Filebase](https://console.filebase.com/) bucket is created and credentials have write access
- The backup interval can be adjusted based on your needs
- Backups are stored with timestamped filenames for easy identification
