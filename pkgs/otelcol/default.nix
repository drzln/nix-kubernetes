{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "otelcol-contrib";
  version = "v0.101.0";
  src = fetchFromGitHub {
    owner = "open-telemetry";
    repo = "opentelemetry-collector-contrib";
    rev = version;
    sha256 = "sha256-WdMQnAYAdyvS0uyRzvLnhi1HeoWqmUQSIq6MdcP7NfY=";
  };
  vendorHash = "sha256-hyD+SwR3EnDkHFmN1KGe8rEBgRp68Yyxs0SftQJVkcU=";
  subPackages = ["./cmd/golden"];
  env.CGO_ENABLED = "0";
  ldflags = [
    "-s"
    "-w"
    "-X go.opentelemetry.io/collector/contrib/internal/version.GitVersion=${version}"
  ];
  doCheck = false;
}
