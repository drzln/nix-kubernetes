# pkgs/node-problem-detector/default.nix
{
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "node-problem-detector";
  version = "0.8.20";
  src = fetchFromGitHub {
    owner = "kubernetes";
    repo = "node-problem-detector";
    rev = "v${version}";
    sha256 = "sha256-nNi4YahrO4zwqwR90tIpQCAydGdQbfy5PXCifpP/T7Q=";
  };
  vendorHash = null;
  subPackages = ["cmd/nodeproblemdetector"];
  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];
  doCheck = false;
}
