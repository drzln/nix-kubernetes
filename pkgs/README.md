```mermaid
flowchart LR
    A([containerd<br>(or CRI-O)]) --> B([etcd])
    B --> C([cilium])
    B --> CP_APISERVER([kube-apiserver])
    B --> CP_SCHEDULER([kube-scheduler])
    B --> CP_CONTROLLER([kube-controller-manager])

    C --> KUBELET([kubelet])
    KUBELET --> KPROXY([kube-proxy?])

    subgraph "Optional Higher Layers"
        I1[Ingress (e.g. Contour/Envoy)] -->|listens on Services| CP_APISERVER
        MESH([Service Mesh <br/>(eBPF / Ambient)]) --> KUBELET
        SERVERLESS([Knative/OpenFaaS]) --> CP_APISERVER
        O11[Observability <br/>(Prometheus, Pixie, etc.)] --> KUBELET
        SEC[Security <br/>(Falco, Kyverno, Tetragon)] --> KUBELET
    end

    subgraph "Bare-Metal?"
        CCLD([cloud-controller-manager?])
    end

    CP_APISERVER --> CCLD
```

**Explanation**:

- **containerd** (or **CRI-O**) has no major build-time dependencies—just the Go toolchain.
- **etcd** also just needs the Go environment; it’s independent of the Kubernetes code.
- **cilium** depends on having a (built) eBPF-capable system, but not on the K8s components.
- **kubelet** typically interacts with containerd and cilium at runtime, but it’s built from the main `kubernetes/kubernetes` repo’s `cmd/kubelet`.
- The **control plane** (API server, scheduler, controller-manager) depends on etcd at runtime (though build-time is typically just the K8s repo).
- Higher-level components like ingress, service mesh, serverless, observability, and security layers all build on top of a functioning cluster but are typically separate derivations in your build system.
- **cloud-controller-manager** is optional if you’re not on a public cloud. On bare metal, you usually skip it or use other solutions (like MetalLB for load balancing).

Place the above code snippet in your `README.md`, and GitHub will render the Mermaid diagram if it has Mermaid support (which it does on many repositories now). Otherwise, you can use a Mermaid-friendly Markdown viewer or an external service to visualize it.
