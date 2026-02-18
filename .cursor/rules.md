# Workspace Scope Rules

This workspace is limited to ingress-lab only.

## Context Policy
- Only analyze files explicitly referenced with @filename
- Do not scan parent directories
- Ignore sibling labs and runtimes
- Avoid loading overlays unless requested

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
