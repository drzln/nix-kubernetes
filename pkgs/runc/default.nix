# pkgs/runc/default.nix
{
  buildGoModule,
  fetchFromGitHub,
  ...
}: let
  version = "1.1.12";
in
  buildGoModule {
    pname = "runc";
    inherit version;
    src = fetchFromGitHub {
      owner = "opencontainers";
      repo = "runc";
      rev = "v${version}";
      sha256 = "sha256-nTVjgNMnB6775ubzK7ezOxR5Z0z5PBxx88CxtbxGxrY=";
    };
    vendorHash = null;
    subPackages = ["."];
    env.CGO_ENABLED = "0";
    ldflags = [
      "-s"
      "-w"
      "-X main.gitCommit=${version}"
      "-X main.version=${version}"
    ];
    doCheck = false;
  }
