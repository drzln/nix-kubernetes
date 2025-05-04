# pkgs/cilium-cli-node/default.nix  (fixed)
{
  lib,
  buildGoModule,
  fetchFromGitHub,
  ...
}: let
  version = "1.17.3";
in
  buildGoModule {
    pname = "cilium-nodecli";
    inherit version;

    src = fetchFromGitHub {
      owner = "cilium";
      repo = "cilium";
      rev = "v${version}";
      sha256 = "sha256-HcKRenRILpJCzJZbOYzrQrLlEeif9J9jJDKFzA6NtXc=";
    };

    vendorHash = null;

    # ← correct path
    subPackages = ["cmd/cilium"];

    env.CGO_ENABLED = "0";
    ldflags = [
      "-s"
      "-w"
      "-X github.com/cilium/cilium/pkg/version.Version=v${version}"
    ];

    # optional: keep binary name plain “cilium”
    postInstall = ''mv "$out/bin/cilium-nodecli" "$out/bin/cilium" || true'';

    doCheck = false;

    meta = with lib; {
      description = "On-node Cilium debug CLI (talks to local agent)";
      homepage = "https://github.com/cilium/cilium";
      license = licenses.asl20;
      maintainers = [maintainers.yourGithubHandle];
      platforms = platforms.linux;
    };
  }
