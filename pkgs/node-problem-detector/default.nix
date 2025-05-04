{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "node-problem-detector";
  version = "0.8.13";

  src = fetchFromGitHub {
    owner = "kubernetes";
    repo = "node-problem-detector";
    rev = "v${version}";
    sha256 = "1q2akgwi1r5xpc2gs7k2k96mfkdq2q9n4f4s3p37gbsm3dd5aspn";
  };

  vendorHash = null;

  subPackages = ["."]; # root is correct for main.go

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  doCheck = false;
}
