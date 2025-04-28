{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.kubernetes;
  pkgsK8s =
    if cfg.overlay != null
    then
      import config.nixpkgs.path {
        inherit (config.nixpkgs) config;
        overlays = [cfg.overlay];
      }
    else pkgs;

  require = name:
    if pkgsK8s ? ${name}
    then pkgsK8s.${name}
    else throw "Required package ‘${name}’ missing from overlay";
in {
  _module.args = {
    inherit pkgsK8s require;
  };
}
