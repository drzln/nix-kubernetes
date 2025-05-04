{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "kubernetes-dashboard";
  version = "v2.7.0";

  src = fetchFromGitHub {
    owner = "kubernetes";
    repo = "dashboard";
    rev = version;
    sha256 = "1q2akgwi1r5xpc2gs7k2k96mfkdq2q9n4f4s3p37gbsm3dd5aspn";
  };

  vendorHash = null;

  subPackages = ["cmd/dashboard"]; # ← Go backend binary

  env.CGO_ENABLED = "0";

  ldflags = [
    "-s"
    "-w"
    "-X github.com/kubernetes/dashboard/src/app/backend/version.Version=${version}"
  ];

  doCheck = false;

  meta = with lib; {
    description = "Web UI for Kubernetes clusters";
    homepage = "https://github.com/kubernetes/dashboard";
    license = licenses.asl20;
    maintainers = [maintainers.yourGithubHandle];
    platforms = platforms.linux;
  };
}
