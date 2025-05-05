{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "otelcol";
  version = "v0.125.0";
  src = fetchFromGitHub {
    owner = "open-telemetry";
    repo = "opentelemetry-collector";
    rev = version;
    sha256 = "sha256-BRZxeTFw4v4LLXPPzIzcjtR/RTckpolGGcB6jyq+ZOA=";
  };
  vendorHash = "sha256-4C5Yz0LDvX0WiAVoPqBfimxc7IXupN8q4XMPwKjlvUA=";
  subPackages = ["cmd/otelcorecol"];
  env.CGO_ENABLED = "0";
  ldflags = [
    "-s"
    "-w"
    "-X go.opentelemetry.io/collector/internal/version.GitVersion=${version}"
  ];
  doCheck = false;
}
