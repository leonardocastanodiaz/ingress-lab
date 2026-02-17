# networking-kind

## Up

1. `kind create cluster --name kind-lab --config runtimes/kind/cluster-template.yaml`
2. Install Argo CD in `argocd` namespace.
3. Apply root app: `gitops/roots/networking-kind/root-app.yaml`.

## Pause

- `docker stop kind-lab-control-plane kind-lab-worker kind-lab-worker2`

## Resume

- `docker start kind-lab-control-plane kind-lab-worker kind-lab-worker2`
- Verify Argo apps, Multus daemonset, and FRR BGP summary.

## Destroy

- `kind delete cluster --name kind-lab`

## Smoke

- `networking-kind-*` apps in `Synced/Healthy`.
- `multus` pod healthy in `kube-system`.
- FRR peers establish and show expected prefixes.
