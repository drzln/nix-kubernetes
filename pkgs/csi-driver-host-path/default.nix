{
  lib,
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
    sha256 = "1q2akgwi1r5xpc2gs7k2k96mfkdq2q9n4f4s3p37gbsm3dd5aspn";
  };
  vendorHash = null;
  subPackages = ["cmd/hostpathplugin"]; # Entry point is here
  env.CGO_ENABLED = "0";
  ldflags = [
    "-s"
    "-w"
  ];
  doCheck = false;
}
