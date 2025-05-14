# modules/kubernetes/services/kubelet/certs.nix
{pkgs, ...}: let
  kubeletCertGen = pkgs.stdenv.mkDerivation {
    pname = "kubelet-cert-gen";
    version = "1.0";
    src = ./generate-certs.sh;
    dontUnpack = true;
    nativeBuildInputs = [pkgs.makeWrapper pkgs.patchShebangs];
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/generate-certs.sh
      chmod +x $out/bin/generate-certs.sh
      patchShebangs $out/bin
    '';
    postInstall = ''
      wrapProgram $out/bin/generate-certs.sh \
        --prefix PATH : ${pkgs.lib.makeBinPath [
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
  systemd.services.kubelet-generate-certs = {
    description = "Generate TLS certs and configs for kubelet";
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${kubeletCertGen}/bin/generate-certs.sh";
    };
  };
}
