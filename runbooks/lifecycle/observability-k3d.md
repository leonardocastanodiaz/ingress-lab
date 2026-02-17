# observability-k3d

## Up

1. `k3d cluster create --config runtimes/k3d/cluster-template.yaml`
2. Install Argo CD in `argocd` namespace.
3. Apply root app: `gitops/roots/observability-k3d/root-app.yaml`.

## Pause

- `docker stop k3d-k3d-lab-server-0 k3d-k3d-lab-agent-0 k3d-k3d-lab-agent-1`

## Resume

- `docker start k3d-k3d-lab-server-0 k3d-k3d-lab-agent-0 k3d-k3d-lab-agent-1`
- Verify Argo apps and Grafana API health.

## Destroy

- `k3d cluster delete k3d-lab`

## Smoke

- All `observability-k3d-*` apps in `Synced/Healthy`.
- Grafana and Prometheus ingress endpoints respond.
- Probe metrics (`probe_success`) available in Prometheus.
