# Environment Setup & Prerequisites

This document outlines the requirements and environment configuration needed to run the Atlas Ansible playbooks.

## 1. Machine Dependencies

Your control machine (where you run Ansible from) requires the following tools installed:

### Core Tools
*   **Ansible Core**: v2.12+
*   **Python 3**: (Required by Ansible)
*   **AWS CLI v2**: For interacting with AWS APIs

### Python Libraries (for AWS modules)
The `amazon.aws` collection requires these Python packages:
```bash
pip install boto3 botocore
```

### AWS Session Manager Plugin
Since we use the `aws_ssm` connection plugin to manage instances without opening SSH ports, you **must** install the Session Manager plugin on your control machine.

**Ubuntu/Debian (WSL):**
```bash
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
sudo dpkg -i session-manager-plugin.deb
```
*(See official AWS docs for other OS installation instructions)*

---

## 2. Environment Variables

Before running any playbooks, you must export the following environment variables in your terminal.

### AWS Credentials
Required for dynamic inventory discovery and SSM connections.
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_SESSION_TOKEN="your-session-token" # Optional: Only if using MFA/SSO
export AWS_REGION="us-east-1"
```

### Ansible Configuration
To ensure Ansible uses the local configuration file (especially important in WSL/World-Writable directories), strictly define the config path:
```bash
export ANSIBLE_CONFIG="./ansible.cfg"
```

### S3 Storage Buckets
Required for SSM logging and the Monitoring Stack (Loki/Tempo). Retrieve these from your Terraform outputs.

```bash
export SSM_LOG_BUCKET="atlas-ssm-logs-xxxxxx"
export LOKI_S3_BUCKET="atlas-loki-data-xxxxxx"
export TEMPO_S3_BUCKET="atlas-tempo-data-xxxxxx"
```

---

## 3. Quick Start Script

You can combine these into a generic `env.sh` (do not commit real keys!) to source before working:

```bash
# setup-env.sh
export AWS_PROFILE=default  # If you use ~/.aws/credentials profiles
export AWS_REGION=us-east-1
export ANSIBLE_CONFIG=./ansible.cfg
export SSM_LOG_BUCKET=$(cd ../terraform && terraform output -raw ssm_bucket_name)
export LOKI_S3_BUCKET=$(cd ../terraform && terraform output -raw loki_bucket_name)
export TEMPO_S3_BUCKET=$(cd ../terraform && terraform output -raw tempo_bucket_name)

# Verify setup
ansible-inventory --graph
```