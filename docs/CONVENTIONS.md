# Multi-Lab and Multi-Runtime Conventions

This repository supports multiple labs and runtimes with a GitOps-first model.

## Naming

- Cluster name: `{runtime}-{lab}` (example: `k3d-observability`)
- Argo CD app name: `{lab}-{runtime}-{component}`
- Namespace: `{lab}-{component}` for lab-scoped workloads
- Ingress host: `{service}.{lab}.local`

## Repository layout

- `labs/catalog/`: lab inventory and ownership metadata
- `runtimes/`: runtime bootstrap profiles
- `gitops/roots/`: Argo root apps by lab/runtime
- `apps/base/`: shared reusable app definitions
- `apps/overlays/{lab}-{runtime}/`: lab/runtime-specific overlays
- `secrets/{lab}-{runtime}/`: SealedSecret manifests by blast radius
- `runbooks/`: operational docs and smoke tests

## GitOps rules

- The source of truth is always Git.
- Argo root apps must reference overlay paths, not ad-hoc mutable manifests.
- Manual kubectl patching is break-glass only and must be documented in runbooks.
- Each lab must have:
  - `up`, `pause`, `resume`, `destroy`, `smoke` procedures
  - acceptance criteria and rollback notes

## Scope isolation

- Avoid shared mutable namespaces for lab workloads.
- Keep secret paths and namespaces lab-scoped.
- Keep runtime profiles independent to avoid accidental cross-runtime drift.
