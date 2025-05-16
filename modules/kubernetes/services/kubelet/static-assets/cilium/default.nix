# modules/kubernetes/services/kubelet/static-assets/cilium/default.nix
{pkgs, ...}: let
  manifest = pkgs.writeText "cilium.yaml" ''
    apiVersion: v1
    kind: Pod
    metadata:
      name: cilium
      namespace: kube-system
      labels:
        k8s-app: cilium
    spec:
      hostNetwork: true
      priorityClassName: system-node-critical
      containers:
        - name: cilium-agent
          image: quay.io/cilium/cilium:v1.17.3
          command:
            - cilium-agent
          args:
            - --debug=true
            - --enable-ipv4
            - --enable-ipv6=false
            - --kube-proxy-replacement=strict
          securityContext:
            sysctls:
              - name: net.ipv4.conf.all.forwarding
                value: "1"
              - name: net.ipv4.conf.default.rp_filter
                value: "0"
              - name: net.ipv4.conf.all.send_redirects
                value: "0"
            capabilities:
              add:
                - NET_ADMIN
                - SYS_MODULE
                - SYS_RESOURCE
                - SYS_ADMIN
          volumeMounts:
            - name: bpf-maps
              mountPath: /sys/fs/bpf
            - name: cilium-run
              mountPath: /var/run/cilium
      volumes:
        - name: bpf-maps
          hostPath:
            path: /sys/fs/bpf
            type: DirectoryOrCreate
        - name: cilium-run
          hostPath:
            path: /var/run/cilium
            type: DirectoryOrCreate
  '';
in {
  config.manifest = manifest;
}
