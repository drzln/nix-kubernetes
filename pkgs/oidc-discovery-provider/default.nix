{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "oidc-discovery-provider";
  version = "1.8.7";
  src = fetchFromGitHub {
    owner = "spiffe";
    repo = "spire";
    rev = "v${version}";
    sha256 = "1q2akgwi1r5xpc2gs7k2k96mfkdq2q9n4f4s3p37gbsm3dd5aspn";
  };
  vendorHash = "sha256-D6NNG//1rM7EIzawKdMA/8nloqMNAkF75YyFpHvxUkI=";
  subPackages = ["cmd/oidc-discovery-provider"];
  env.CGO_ENABLED = "0";
  ldflags = ["-s" "-w"];
  doCheck = false;
}
