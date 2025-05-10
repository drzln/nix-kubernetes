# modules/kubernetes/services/kubelet/pod-lib.nix
{...}: let
  mkStaticPodVolumes = pki: extra:
    [
      {
        name = "pki";
        hostPath.path = pki;
        hostPath.type = "Directory";
      }
      {
        name = "etcd-data";
        hostPath.path = "/var/run/etcd";
        hostPath.type = "DirectoryOrCreate";
      }
    ]
    ++ extra;

  mkStaticPodVolumeMounts = pki: extra:
    [
      {
        name = "pki";
        mountPath = pki;
        readOnly = true;
      }
      {
        name = "etcd-data";
        mountPath = "/var/run/etcd";
      }
    ]
    ++ extra;
  mkPod = pki: name: args: image: extra: {
    apiVersion = "v1";
    kind = "Pod";
    metadata.name = name;
    spec = {
      hostNetwork = true;
      priorityClassName = "system-cluster-critical";
      volumes = mkStaticPodVolumes pki (extra.volumes or []);
      containers = [
        {
          name = name;
          image = image;
          command = args;
          volumeMounts = mkStaticPodVolumeMounts pki (extra.volumeMounts or []);
        }
      ];
    };
  };
  manifestFile = filename: pod: {
    environment.etc."kubernetes/manifests/${filename}".text = builtins.toJSON pod;
  };
in {
  inherit mkPod manifestFile;
}
