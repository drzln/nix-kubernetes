# pkgs/runc/default.nix
{
  buildGoModule,
  fetchFromGitHub,
  ...
}: let
  version = "1.3.0";
in
  buildGoModule {
    pname = "runc";
    inherit version;
    src = fetchFromGitHub {
      owner = "opencontainers";
      repo = "runc";
      rev = "v${version}";
      sha256 = "sha256-nTVjgNMnB6775ubzK7ezOxR5Z0z5PBxx88CxtbxGxrY=";
      # hash = "sha256-oXoDio3l23Z6UyAhb9oDMo1O4TLBbFyLh9sRWXnfLVY=";
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
