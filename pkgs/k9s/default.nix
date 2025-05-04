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
    sha256 = "1q2akgwi1r5xpc2gs7k2k96mfkdq2q9n4f4s3p37gbsm3dd5aspn";
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

  meta = with lib; {
    description = "K9s - Kubernetes CLI terminal UI";
    homepage = "https://k9scli.io";
    license = licenses.asl20;
    maintainers = [maintainers.yourGithubHandle];
    platforms = platforms.linux;
  };
}
