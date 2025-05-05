# pkgs/external-dns/default.nix
{
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "external-dns";
  version = "0.14.2";
  src = fetchFromGitHub {
    owner = "kubernetes-sigs";
    repo = "external-dns";
    rev = "v${version}";
    sha256 = "sha256-FT+yk+01JdcFOgSvpSn8NXsig0y8pToadBQ6RdFaugE=";
  };
  vendorHash = "sha256-hahwwd++1q+6akQcTTQ6E5kyIuKVOveYKlX3WQHqMz8=";
  subPackages = ["."];
  env.CGO_ENABLED = "0";
  ldflags = [
    "-s"
    "-w"
    "-X github.com/kubernetes-sigs/external-dns/pkg/version.Version=${version}"
  ];
  doCheck = false;
}
