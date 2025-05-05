# pkgs/cmctl/default.nix
{
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "cmctl";
  version = "v2.2.0";
  src = fetchFromGitHub {
    owner = "cert-manager";
    repo = "cmctl";
    rev = version;
    sha256 = "sha256-Kr7vwVW6v08QRbJDs2u0vK241ljNfhLVYIQCBl31QSs=";
  };
  vendorHash = "sha256-D83Ufpa7PLQWBCHX5d51me3aYprGzc9RoKVma2Ax1Is=";
  subPackages = ["."];
  ldflags = [
    "-s"
    "-w"
    "-X github.com/cert-manager/cmctl/pkg/build.name=cmctl"
  ];
  doCheck = false;
}
