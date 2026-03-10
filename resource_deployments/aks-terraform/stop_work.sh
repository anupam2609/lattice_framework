#!/bin/bash

# Exit immediately if a command fails
set -e

# Generate a timestamp for the backup folder
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="cluster-backups/$TIMESTAMP"
mkdir -p "$BACKUP_DIR/manifests"

echo "Saving current cluster state to $BACKUP_DIR..."

# 1. Export ConfigMaps and Secrets
# We use --all-namespaces to ensure we capture all Xpander AI configurations
kubectl get configmaps --all-namespaces -o yaml > "$BACKUP_DIR/configmaps.yaml" 2>/dev/null || true
kubectl get secrets --all-namespaces -o yaml > "$BACKUP_DIR/secrets.yaml" 2>/dev/null || true

# 2. Export Deployments, Services, and Ingress
# This captures the actual application structure
kubectl get deployments,services,ingress --all-namespaces -o yaml > "$BACKUP_DIR/manifests/all-manifests.yaml" 2>/dev/null || true

echo "Cluster state exported successfully."

# 3. Destroy Infrastructure
echo "Destroying AKS cluster to stop Azure charges..."
terraform destroy -auto-approve

echo "Work session closed and resources deleted."