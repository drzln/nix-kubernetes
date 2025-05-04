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
    sha256 = "sha256-REPLACE_AFTER_PREFETCH";
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
