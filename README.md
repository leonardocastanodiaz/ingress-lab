
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
- ✔ Prometheus exposed at `prometheus.demo.local`

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

## Multus network lab (SR-IOV style emulation)

This lab uses Multus in GitOps mode to add secondary interfaces to FRR pods. On kind/macOS this is an emulation path (bridge-based), not physical SR-IOV passthrough.

Resources used:

- Argo CD app: `bootstrap/multus.yaml`
- Argo CD app: `bootstrap/cni-plugins.yaml` (installs missing CNI binaries in kind nodes)
- Secondary network (NAD): `apps/network-lab/frr/multus-net.yaml`
- FRR StatefulSets with Multus annotation and static secondary IPs:
  - `frr1` -> `net1: 172.30.0.11/24`
  - `frr2` -> `net1: 172.30.0.12/24`
- BGP transport mode is configurable with `BGP_TRANSPORT`:
  - `primary` (default): peers over primary pod network (`eth0`, stable in kind)
  - `secondary`: peers over Multus secondary network (`net1`) for experiments

### PVC guidance for this lab

- Multus itself does not require PVC.
- FRR StatefulSets include per-router PVCs mounted at `/captures` for lab artifacts (pcap, debug files).
- PVC keeps captures across pod restarts while configs remain GitOps-managed.

### Validation commands

```bash
kubectl get applications -n argocd | rg cni-plugins
kubectl get pods -n kube-system | rg cni-plugins-installer
kubectl get applications -n argocd | rg multus
kubectl get pods -n kube-system | rg multus
kubectl get net-attach-def -n network-lab

kubectl get pods -n network-lab -o wide
kubectl get pvc -n network-lab

kubectl exec -n network-lab pod/frr1-0 -- ip -4 a
kubectl exec -n network-lab pod/frr2-0 -- ip -4 a
kubectl exec -n network-lab pod/frr1-0 -- vtysh -c "show bgp summary"
kubectl exec -n network-lab pod/frr2-0 -- vtysh -c "show bgp summary"
```

---

## Blackbox Exporter (Kubernetes telemetry)

Blackbox Exporter is deployed via GitOps to monitor connectivity from inside Kubernetes and help diagnose local network instability.

### What is monitored

- ICMP reachability: `1.1.1.1`
- DNS over UDP checks: `1.1.1.1`, `8.8.8.8`
- HTTP checks: `https://www.google.com`, `https://cloudflare.com`
- TCP connectivity: `1.1.1.1:443`, `8.8.8.8:53`

### GitOps resources

- Argo CD app: `bootstrap/blackbox-exporter.yaml`
- Probe manifests app: `bootstrap/monitoring-probes.yaml`
- Blackbox chart values: `apps/monitoring/blackbox-values.yaml`
- Probe CRs: `apps/monitoring/manifests/blackbox-probes.yaml`

### Validation commands

```bash
kubectl get applications -n argocd
kubectl get pods,svc -n monitoring | rg blackbox
kubectl get probe -n monitoring
kubectl get prometheusrule -n monitoring | rg blackbox
```

### Prometheus metrics to use in Grafana

- `probe_success`
- `probe_duration_seconds`
- `probe_http_duration_seconds`
- `probe_dns_lookup_time_seconds`
- `probe_icmp_duration_seconds`

### ICMP test (from Kubernetes)

Use this query in Prometheus:

```promql
probe_success{job="blackbox-icmp-internet"}
```

Interpretation:

- `1` = reachable
- `0` = failed probe

This lab also includes alert `BlackboxIcmpTargetDown` if ICMP probe stays down for 2 minutes.
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

---

## Traffic Correlation MVP runbook (FRR restart)

Goal: run one low-cost traffic event and validate that disruption/recovery is visible in FRR checks plus Prometheus/Grafana metrics.

### Exact commands used

1) Baseline check (FRR healthy before event):

```bash
kubectl exec -n network-lab pod/frr1-0 -- vtysh -c "show bgp summary"
kubectl exec -n network-lab pod/frr2-0 -- vtysh -c "show bgp summary"
```

Expected baseline: both peers show `State/PfxRcd = 1`.

2) Baseline check (Blackbox metrics present in Prometheus):

```bash
kubectl exec -n monitoring pod/prometheus-monitoring-kube-prometheus-prometheus-0 -c prometheus -- \
  wget -qO- "http://localhost:9090/api/v1/query?query=probe_success"

kubectl exec -n monitoring pod/prometheus-monitoring-kube-prometheus-prometheus-0 -c prometheus -- \
  wget -qO- "http://localhost:9090/api/v1/query?query=probe_duration_seconds"
```

3) Single controlled event (restart `frr2` once):

```bash
kubectl rollout restart statefulset/frr2 -n network-lab
```

Event window captured in this run:

- `EVENT_START=2026-02-16T17:28:25Z`
- `EVENT_END=2026-02-16T17:29:44Z`

4) Correlate FRR and Prometheus around the event:

```bash
# FRR behavior (repeat every few seconds during event)
kubectl exec -n network-lab pod/frr1-0 -- vtysh -c "show bgp summary"
kubectl exec -n network-lab pod/frr2-0 -- vtysh -c "show bgp summary"

# Prometheus query_range for Blackbox ICMP
kubectl exec -n monitoring pod/prometheus-monitoring-kube-prometheus-prometheus-0 -c prometheus -- \
  wget -qO- "http://localhost:9090/api/v1/query_range?query=probe_success%7Bjob%3D%22blackbox-icmp-internet%22%2Cinstance%3D%221.1.1.1%22%7D&start=1771262905&end=1771263084&step=15"

kubectl exec -n monitoring pod/prometheus-monitoring-kube-prometheus-prometheus-0 -c prometheus -- \
  wget -qO- "http://localhost:9090/api/v1/query_range?query=probe_duration_seconds%7Bjob%3D%22blackbox-icmp-internet%22%2Cinstance%3D%221.1.1.1%22%7D&start=1771262905&end=1771263084&step=15"
```

### Grafana/Prometheus queries to use

- `probe_success{job="blackbox-icmp-internet",instance="1.1.1.1"}`
- `probe_duration_seconds{job="blackbox-icmp-internet",instance="1.1.1.1"}`
- `kube_pod_container_status_ready{namespace="network-lab",pod="frr2-0",container="frr"}`

Use a dashboard time range covering at least 5 minutes around `EVENT_START`/`EVENT_END`.

### Expected metric behavior

- FRR BGP check: short degradation during router restart (`Idle/Connect/Active` or `PfxRcd=0`), then returns to `PfxRcd=1`.
- Blackbox ICMP availability: should usually remain `1` (control-plane restart can be isolated from internet probe path).
- Blackbox latency: may show small jitter but should return near baseline.

### Pass/fail criteria

Pass:

- FRR returns to healthy state (`State/PfxRcd=1`) after event.
- At least one query/panel clearly shows event window and post-event recovery.
- Procedure is reproducible with the exact commands above.

Fail:

- FRR remains in `Active/Connect/Idle` without recovery.
- No observable change/correlation across FRR checks and Prometheus metrics.

### Notes from this run

- Disturbance was clear immediately after restart (`Idle -> Connect`).
- Blackbox ICMP stayed healthy (`probe_success=1` across sampled range).
- Recovery required neighbor refresh after pod IP change; after correction, both peers returned to `State/PfxRcd=1`.
