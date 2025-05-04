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
    sha256 = "sha256-iT+Plrk0FsDnUISx2ZNSqxx777Yw+xGq8YWWgQpmzGw=";
  };

  vendorHash = "sha256-FosfFQ471zAMhtnSOXPLtzG6OxnyFigbgpe9DkGjjsY=";

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
