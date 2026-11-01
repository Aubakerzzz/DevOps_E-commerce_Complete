# GitHub Actions OIDC setup for Azure

1. Set the environment variables
In PowerShell, from your infra folder, run:

$env:ARM_CLIENT_ID = "YOUR_CLIENT_ID"
$env:ARM_CLIENT_SECRET = "YOUR_CLIENT_SECRET"
$env:ARM_TENANT_ID = "YOUR_TENANT_ID"
$env:ARM_SUBSCRIPTION_ID = "YOUR_SUBSCRIPTION_ID"

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

The deployment workflow uses GitHub's OIDC identity to assume an Azure AD Application (Service Principal). This avoids storing permanent Azure credentials in GitHub.

## Federated Credentials (Trust Relationship)

In your Azure AD App Registration, add a Federated Credential:
- **Issuer**: `https://token.actions.githubusercontent.com`
- **Subject**: `repo:YOUR_ORG/YOUR_REPO:ref:refs/heads/main`
- **Audience**: `api://AzureADTokenExchange`

## GitHub Configuration

Repository Settings -> Secrets and variables -> Actions:

Secrets:
- `AZURE_CLIENT_ID`: The Application (client) ID.
- `AZURE_TENANT_ID`: The Directory (tenant) ID.
- `AZURE_SUBSCRIPTION_ID`: Your Azure Subscription ID.
- `EC2_SSH_PRIVATE_KEY`: Private key for the VM (rename secret as needed).
- `EC2_USER`: `azureuser` (or your admin_username).

Variables:
- `AZURE_REGION`: Same region used by Terraform (e.g., `East US`).

## SSH Connectivity

The NSG restricts port 22 to `admin_cidr`. Ensure your GitHub runner IP is allowed, or use a self-hosted runner / Azure Bastion for secure access.