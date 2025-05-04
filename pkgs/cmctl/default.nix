{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "cmctl";
  version = "v1.14.4";
  src = fetchFromGitHub {
    owner = "cert-manager";
    repo = "cert-manager";
    rev = version;
    sha256 = "sha256-iUXN+8ueCxGsFnwhC2WjrQQSXV7TGUR80xaKqjxcC6o=";
  };
  vendorHash = null;
  subPackages = ["cmd/cmctl"];
  env.CGO_ENABLED = "0";
  ldflags = [
    "-s"
    "-w"
    "-X github.com/cert-manager/cert-manager/pkg/util.AppVersion=${version}"
  ];
  doCheck = false;
}
