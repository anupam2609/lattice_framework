#!/bin/bash


set -e

echo "Starting work session: Provisioning AKS Cluster..."
terraform apply -auto-approve
echo "Infrastructure ready."

# 1. Define and Export KUBECONFIG
KUBECONFIG_FILE="$(pwd)/kubeconfig"
export KUBECONFIG="$KUBECONFIG_FILE"

# 2. Extract the Kubeconfig from Terraform
# We use -raw and redirect errors to handle the sensitive flag automatically
echo "Generating kubeconfig file..."
terraform output -raw kube_config_raw > "$KUBECONFIG_FILE" 2>/dev/null || true

# Give the Azure API a moment to stabilize
sleep 2

# 3. Restore from Backup
BACKUP_ROOT="cluster-backups"
if [ -d "$BACKUP_ROOT" ]; then
    # Find the most recent timestamped folder
    LATEST_BACKUP=$(ls -td ${BACKUP_ROOT}/*/ 2>/dev/null | head -1)

    if [ -n "$LATEST_BACKUP" ]; then
        echo "Restoring state from: $LATEST_BACKUP"

        # Apply secrets and configmaps first (dependencies)
        [ -f "${LATEST_BACKUP}secrets.yaml" ] && kubectl apply -f "${LATEST_BACKUP}secrets.yaml" || true
        [ -f "${LATEST_BACKUP}configmaps.yaml" ] && kubectl apply -f "${LATEST_BACKUP}configmaps.yaml" || true

        # Apply the main application manifests
        if [ -d "${LATEST_BACKUP}manifests" ]; then
            kubectl apply -f "${LATEST_BACKUP}manifests/" --recursive || true
        fi

        echo "Application state restored."
    fi
else
    echo "No existing backups found. Starting with a fresh cluster."
fi

echo "Environment is ready. Use 'kubectl get pods' to check your Xpander AI status."