# Lab Progress — ingress-lab

Estado de avance del conocimiento construido en este repositorio.
Este repo es una plataforma multi-lab, multi-runtime, GitOps-first para practicar
ingeniería de plataforma a nivel senior/staff.

---

## Arquitectura del repo

```
ingress-lab/
├── runtimes/          → perfiles de cluster por runtime (k3d, kind, k3s)
├── gitops/roots/      → root apps de Argo CD por lab/runtime
├── apps/
│   ├── base/          → definiciones reutilizables
│   └── overlays/      → configuración específica por lab/runtime
├── runbooks/          → procedimientos operacionales
├── labs/catalog/      → inventario de labs
└── docs/              → convenciones y arquitectura
```

**Principio rector:** Git es la única fuente de verdad. Todo lo que corre en el cluster
está versionado. El único paso manual es instalar Argo CD y aplicar el root app.

---

## Labs construidos

### 1. GitOps Platform Lab (kind)
**Runtime:** kind  
**Estado:** completado

**Lo que se construyó:**
- Cluster kind con Argo CD completamente declarativo
- NGINX Ingress Controller gestionado por Argo CD
- Sealed Secrets para credenciales en Git
- Docker Registry v2 desplegado dentro del cluster
- Gitea como servidor Git self-hosted
- Gitea Actions Runner con imagen custom (Terraform + Docker + OpenStack CLI)

**Conocimiento adquirido:**
- Patrón app-of-apps (root app → bootstrap/ → applications)
- GitOps estricto: sin `kubectl apply` ad-hoc, todo en Git
- Sealed Secrets: asimetría de clave, blast radius por namespace
- Runners efímeros en Kubernetes vs runners permanentes
- Imagen custom de CI con múltiples toolchains

---

### 2. Networking Lab — FRR/BGP/Multus (kind)
**Runtime:** kind  
**Estado:** completado

**Lo que se construyó:**
- Multus CNI para interfaces secundarias en pods
- FRR (Free Range Routing) como router en StatefulSets
- BGP eBGP entre dos routers (frr1, frr2) con secondary interfaces
- NetworkAttachmentDefinition (NAD) para la red secundaria
- PVCs por router para captura de tráfico (pcap)
- Traffic correlation: evento de restart → correlación en Prometheus

**Conocimiento adquirido:**
- Multus: múltiples interfaces de red en un pod, NotworkAttachmentDefinition
- BGP: eBGP, multihop, disable-connected-check, prefix exchange
- FRR: vtysh, bgpd, neighbor config via postStart hooks
- Diferencia entre primary network (eth0) y secondary (net1)
- Correlación de eventos: FRR BGP state + Blackbox ICMP en Prometheus
- StatefulSets con headless service para DNS estable entre routers

---

### 3. Crossplane Lab (k3s)
**Runtime:** k3s  
**Estado:** definido (runbook existe)

**Objetivo:** patrones de provisioning y automatización de control-plane con Crossplane.

**Conocimiento pendiente:**
- Crossplane Providers (AWS, OpenStack, etc.)
- Composite Resources (XR) y Compositions
- GitOps de infraestructura cloud desde el cluster

---

### 4. Observability Lab — Cilium/eBPF (k3d)
**Runtime:** k3d  
**Estado:** en construcción

**Lo que se construyó hasta ahora:**
- Cluster k3d con 3 nodos (1 server + 2 agents)
- Argo CD instalado con root app vía GitOps
- NGINX Ingress como LoadBalancer (resuelto: NodePort no funciona con mapeo de puertos k3d)
- Sealed Secrets controller activo y operacional
- Blackbox Exporter corriendo
- Monitoring probes sincronizadas (Kustomize, resuelto: seguridad de paths)
- Argo CD expuesto via Ingress (parcial: login funciona por port-forward)

**Problemas resueltos en este lab:**
- k3d `type: NodePort` vs `type: LoadBalancer`: el mapeo de puertos de k3d solo funciona con LoadBalancer
- Kustomize security constraint: los recursos deben estar dentro del árbol del kustomization.yaml
- Argo CD `--insecure` mode: necesario para exponer detrás de Ingress HTTP
- `argocd login` no acepta prefijo `http://`, solo `host:port`
- Warning `--grpc-web`: NGINX no soporta gRPC puro; usar `ARGOCD_OPTS=--grpc-web`
- bcrypt hash en argocd-secret: formato `$2y$` requerido, generado con `htpasswd -nbBC 10`

