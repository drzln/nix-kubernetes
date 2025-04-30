{
  lib,
  config,
  ...
}: let
  cfg = config.kubernetes;
  isWorker = cfg.role == "worker";
in {
  assertions = [
    {
      condition = elem cfg.role ["master" "worker" "single"];
      message = "kubernetes.role must be master / worker / single.";
    }
    # {
    #   condition =
    #     !isWorker
    #     || (cfg.join.address != "" && cfg.join.token != "" && cfg.join.caHash != "");
    #   message = "worker nodes need join.{address,token,caHash} set.";
    # }
  ];
}
