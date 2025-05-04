# pkgs/cilium-dbg/default.nix
{
  lib,
  buildGoModule,
  fetchFromGitHub,
  ...
}: let
  version = "1.17.3"; # same tag as the agent
in
  buildGoModule {
    pname = "cilium-dbg";
    inherit version;

    src = fetchFromGitHub {
      owner = "cilium";
      repo = "cilium";
      rev = "v${version}";
      sha256 = "sha256-HcKRenRILpJCzJZbOYzrQrLlEeif9J9jJDKFzA6NtXc="; # tar-ball hash
    };

    vendorSha256 = lib.fakeSha256;
    subPackages = ["cilium-dbg/cmd"]; # ← correct path

    env.CGO_ENABLED = "0";
    ldflags = [
      "-s"
      "-w"
      "-X github.com/cilium/cilium/pkg/version.Version=v${version}"
    ];

    doCheck = false;

    meta = with lib; {
      description = "On-node Cilium debug CLI (replaces the old `cilium` command)";
      homepage = "https://github.com/cilium/cilium";
      license = licenses.asl20;
      maintainers = [maintainers.yourGithubHandle];
      platforms = platforms.linux;
    };
  }
