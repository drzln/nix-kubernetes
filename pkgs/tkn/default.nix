# pkgs/tkn/default.nix
{
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "tkn";
  version = "v0.38.0";
  src = fetchFromGitHub {
    owner = "tektoncd";
    repo = "cli";
    rev = version;
    sha256 = "sha256-gg3FhPDXqnn3y/tcvlHTd0t8KxtPGTrN/2buBSVffBg=";
  };
  vendorHash = null;
  subPackages = ["./cmd/tkn"];
  env.CGO_ENABLED = "0";
  ldflags = [
    "-s"
    "-w"
    "-X github.com/tektoncd/cli/pkg/version.Version=${version}"
  ];
  doCheck = false;
}
