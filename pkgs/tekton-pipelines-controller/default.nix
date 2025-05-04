{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "tekton-pipelines-controller";
  version = "v0.58.0";
  src = fetchFromGitHub {
    owner = "tektoncd";
    repo = "pipeline";
    rev = version;
    sha256 = "1q2akgwi1r5xpc2gs7k2k96mfkdq2q9n4f4s3p37gbsm3dd5aspn";
  };
  vendorHash = null;
  subPackages = ["cmd/controller"];
  env.CGO_ENABLED = "0";
  ldflags = [
    "-s"
    "-w"
    "-X github.com/tektoncd/pipeline/version.PipelineVersion=${version}"
  ];
  doCheck = false;
}
