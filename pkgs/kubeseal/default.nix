{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "kubeseal";
  version = "v0.29.0";
  src = fetchFromGitHub {
    owner = "bitnami-labs";
    repo = "sealed-secrets";
    rev = version;
    sha256 = "sha256-unPqjheT8/2gVQAwvzOvHtG4qTqggf9o0M5iLwl1eh4=";
  };
  vendorHash = "sha256-4BseFdfJjR8Th+NJ82dYsz9Dym1hzDa4kB4bpy71q7Q=";
  subPackages = ["cmd/kubeseal"];
  env.CGO_ENABLED = "0";
  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];
  doCheck = false;
}
