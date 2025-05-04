# pkgs/containerd/default.nix
{
  lib,
  buildGoModule,
  fetchFromGitHub,
  stdenv,
  pkgs,
  ...
}: let
  version = "1.7.15"; # <-- bump with ./update.sh
  rev = "v${version}";
in
  buildGoModule rec {
    pname = "containerd";
    inherit version;

    src = fetchFromGitHub {
      owner = "containerd";
      repo = "containerd";
      rev = rev;
      sha256 = "sha256-lk0IJ5uXeiqgR/hEPZojKn6z0niCsaBYijjkE4mTJqk=";
    };

    # buildGoModule does the mod download; pin its hash
    vendorHash = "sha256-7Q0U8RorMBYGH/J3ex72tzIezHY0hKkEMEP7zzfO0y8=";

    subPackages = [
      "./cmd/containerd"
      "./cmd/ctr"
      "./cmd/containerd-shim-runc-v1"
      "./cmd/containerd-shim-runc-v2"
    ];

    ldflags = ["-s" "-w"];
    doCheck = false; # upstream tests require root/network

    meta = with lib; {
      description = "OCI-compatible container runtime";
      homepage = "https://containerd.io";
      license = licenses.asl20;
      maintainers = [maintainers.yourGithubHandle];
      platforms = platforms.linux;
    };
  }
