# pkgs/cilium-agent/default.nix
{
  buildGoModule,
  fetchFromGitHub,
  ...
}: let
  version = "1.17.3";
in
  buildGoModule {
    pname = "cilium-agent";
    inherit version;
    src = fetchFromGitHub {
      owner = "cilium";
      repo = "cilium";
      rev = "v${version}";
      sha256 = "sha256-HcKRenRILpJCzJZbOYzrQrLlEeif9J9jJDKFzA6NtXc=";
    };
    vendorHash = null;
    subPackages = ["daemon"];
    env.CGO_ENABLED = "0";
    ldflags = [
      "-s"
      "-w"
      "-X github.com/cilium/cilium/pkg/version.Version=v${version}"
    ];
    doCheck = false;
  }
