{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "otelcol";
  version = "v0.101.0";
  src = fetchFromGitHub {
    owner = "open-telemetry";
    repo = "opentelemetry-collector";
    rev = version;
    sha256 = "1q2akgwi1r5xpc2gs7k2k96mfkdq2q9n4f4s3p37gbsm3dd5aspn";
  };
  vendorHash = null;
  subPackages = ["cmd/otelcol"];
  env.CGO_ENABLED = "0";
  ldflags = [
    "-s"
    "-w"
    "-X go.opentelemetry.io/collector/internal/version.GitVersion=${version}"
  ];
  doCheck = false;
}
