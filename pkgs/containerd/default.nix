# pkgs/containerd/default.nix
{
  buildGoModule,
  fetchFromGitHub,
  ...
}: let
  version = "1.7.15";
  rev = "v${version}";
in
  buildGoModule {
    pname = "containerd";
    inherit version;

    src = fetchFromGitHub {
      owner = "containerd";
      repo = "containerd";
      rev = rev;
      sha256 = "sha256-qLrPLGxsUmgEscrhyl+1rJ0k7c9ibKnpMpsJPD4xDZU=";
    };
    vendorHash = null;
    subPackages = [
      "./cmd/containerd"
      "./cmd/ctr"
      "./cmd/containerd-shim-runc-v1"
      "./cmd/containerd-shim-runc-v2"
    ];
    ldflags = ["-s" "-w"];
    doCheck = false;
  }
