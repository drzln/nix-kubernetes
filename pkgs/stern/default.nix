{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "stern";
  version = "v1.29.0";

  src = fetchFromGitHub {
    owner = "stern";
    repo = "stern";
    rev = version;
    sha256 = "1q2akgwi1r5xpc2gs7k2k96mfkdq2q9n4f4s3p37gbsm3dd5aspn";
  };

  vendorHash = null;

  subPackages = ["."];

  env.CGO_ENABLED = "0";

  ldflags = [
    "-s"
    "-w"
    "-X github.com/stern/stern/cmd.version=${version}"
  ];

  doCheck = false;

  meta = with lib; {
    description = "Stern - tail multiple Kubernetes pods and containers logs";
    homepage = "https://github.com/stern/stern";
    license = licenses.asl20;
    maintainers = [maintainers.yourGithubHandle];
    platforms = platforms.linux;
  };
}
