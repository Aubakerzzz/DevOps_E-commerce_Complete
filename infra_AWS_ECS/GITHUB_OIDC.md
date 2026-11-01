# GitHub Actions OIDC setup
1. Set the environment variables
In PowerShell, from your infra folder, run:


$env:AWS_ACCESS_KEY_ID = "YOUR_ACCESS_KEY"
$env:AWS_SECRET_ACCESS_KEY = "YOUR_SECRET_KEY"
$env:AWS_REGION = "us-east-1"

docker compose build


##enter into the container
docker compose run --rm terraform

# apply terraform commands
terraform init
terraform fmt -recursive
terraform validate
terraform plan

terraform apply

terraform output instance_public_ip

terraform destroy


The deployment workflow uses GitHub's OIDC identity to assume an AWS IAM role. This avoids storing permanent AWS access keys in GitHub.

## Trust relationship

Create an IAM role and configure its trust policy for your GitHub repository. Replace `YOUR_ORG` and `YOUR_REPO`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_ORG/YOUR_REPO:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

If your AWS account does not already have the GitHub OIDC provider, create the IAM OIDC identity provider for `https://token.actions.githubusercontent.com` with audience `sts.amazonaws.com`.

## IAM permissions

Attach a least-privilege policy permitting the role to use `sts:AssumeRoleWithWebIdentity` through the trust policy. The workflow itself does not need broad EC2 permissions to SSH into the instance; it needs `ec2:DescribeInstances` only if you choose to add discovery. For this starter workflow, the host is provided via the `EC2_HOST` GitHub secret.

## GitHub configuration

Repository Settings -> Secrets and variables -> Actions:

Secrets:
- `AWS_ROLE_TO_ASSUME`: the IAM role ARN.
- `EC2_HOST`: value of `terraform output -raw instance_public_ip`.
- `EC2_SSH_PRIVATE_KEY`: private key for the existing EC2 key pair.
- `EC2_USER`: `ubuntu`.

Variables:
- `AWS_REGION`: same region used by Terraform.

## SSH connectivity

The default security group restricts port 22 to `admin_cidr`, which is good for manual administration but usually blocks GitHub-hosted runner IPs. Do not make SSH globally open just to make the workflow pass. Consider a self-hosted GitHub runner on the instance/VPC, AWS Systems Manager, or another controlled connectivity design.
