{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "spire-server";
  version = "1.8.7"; # latest stable at time of writing

  src = fetchFromGitHub {
    owner = "spiffe";
    repo = "spire";
    rev = "v${version}";
    sha256 = "sha256-D6NNG//1rM7EIzawKdMA/8nloqMNAkF75YyFpHvxUkI=";
  };

  vendorHash = null;

  subPackages = ["cmd/spire-server"];

  env.CGO_ENABLED = "0";

  ldflags = ["-s" "-w"];

  doCheck = false;

  meta = with lib; {
    description = "SPIRE server for managing SPIFFE identities (mTLS CA)";
    homepage = "https://spiffe.io";
    license = licenses.asl20;
    platforms = platforms.linux;
    maintainers = [maintainers.yourGithubHandle];
  };
}
