# modules/kubernetes/crictl.nix
{pkgs, ...}: {
  config = {
    environment.etc."crictl.yaml".text = ''
      runtime-endpoint: unix:///run/containerd/containerd.sock
      image-endpoint: unix:///run/containerd/containerd.sock
      timeout: 10
      debug: false
    '';

    environment.systemPackages = [pkgs.cri-tools];
  };
}
