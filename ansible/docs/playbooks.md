# Kubernetes Cluster Setup Playbooks

This document provides a comprehensive guide to the Ansible playbooks used to provision a Kubernetes cluster on AWS EC2 instances.

## Overview

The cluster setup is divided into **three sequential playbooks** that must be executed in order:

1. **`init-nodes.yaml`** - Prepares all nodes (control plane + workers)
2. **`init-control-nodes.yaml`** - Initializes the Kubernetes control plane
3. **`init-worker-nodes.yaml`** - Joins worker nodes to the cluster
4. **`init-ebs-csi.yaml`** - Installs the AWS EBS CSI Driver for persistent storage
5. **`init-monitoring-stack.yaml`** - Deploys Loki and Grafana with automated security

---

## Playbook 1: `init-nodes.yaml` (Common Layer)

**Target:** `all` nodes (Control Plane + Workers)

**Purpose:** Prepares the underlying Linux OS to be "Kubernetes-ready" by installing and configuring all prerequisites.

### Tasks Performed

#### System Configuration
1. **Disable Swap** (Required by Kubernetes)
   - Runs `swapoff -a` to disable swap in the current session
   - Comments out swap entries in `/etc/fstab` for persistence across reboots

2. **Load Kernel Modules**
   - Configures `overlay` and `br_netfilter` modules to load at boot
   - Loads modules immediately for the current session

3. **Configure Kernel Parameters**
   - Sets `net.bridge.bridge-nf-call-iptables = 1`
   - Sets `net.ipv4.ip_forward = 1`
   - Sets `net.bridge.bridge-nf-call-ip6tables = 1`
   - Applies settings with `sysctl --system`

#### Container Runtime (containerd)
4. **Install Dependencies**
   - Installs: `apt-transport-https`, `ca-certificates`, `curl`, `gpg`, `gnupg`, `jq`

5. **Install containerd**
   - Adds Docker's official GPG key
   - Adds Docker repository (ARM64 architecture)
   - Installs `containerd.io` package

6. **Configure containerd**
   - Stops containerd service
   - Removes any existing configuration
   - Generates fresh default configuration
   - Enables `SystemdCgroup = true` (required for Kubernetes)
   - Starts and enables containerd service
   - Waits for containerd socket to be available

#### Kubernetes Tools
7. **Install Kubernetes Components**
   - Adds Kubernetes official GPG key
   - Adds Kubernetes apt repository (v1.29)
   - Installs: `kubelet`, `kubeadm`, `kubectl`
   - Marks packages as "held" to prevent accidental upgrades

### Execution
```bash
ansible-playbook init-nodes.yaml
```

### Expected Outcome
- All 3 nodes report `failed=0`
- Swap is disabled on all nodes
- containerd is running and responding
- Kubernetes tools are installed and version-locked

---

## Playbook 2: `init-control-nodes.yaml` (Brain Layer)

**Target:** `role_control_plane` group (1 node)

**Purpose:** Transforms a prepared node into the Kubernetes cluster control plane.

### Tasks Performed

#### Pre-flight Checks
1. **Verify containerd Health**
   - Ensures containerd service is running
   - Waits for containerd socket
   - Tests containerd with `crictl info`
   - Automatically restarts if not responding

#### Cluster Initialization
2. **Initialize Kubernetes Cluster**
   - Runs `kubeadm init --pod-network-cidr=10.244.0.0/16`
   - Only executes if `/etc/kubernetes/admin.conf` doesn't exist (idempotent)
   - Initializes cluster with Flannel-compatible pod network CIDR

#### kubectl Configuration
3. **Configure kubectl Access**
   - Creates `.kube` directory for `ubuntu` user
   - Copies `admin.conf` to `/home/ubuntu/.kube/config`
   - Sets proper ownership (`ubuntu:ubuntu`) and permissions (`0600`)
   - Creates `.kube` directory for `root` user
   - Copies `admin.conf` to `/root/.kube/config`

#### Networking (CNI)
4. **Install Flannel CNI**
   - Applies Flannel manifest from official GitHub releases
   - Runs as `ubuntu` user (not root)
   - Only installs if cluster was just initialized
   - **Critical:** Cluster stays in `NotReady` state until this completes

5. **Wait for Control Plane Pods**
   - Monitors pods in `kube-system` namespace
   - Waits for all control plane pods to reach `Running` state
   - Retries up to 30 times with 10-second delays (5 minutes total)

