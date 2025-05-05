# pkgs/coredns/default.nix
{
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
  vendorHash = "sha256-f7ql30gJNzeldJFM0KXfLReAUSQwdyEmf7xW6lgCkpk=";
  subPackages = ["."];
  ldflags = [
    "-s"
    "-w"
  ];
  doCheck = false;
}
