# pkgs/coredns/default.nix
{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "coredns";
  version = "1.12.1";

  src = fetchFromGitHub {
    owner = "coredns";
    repo = "coredns";
    rev = "v${version}";
    sha256 = "sha256-XZoRN907PXNKV2iMn51H/lt8yPxhPupNfJ49Pymdm9Y=";
  };
  vendorHash = null;
  subPackages = ["."];
  ldflags = [
    "-s"
    "-w"
  ];
  doCheck = false;
}
