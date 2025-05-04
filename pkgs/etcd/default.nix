{
  lib,
  buildGoModule,
  fetchFromGitHub,
  symlinkJoin,
  ...
}:
##############################################################################
# Shared constants
##############################################################################
let
  version = "3.5.9";

  src = fetchFromGitHub {
    owner = "etcd-io";
    repo = "etcd";
    rev = "v${version}";
    sha256 = "sha256-Vp8U49fp0FowIuSSvbrMWjAKG2oDO1o0qO4izSnTR3U=";
  };

  common = {
    inherit version src;
    doCheck = false;
    env.CGO_ENABLED = "0";
  };

  ##########################################################################
  # Individual binaries (exactly as in your working snippet)
  ##########################################################################
  etcdutl = buildGoModule (common
    // {
      pname = "etcdutl";
      vendorHash = "sha256-i60rKCmbEXkdFOZk2dTbG5EtYKb5eCBSyMcsTtnvATs=";
      modRoot = "./etcdutl";
    });

  etcdctl = buildGoModule (common
    // {
      pname = "etcdctl";
      vendorHash = "sha256-awl/4kuOjspMVEwfANWK0oi3RId6ERsFkdluiRaaXlA=";
      modRoot = "./etcdctl";
    });

  etcdserver = buildGoModule (common
    // {
      pname = "etcdserver";
      vendorHash = "sha256-vu5VKHnDbvxSd8qpIFy0bA88IIXLaQ5S8dVUJEwnKJA=";
      modRoot = "./server";
      postBuild = ''mv "$GOPATH"/bin/{server,etcd} || true'';
    });
in
  ##############################################################################
  # Export all four artefacts; `etcd` is the roll-up package
  ##############################################################################
  let
    etcd = symlinkJoin {
      name = "etcd-${version}";
      paths = [etcdserver etcdctl etcdutl];
      doCheck = false;
    };
  in {
    inherit etcd etcdserver etcdctl etcdutl;
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

