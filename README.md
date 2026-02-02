# ingress-lab (GitOps)

GitOps-first Kubernetes lab on kind (advanced-lab).

## Goals
- Argo CD as the only deployment mechanism
- NGINX Ingress Controller managed by GitOps
- Demo apps exposed via demo.local/app1 and demo.local/app2
- Gitea exposed via demo.local/gitea

## Architecture
- App of Apps (bootstrap)
- Platform layer (ingress-nginx)
- Application layer (demo apps)
- Application layer (gitea)
- Routing via Ingress

## Unique command to run 
- kubectl apply -f bootstrap/root-app.yaml
