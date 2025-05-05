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
  vendorHash = "sha256-RLcF7KfKtkwB+nWzaQb8Va9pau+TS2uE9AmJ0aFNsik=";
  subPackages = ["."];
  env.CGO_ENABLED = "0";
  ldflags = [
    "-s"
    "-w"
    "-X github.com/stern/stern/cmd.version=${version}"
  ];
  doCheck = false;
}
