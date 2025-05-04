{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "snapshot-validation-webhook";
  version = "v6.3.3";

  src = fetchFromGitHub {
    owner = "kubernetes-csi";
    repo = "external-snapshotter";
    rev = version;
    sha256 = "1q2akgwi1r5xpc2gs7k2k96mfkdq2q9n4f4s3p37gbsm3dd5aspn";
  };

  vendorHash = null;

  subPackages = ["cmd/snapshot-validation-webhook"];

  env.CGO_ENABLED = "0";

  ldflags = [
    "-s"
    "-w"
  ];

  doCheck = false;

  meta = with lib; {
    description = "Admission webhook that validates VolumeSnapshot CRDs in Kubernetes";
    homepage = "https://github.com/kubernetes-csi/external-snapshotter";
    license = licenses.asl20;
    maintainers = [maintainers.yourGithubHandle];
    platforms = platforms.linux;
  };
}
