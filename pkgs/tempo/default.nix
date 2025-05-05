{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "tempo";
  version = "2.7.2";

  src = fetchFromGitHub {
    owner = "grafana";
    repo = "tempo";
    rev = "v${version}";
    sha256 = "sha256-HpVusZejrOV4cuInc4+/PY0JAHJX2Mf4zg6OtQtlhNc=";
  };

  vendorHash = null;

  subPackages = ["cmd/tempo"];

  env.CGO_ENABLED = "0";

  ldflags = [
    "-s"
    "-w"
    "-X github.com/grafana/tempo/pkg/util/build.Version=${version}"
  ];

  doCheck = false;

  meta = with lib; {
    description = "Grafana Tempo – trace backend that stores OTLP spans without indexing";
    homepage = "https://grafana.com/oss/tempo";
    license = licenses.asl20;
    platforms = platforms.linux;
    maintainers = [maintainers.yourGithubHandle];
  };
}
