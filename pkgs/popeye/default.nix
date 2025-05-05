# pkgs/popeye/default.nix
{
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "popeye";
  version = "v0.10.0";
  src = fetchFromGitHub {
    owner = "derailed";
    repo = "popeye";
    rev = version;
    sha256 = "sha256-iCsEYbEENDOg69wdWu9QQ8tTGxvaY2i/Hboc6XSYyEM=";
  };
  vendorHash = "sha256-aLTzhBMwQHa6twzBC3FyMsZa1vQsBDdg4MpzJWZz3n4=";
  subPackages = ["."];
  env.CGO_ENABLED = "0";
  ldflags = [
    "-s"
    "-w"
    "-X github.com/derailed/popeye/cmd.version=${version}"
  ];
  doCheck = false;
}