#### Worker Join Preparation
6. **Generate Join Token**
   - Creates a fresh join token with `kubeadm token create --print-join-command`
   - Saves token as an Ansible fact for worker playbook
   - Displays join command for manual reference
   - Saves join command to `/home/ubuntu/join-command.sh` on control plane

### Execution
```bash
ansible-playbook init-control-nodes.yaml
```

### Expected Outcome
- Control plane initialized successfully
- Flannel CNI installed and running
- Join token generated and saved
- Control plane node shows as `Ready`

---

## Playbook 3: `init-worker-nodes.yaml` (Muscle Layer)

**Target:** `role_worker` group (2 nodes)

**Purpose:** Joins worker nodes to the cluster and verifies the final cluster state.

### Playbook Structure (3 Plays)

#### Play 1: Retrieve Join Command
**Target:** `role_control_plane`

1. **Generate Fresh Join Token**
   - Runs `kubeadm token create --print-join-command` on control plane
   - Stores command as an Ansible fact
   - Ensures workers get a valid, current token

#### Play 2: Join Workers to Cluster
**Target:** `role_worker`

2. **Check Join Status**
   - Checks for existence of `/etc/kubernetes/kubelet.conf`
   - Skips join if node is already part of the cluster (idempotent)

3. **Execute Join Command**
   - Retrieves join command from control plane's facts
   - Runs `kubeadm join <control-plane-ip>:6443 --token <token> --discovery-token-ca-cert-hash <hash>`
   - Only executes if node is not already joined

4. **Display Join Result**
   - Shows output from join command for verification

#### Play 3: Verify Cluster Status
**Target:** `role_control_plane`

5. **Wait for All Nodes to be Ready**
   - Runs `kubectl get nodes` and counts nodes not in `Ready` state
   - Retries until all nodes are `Ready`
   - Maximum wait time: 5 minutes (30 retries × 10 seconds)

6. **Display Final Cluster State**
   - Runs `kubectl get nodes -o wide`
   - Shows comprehensive cluster information:
     - Node names and roles
     - Status (should all be `Ready`)
     - Kubernetes version
     - Internal IPs
     - OS and kernel versions
     - Container runtime

### Execution
```bash
ansible-playbook init-worker-nodes.yaml
```

### Expected Outcome
- Both worker nodes successfully joined
- All 3 nodes show `STATUS: Ready`
- Cluster displays:
  - 1 control-plane node
  - 2 worker nodes
  - All running Kubernetes v1.29.x

---

## Complete Setup Sequence

### Prerequisites
1. EC2 instances provisioned via Terraform
2. Instances tagged with `Role: control-plane` or `Role: worker`
3. AWS SSM connectivity configured
4. Ansible dynamic inventory configured

### Execution Order

```bash
# Step 1: Prepare all nodes (5-10 minutes)
ansible-playbook init-nodes.yaml

# Step 2: Initialize control plane (3-5 minutes)
ansible-playbook init-control-nodes.yaml

# Step 3: Join workers and verify (2-3 minutes)
ansible-playbook init-worker-nodes.yaml
```

### Total Setup Time
**Approximately 10-18 minutes** for a complete 3-node cluster.

---

## Idempotency

All playbooks are designed to be **idempotent** - they can be safely re-run multiple times:

- **`init-nodes.yaml`**: Regenerates containerd config on every run (ensures clean state)
- **`init-control-nodes.yaml`**: Skips cluster init if already initialized
- **`init-worker-nodes.yaml`**: Skips join if node is already part of cluster

### When to Re-run

**Re-run `init-nodes.yaml` if:**
- containerd is not responding
- Kernel modules are not loaded
- Swap is enabled

**Re-run `init-control-nodes.yaml` if:**
- CNI networking is broken
- kubectl is not configured
- Join token expired

**Re-run `init-worker-nodes.yaml` if:**
- Worker nodes are not showing in `kubectl get nodes`
- Nodes are in `NotReady` state

---

## Troubleshooting

### Common Issues

**Issue:** containerd not responding
- **Solution:** Re-run `init-nodes.yaml` to regenerate config

**Issue:** Flannel pods stuck in `Pending`
- **Solution:** Check containerd status, verify pod network CIDR

**Issue:** Workers fail to join
- **Solution:** Verify network connectivity between nodes, check token validity

**Issue:** Nodes stuck in `NotReady`
- **Solution:** Check CNI pod status with `kubectl get pods -n kube-flannel`

