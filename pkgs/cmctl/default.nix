{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "cmctl";
  version = "v2.2.0";
  src = fetchFromGitHub {
    owner = "cert-manager";
    repo = "cmctl";
    rev = version;
    sha256 = "sha256-REPLACE_WITH_ACTUAL_HASH";
  };
  vendorHash = null;
  subPackages = ["."];
  ldflags = [
    "-s"
    "-w"
    "-X github.com/cert-manager/cmctl/pkg/build.name=cmctl"
  ];
  doCheck = false;
}
