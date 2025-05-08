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
  vendorHash = "sha256-QK9F2tp8l7+KT9B2wyu1W9n6bt5ioei5dz8mD5vx9q0=";
  subPackages = ["."];
  CGO_ENABLED = "0"; # static binary, no cgo
  ldflags = ["-s" "-w" "-X" "main.version=${version}"];
  doCheck = false; # upstream tests need root / network
}
