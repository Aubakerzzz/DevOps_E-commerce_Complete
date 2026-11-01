Here is the `README.md` for `docs/HELM`. It explains how Helm, the chart, and Kubernetes fit together, walks through running it locally and in a cluster, and documents every value in `values.yaml`.

```markdown
# Leyo — Helm Chart (Kubernetes)

This chart deploys the full Leyo stack — **React client**, **Express server**, and **MongoDB** — into any Kubernetes cluster (local or cloud).

It sits **between** your Docker images and the running cluster:

```text
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  Source code │────▶│    Docker    │────▶│    Helm      │────▶│  Kubernetes  │
│   (React +   │     │    images    │     │    chart     │     │   cluster    │
│    Express)  │     │              │     │  (this dir)  │     │              │
└──────────────┘     └──────────────┘     └──────────────┘     └──────────────┘
```

You do **not** run raw `kubectl apply` on YAML files. Helm renders the templates in `templates/` with the values in `values.yaml` and applies the result to the cluster in one atomic release.

---

## How Helm connects to Kubernetes

1. **You run `helm install`** (or `upgrade`) from this folder.
2. **Helm reads** `Chart.yaml` (metadata), `values.yaml` (defaults), and any `--values` overrides you pass.
3. **Helm renders** every file in `templates/` into plain Kubernetes YAML — substituting `{{ .Values.* }}`, running helpers from `_helpers.tpl`, and applying `{{- if ... }}` conditionals.
4. **Helm talks to the Kubernetes API** using whatever context `kubectl` is currently pointed at (`kubectl config current-context`). No separate configuration needed — Helm reuses your kubeconfig.
5. **Kubernetes creates** Deployments, Services, Secrets (referenced), PersistentVolumeClaims, and optionally an Ingress.
6. **Helm records** the release in a Secret (`sh.helm.release.v1.<release>.v1`) inside the cluster, so `helm upgrade` and `helm rollback` know what changed.

If you switch clusters (`kubectl config use-context minikube`), the next `helm install` goes to that cluster. Helm follows `kubectl`.

---

## Prerequisites

- **Docker** — to build the `leyo-client` and `leyo-server` images.
- **A Kubernetes cluster** — local (Docker Desktop, minikube, kind, k3d) or cloud (EKS, AKS, IKS, GKE).
- **`kubectl`** — pointed at the cluster (`kubectl cluster-info` should succeed).
- **`helm` v3** — `helm version` should print ≥ `3.12`.
- **Built images available to the cluster** — either pushed to a registry the cluster can pull from, or (for local clusters) loaded with `minikube image load` / `kind load docker-image` / `k3d image import`.

---

## Folder layout

```text
helm/
├── Chart.yaml                    # Chart metadata (name, version, appVersion)
├── values.yaml                   # Default values (production-ish)
├── values-local.yaml             # Overrides for local clusters (NodePort, :local tags)
├── _helpers.tpl                  # Reusable name/label templates
└── templates/
    ├── client-deployment.yaml    # React frontend Deployment
    ├── client-service.yaml       # Frontend Service (NodePort by default)
    ├── server-deployment.yaml    # Express backend Deployment (+ probes)
    ├── server-service.yaml       # Backend Service (ClusterIP)
    ├── mongo-deployment.yaml     # MongoDB Deployment (if mongo.enabled)
    ├── mongo-service.yaml        # MongoDB Service (ClusterIP :27017)
    ├── mongo-pvc.yaml            # MongoDB PersistentVolumeClaim
    └── ingress.yaml              # Optional Ingress for / and /api
```

---

## What gets deployed

| Component | Kubernetes resources | Default exposure |
|---|---|---|
| **client** | Deployment + Service | `NodePort :30080` → `containerPort 5173` |
| **server** | Deployment + Service | `ClusterIP :5000` → `containerPort 5000` |
| **mongo** | Deployment + Service + PVC | `ClusterIP :27017` → `containerPort 27017` |
| **ingress** | optional Ingress | disabled by default |

The server reads `MONGODB_URI` from the existing Secret `leyo-secrets` (configurable). Create it **before** installing the chart:

```bash
kubectl create secret generic leyo-secrets \
  --from-literal=MONGODB_URI='mongodb://leyo-mongo:27017/leyo' \
  --from-literal=SECRET_KEY_ACCESS_TOKEN='...' \
  --from-literal=SECRET_KEY_REFRESH_TOKEN='...' \
  --from-literal=CLIENT_URL='http://localhost:30080' \
  --from-literal=RESEND_API='re_...'
