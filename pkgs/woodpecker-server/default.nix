{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "woodpecker-server";
  version = "v2.3.1";

  src = fetchFromGitHub {
    owner = "woodpecker-ci";
    repo = "woodpecker";
    rev = version;
    sha256 = "sha256-REPLACE_AFTER_PREFETCH";
  };

  vendorHash = null;

  subPackages = ["cmd/server"];

  env.CGO_ENABLED = "0";

  ldflags = [
    "-s"
    "-w"
    "-X github.com/woodpecker-ci/woodpecker/version.Version=${version}"
  ];

  doCheck = false;

  meta = with lib; {
    description = "Woodpecker CI server – lightweight CI/CD engine";
    homepage = "https://woodpecker-ci.org";
    license = licenses.asl20;
    maintainers = [maintainers.yourGithubHandle];
    platforms = platforms.linux;
  };
}
