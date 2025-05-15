{
  pkgs,
  lib,
  ...
}: let
  pki = "/var/lib/blackmatter/certs";
  scr = "/run/secrets/kubernetes";
  podLib = import ../pod-lib.nix {inherit pkgs lib;};
  image = "registry.k8s.io/kube-controller-manager:v1.30.1";
  manifest =
    podLib.manifestFile "kube-controller-manager.json"
    (podLib.mkControllerManagerPod pki scr image {
      volumes = [
        {
          name = "kubeconfig";
          hostPath = {
            path = "${scr}/configs/controller-manager/kubeconfig";
            type = "File";
          };
        }
      ];
      volumeMounts = [
        {
          name = "kubeconfig";
          mountPath = "${scr}/configs/controller-manager/kubeconfig";
          readOnly = true;
        }
      ];
    });
in {inherit manifest;}
