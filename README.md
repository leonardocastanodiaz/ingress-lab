
---

## ✅ Implemented Features

### ☸️ Kubernetes & GitOps
- ✔ **kind** as local Kubernetes cluster
- ✔ **NGINX Ingress Controller**
- ✔ **Argo CD** with:
  - automated sync
  - prune & self-heal
  - fully declarative platform deployments
- ✔ **Sealed Secrets** for GitOps-managed credentials

---

### 📦 Container Registry
- ✔ **Docker Registry v2 (distribution)**
- ✔ Deployed inside Kubernetes
- ✔ Managed 100% through GitOps (Argo CD)
- ✔ Used internally by CI runners and workloads
- ✔ Registry accessible via `registry.demo.local`

---

### 📊 Observability
- ✔ **Prometheus + Grafana** via kube-prometheus-stack (Helm)
- ✔ Managed via Argo CD with repo-based values
- ✔ Grafana exposed at `demo.local/grafana`

---

### 🧠 Source Control Plane
- ✔ **Gitea** as self-hosted Git server
- ✔ Dedicated repositories for:
  - GitOps manifests
  - CI workflows
  - Infrastructure as Code

---

### ⚙️ CI / Automation
- ✔ **Gitea Actions enabled**
- ✔ **Custom Gitea Action Runner** deployed in Kubernetes
- ✔ Runner created via GitOps using `gitea-runner-token`
- ✔ Runner built as a **custom container image** including:
  - Terraform
  - Docker CLI
  - OpenStack CLI
  - AWS CLI
  - LocalStack CLI
- ✔ Automatic runner registration (GitOps-friendly)
- ✔ Runners run as Kubernetes pods (ephemeral & scalable)
- ✔ Runner ready to execute Terraform against DockerStack Dev on a VM

Example runner labels (from the runner config):
- `docker` → `registry.demo.local/terraform-runner:0.1`
- `terraform` → `registry.demo.local/terraform-runner:0.1`
- `localstack` → `registry.demo.local/terraform-runner:0.1`

Example workflow snippet:
```yaml
jobs:
  plan:
    runs-on: [terraform]
    steps:
      - uses: actions/checkout@v4
      - run: terraform version
```

OpenStack credentials (SealedSecret):
- SealedSecret: `apps/gitea-runner/manifests/openstack-clouds-sealedsecret.yaml`
- It creates `Secret/openstack-clouds` with `clouds.yaml`
- Runner mounts it at `/etc/openstack/clouds.yaml` and exports:
  - `OS_CLIENT_CONFIG_FILE=/etc/openstack/clouds.yaml`
  - `OS_CLOUD=devstack`

---

### ✅ Runner Validation Checklist
- `kubectl get pods -n gitea-runner` → `2/2 Running`
- Gitea UI → Actions → Runners → runner is **Online**
- `kubectl logs -n gitea-runner deploy/gitea-runner -c act-runner --tail=50` has no token or docker errors
- Smoke workflow runs with `runs-on: [terraform]` and prints `terraform version`

### 🔧 OpenStack Troubleshooting
- If `openstack token issue` hangs or returns 500, check MySQL in the VM:
  - `sudo systemctl status mysql`
  - `sudo systemctl start mysql`
  - `sudo systemctl restart apache2`

---

### ☁️ Cloud Platform (OpenStack)
- ✔ **OpenStack DevStack** fully operational
- ✔ Keystone / Nova / Neutron / Glance / Horizon
- ✔ API and Dashboard access
- ✔ Integrated with Terraform and OpenStack CLI

---

### 🧱 Infrastructure as Code (IaC)
- ✔ **Terraform**
  - OpenStack provider
  - VM provisioning from CI pipelines
- ✔ **Pulumi** (prepared for integration)
- ✔ `clouds.yaml`–based authentication
- ✔ Design ready for remote state backends

---

## 📁 Repository Structure (Example)


---

## 🧪 Network Lab (FRR) Validation

Target: app `network-lab` with two routers (`frr1-0`, `frr2-0`) in namespace `network-lab`.

### Post-sync acceptance checklist

- `network-lab` is `Synced` and `Healthy` in Argo CD.
- Exactly two FRR pods are running (`frr1-0`, `frr2-0`).
- BGP is `Established` on both sides (not `Active`/`Connect`).
- Message counters increase on both peers.
- Each router sees its own network and the learned prefix from the peer.

### Standard verification commands

```bash
kubectl get pods -n network-lab -o wide
kubectl get statefulset,svc -n network-lab

kubectl exec -n network-lab pod/frr1-0 -- vtysh -c "show bgp summary"
kubectl exec -n network-lab pod/frr2-0 -- vtysh -c "show bgp summary"

kubectl exec -n network-lab pod/frr1-0 -- vtysh -c "show ip bgp"
kubectl exec -n network-lab pod/frr2-0 -- vtysh -c "show ip bgp"

kubectl logs -n network-lab pod/frr1-0 --tail=80
kubectl logs -n network-lab pod/frr2-0 --tail=80
```

### Common troubleshooting states

- `No BGP neighbors found`:
  - Verify peer DNS resolves from the pod (`frr1-0.frr1...`, `frr2-0.frr2...`).
  - Check `postStart` logs and ensure `bgpd` was ready before neighbor injection.
- `Active` or `Connect`:
  - Confirm both routers have matching `remote-as`.
  - Confirm `ebgp-multihop 2` and `disable-connected-check` were applied.
  - Re-check neighbor IP after restart (pod IP can change, DNS must be used).
- `Established` but `(Policy)`:
  - Ensure `no bgp ebgp-requires-policy` is set in router config.
  - Ensure neighbor is activated under `address-family ipv4 unicast`.

---

## 📈 Zabbix Integration Prep (Next Phase)

Use FRR validation as the baseline before adding Zabbix templates/items.

Initial FRR metrics to poll first:

- BGP peer state (`Established`, `Active`, `Connect`).
- Peer uptime (`Up/Down` column).
- Prefixes received/sent (`State/PfxRcd`, `PfxSnt`).
- Message counters (`MsgRcvd`, `MsgSent`).

Recommended baseline gate before enabling alerts:

- 2/2 routers running.
- BGP established on both routers for at least 5 minutes.
- Prefix exchange visible on both nodes.
