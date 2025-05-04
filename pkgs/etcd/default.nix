{
  lib,
  buildGoModule,
  fetchFromGitHub,
  ...
}: let
  version = "3.5.14";
in
  buildGoModule {
    pname = "etcd";
    inherit version;

    src = fetchFromGitHub {
      owner = "etcd-io";
      repo = "etcd";
      rev = "v${version}";
      sha256 = "sha256-nTVjgNMnB6775ubzK7ezOxR5Z0z5PBxx88CxtbxGxrY=";
    };

    vendorHash = null;

    # <- correct path!
    subPackages = ["server/v3"];

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
    };
  }
