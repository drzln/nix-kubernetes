{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "csi-snapshot-controller";
  version = "v6.3.3"; # latest stable at time of writing

  src = fetchFromGitHub {
    owner = "kubernetes-csi";
    repo = "external-snapshotter";
    rev = version;
    sha256 = "1q2akgwi1r5xpc2gs7k2k96mfkdq2q9n4f4s3p37gbsm3dd5aspn";
  };

  vendorHash = null;

  subPackages = ["cmd/snapshot-controller"];

  env.CGO_ENABLED = "0";

  ldflags = [
    "-s"
    "-w"
  ];

  doCheck = false;

  meta = with lib; {
    description = "CSI external snapshot controller for managing PVC snapshots";
    homepage = "https://github.com/kubernetes-csi/external-snapshotter";
    license = licenses.asl20;
    platforms = platforms.linux;
    maintainers = [maintainers.yourGithubHandle];
  };
}
