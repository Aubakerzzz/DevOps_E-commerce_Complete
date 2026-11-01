#How to Run:

https://chat.deepseek.com/share/pg6rj3bpifkkrssfx8

Admin Role will do CRUD operations on PHAAL/Fruits: HINT Login As admin using Shell Scripting We will create admin role in start

# Leyo deployment scaffold

This scaffold separates four concerns:

- `helm/leyo/`: Helm chart for deploying the frontend and backend to Kubernetes.
- `kubernetes/`: local-cluster values and commands that install the Helm chart.
- `infra/`: Terraform for one Ubuntu EC2 instance (`t3.medium`) for a **direct, non-Kubernetes** deployment.
- `.github/workflows/deploy-ec2.yml`: GitHub Actions deployment to that EC2 instance using AWS OIDC for AWS authentication and SSH for deployment.

## Important architecture note

Kubernetes does not require the Docker CLI, but Kubernetes still runs **container images**. The Helm chart therefore expects client and server images. You can build them with Podman/Buildah or another OCI-compatible builder. This scaffold does not use Docker Compose.

The EC2 deployment is a separate path: it installs Node.js and Nginx on EC2 and runs the server with PM2; it does not use Kubernetes. AWS EKS can be added later as a separate deployment target.

## 1. Local Kubernetes

Prerequisites: a local Kubernetes cluster (for example Minikube or Docker Desktop Kubernetes), `kubectl`, and Helm 3.

1. Build and make your application images available to your local cluster. Image names in `kubernetes/values-local.yaml` are examples; change them to match your image builder and cluster.
2. Ensure your backend can read `MONGODB_URI`. For local testing, create a Kubernetes Secret:
   ```bash
   kubectl create namespace leyo
   kubectl -n leyo create secret generic leyo-secrets \
     --from-literal=MONGODB_URI='mongodb://YOUR_REACHABLE_MONGODB_HOST:27017/leyo'
   ```
   If using MongoDB Atlas, use its connection string instead. Do not commit credentials.
3. Install/update the chart:
   ```bash
   helm upgrade --install leyo ./helm/leyo \
     --namespace leyo --create-namespace \
     -f kubernetes/values-local.yaml
   ```
4. Check resources:
   ```bash
   kubectl -n leyo get pods,svc
   kubectl -n leyo logs deploy/leyo-server
   ```
5. For Minikube, access the frontend service with:
   ```bash
   minikube service leyo-client -n leyo
   ```
   For other clusters, use the service type and access method appropriate to your cluster.

### Image requirement

The chart uses `image.repository` and `image.tag` from its values. Build images with an OCI-compatible tool and load/push them to a registry that the cluster can access. For example, with Podman:
```bash
podman build -t leyo-client:local -f deployment/containerfiles/client.Containerfile ./client
podman build -t leyo-server:local -f deployment/containerfiles/server.Containerfile ./server
```
For Minikube, load them into Minikube:
```bash
minikube image load leyo-client:local
minikube image load leyo-server:local
```
The client Containerfile assumes the Vite app builds to `client/dist`. It uses Nginx to serve the static frontend. The backend Containerfile assumes `server/index.js` is the backend entrypoint and that `npm start` or `node index.js` works. Verify these assumptions against your package files.

## 2. Terraform: create EC2

Prerequisites: Terraform, AWS CLI, and an AWS account with permission to create EC2, security groups, IAM roles/policies, and an OIDC provider role for GitHub Actions.

```bash
cd infra
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

Terraform outputs the instance public IP and instance ID. The instance security group allows SSH only from `var.admin_cidr` and HTTP on port 80 from the internet. Backend port 5000 is intentionally not public; Nginx proxies `/api/` to localhost:5000.

Before applying, set `admin_cidr` to your public IP with `/32`, for example via:
```bash
terraform apply -var='admin_cidr=YOUR_PUBLIC_IP/32'
```
Never use `0.0.0.0/0` for SSH.

Terraform creates an EC2 instance and a security group. It does **not** create a GitHub OIDC IAM role automatically; use the setup in `infra/GITHUB_OIDC.md` or provide an existing role ARN as a GitHub secret.

## 3. GitHub Actions -> AWS -> EC2

This workflow uses GitHub OIDC to obtain temporary AWS credentials (preferred over long-lived access keys), then uses SSH to copy/deploy the code on the EC2 instance.

Configure these repository secrets:
- `AWS_ROLE_TO_ASSUME`: IAM role ARN trusted by GitHub OIDC.
- `EC2_HOST`: Terraform output `instance_public_ip`.
- `EC2_SSH_PRIVATE_KEY`: private key corresponding to the EC2 key pair.
- `EC2_USER`: normally `ubuntu`.

Configure this repository variable:
- `AWS_REGION`: e.g. `us-east-1`.

Also ensure the EC2 instance's SSH security-group ingress permits the GitHub-hosted runner's source IP. GitHub-hosted runner IP ranges change, so a safer option is a self-hosted runner or a controlled deployment path. The included Terraform defaults SSH ingress to your admin CIDR, so a hosted runner will not necessarily be able to connect. Do not open SSH to the entire internet merely to make the workflow work.

The workflow expects the repository to contain `client/` and `server/`, with `client/package.json` providing `npm run build`, and `server/package.json` providing a working `npm start` script or `index.js` entrypoint. It copies the repository to `/opt/leyo`, builds the frontend on EC2, installs backend production dependencies, writes an Nginx config, and starts the backend with PM2.

## Security and production notes

- Never commit `.env`, MongoDB credentials, private SSH keys, or AWS credentials.
- Use AWS Systems Manager Session Manager or a self-hosted runner/private connectivity for stronger SSH security.
- Put production secrets in AWS Systems Manager Parameter Store or Secrets Manager rather than GitHub workflow literals.
- This is a starter scaffold. Test it with your actual package scripts, environment variables, image names, and app routes before production use.
