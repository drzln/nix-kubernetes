{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "k9s";
  version = "v0.32.4";

  src = fetchFromGitHub {
    owner = "derailed";
    repo = "k9s";
    rev = version;
    sha256 = "sha256-0MAnN1ekzHLs25EspDN3xacmDvwXGwKO/5RsCMMwTI8=";
  };
  vendorHash = null;
  subPackages = ["."];
  env.CGO_ENABLED = "0";
  ldflags = [
    "-s"
    "-w"
    "-X github.com/derailed/k9s/cmd.version=${version}"
  ];
  doCheck = false;
}