**Pendiente en este lab:**
- Cilium: recrear cluster con `--disable=flannel` para que sea el CNI exclusivo
- Hubble: habilitar para visualización de flows de red con eBPF
- Grafana: aplicar secret `grafana-admin-secret` via Sealed Secrets
- Argo CD Ingress: anotaciones para login sin port-forward
- Tests de observabilidad profunda: flows Hubble + Prometheus

---

## Runtimes dominados

| Runtime | Uso | Estado |
|---------|-----|--------|
| **kind** | Labs locales rápidos, CNI custom, networking | Dominado |
| **k3d** | Labs con Docker, mapeo de puertos, Cilium | En progreso |
| **k3s** | Comportamiento production-like en VM/bare metal | Definido |

---

## Patrones GitOps establecidos

### Bootstrap estándar (cualquier lab)

```bash
# 1. Crear cluster
k3d cluster create --config runtimes/k3d/cluster-template.yaml

# 2. Instalar Argo CD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 3. Aplicar root app (único paso manual)
kubectl apply -f gitops/roots/{lab}-{runtime}/root-app.yaml

# A partir de aquí, todo lo que esté en apps/ se despliega automáticamente
```

### Sealed Secrets (cualquier secret en Git)

```bash
kubectl create secret generic <nombre> \
  --from-literal=key=value \
  --namespace <ns> \
  --dry-run=client -o yaml > /tmp/secret.yaml

kubeseal --format yaml \
  --controller-name <release-name> \
  --controller-namespace sealed-secrets \
  < /tmp/secret.yaml > apps/overlays/<lab>/secrets/<nombre>-sealedsecret.yaml

rm /tmp/secret.yaml
git add . && git commit && git push
```

### Convención de nombres

```
Cluster:        {runtime}-{lab}                   → k3d-lab
App Argo CD:    {lab}-{runtime}-{component}        → observability-k3d-monitoring-stack
Namespace:      {lab}-{component}                  → observability-monitoring
Ingress host:   {service}.{lab}.local              → grafana.observability.local
```

---

## Conocimiento técnico acumulado

### Kubernetes
- Kustomize: base/overlays, restricciones de seguridad de paths
- Helm via Argo CD: chart externo + values desde Git (multi-source)
- StatefulSets con headless service
- NetworkAttachmentDefinition (Multus)
- PodDisruptionBudgets, admission webhooks

### Networking
- CNI: Flannel (default k3s), Cilium (eBPF), Multus (multi-NIC)
- BGP: eBGP entre pods, FRR, multihop, prefix exchange
- L7 Ingress: NGINX, Traefik, diferencia con API Gateway y Service Mesh
- k3d port mapping: solo funciona con `type: LoadBalancer`

### Observabilidad
- Prometheus: Probe CRDs, PrometheusRule, ServiceMonitor
- Grafana: admin secret, ingress, sub-path serving
- Blackbox Exporter: módulos ICMP, DNS, HTTP, TCP
- Correlación de eventos: restart → degradación → recovery en métricas

### GitOps / Argo CD
- App-of-apps pattern
- Automated sync con prune y selfHeal
- Multi-source applications (Helm chart + values desde repo)
- Server-Side Apply para CRDs grandes
- `--grpc-web` detrás de NGINX Ingress
- Sealed Secrets como práctica estándar de seguridad

### IaC y CI
- Terraform con OpenStack provider
- Gitea Actions con runners en Kubernetes
- Imagen custom de runner con múltiples toolchains
- Credenciales via SealedSecret montadas en pods

---

## Próximos labs planeados

| Lab | Runtime | Objetivo |
|-----|---------|---------|
| Observability profunda (Cilium/Hubble) | k3d | eBPF flows, Tetragon, correlación L3-L7 |
| Crossplane | k3s | Provisioning declarativo de infra cloud |
| Service Mesh (Istio/Linkerd) | kind o k3d | mTLS, traffic management, observabilidad L7 |
| Gateway API | k3d | Sucesor de Ingress, Cilium Gateway |
| Multi-cluster | kind + k3d | Federation, Argo CD multi-cluster |
