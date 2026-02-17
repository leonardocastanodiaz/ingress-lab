# Runtime profiles

This folder contains cluster bootstrap profiles by runtime.

- `kind/`: networking-heavy and conformance-like labs
- `k3d/`: fastest local iteration
- `k3s/`: lightweight production-like control-plane behavior

Each runtime folder should provide:

- cluster profile/config
- prerequisites
- commands for create/destroy
