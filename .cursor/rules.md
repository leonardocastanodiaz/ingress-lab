# Workspace Scope Rules

This workspace is limited to ingress-lab only.

## Context Policy
- Only analyze files explicitly referenced with @filename
- Do not scan parent directories
- Ignore sibling labs and runtimes
- Avoid loading overlays unless requested

## GitOps Enforcement Policy (MANDATORY)

All changes MUST follow GitOps principles.

Allowed:
- Propose changes as file edits inside the repo
- Modify manifests, kustomizations, or Helm values declaratively
- Suggest PR-style diffs only

Forbidden:
- kubectl patch
- kubectl edit
- kubectl apply (manual)
- helm upgrade/install from CLI
- Any imperative runtime mutation
- Direct cluster state fixes

Rules:
- Never suggest hotfixes directly in the cluster
- Never modify live resources outside Git
- Assume ArgoCD is the single source of truth
- If a fix requires cluster change, propose repo change instead

## Drift Awareness
- Assume manual drift is a bug
- Never propose runtime-only fixes
- Always restore desired state from Git

Decision rule:
IF a problem could be solved via kubectl,
THEN redesign solution as Git change.

## Repository Structure Awareness
This is part of a mono-repo, but treat ingress-lab as isolated.

Ignored paths:
  # Otros labs (roots)
  - gitops/roots/networking-kind
  - gitops/roots/crossplane-k3s

  # Overlays de otros labs
  - apps/overlays/networking-kind
  - apps/overlays/crossplane-k3s

  # Bases y apps no usadas por observability
  - apps/base/network-lab-frr
  - apps/base/cni-plugins
  - apps/base/gitea-runner
  - apps/base/gitea
  - apps/base/registry
  - apps/base/demo
  - apps/network-lab
  - apps/cni-plugins
  - apps/gitea-runner
  - apps/gitea
  - apps/registry
  - apps/demo
  - apps/monitoring

  # Otros runtimes
  - runtimes/kind
  - runtimes/k3s

  # Bootstrap manual
  - bootstrap

  # Labs edge
  - labs/edge

## Response Style
- Minimal context
- Short answers
- No global architecture assumptions
- Prefer diff-style responses

