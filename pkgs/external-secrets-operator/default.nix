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
    sha256 = "1q2akgwi1r5xpc2gs7k2k96mfkdq2q9n4f4s3p37gbsm3dd5aspn";
  };

  vendorHash = null;

  subPackages = ["cmd/operator"];

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
