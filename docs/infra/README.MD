Here is the `README.md` for the **infra** folder. It documents all three Terraform stacks (`infra_AWS`, `infra_Azure`, `infra_IBM`), the Docker wrapper workflow, variables, outputs, and the OIDC bootstrap steps. Drop it in `docs/infra/README.md`.

```markdown
# Leyo — Infrastructure (Terraform)

This folder contains three independent Terraform stacks that provision a single Linux VM (Ubuntu 22.04) with Nginx + Node.js 22 + PM2 preinstalled, reachable over HTTP (port 80) and SSH (port 22, restricted to your admin CIDR).

| Folder | Cloud | Provider | VM resource |
|---|---|---|---|
| `infra_AWS/` | AWS | `hashicorp/aws` ~> 5.0 | `aws_instance` (EC2) |
| `infra_Azure/` | Azure | `hashicorp/azurerm` ~> 4.0 | `azurerm_linux_virtual_machine` |
| `infra_IBM/` | IBM Cloud | `IBM-Cloud/ibm` ~> 2.0 | `ibm_is_instance` (VPC VSI) |

All three follow the **same folder layout** and the **same Docker-based workflow**:

```text
<infra_CLOUD>/
├── .terraform.lock.hcl
├── compose.yaml           # Docker wrapper for Terraform
├── Dockerfile             # Terraform + cloud CLI image
├── main.tf                # VM + network + security group
├── outputs.tf             # instance_id, public IP, ssh_command
├── providers.tf
├── terraform.tfvars       # (gitignored) your real values
├── terraform.tfvars.example
├── user_data.sh           # Ubuntu bootstrap (Nginx + Node 22 + PM2)
├── variables.tf
└── versions.tf
```

---

## Common workflow (all clouds)

Terraform runs inside a Docker container so you don't need to install Terraform or the cloud CLI on your host.

```bash
cd infra_AWS       # or infra_Azure / infra_IBM
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with real values

docker compose build
docker compose run --rm terraform

# inside the container:
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply

terraform output instance_public_ip
terraform output ssh_command

# tear down when done
terraform destroy
```

State files (`terraform.tfstate*`) stay on your host via the volume mount — do not commit them.

---

## Shared variables

Every stack defines these:

| Variable | Type | Default | Purpose |
|---|---|---|---|
| `project_name` | string | `leyo` | Prefix for all resource names |
| `admin_cidr` | string | — | Your public IP in CIDR (e.g. `203.0.113.10/32`) — SSH is restricted to this |
| `aws_region` / `location` / `region` | string | `us-east-1` / `East US` / `us-south` | Target region |
| `instance_type` / `vm_size` / `profile` | string | `t3.medium` / `Standard_B2s` / `bx2-2x8` | VM size |
| `root_volume_size` | number | `20` | Root disk GiB (AWS only; Azure/IBM use provider defaults) |

Cloud-specific:

| Variable | AWS | Azure | IBM |
|---|---|---|---|
| `key_name` | ✅ existing EC2 key pair | | |
| `ssh_public_key_path` | | ✅ path to `id_rsa.pub` | |
| `ssh_public_key` | | | ✅ raw public key string |
| `admin_username` | | ✅ default `azureuser` | |
| `zone` | | | ✅ default `us-south-1` |

---

## Shared outputs

```hcl
output "instance_id"
output "instance_public_ip"
output "instance_public_dns"     # AWS, Azure (IBM VSI has no public DNS)
output "ssh_command"
```

---

## What gets created per cloud

### AWS (`infra_AWS`)
- Default VPC + first default subnet (reused via data sources).
- `aws_security_group` — SSH from `admin_cidr`, HTTP from `0.0.0.0/0`.
- `aws_instance` — Ubuntu 22.04 AMI (Canonical), `gp3` encrypted root volume, `user_data.sh` bootstrap, public IP associated.

### Azure (`infra_Azure`)
- `azurerm_resource_group` — `<project>-rg`.
- `azurerm_virtual_network` + `azurerm_subnet` — `10.0.0.0/16` / `10.0.1.0/24`.
- `azurerm_public_ip` — static, Standard SKU.
- `azurerm_network_security_group` — SSH from `admin_cidr`, HTTP open.
- `azurerm_network_interface` + association.
- `azurerm_linux_virtual_machine` — Ubuntu 22.04 (`Canonical/0001-com-ubuntu-server-jammy/22_04-lts`), SSH key via `admin_ssh_key`, `custom_data = base64encode(user_data.sh)`.

### IBM Cloud (`infra_IBM`)
- `ibm_is_vpc` + `ibm_is_subnet` — `10.240.0.0/24` in `us-south-1`.
- `ibm_is_ssh_key` — registered public key.
- `ibm_is_security_group` + rules — SSH from `admin_cidr`, HTTP open.
- `ibm_is_instance` — Ubuntu 22.04 minimal image, `bx2-2x8` profile, `user_data.sh`.
- `ibm_is_floating_ip` — attached to the VSI's primary NIC.

---

## VM bootstrap (`user_data.sh`)

Identical on all three clouds:

```bash
#!/bin/bash
set -euxo pipefail
apt-get update
apt-get install -y nginx curl ca-certificates git build-essential
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs
npm install --global pm2
systemctl enable nginx && systemctl start nginx
mkdir -p /opt/leyo
```

The deploy workflows later clone the app into `/opt/leyo` and run `docker compose up -d --build`. The VM's `.env` at `/opt/leyo/.env` is **not** created here — it's managed separately.

---

## Authentication

Each `compose.yaml` passes cloud credentials from your host environment into the container.

### AWS
```powershell
$env:AWS_ACCESS_KEY_ID     = "..."
$env:AWS_SECRET_ACCESS_KEY = "..."
$env:AWS_REGION            = "us-east-1"
docker compose run --rm terraform
```

### Azure
```powershell
$env:ARM_CLIENT_ID       = "..."
$env:ARM_CLIENT_SECRET   = "..."
$env:ARM_TENANT_ID       = "..."
$env:ARM_SUBSCRIPTION_ID = "..."
docker compose run --rm terraform
```

Or log in interactively inside the container with `az login`.

### IBM Cloud
```powershell
$env:IC_API_KEY = "..."
docker compose run --rm terraform
```

---

## GitHub Actions (deploy workflows)

The **deploy** workflows (`.github/workflows/deploy-*.yml`) are separate from this infra folder. They assume the VM already exists (created by `terraform apply` here) and only push code + restart Compose.

See `GITHUB_OIDC.md` in each stack for the trust relationship setup:

| Cloud | Auth method | Secrets for GitHub Actions |
|---|---|---|
| AWS | IAM user keys or OIDC role | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` |
| Azure | OIDC Federated Credential | `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` |
| IBM | API key | `IC_API_KEY`, `IBM_DEPLOY_SSH_KEY` |

