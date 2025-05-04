{
  lib,
  buildGoModule,
  fetchFromGitHub,
  stdenv,
  pkgs,
  ...
}: let
  # Bump when you want a new Kubernetes release
  version = "1.30.1";
in
  buildGoModule rec {
    pname = "kube-scheduler";
    inherit version;

    # ░░ Source tarball ░░
    src = fetchFromGitHub {
      owner = "kubernetes";
      repo = "kubernetes";
      rev = "v${version}";
      sha256 = "sha256-REPLACE_ME_AFTER_PREFETCH";
    };

    # ░░ Go module vendor hash ░░
    # Keep it null (or lib.fakeHash) on first commit; build once,
    # copy the printed hash back here, rebuild, commit.
    vendorHash = null;

    # Build only the scheduler binary from the monorepo
    subPackages = ["cmd/kube-scheduler"];

    # Produce a small, static binary
    env.CGO_ENABLED = "0";
    ldflags = [
      "-s"
      "-w"
      "-X=k8s.io/component-base/version.gitVersion=v${version}"
      "-X=k8s.io/component-base/version.gitTreeState=clean"
    ];

    doCheck = false;

    meta = with lib; {
      description = "Kubernetes scheduler component";
      homepage = "https://github.com/kubernetes/kubernetes";
      license = licenses.asl20;
      platforms = platforms.linux;
      maintainers = [maintainers.yourGithubHandle];
    };
  }
