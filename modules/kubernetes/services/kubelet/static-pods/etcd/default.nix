{
  pkgs,
  lib,
  ...
}: let
  pki = "/var/lib/blackmatter/certs";
  podLib = import ../pod-lib.nix {inherit pkgs lib;};
  image = "quay.io/coreos/etcd:v3.5.9";
  manifest =
    podLib.manifestFile "etcd.json"
    (podLib.mkEtcdPod pki image {});
in {inherit manifest;}