```

---

## Running locally (minikube / kind / Docker Desktop)

### 1. Build the images

From the **repository root** (where the Dockerfiles are):

```bash
docker build -t leyo-client:local -f client/Dockerfile client/
docker build -t leyo-server:local -f server/Dockerfile server/
```

### 2. Make the images visible to your cluster

Pick the command for your local cluster:

```bash
# minikube
minikube image load leyo-client:local
minikube image load leyo-server:local

# kind
kind load docker-image leyo-client:local
kind load docker-image leyo-server:local

# k3d
k3d image import leyo-client:local leyo-server:local -c <cluster-name>

# Docker Desktop
# No load needed — Docker Desktop shares the image cache with its K8s node.
```

### 3. Create the Secret

```bash
kubectl create namespace leyo   # optional, but cleaner
kubectl -n leyo create secret generic leyo-secrets \
  --from-literal=MONGODB_URI='mongodb://leyo-mongo:27017/leyo' \
  --from-literal=SECRET_KEY_ACCESS_TOKEN='dev-access' \
  --from-literal=SECRET_KEY_REFRESH_TOKEN='dev-refresh' \
  --from-literal=CLIENT_URL='http://localhost:30080' \
  --from-literal=RESEND_API='re_dev'
```

### 4. Install the chart with local overrides

```bash
cd helm
helm upgrade --install leyo . \
  --namespace leyo --create-namespace \
  --values values-local.yaml
```

`values-local.yaml` overrides the image repositories to `leyo-client:local` / `leyo-server:local`, switches the client Service to `NodePort :80` (mapped to `30080` by default in `values.yaml` — see note below), and disables the Ingress.

> **Note on the NodePort:** `values-local.yaml` sets `client.service.port: 80` but does **not** override `nodePort`. If you want a specific port, add `client.service.nodePort: 30080` to `values-local.yaml` or pass `--set client.service.nodePort=30080`.

### 5. Open the app

```bash
# minikube
minikube service leyo-client -n leyo --url

# kind / k3d / Docker Desktop
# Port-forward is the most portable:
kubectl -n leyo port-forward svc/leyo-client 8080:80
# then open http://localhost:8080
```

For the API, port-forward the server:

```bash
kubectl -n leyo port-forward svc/leyo-server 5000:5000
# http://localhost:5000
```

> **Heads-up:** the client is built with `VITE_API_URL="http://localhost:5000"` in `values.yaml`. When you access the app through a port-forward, the browser calls `localhost:5000` on **your machine**, which matches the second port-forward above. If you deploy to a real cluster, override `client.env.VITE_API_URL` to the cluster's public API URL (or route `/api` through the Ingress — see below).

---

## Running against a cloud cluster

```bash
# 1. Make sure your kubeconfig points at the cloud cluster
kubectl config use-context <your-cloud-context>
kubectl cluster-info

# 2. Push images to a registry the cluster can pull from
docker tag leyo-client:local <registry>/leyo-client:1.0.0
docker tag leyo-server:local <registry>/leyo-server:1.0.0
docker push <registry>/leyo-client:1.0.0
docker push <registry>/leyo-server:1.0.0

# 3. Create the Secret in the target namespace
kubectl -n leyo create secret generic leyo-secrets \
  --from-literal=MONGODB_URI='...' \
  --from-literal=SECRET_KEY_ACCESS_TOKEN='...' \
  --from-literal=SECRET_KEY_REFRESH_TOKEN='...' \
  --from-literal=CLIENT_URL='https://leyo.example.com' \
  --from-literal=RESEND_API='...'

