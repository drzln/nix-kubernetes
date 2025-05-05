# pkgs/etcd/default.nix
{
  buildGoModule,
  fetchFromGitHub,
  symlinkJoin,
  ...
}: let
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
in let
  etcd = symlinkJoin {
    name = "etcd-${version}";
    paths = [etcdserver etcdctl etcdutl];
    doCheck = false;
  };
in {inherit etcd etcdserver etcdctl etcdutl;}
