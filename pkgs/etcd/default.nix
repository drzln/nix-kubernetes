{
  lib,
  buildGoModule,
  fetchFromGitHub,
  ...
}: let
  # Keep etcd roughly in sync with your control-plane
  version = "3.5.14";
in
  buildGoModule rec {
    pname = "etcd";
    inherit version;

    ########################################################################
    # Source
    ########################################################################
    src = fetchFromGitHub {
      owner = "etcd-io";
      repo = "etcd";
      rev = "v${version}";
      # Replace after `nix-prefetch-url ...`
      sha256 = "sha256-nTVjgNMnB6775ubzK7ezOxR5Z0z5PBxx88CxtbxGxrY=";
    };

    ########################################################################
    # Go module vendoring (set after first build)
    ########################################################################
    vendorHash = null;

    ########################################################################
    # Build only the server binary
    ########################################################################
    subPackages = ["server"];

    # Static, stripped
    env.CGO_ENABLED = "0";
    ldflags = [
      "-s"
      "-w"
      "-X go.etcd.io/etcd/server/v3/version.Version=v${version}"
    ];

    doCheck = false;

    meta = with lib; {
      description = "Distributed reliable key-value store (server binary)";
      homepage = "https://github.com/etcd-io/etcd";
      license = licenses.asl20;
      platforms = platforms.linux;
      maintainers = [maintainers.yourGithubHandle];
    };
  }
# pkgs: rec {
#   version = "3.5.9";
#   src = pkgs.fetchFromGitHub {
#     owner = "etcd-io";
#     repo = "etcd";
#     rev = "v${version}";
#     sha256 = "sha256-Vp8U49fp0FowIuSSvbrMWjAKG2oDO1o0qO4izSnTR3U=";
#   };
#   etcdutl = pkgs.buildGoModule {
#     pname = "etcdutl";
#     inherit version src;
#     doCheck = false;
#     vendorHash = "sha256-i60rKCmbEXkdFOZk2dTbG5EtYKb5eCBSyMcsTtnvATs=";
#     modRoot = "./etcdutl";
#     env.CGO_ENABLED = "0";
#   };
#   etcdctl = pkgs.buildGoModule {
#     pname = "etcdctl";
#     inherit version src;
#     doCheck = false;
#     vendorHash = "sha256-awl/4kuOjspMVEwfANWK0oi3RId6ERsFkdluiRaaXlA=";
#     modRoot = "./etcdctl";
#     env.CGO_ENABLED = "0";
#   };
#   etcdserver = pkgs.buildGoModule {
#     pname = "etcdserver";
#     inherit version src;
#     doCheck = false;
#     vendorHash = "sha256-vu5VKHnDbvxSd8qpIFy0bA88IIXLaQ5S8dVUJEwnKJA=";
#     modRoot = "./server";
#     env.CGO_ENABLED = "0";
#     postBuild = ''
#       mv "$GOPATH"/bin/{server,etcd} || true
#     '';
#   };
#   etcd = pkgs.symlinkJoin {
#     name = "etcd-${version}";
#     paths = [etcdserver etcdctl etcdutl];
#     doCheck = false;
#   };
# }

