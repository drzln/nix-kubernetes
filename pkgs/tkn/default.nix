{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "tkn";
  version = "v0.38.0";
  src = fetchFromGitHub {
    owner = "tektoncd";
    repo = "cli";
    rev = version;
    sha256 = "1q2akgwi1r5xpc2gs7k2k96mfkdq2q9n4f4s3p37gbsm3dd5aspn";
  };
  vendorHash = null;
  subPackages = ["."];
  env.CGO_ENABLED = "0";
  ldflags = [
    "-s"
    "-w"
    "-X github.com/tektoncd/cli/pkg/version.Version=${version}"
  ];
  doCheck = false;
}
