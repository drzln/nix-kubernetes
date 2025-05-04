# pkgs/coredns/default.nix
{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "coredns";
  version = "1.11.1"; # or the latest stable

  src = fetchFromGitHub {
    owner = "coredns";
    repo = "coredns";
    rev = "v${version}";
    sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Replace after first run
  };

  vendorHash = null; # Let Nix print it the first time

  subPackages = ["."]; # root of repo builds the coredns binary

  ldflags = [
    "-s"
    "-w"
  ];

  doCheck = false;

  meta = with lib; {
    description = "CoreDNS is a DNS server that chains plugins and serves as the cluster DNS in Kubernetes.";
    homepage = "https://coredns.io";
    license = licenses.asl20;
    maintainers = with maintainers; []; # Add yourself
    platforms = platforms.linux;
  };
}
