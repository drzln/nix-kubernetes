{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "woodpecker-cli";
  version = "v3.5.2";

  src = fetchFromGitHub {
    owner = "woodpecker-ci";
    repo = "woodpecker";
    rev = version;
    sha256 = "sha256-XV9Cz48mMBLngsz9ss9se7BZ9bOhIxbbOQNFGrRIsOg=";
  };

  vendorHash = "sha256-hwWKfMjLuz3oKCU6dCNhIlPYMy1AU1uOvRCLwJths+o=";

  subPackages = ["cmd/cli"];

  env.CGO_ENABLED = "0";

  ldflags = [
    "-s"
    "-w"
    "-X github.com/woodpecker-ci/woodpecker/version.Version=${version}"
  ];

  doCheck = false;

  meta = with lib; {
    description = "Woodpecker CLI – manage pipelines, users, secrets from terminal";
    homepage = "https://woodpecker-ci.org";
    license = licenses.asl20;
    maintainers = [];
    platforms = platforms.linux;
  };
}
