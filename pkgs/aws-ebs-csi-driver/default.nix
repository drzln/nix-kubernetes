{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "aws-ebs-csi-driver";
  version = "v1.30.0";

  src = fetchFromGitHub {
    owner = "kubernetes-sigs";
    repo = "aws-ebs-csi-driver";
    rev = version;
    sha256 = "1q2akgwi1r5xpc2gs7k2k96mfkdq2q9n4f4s3p37gbsm3dd5aspn";
  };

  vendorHash = null;

  subPackages = ["cmd/ebs-plugin"]; # this is the main binary

  env.CGO_ENABLED = "0";

  ldflags = [
    "-s"
    "-w"
    "-X sigs.k8s.io/aws-ebs-csi-driver/pkg/driver.driverVersion=${version}"
  ];

  doCheck = false;

  meta = with lib; {
    description = "CSI driver for AWS EBS volumes";
    homepage = "https://github.com/kubernetes-sigs/aws-ebs-csi-driver";
    license = licenses.asl20;
    maintainers = [maintainers.yourGithubHandle];
    platforms = platforms.linux;
  };
}
