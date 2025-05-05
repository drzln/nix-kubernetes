{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "kubeseal";
  version = "v0.29.0";
  src = fetchFromGitHub {
    owner = "bitnami-labs";
    repo = "sealed-secrets";
    rev = version;
    sha256 = "1q2akgwi1r5xpc2gs7k2k96mfkdq2q9n4f4s3p37gbsm3dd5aspn";
  };
  vendorHash = null;
  subPackages = ["cmd/kubeseal"];
  env.CGO_ENABLED = "0";
  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];
  doCheck = false;
}
