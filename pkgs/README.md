┌─────────────────────────┐
│ Linux Kernel & Tools    │  (outside scope; we assume a working system)
└─────────────────────────┘

        (lowest-level userland)

      ┌─────────────────────┐
      │ containerd or CRI-O │
      │ (runtime)           │
      └─────────────────────┘
               ▼
      ┌─────────────────────┐
      │ etcd                │
      │ (store)             │
      └─────────────────────┘
               ▼
      ┌─────────────────────┐
      │ cilium (CNI)        │
      │ or other eBPF plugin│
      └─────────────────────┘
               ▼
┌────────────────────────┐   ┌─────────────────────────┐
│ kubelet                │   │ apiserver, scheduler,   │
│ (node agent)           │   │ controller-manager      │
└────────────────────────┘   └─────────────────────────┘
               ▼                        ▼
            (kube-proxy optional)    (cloud-ctrl optional)
               ▼                        ▼
                 ┌───────────────────────────────────────┐
                 │ Additional stacks (ingress, mesh,     │
                 │ serverless, observability, security)  │
                 └───────────────────────────────────────┘

