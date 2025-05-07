# 🧱 Kubernetes Internal Networking and Identity Standards

These are the de facto standards used across Kubernetes distributions like `kubeadm`, GKE, k3s, and in your own `nix-kubernetes` stack.

---

## 🧭 Cluster DNS and IP Layout

| Component          | Standard Value                         | Purpose                                     |
| ------------------ | -------------------------------------- | ------------------------------------------- |
| **Service CIDR**   | `10.96.0.0/12`                         | Default Kubernetes service IP range         |
| **CoreDNS**        | `10.96.0.10`                           | Cluster DNS IP                              |
| **API Server IP**  | `10.96.0.1`                            | Often reserved as the ClusterIP of API      |
| **Cluster Domain** | `cluster.local`                        | Internal DNS root for all services/pods     |
| **Pod CIDR**       | `10.244.0.0/16`                        | Allocated by CNI (e.g., Cilium)             |
| **Node name**      | `single.cluster.local` (example)       | Matches SPIFFE IDs and DNS naming           |
| **Kube DNS**       | `kubernetes.default.svc.cluster.local` | Canonical DNS for the Kubernetes API server |

---

## 🔐 TLS Certificate Subject Alternative Names (SANs)

For internal components, SANs should include:

```ini
DNS.1 = localhost
DNS.2 = single
DNS.3 = single.cluster.local
DNS.4 = etcd.single.cluster.local
DNS.5 = kubernetes
DNS.6 = kubernetes.default
DNS.7 = kubernetes.default.svc
DNS.8 = kubernetes.default.svc.cluster.local
IP.1  = 127.0.0.1
IP.2  = 10.96.0.1   # kube-apiserver ClusterIP
IP.3  = 10.96.0.10  # CoreDNS
```
