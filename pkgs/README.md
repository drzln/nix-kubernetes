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
