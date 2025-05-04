{
  lib,
  buildGoModule,
  fetchFromGitHub,
  stdenv,
  pkgs,
  ...
}: let
  # Upstream Kubernetes tag you want
  version = "1.30.1";
in
  buildGoModule rec {
    pname = "kube-apiserver";
    inherit version;

    # ░░ Source ░░
    src = fetchFromGitHub {
      owner = "kubernetes";
      repo = "kubernetes";
      rev = "v${version}";
      # Replace this with the real SRI hash once you prefetched it
      sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };

    # ░░ Go module dependencies ░░
    #
    #  Put a fake hash the first time:
    #  vendorSha256 = lib.fakeHash;
    #  then run `nix build .#kube-apiserver` to get the real hash.
    vendorHash = null;

    # Build only the apiserver binary out of the Kubernetes monorepo
    subPackages = ["cmd/kube-apiserver"];

    # Disable CGO for a fully static binary (optional)
    CGO_ENABLED = 0;

    # Make the binary as small as possible
    ldflags = [
      "-s"
      "-w"
      "-X=k8s.io/component-base/version.gitVersion=v${version}"
      "-X=k8s.io/component-base/version.gitTreeState=clean"
    ];

    doCheck = false; # upstream tests are huge / need Docker+CGO

    meta = with lib; {
      description = "Kubernetes API server component";
      homepage = "https://github.com/kubernetes/kubernetes";
      license = licenses.asl20;
      platforms = platforms.linux;
      maintainers = [maintainers.yourGithubHandle];
    };
  }
