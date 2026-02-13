#!/bin/bash
# Atlas Console - Secure Tunnel for Grafana
# Usage: ./scripts/atlas-console.sh [INSTANCE_ID]
# If no ID is provided, it attempts to fetch from Terraform.

# Optional: Get the directory where the script is located to find Terraform
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 1. Use the provided argument if it exists
INSTANCE_ID=$1

# 2. If no argument, try to fetch from Terraform (requires terraform and jq in path)
if [ -z "$INSTANCE_ID" ]; then
    echo "No Instance ID provided. Attempting to fetch from Terraform..."
    if command -v terraform >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
        INSTANCE_ID=$(cd "$PROJECT_ROOT/terraform" && terraform output -json instance_ids | jq -r '.[3]')
    fi
fi

# 3. Fail if we still don't have an ID
if [ "$INSTANCE_ID" == "null" ] || [ -z "$INSTANCE_ID" ]; then
    echo "Error: No Instance ID provided and could not fetch from Terraform."
    echo "Usage: $0 [INSTANCE_ID]"
    echo "Example: $0 i-076515c397d1b632c"
    exit 1
fi

echo "----------------------------------------------------"
echo "Atlas Secure Dashboard Tunnel"
echo "----------------------------------------------------"
echo "Target Node:  $INSTANCE_ID"
echo "Local Access: http://localhost:3000"
echo "----------------------------------------------------"
echo "Tunneling is ACTIVE. Press Ctrl+C to disconnect."

aws ssm start-session \
    --target "$INSTANCE_ID" \
    --document-name AWS-StartPortForwardingSession \
    --parameters '{"portNumber":["32172"],"localPortNumber":["3000"]}'
