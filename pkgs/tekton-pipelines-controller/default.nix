# pkgs/tekton-pipeline-controller/default.nix
{
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
    sha256 = "sha256-uzmYXfK3X4UTBgI13pJUoutEIxbm/56vJvXvoZH6BsM=";
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