These are **independent** from the credentials used to run `terraform apply` locally.

---

## Security notes

- **SSH is never opened to the world.** All three stacks restrict port 22 to `admin_cidr`. Update it whenever your public IP changes.
- **HTTP (80) is open to `0.0.0.0/0`** by design (Nginx fronts the app). Put Cloudflare or an ALB/App Gateway in front if you need TLS.
- **Root disk is encrypted** on AWS (`encrypted = true`); Azure and IBM default to encryption at rest.
- **State files contain secrets.** `.gitignore` excludes `terraform.tfstate*` and `terraform.tfvars`. Never commit either.
- **Destroy when not in use** to avoid charges: `terraform destroy`.

---

## State management

Currently **local state** (`terraform.tfstate` on your host, mounted into the Docker container). This is fine for a solo project but breaks the moment two people apply.

To move to remote state later:

- **AWS**: S3 bucket + DynamoDB lock table
- **Azure**: Storage Account + blob container
- **IBM**: IBM Cloud Object Storage bucket

Add a `backend "..." {}` block to `versions.tf` and run `terraform init -migrate-state`.

---

## Quick reference — apply a fresh stack

```bash
cd infra_IBM
cp terraform.tfvars.example terraform.tfvars
# fill in admin_cidr, ssh_public_key, region, etc.

docker compose build
docker compose run --rm terraform -c "
  terraform init &&
  terraform apply -auto-approve
"

# grab the IP for the deploy workflow
docker compose run --rm terraform -c "terraform output -raw instance_public_ip"
```

Copy that IP into the corresponding deploy workflow's `EC2_INSTANCE_ID` / `AZURE_VM` (Azure resolves via `az vm show`) / `IBM_INSTANCE_NAME` (IBM resolves via `ibmcloud is instances`).
```

---

### Notes on what I put in / left out

- **Did not** invent variable names that don't exist in your `.tf` files — every variable listed maps to an actual declaration in `variables.tf` for that stack.
- **Did not** claim IBM has `instance_public_dns` — it doesn't; the IBM `outputs.tf` only exposes `instance_public_ip` and `ssh_command`.
- **Did not** document a remote backend as "supported" — it's flagged as a future migration.
- The **GitHub Actions secret table is intentionally minimal** and mirrors what you'll actually need based on the three deploy workflows, not the credentials for local `terraform apply` (which are a separate concern).

If you later add a `docs/infra/` directory and want this file to cross-reference `docs/deploy/README.md`, I can produce a top-level `docs/README.md` index as well.