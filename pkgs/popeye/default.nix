{
  lib,
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

  vendorHash = "sha256-iCsEYbEENDOg69wdWu9QQ8tTGxvaY2i/Hboc6XSYyEM=";

  subPackages = ["."];

  env.CGO_ENABLED = "0";

  ldflags = [
    "-s"
    "-w"
    "-X github.com/derailed/popeye/cmd.version=${version}"
  ];

  doCheck = false;

  meta = with lib; {
    description = "Popeye scans your Kubernetes clusters and reports potential issues";
    homepage = "https://github.com/derailed/popeye";
    license = licenses.asl20;
    platforms = platforms.linux;
    maintainers = [maintainers.yourGithubHandle];
  };
}
