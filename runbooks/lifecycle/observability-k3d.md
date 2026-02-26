# observability-k3d
## Prerequisites (one-time)

Add to `/etc/hosts`:
## Up

**Bootstrap automático** (recomendado):

```bash
./scripts/bootstrap-observability-k3d.sh
```

El script ejecuta en orden: cluster → Cilium (CNI) → Argo CD → root app. Cilium debe instalarse antes de Argo CD porque el cluster arranca sin CNI (flannel deshabilitado).

**Pasos manuales** (si prefieres control granular):

1. `k3d cluster create --config runtimes/k3d/cluster-template.yaml`
2. Instalar Cilium (antes de Argo CD):
   ```bash
   helm repo add cilium https://helm.cilium.io/
   helm install cilium cilium/cilium -n kube-system --version 1.15 \
     --set kubeProxyReplacement=false --set tunnel=vxlan --wait
   kubectl -n kube-system rollout status daemonset/cilium
   kubectl -n kube-system rollout status deployment/cilium-operator
   ```
3. Instalar Argo CD en namespace `argocd`.
4. Aplicar root app: `gitops/roots/observability-k3d/root-app.yaml`.

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
