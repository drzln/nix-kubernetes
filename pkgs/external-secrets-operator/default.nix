{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "external-secrets-operator";
  version = "v0.9.19";

  src = fetchFromGitHub {
    owner = "external-secrets";
    repo = "external-secrets";
    rev = version;
    sha256 = "sha256-YnoM/q1ilyFhhJqvI1I7GKTFHuL9JHOojQKPCCs3HvE=";
  };

  vendorHash = "sha256-7W27ZbiHsz1nSJROeYRvuDc6Tk0Br7YszwpOPcNktJQ=";

  subPackages = ["cmd/controller"];

  env.CGO_ENABLED = "0";

  ldflags = [
    "-s"
    "-w"
    "-X github.com/external-secrets/external-secrets/pkg/version.Version=${version}"
  ];

  doCheck = false;

  meta = with lib; {
    description = "External Secrets Operator – sync secrets from cloud backends into Kubernetes";
    homepage = "https://external-secrets.io";
    license = licenses.asl20;
    platforms = platforms.linux;
    maintainers = [maintainers.yourGithubHandle];
  };
}
