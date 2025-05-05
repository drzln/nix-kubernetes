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
    sha256 = "sha256-BRZxeTFw4v4LLXPPzIzcjtR/RTckpolGGcB6jyq+ZOA=";
  };
  vendorHash = "sha256-BRZxeTFw4v4LLXPPzIzcjtR/RTckpolGGcB6jyq+ZOA=";
  subPackages = ["cmd/otelcol"];
  env.CGO_ENABLED = "0";
  ldflags = [
    "-s"
    "-w"
    "-X go.opentelemetry.io/collector/internal/version.GitVersion=${version}"
  ];
  doCheck = false;
}
