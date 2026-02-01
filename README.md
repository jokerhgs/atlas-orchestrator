## Terraform Project Structure

```text
terraform/
├── main.tf                 # Root orchestration
├── providers.tf            # AWS & Provider configuration
├── variables.tf            # Global variables
├── terraform.tfvars        # Environment-specific values
└── modules/
    ├── network/            # Core networking stack
    │   ├── vpc.tf          # VPC, IGW, and Core Networking
    │   ├── subnets.tf      # Public, Private, and Databases
    │   ├── routing.tf      # Route Tables & Associations
    │   ├── gates.tf        # NAT Gateways & Elastic IPs
    │   ├── security.tf     # Security Groups & NACLs
    │   ├── variables.tf    # Module-specific variables
    │   └── outputs.tf      # Module-specific outputs
    └── iam/                # Identity & Access Management
        ├── roles.tf        # IAM Roles & Instance Profiles
        ├── policies.tf     # IAM Policies & Permissions
        ├── variables.tf    # Module-specific variables
        └── outputs.tf      # Module-specific outputs
```

## Design Principles
- **Functional Split:** Instead of over-dividing into micro-modules, we use a single `network` module with split `.tf` files to keep dependencies simple and maintainable.
- **Least Privilege:** All IAM roles and security groups follow the principle of least privilege.
- **Environment Isolation:** Variables and `.tfvars` are used to ensure consistency across different environments.