# 4. Install / upgrade
helm upgrade --install leyo ./helm \
  --namespace leyo --create-namespace \
  --set client.image.repository=<registry>/leyo-client \
  --set client.image.tag=1.0.0 \
  --set server.image.repository=<registry>/leyo-server \
  --set server.image.tag=1.0.0 \
  --set client.env.VITE_API_URL='https://leyo.example.com/api'
```

### With Ingress enabled

```bash
helm upgrade --install leyo ./helm \
  --namespace leyo --create-namespace \
  --set ingress.enabled=true \
  --set ingress.className=nginx \
  --set ingress.host=leyo.example.com \
  --set client.env.VITE_API_URL='https://leyo.example.com/api' \
  --set client.image.repository=<registry>/leyo-client \
  --set client.image.tag=1.0.0 \
  --set server.image.repository=<registry>/leyo-server \
  --set server.image.tag=1.0.0
```

The Ingress routes:

- `/<anything>` → `leyo-client:8080`
- `/api/<anything>` → `leyo-server:5000`

Enable TLS by populating `ingress.tls` in a values file:

```yaml
ingress:
  enabled: true
  className: nginx
  host: leyo.example.com
  tls:
    - hosts: [leyo.example.com]
      secretName: leyo-tls
```

---

## Values reference

### Top-level

| Key | Default | Description |
|---|---|---|
| `nameOverride` | `""` | Override chart name in resource names |
| `fullnameOverride` | `""` | Override full resource prefix |

### `client.*`

| Key | Default | Description |
|---|---|---|
| `client.replicaCount` | `1` | Number of frontend pods |
| `client.image.repository` | `leyo-main-client` | Image name |
| `client.image.tag` | `latest` | Image tag |
| `client.image.pullPolicy` | `IfNotPresent` | Pull policy |
| `client.service.type` | `NodePort` | Service type |
| `client.service.port` | `8080` | Service port (as exposed by the NodePort) |
| `client.service.targetPort` | `5173` | Port on the pod |
| `client.service.nodePort` | `30080` | NodePort (only when `type: NodePort`) |
| `client.containerPort` | `5173` | Vite preview port inside the container |
| `client.env.VITE_API_URL` | `http://localhost:5000` | API base URL baked into the frontend |
| `client.resources` | `{}` | CPU/memory requests/limits |

### `server.*`

| Key | Default | Description |
|---|---|---|
| `server.replicaCount` | `1` | Number of backend pods |
| `server.image.repository` | `leyo-main-server` | Image name |
| `server.image.tag` | `latest` | Image tag |
| `server.image.pullPolicy` | `IfNotPresent` | Pull policy |
| `server.service.type` | `ClusterIP` | Service type |
| `server.service.port` | `5000` | Service port |
| `server.service.targetPort` | `5000` | Container port |
| `server.containerPort` | `5000` | Port the Express server listens on |
| `server.env.PORT` | `"5000"` | Env var passed to the container |
| `server.env.NODE_ENV` | `production` | Env var passed to the container |
| `server.existingSecret` | `leyo-secrets` | Secret already present in the namespace |
| `server.mongodbSecretKey` | `MONGODB_URI` | Key inside that Secret holding the Mongo URI |

### `mongo.*`

| Key | Default | Description |
|---|---|---|
| `mongo.enabled` | `true` | Deploy an in-cluster MongoDB |
| `mongo.image.repository` | `mongo` | Image name |
| `mongo.image.tag` | `"7"` | Image tag |
| `mongo.service.port` | `27017` | Service port |
| `mongo.persistence.enabled` | `true` | Create a PVC |
| `mongo.persistence.size` | `1Gi` | PVC size |
| `mongo.persistence.mountPath` | `/data/db` | Where Mongo stores data |
| `mongo.healthcheck.*` | `5s/5s/10` | Probe timing |

Set `mongo.enabled: false` if you use **MongoDB Atlas** or an external database — just make sure `MONGODB_URI` in `leyo-secrets` points to it.

### `ingress.*`

