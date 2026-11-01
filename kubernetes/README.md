# Local Kubernetes deployment

The Helm chart is stored in `../helm/leyo`; this folder holds environment-specific configuration and local deployment instructions.

1. Start your local Kubernetes cluster.
2. Build images using the Containerfiles in `../deployment/containerfiles/`.
3. Load images into the cluster (example for Minikube):
   ```bash
   minikube image load leyo-client:local
   minikube image load leyo-server:local
   ```
4. Create the namespace and MongoDB secret:
   ```bash
   kubectl create namespace leyo
   kubectl -n leyo create secret generic leyo-secrets \
     --from-literal=MONGODB_URI='YOUR_MONGODB_CONNECTION_STRING'
   ```
5. Install the chart:
   ```bash
   helm upgrade --install leyo ../helm/leyo \
     --namespace leyo --create-namespace \
     -f values-local.yaml
   ```
6. Inspect:
   ```bash
   kubectl -n leyo get all
   kubectl -n leyo logs deploy/leyo-server
   ```
7. With Minikube:
   ```bash
   minikube service leyo-client -n leyo
   ```

Do not commit the MongoDB connection string. Kubernetes uses container images even when you do not use Docker CLI; Podman is one option for building those images.
