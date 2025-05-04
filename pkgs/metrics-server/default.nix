{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "metrics-server";
  version = "0.7.0";
  src = fetchFromGitHub {
    owner = "kubernetes-sigs";
    repo = "metrics-server";
    rev = "v${version}";
    sha256 = "sha256-X1l5czZ4iFlEyKVQjT4Ai0fI3JQusLQqENBoZJTxYpo=";
  };
  vendorHash = null;
  subPackages = ["."]; # main.go is at the repo root
  ldflags = [
    "-s"
    "-w"
  ];
  doCheck = false;
}
