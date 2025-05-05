{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "loki";
  version = "v2.9.3";

  src = fetchFromGitHub {
    owner = "grafana";
    repo = "loki";
    rev = version;
    sha256 = "sha256-9EUlznnZczgHXUy784830FvUS6OwaFf7FmUJGeWeXP0=";
  };

  vendorHash = null;

  subPackages = ["cmd/loki"];

  env.CGO_ENABLED = "0";

  ldflags = [
    "-s"
    "-w"
    "-X github.com/grafana/loki/pkg/util/build.Version=${version}"
  ];

  doCheck = false;

  meta = with lib; {
    description = "Grafana Loki – like Prometheus, but for logs";
    homepage = "https://grafana.com/oss/loki";
    license = licenses.asl20;
    maintainers = [maintainers.yourGithubHandle];
    platforms = platforms.linux;
  };
}
