#!/usr/bin/env bash
# Bootstrap observability-k3d lab: cluster + Cilium (before Argo CD) + Argo CD + root app.
# Cilium must be installed first because the cluster starts without CNI (flannel disabled).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CLUSTER_NAME="k3d-lab"

echo "==> 1. Creating k3d cluster (flannel disabled)"
k3d cluster create --config "${REPO_ROOT}/runtimes/k3d/cluster-template.yaml"

echo "==> 2. Installing Cilium (CNI) before Argo CD"
helm repo add cilium https://helm.cilium.io/ 2>/dev/null || true
helm repo update
helm upgrade --install cilium cilium/cilium \
  --namespace kube-system \
  --version 1.15 \
  --set kubeProxyReplacement=false \
  --set routingMode=native \
  --set ipv4NativeRoutingCIDR=10.0.0.0/8 \
  --set autoDirectNodeRoutes=true

echo "==> 3. Waiting for Cilium to be ready"
kubectl -n kube-system rollout status daemonset/cilium --timeout=120s
kubectl -n kube-system rollout status deployment/cilium-operator --timeout=120s

echo "==> 4. Installing Argo CD"
kubectl create namespace argocd 2>/dev/null || true
# --server-side avoids the 262144-byte annotation limit on large CRDs (e.g. applicationsets.argoproj.io)
kubectl apply -n argocd --server-side \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "==> 5. Waiting for Argo CD to be ready"
kubectl -n argocd rollout status deployment/argocd-server --timeout=120s

echo "==> 6. Applying root app"
kubectl apply -f "${REPO_ROOT}/gitops/roots/observability-k3d/root-app.yaml"

echo ""
echo "Bootstrap complete. Argo CD will sync apps automatically."
echo "Check status: kubectl get applications -n argocd"
