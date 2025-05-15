# modules/kubernetes/services/kubelet/certs.nix
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.blackmatter.components.kubernetes.kubelet.certs;
  kubeletCertGen = pkgs.stdenv.mkDerivation {
    pname = "kubelet-cert-gen";
    version = "1.0";
    src = ./generate-certs.sh;
    dontUnpack = true;
    nativeBuildInputs = with pkgs; [makeWrapper];
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/generate-certs.sh
      chmod +x $out/bin/generate-certs.sh
      patchShebangs $out/bin
      wrapProgram $out/bin/generate-certs.sh \
        --prefix PATH : ${pkgs.lib.makeBinPath [
        pkgs.bash
        pkgs.coreutils
        pkgs.iproute2
        pkgs.gawk
        pkgs.gnugrep
        pkgs.openssl
        pkgs.inetutils
      ]}
    '';
  };
in {
  options.blackmatter.components.kubernetes.kubelet.certs = {
    enable = lib.mkEnableOption "certificate placement";
  };
  config = lib.mkIf cfg.enable {
    systemd.services.kubelet-generate-certs = {
      description = "Generate TLS certs and configs for kubelet";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${kubeletCertGen}/bin/generate-certs.sh";
      };
    };
  };
}
