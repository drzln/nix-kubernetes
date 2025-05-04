{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "spire-agent";
  version = "1.8.7";

  src = fetchFromGitHub {
    owner = "spiffe";
    repo = "spire";
    rev = "v${version}";
    sha256 = "sha256-D6NNG//1rM7EIzawKdMA/8nloqMNAkF75YyFpHvxUkI=";
  };

  vendorHash = "sha256-bSQitqXTY1LMnpGkXAmDiDsMd0xZHrcr/Ms1F6avBKM=";

  subPackages = ["cmd/spire-agent"];

  env.CGO_ENABLED = "0";

  ldflags = [
    "-s"
    "-w"
  ];

  doCheck = false;

  meta = with lib; {
    description = "SPIRE agent – fetches and delivers SPIFFE SVIDs to workloads";
    homepage = "https://spiffe.io";
    license = licenses.asl20;
    maintainers = [maintainers.yourGithubHandle];
    platforms = platforms.linux;
  };
}
