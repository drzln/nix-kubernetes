{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "popeye";
  version = "v0.10.0"; # adjust to latest if needed

  src = fetchFromGitHub {
    owner = "derailed";
    repo = "popeye";
    rev = version;
    sha256 = "1q2akgwi1r5xpc2gs7k2k96mfkdq2q9n4f4s3p37gbsm3dd5aspn";
  };

  vendorHash = null;

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
