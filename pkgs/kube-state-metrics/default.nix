{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "kube-state-metrics";
  version = "2.10.1";
  src = fetchFromGitHub {
    owner = "kubernetes";
    repo = "kube-state-metrics";
    rev = "v${version}";
    sha256 = "sha256-RwJpRBGtRKKsNAwiZskqfyq4r0iiS4Evdmin1EjDgtg=";
  };
  vendorHash = "sha256-Qi/mStPsf20ngsUl/3b0FcSI0hK6RCeMm5bGqerQkLk=";
  subPackages = ["."];
  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];
  doCheck = false;
}
