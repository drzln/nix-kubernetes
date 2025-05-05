{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "tempo";
  version = "2.4.1";

  src = fetchFromGitHub {
    owner = "grafana";
    repo = "tempo";
    rev = "v${version}";
    sha256 = "1q2akgwi1r5xpc2gs7k2k96mfkdq2q9n4f4s3p37gbsm3dd5aspn";
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
