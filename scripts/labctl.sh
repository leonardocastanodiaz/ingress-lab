#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <up|pause|resume|destroy|smoke> <lab> <runtime>"
  echo "Example: $0 up observability k3d"
  exit 1
fi

ACTION="$1"
LAB="$2"
RUNTIME="$3"
TARGET="${LAB}-${RUNTIME}"

case "${ACTION}" in
  up)
    case "${RUNTIME}" in
      kind)
        kind create cluster --name "${RUNTIME}-${LAB}" --config runtimes/kind/cluster-template.yaml
        ;;
      k3d)
        k3d cluster create --config runtimes/k3d/cluster-template.yaml
        ;;
      k3s)
        echo "Run k3s bootstrap from runtimes/k3s/README.md"
        ;;
      *)
        echo "Unsupported runtime: ${RUNTIME}"
        exit 1
        ;;
    esac
    echo "Apply root app: gitops/roots/${TARGET}/root-app.yaml"
    ;;
  pause)
    echo "Use runbook: runbooks/lifecycle/${TARGET}.md"
    ;;
  resume)
    echo "Use runbook: runbooks/lifecycle/${TARGET}.md"
    ;;
  destroy)
    case "${RUNTIME}" in
      kind)
        kind delete cluster --name "${RUNTIME}-${LAB}"
        ;;
      k3d)
        k3d cluster delete k3d-lab
        ;;
      k3s)
        echo "Use k3s uninstall script in target host/VM"
        ;;
      *)
        echo "Unsupported runtime: ${RUNTIME}"
        exit 1
        ;;
    esac
    ;;
  smoke)
    echo "Run smoke checklist from runbooks/lifecycle/${TARGET}.md"
    ;;
  *)
    echo "Unsupported action: ${ACTION}"
    exit 1
    ;;
esac
