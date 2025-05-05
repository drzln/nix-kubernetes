# pkgs/kubectl/default.nix
{
  buildGoModule,
  fetchFromGitHub,
  ...
}: let
  version = "1.30.1";
in
  buildGoModule rec {
    pname = "kubectl";
    inherit version;
    src = fetchFromGitHub {
      owner = "kubernetes";
      repo = "kubernetes";
      rev = "v${version}";
      sha256 = "sha256-nTVjgNMnB6775ubzK7ezOxR5Z0z5PBxx88CxtbxGxrY=";
    };
    vendorHash = null;
    subPackages = ["cmd/kubectl"];
    env.CGO_ENABLED = "0";
    ldflags = [
      "-s"
      "-w"
      "-X=k8s.io/component-base/version.gitVersion=v${version}"
      "-X=k8s.io/component-base/version.gitTreeState=clean"
    ];
    doCheck = false;
  }