### Verification Commands

Run these on the control plane after setup:

```bash
# Check all nodes
kubectl get nodes -o wide

# Check system pods
kubectl get pods -n kube-system

# Check Flannel
kubectl get pods -n kube-flannel

# Verify cluster info
kubectl cluster-info
```

---

## Architecture Summary

```
┌─────────────────────────────────────────────────────┐
│  Playbook 1: init-nodes.yaml                        │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────┐│
│  │ Control      │  │ Worker 1     │  │ Worker 2   ││
│  │ Plane        │  │              │  │            ││
│  └──────────────┘  └──────────────┘  └────────────┘│
│  • Disable swap   • Install containerd  • Install  │
│  • Kernel config  • Install k8s tools   • Hold pkgs│
└─────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────┐
│  Playbook 2: init-control-nodes.yaml                │
│  ┌──────────────┐                                   │
│  │ Control      │  kubeadm init                     │
│  │ Plane        │  Install Flannel CNI              │
│  │ (Ready)      │  Generate join token              │
│  └──────────────┘                                   │
└─────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────┐
│  Playbook 3: init-worker-nodes.yaml                 │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────┐│
│  │ Control      │  │ Worker 1     │  │ Worker 2   ││
│  │ Plane        │  │ (Joining)    │  │ (Joining)  ││
│  │ (Ready)      │  │              │  │            ││
│  └──────────────┘  └──────────────┘  └────────────┘│
│       ↓                   ↓                 ↓       │
│  [Verify all nodes Ready]                           │
└─────────────────────────────────────────────────────┘
```

---

## Playbook 4: `init-ebs-csi.yaml` (Storage Layer)

**Target:** `role_control_plane`

**Purpose:** Installs the AWS EBS CSI Driver to enable dynamic provisioning of EBS volumes as Persistent Volumes.

### Tasks Performed
1. **Helm Setup**: Adds the AWS EBS CSI Driver Helm repository.
2. **Installation**: Deploys the driver to the `kube-system` namespace.
3. **Verification**: Waits for CSI controller and node pods to reach `Running` state.

### Execution
```bash
ansible-playbook init-control-nodes.yaml
```

### Verification Commands
```bash
# Check CSI driver registration
kubectl get csidriver

# Check driver pods
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-ebs-csi-driver
```

---

## Playbook 5: `init-monitoring-stack.yaml` (Observability Layer)

**Target:** `role_control_plane`

**Purpose:** Deploys a full monitoring stack (Loki for logs, Grafana for dashboards) using AWS EBS for persistent data storage.

### Security Highlights
*   **Ansible Vault**: Sensitive credentials (like the Grafana admin password) are stored in an encrypted `vault.yml` file.
*   **No-Log Execution**: Tasks handling secrets are marked with `no_log: true` to prevent data leakage in logs.
*   **Shell Hardening**: All shell commands are quoted to prevent injection attacks.
*   **Automated Cleanup**: The StorageClass is configured with `reclaimPolicy: Delete` to ensure EBS volumes are destroyed when the stack is removed.

### Tasks Performed
1. **Namespace Creation**: Creates the `monitoring` namespace.
2. **Storage Configuration**: Creates a `gp3` StorageClass specifically for monitoring.
3. **Loki Deployment**: Deploys Loki in `SingleBinary` mode with filesystem storage compatibility.
4. **Grafana Deployment**: Deploys Grafana with persistence and exposes it via a `NodePort`.
5. **Auto-Discovery**: Automatically fetches the assigned NodePort and displays connection instructions.

### Security Setup (Ansible Vault)
Before running the playbook, you must set up your vault:

1. **Create Vault**: `ansible-vault create group_vars/all/vault.yml`
2. **Set Password**:
   ```bash
   # Securely set the environment variable
   read -s ANSIBLE_VAULT_PASSWORD
   export ANSIBLE_VAULT_PASSWORD
   ```
3. **Configure Auto-Loading**: Ensure `ansible.cfg` points to the password script:
   ```ini
   vault_password_file = ./vault_pass.sh
   ```

### Execution
```bash
ansible-playbook -i inventory.aws_ec2.yml init-monitoring-stack.yaml
```

### Verification & Access
```bash
# Check monitoring pods
kubectl get pods -n monitoring

# Get the Public IP of any node and combine it with the discovered NodePort:
# URL: http://<NODE_PUBLIC_IP>:<NODE_PORT>
```
```