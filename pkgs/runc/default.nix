# pkgs/runc/default.nix
{
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "runc";
  version = "1.3.0";
  src = fetchFromGitHub {
    owner = "opencontainers";
    repo = "runc";
    rev = "v${version}";
    hash = "sha256-nTVjgNMnB6775ubzK7ezOxR5Z0z5PBxx88CxtbxGxrY=";
  };
  vendorHash = null;
  subPackages = ["."];
  env.CGO_ENABLED = "0";
  ldflags = ["-s" "-w" "-X" "main.version=${version}"];
  doCheck = false;
}
