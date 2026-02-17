# crossplane-k3s

## Up

1. Provision k3s runtime (VM or host) with Traefik disabled.
2. Install Argo CD in `argocd` namespace.
3. Apply root app: `gitops/roots/crossplane-k3s/root-app.yaml`.

## Pause

- Stop k3s service on the target host.

## Resume

- Start k3s service and wait for node readiness.
- Verify Crossplane and provider pods in `crossplane-system`.

## Destroy

- Uninstall k3s from host or destroy VM.

## Smoke

- `crossplane-k3s-*` apps in `Synced/Healthy`.
- Crossplane pod and RBAC manager healthy.
- A test provider package can be installed successfully.
