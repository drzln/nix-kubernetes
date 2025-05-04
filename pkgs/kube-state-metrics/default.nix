{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "kube-state-metrics";
  version = "2.10.1"; # latest as of May 2025

  src = fetchFromGitHub {
    owner = "kubernetes";
    repo = "kube-state-metrics";
    rev = "v${version}";
    sha256 = "1q2akgwi1r5xpc2gs7k2k96mfkdq2q9n4f4s3p37gbsm3dd5aspn";
  };

  vendorHash = null;

  subPackages = ["."]; # entry point is repo root

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  doCheck = false;

  meta = with lib; {
    description = "Expose Kubernetes object state as Prometheus metrics";
    homepage = "https://github.com/kubernetes/kube-state-metrics";
    license = licenses.asl20;
    platforms = platforms.linux;
    maintainers = [maintainers.yourGithubHandle];
  };
}
