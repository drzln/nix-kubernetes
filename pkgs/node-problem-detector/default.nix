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
    sha256 = "sha256-nNi4YahrO4zwqwR90tIpQCAydGdQbfy5PXCifpP/T7Q=";
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
