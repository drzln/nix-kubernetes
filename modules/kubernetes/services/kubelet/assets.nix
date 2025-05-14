# modules/kubernetes/services/kubelet/assets.nix
{
  pkgs,
  lib,
  ...
}: let
  # Define the wrapped script as a package derivation
  kubeletCertGen = pkgs.stdenv.mkDerivation {
    pname = "kubelet-cert-gen";
    version = "1.0";

    src = ./generate-certs.sh;

    dontUnpack = true;

    nativeBuildInputs = [pkgs.makeWrapper];

    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/generate-certs.sh
      chmod +x $out/bin/generate-certs.sh
    '';

    postInstall = ''
      wrapProgram $out/bin/generate-certs.sh \
        --prefix PATH : ${lib.makeBinPath [
        pkgs.bash
        pkgs.openssl
        pkgs.iproute2
        pkgs.coreutils
        pkgs.gawk
        pkgs.gnugrep
      ]}
    '';
  };
in {
  # Optionally make the raw script visible in /etc if needed
  # environment.etc."kubernetes/scripts/generate-certs.sh".source = ./generate-certs.sh;

  systemd.services.kubelet-generate-certs = {
    description = "Generate TLS certs and configs for kubelet";
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${kubeletCertGen}/bin/generate-certs.sh";
    };
  };
}
