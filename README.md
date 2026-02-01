# ingress-lab (GitOps)

GitOps-first Kubernetes lab on kind (advanced-lab).

## Goals
- Argo CD as the only deployment mechanism
- NGINX Ingress Controller managed by GitOps
- Demo apps exposed via demo.local/app1 and demo.local/app2

## Architecture
- App of Apps (bootstrap)
- Platform layer (ingress-nginx)
- Application layer (demo apps)
- Routing via Ingress

## Unique command to run 
- kubectl apply -f bootstrap/root-app.yaml
