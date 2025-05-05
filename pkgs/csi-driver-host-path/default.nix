# pkgs/csi-driver-host-path/default.nix
{
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "csi-driver-host-path";
  version = "v1.10.0";
  src = fetchFromGitHub {
    owner = "kubernetes-csi";
    repo = "csi-driver-host-path";
    rev = version;
    sha256 = "sha256-6hyJkPcAQzazobMxGJ/p5OQefvijMVnIyQEmfZWvtMI=";
  };
  vendorHash = null;
  subPackages = ["cmd/hostpathplugin"];
  env.CGO_ENABLED = "0";
  ldflags = [
    "-s"
    "-w"
  ];
  doCheck = false;
}
