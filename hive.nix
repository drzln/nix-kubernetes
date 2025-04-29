{inputs, ...}:
inputs.colmena.lib.makeHive {
  meta.nixpkgs = import inputs.nixpkgs {system = "x86_64-linux";};

  defaults = {pkgs, ...}: {
    _module.args.inputs = inputs;
    system.stateVersion = "24.05";
  };

  # master-1 = {pkgs, ...}: {
  #   imports = [inputs.self.nixosModules.kubernetes];
  #   kubernetes = {
  #     enable = true;
  #     role = "master";
  #     # etcdPackage = pkgs.etcd;
  #     # containerdPackage = pkgs.containerd;
  #   };
  #   # networking.hostName = "master-1";
  #   # deployment.targetHost = "192.168.1.10";
  # };

  # master-2 = {pkgs, ...}: {
  #   imports = [./modules/kubernetes];
  #   kubernetes = {
  #     enable = true;
  #     role = "master";
  #     etcdPackage = pkgs.etcd;
  #     containerdPackage = pkgs.containerd;
  #   };
  #   networking.hostName = "master-2";
  #   deployment.targetHost = "192.168.1.20";
  # };

  # worker = {pkgs, ...}: {
  #   imports = [./modules/kubernetes];
  #   kubernetes = {
  #     enable = true;
  #     role = "worker";
  #     etcdPackage = pkgs.etcd;
  #     containerdPackage = pkgs.containerd;
  #     join.address = "192.168.1.10:6443";
  #     join.token = "abcdef.0123456789abcdef";
  #     join.caHash = "sha256:deadbeefcafebabe0123456789abcdef0123456789abcdef0123456789abcd";
  #   };
  #   networking.hostName = "worker";
  #   deployment.targetHost = "192.168.1.11";
  # };

  # single = {pkgs, ...}: {
  #   imports = [./modules/kubernetes];
  #   kubernetes = {
  #     enable = true;
  #     role = "single";
  #     etcdPackage = pkgs.etcd;
  #     containerdPackage = pkgs.containerd;
  #   };
  #   networking.hostName = "single";
  #   deployment.targetHost = "192.168.1.12";
  # };
}
