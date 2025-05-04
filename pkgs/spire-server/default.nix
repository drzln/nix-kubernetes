{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "spire-server";
  version = "1.8.7";
  src = fetchFromGitHub {
    owner = "spiffe";
    repo = "spire";
    rev = "v${version}";
    sha256 = "sha256-D6NNG//1rM7EIzawKdMA/8nloqMNAkF75YyFpHvxUkI=";
  };
  vendorHash = "sha256-D6NNG//1rM7EIzawKdMA/8nloqMNAkF75YyFpHvxUkI=";
  subPackages = ["cmd/spire-server"];
  env.CGO_ENABLED = "0";
  ldflags = ["-s" "-w"];
  doCheck = false;
}