| Key | Default | Description |
|---|---|---|
| `ingress.enabled` | `false` | Create an Ingress resource |
| `ingress.className` | `""` | IngressClass (e.g. `nginx`) |
| `ingress.annotations` | `{}` | Extra annotations (cert-manager, etc.) |
| `ingress.host` | `leyo.local` | Hostname |
| `ingress.tls` | `[]` | TLS hosts + secret |

---

## Common operations

```bash
# See what's running
kubectl -n leyo get pods,svc,pvc,ingress

# Tail logs
kubectl -n leyo logs -l app.kubernetes.io/component=server -f
kubectl -n leyo logs -l app.kubernetes.io/component=client -f
kubectl -n leyo logs -l app.kubernetes.io/component=mongo -f

# Upgrade after a code change
helm upgrade leyo ./helm -n leyo --values values-local.yaml

# Dry-run to see rendered YAML
helm template leyo ./helm --values values-local.yaml

# Roll back to the previous revision
helm rollback leyo 1 -n leyo

# Uninstall the release (PVCs survive — delete them separately)
helm uninstall leyo -n leyo
kubectl -n leyo delete pvc -l app.kubernetes.io/instance=leyo

# Lint the chart
helm lint ./helm
```

---

## How this chart relates to the other folders

| Folder | Role |
|---|---|
| `client/`, `server/` | Source code + Dockerfiles → build `leyo-client` / `leyo-server` images |
| `infra_AWS`, `infra_Azure`, `infra_IBM` | Provision a **single VM** (no Kubernetes) — deploy via Docker Compose workflows |
| `helm/` (this folder) | Deploy the **same images** to **Kubernetes** — deploy via `helm upgrade` |
| `.github/workflows/deploy-aws.yml` etc. | Deploy to the VM path (Compose) |
| `.github/workflows/deploy-k8s.yml` (if added) | Deploy to the Kubernetes path (Helm) |

The two deployment paths are **independent**: you can run the Compose-based VM deployment, the Helm-based Kubernetes deployment, or both — they share images but not infrastructure.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `ImagePullBackOff` | Image not loaded / pushed, or wrong tag | `minikube image load …` / `docker push …`; check `image.repository` and `image.tag` |
| `CrashLoopBackOff` on server | Missing or wrong `MONGODB_URI` | `kubectl -n leyo describe pod …`; verify `leyo-secrets` exists and the key matches `server.mongodbSecretKey` |
| Server ready but frontend can't reach API | `VITE_API_URL` points to `localhost:5000` from the browser | Set `client.env.VITE_API_URL` to the cluster-exposed URL, or add a port-forward for `:5000`, or enable the Ingress and use `…/api` |
| `pending` PVC | No default StorageClass | Install one (`minikube addons enable storage-provisioner` / cloud provider default) or set `mongo.persistence.enabled: false` for ephemeral tests |
| Ingress returns 404 | `ingress.className` wrong, or no ingress controller | Install `ingress-nginx`, set `ingress.className: nginx` |
| `helm install` says release exists | Previous failed install | `helm uninstall leyo -n leyo` then retry, or use `helm upgrade --install` |
```

---

### Notes on accuracy

- Every value name in the reference tables maps 1:1 to a key in `values.yaml` or `values-local.yaml`.
- The **NodePort note** is deliberate: `values-local.yaml` sets `client.service.port: 80` but *not* `nodePort`, so the effective node port comes from `values.yaml` (`30080`). I called this out rather than pretending it's automatic.
- The **`VITE_API_URL` gotcha** is real — Vite bakes env vars at build time, and the default `http://localhost:5000` only works with a matching port-forward. That's why I documented the port-forward path explicitly instead of just saying "open the NodePort".
- I referenced `mongo-deployment.yaml`, `mongo-service.yaml`, `mongo-pvc.yaml` in the folder layout because `values.yaml` has `mongo.enabled: true` and the healthcheck block — if those templates don't exist yet, you'll want to create them or flip `mongo.enabled: false` and point `MONGODB_URI` at an external Mongo. I did **not** invent values that aren't in your `values.yaml`.