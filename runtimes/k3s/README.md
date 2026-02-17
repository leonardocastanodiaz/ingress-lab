# k3s runtime profile

Use k3s when you want lightweight production-like behavior and stable provider tests.

## Example bootstrap

```bash
curl -sfL https://get.k3s.io | \
  INSTALL_K3S_EXEC="--write-kubeconfig-mode=644 --disable=traefik" \
  sh -
```

## Notes

- This runtime is usually validated on VM/bare metal.
- Keep this profile separate from `kind` and `k3d` labs.
