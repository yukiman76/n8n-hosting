#!/bin/bash

# Kubernetes PostgreSQL Backup Script with All Configs from Secret

# Source your bash aliases to use the kubectl alias
source ~/.bash_aliases

# Enable alias expansion in script
shopt -s expand_aliases

# Configuration variables
BACKUP_DIR="./bkups"
RETENTION_DAYS=7
SECRET_NAME="postgres-secret"  # Name of the Kubernetes secret with all DB configs
NAMESPACE="n8n"

# Make sure backup directory exists locally
mkdir -p "$BACKUP_DIR"

# Create timestamp for backup filename
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Retrieve all configuration from Kubernetes secret
echo "Retrieving database configuration from secret $SECRET_NAME"


# Now get all the configuration values from the secret
DB_NAME=$(kubectl get secret -n "$NAMESPACE" "$SECRET_NAME" -o jsonpath="{.data.POSTGRES_DB}"| base64 --decode)
DB_USER=$(kubectl get secret -n "$NAMESPACE" "$SECRET_NAME" -o jsonpath="{.data.POSTGRES_USER}"| base64 --decode)
DB_PASSWORD=$(kubectl get secret -n "$NAMESPACE" "$SECRET_NAME" -o jsonpath="{.data.POSTGRES_PASSWORD}"| base64 --decode)

# Validate that we got all the required configuration
if [ -z "$DB_NAME" ] || [ -z "$NAMESPACE" ] ||  [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ]; then
    echo "Error: Failed to retrieve all required database configuration from secret $SECRET_NAME"
    echo "Required fields: database, namespace, username, password"
    exit 1
fi

# Update backup filename with retrieved DB_NAME
BACKUP_FILENAME="${DB_NAME}_${TIMESTAMP}.sql"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_FILENAME}"

# Log start of backup with retrieved configuration
echo "Starting PostgreSQL backup with configuration from secret:"
echo "Database: $DB_NAME"
echo "Namespace: $NAMESPACE"
echo "User: $DB_USER"
echo "Timestamp: $TIMESTAMP"

# Get the PostgreSQL pod name using retrieved namespace and pod label
PG_POD=$(kubectl get pods  -n "$NAMESPACE"  -o name | sed 's/^pod\///' | grep postgres)

if [ -z "$PG_POD" ]; then
    echo "Error: PostgreSQL pod not found in namespace $NAMESPACE"
    exit 1
fi

echo "Using PostgreSQL pod: $PG_POD"

# Perform the backup directly from the Kubernetes pod using retrieved credentials
echo "Executing pg_dump in the pod..."
kubectl exec -n "$NAMESPACE" "$PG_POD" -- bash -c "PGPASSWORD='$DB_PASSWORD' pg_dump -U $DB_USER $DB_NAME" > "$BACKUP_PATH"

# Check if backup was successful
if [ $? -eq 0 ]; then
    # Compress the backup
    gzip "$BACKUP_PATH"
    COMPRESSED_PATH="${BACKUP_PATH}.gz"
    
    # Calculate backup size
    BACKUP_SIZE=$(du -h "$COMPRESSED_PATH" | cut -f1)
    
    echo "Backup completed successfully at $(date)"
    echo "Backup saved to: $COMPRESSED_PATH"
    echo "Backup size: $BACKUP_SIZE"
    
    # Delete backups older than retention period
    find "$BACKUP_DIR" -name "${DB_NAME}_*.sql.gz" -type f -mtime +$RETENTION_DAYS -delete
    echo "Cleaned up old backups older than $RETENTION_DAYS days"
else
    echo "Backup failed with error code $?"
    exit 1
fi

# Log completion
echo "Backup process completed at $(date)"

# For security, clear variables containing sensitive information
unset DB_PASSWORD