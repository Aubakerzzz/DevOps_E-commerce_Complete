# GitHub Actions OIDC setup for IBM Cloud

1. Set the environment variables
In PowerShell, from your infra folder, run:

$env:IC_API_KEY = "YOUR_IBM_CLOUD_API_KEY"

docker compose build

## Enter into the container
docker compose run --rm terraform

# Apply terraform commands
terraform init
terraform fmt -recursive
terraform validate
terraform plan

terraform apply

terraform output instance_public_ip

terraform destroy

**Note on OIDC:** IBM Cloud does not natively support GitHub OIDC federation in the same way AWS/Azure do. The standard practice is to use an IBM Cloud API Key stored as a GitHub Secret (`IC_API_KEY`), scoped to the minimum required IAM permissions. For stricter security, consider a self-hosted runner or IBM Cloud trusted profiles with an API key.

## GitHub Configuration

Repository Settings -> Secrets and variables -> Actions:

Secrets:
- `IC_API_KEY`: IBM Cloud API key with VPC infrastructure permissions.
- `SSH_PRIVATE_KEY`: Private key for the VM.
- `SSH_USER`: `root` (IBM Cloud VPC Ubuntu images default to root unless a custom user is configured).

Variables:
- `IBM_REGION`: Same region used by Terraform (e.g., `us-south`).

## SSH Connectivity

The security group restricts port 22 to `admin_cidr`. Do not open SSH globally; use a bastion or VPN for access from GitHub-hosted runners.