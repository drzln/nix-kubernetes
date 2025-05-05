{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "stern";
  version = "v1.29.0";

  src = fetchFromGitHub {
    owner = "stern";
    repo = "stern";
    rev = version;
    sha256 = "sha256-8Tvhul7GwVbRJqJenbYID8OY5zGzFhIormUwEtLE0Lw=";
  };

  vendorHash = null;

  subPackages = ["."];

  env.CGO_ENABLED = "0";

  ldflags = [
    "-s"
    "-w"
    "-X github.com/stern/stern/cmd.version=${version}"
  ];

  doCheck = false;

  meta = with lib; {
    description = "Stern - tail multiple Kubernetes pods and containers logs";
    homepage = "https://github.com/stern/stern";
    license = licenses.asl20;
    maintainers = [maintainers.yourGithubHandle];
    platforms = platforms.linux;
  };
}
