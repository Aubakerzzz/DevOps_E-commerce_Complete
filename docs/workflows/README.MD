# Leyo — Multi-Cloud Deployment Workflows

This repository contains three independent GitHub Actions workflows that deploy the Leyo application (Docker Compose stack) to **AWS**, **Azure**, and **IBM Cloud** respectively.

Each workflow follows the same pattern:

1. **Authenticate** to the cloud provider.
2. **Inject an ephemeral (or static) SSH key** into the target VM.
3. **SSH into the VM**, clone the repo, sync the source to `/opt/leyo`, and run `docker compose up -d --build`.

A `.env` file is expected to already exist at `/opt/leyo/.env` on each VM (created once manually or via a separate secrets-sync workflow). The deploy workflows do **not** push secrets.

---

## Workflows

| File | Cloud | Trigger | Target |
|---|---|---|---|
| `.github/workflows/deploy-aws.yml` | AWS EC2 | push to `main`, manual | EC2 instance via EC2 Instance Connect |
| `.github/workflows/deploy-azure.yml` | Azure VM | push to `main`, manual | Azure Linux VM via `az vm user update` |
| `.github/workflows/deploy-ibm.yml` | IBM Cloud VPC | push to `main`, manual | IBM VSI via static deploy key |

---

## 1. `deploy-aws.yml` — AWS EC2

### What it does
1. Configures AWS credentials from static access keys.
2. Generates a short-lived Ed25519 key pair and pushes the public half to the instance with `aws ec2-instance-connect send-ssh-public-key` (valid for 60 seconds).
3. Fetches the instance's public IP with `aws ec2 describe-instances`.
4. SSHs into the instance and runs:
   - Install `git`, `docker.io`, `docker-compose-v2` if missing.
   - `git clone --depth 1` the repo.
   - `rsync` into `/opt/leyo`, excluding `.env` and `.git`.
   - `docker compose up -d --build`.

### GitHub Secrets required
| Secret | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | IAM access key with EC2 Instance Connect + DescribeInstances permissions |
| `AWS_SECRET_ACCESS_KEY` | Matching secret key |

### GitHub Variables (optional — can be hardcoded in the workflow)
| Variable | Example | Description |
|---|---|---|
| `AWS_REGION` | `us-east-1` | Target region |
| `EC2_INSTANCE_ID` | `i-0e1e5b24362534a27` | EC2 instance ID |
| `SSH_USER` | `ubuntu` | Default user on Ubuntu AMIs |

### IAM permissions needed
```json
{
  "Effect": "Allow",
  "Action": [
    "ec2-instance-connect:SendSSHPublicKey",
    "ec2:DescribeInstances"
  ],
  "Resource": "*"
}