# modules/kubernetes/services/kubelet/static-pods/cilium/manifest.nix
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.blackmatter.components.kubernetes.kubelet.static-pods.cilium;

  ciliumManifest = pkgs.writeText "cilium.yaml" (builtins.toJSON {
    apiVersion = "v1";
    kind = "Pod";
    metadata = {
      name = "cilium";
      namespace = "kube-system";
      labels = {
        k8s-app = "cilium";
      };
    };
    spec = {
      hostNetwork = true;
      hostPID = true;
      containers = [
        {
          name = "cilium-agent";
          image = "quay.io/cilium/cilium:v1.17.3";
          imagePullPolicy = "IfNotPresent";
          securityContext = {privileged = true;};
          command = ["cilium-agent"];
          args = [
            "--enable-ipv4=true"
            "--enable-ipv6=false"
            "--tunnel=vxlan"
            "--enable-node-port"
            "--kube-proxy-replacement=true"
            "--ipam=kubernetes"
          ];
          env = [
            {
              name = "KUBERNETES_SERVICE_HOST";
              value = "127.0.0.1";
            }
            {
              name = "KUBERNETES_SERVICE_PORT";
              value = "6443";
            }
          ];
          volumeMounts = [
            {
              name = "bpf";
              mountPath = "/sys/fs/bpf";
            }
            {
              name = "cni-bin";
              mountPath = "/opt/cni/bin";
            }
            {
              name = "cni-conf";
              mountPath = "/etc/cni/net.d";
            }
            {
              name = "lib-modules";
              mountPath = "/lib/modules";
              readOnly = true;
            }
            {
              name = "var-run";
              mountPath = "/var/run/cilium";
            }
          ];
        }
      ];
      volumes = [
        {
          name = "bpf";
          hostPath = {path = "/sys/fs/bpf";};
        }
        {
          name = "cni-bin";
          hostPath = {path = "/opt/cni/bin";};
        }
        {
          name = "cni-conf";
          hostPath = {path = "/etc/cni/net.d";};
        }
        {
          name = "lib-modules";
          hostPath = {path = "/lib/modules";};
        }
        {
          name = "var-run";
          hostPath = {path = "/var/run/cilium";};
        }
      ];
    };
  });
in {
  options.blackmatter.components.kubernetes.kubelet.static-pods.cilium.enable =
    lib.mkEnableOption "Enable Cilium static pod";

  config = lib.mkIf cfg.enable {
    manifest = "${ciliumManifest}";
  };
}
