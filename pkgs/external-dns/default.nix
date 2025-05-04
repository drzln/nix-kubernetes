{
  lib,
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
  vendorHash = null;
  subPackages = ["."];
  env.CGO_ENABLED = "0";
  ldflags = [
    "-s"
    "-w"
    "-X github.com/kubernetes-sigs/external-dns/pkg/version.Version=${version}"
  ];
  doCheck = false;
}
