#!/bin/bash
set -euo pipefail

# Define region
REGION="us-east-1"
PROJECT=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --project) PROJECT="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [ -z "$PROJECT" ]; then
    echo "Error: Project name must be specified using --project <name>"
    exit 1
fi

# Fetch IDs of running instances
# We use the AWS CLI within WSL to get the list
ids=$(aws ec2 describe-instances \
    --region "$REGION" \
    --filters "Name=instance-state-name,Values=running" "Name=tag:Project,Values=$PROJECT" \
    --query "Reservations[].Instances[].InstanceId" \
    --output text)

# Check if any IDs were found
if [ -n "$ids" ]; then
    echo "Stopping instances: $ids"
    # Stop the instances found
    aws ec2 stop-instances --region "$REGION" --instance-ids $ids
else
    echo "No running instances found to stop."
fi
