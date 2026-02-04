## Terraform Project Structure

```text
terraform/
├── main.tf                 # Root orchestration
├── providers.tf            # AWS & Provider configuration
├── variables.tf            # Global variables
├── outputs.tf              # Global outputs
├── terraform.tfvars        # Environment-specific values
└── modules/
    ├── network/            # Core networking stack
    ├── iam/                # Identity & Access Management
    ├── s3/                 # Centralized Logging & Storage
    └── ec2/                # Compute resources

ansible/
├── ansible.cfg             # Core configuration (SSM Tunneling)
├── inventory.aws_ec2.yml   # AWS Dynamic Inventory
└── group_vars/
    └── aws_ec2.yml         # Connection settings & Env lookups
```

## Ansible Configuration

The project uses a **Keyless, Portless & Private** approach to server management. Ansible is configured to tunnel traffic over **AWS Systems Manager (SSM) Session Manager**, allowing you to manage instances in private subnets without a Bastion host or exposed SSH ports.

### Prerequisites

To run Ansible from your local machine, you need:
1.  **AWS CLI** installed and configured.
2.  **Session Manager Plugin** installed locally.
3.  **Ansible** with the following collections:
    ```bash
    ansible-galaxy collection install amazon.aws community.aws
    ```

### Usage

The inventory is dynamic and filters instances based on the `Project: atlas` tag. It uses an environment variable for the S3 logging bucket to keep credentials safe.

```bash
# 1. Export the S3 Logging Bucket (get this from `terraform output ssm_bucket_name`)
export SSM_LOG_BUCKET="atlas-ssm-logs-xxxxxxxxxxx"

# 2. Verify connectivity
ansible all -m ping

# 3. Run a playbook
ansible-playbook your-playbook.yml
```

## Design Principles
- **Functional Split:** Instead of over-dividing into micro-modules, we use a single `network` module with split `.tf` files to keep dependencies simple and maintainable.
- **Least Privilege:** All IAM roles and security groups follow the principle of least privilege.
- **Environment Isolation:** Variables and `.tfvars` are used to ensure consistency across different environments.